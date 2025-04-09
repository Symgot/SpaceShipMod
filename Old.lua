
-- Function to handle spaceship takeoff
function SpaceShip.shipTakeoff(player)
    local src_surface = player.surface
    local dest_surface
    -- Check if the player is in the cockpit or standing on ship flooring
    local player_tile = src_surface.get_tile(player.position)
    if player.vehicle and player.vehicle.name == "spaceship-control-hub-car" then
        -- Player is in the cockpit, proceed
        storage.spaceships[storage.opened_entity_id].player_in_cockpit = true
    elseif player_tile and player_tile.name ~= "spaceship-flooring" then
        -- Player is not standing on ship flooring, proceed
        storage.spaceships[storage.opened_entity_id].player_in_cockpit = false
    else
        player.print("Error: You must be in the cockpit or not on ship to initiate takeoff.")
        return
    end

    for id, plat in pairs(player.force.platforms) do
        if plat.space_location then
            if plat.space_location.name == player.surface.name and plat.space_location.type == "planet" then
                dest_surface = player.force.platforms[id]
            end
        end
    end

    if not dest_surface then
        player.print("Error: No stations found, or not on planet!")
        return
    end

    storage.spaceships[storage.opened_entity_id].taking_off = true -- Flag to indicate takeoff process has started

    if not storage.spaceships[storage.opened_entity_id].scanned then
        player.print("Error: No scanned ship data found. Run a ship scan first.")
        return
    end

    -- Save the player's body (character) in storage
    storage.player_body = player.character

    -- Change the player's controller to ghost and move their camera to the target surface
    local player_pos = player.position
    local dest_center = { x = 0, y = 0 }
    player.set_controller({ type = defines.controllers.ghost }) -- Set the player to ghost contro
    player.teleport(dest_center, dest_surface.surface)

    -- Highlight the ship area using combined renders

    storage.player_position_on_render = player.position
    -- Store the highlight data for later updates
    storage.highlight_data = storage.highlight_data or {}
    storage.highlight_data = SpaceShip.create_combined_renders(player, storage.spaceships[storage.opened_entity_id]
        .floor, false, { x = 2, y = -4 })
    player.print("rends count: " .. #storage.highlight_data)
    storage.highlight_data_player_index = player.index

    -- Store the player state for later use
    storage.takeoff_player = player.index

    -- Create a GUI in the top-left corner with Confirm and Cancel buttons
    local gui = player.gui.screen.add {
        type = "frame",
        name = "takeoff_confirmation_gui",
        caption = "Confirm Takeoff",
        direction = "vertical"
    }
    gui.location = { x = 10, y = 10 }

    gui.add {
        type = "button",
        name = "confirm_takeoff",
        caption = "Confirm"
    }
    gui.add {
        type = "button",
        name = "cancel_takeoff",
        caption = "Cancel"
    }
end

-- Usage in finalizeTakeoff
function SpaceShip.finalizeTakeoff(player)
    if not storage.spaceships[storage.opened_entity_id].scanned then
        player.print("Error: No scanned ship data found.")
        return
    end

    local src_surface = storage.spaceships[storage.opened_entity_id].surface -- Retrieve the source surface
    local dest_surface = player.surface
    local dest_center = { x = math.ceil(player.position.x), y = math.floor(player.position.y - 5) }

    -- Define the types of entities to exclude
    local excluded_types = {
        ["logistic-robot"] = true,
        ["contruction-robot"] = true,
    }
    storage.spaceships[storage.opened_entity_id].planet_orbiting = src_surface.name
    -- Clone the ship area to the destination surface
    SpaceShip.clone_ship_area(src_surface, dest_surface, dest_center, excluded_types)

    -- Teleport the player to the spaceship control hub car and make them enter it
    local control_hub_car
    local search_area = {
        { x = dest_center.x - 50, y = dest_center.y - 50 }, -- Define a reasonable search area around the cloned ship
        { x = dest_center.x + 50, y = dest_center.y + 50 }
    }

    -- Search for the spaceship-control-hub-car in the newly cloned ship
    local entities_in_area = dest_surface.find_entities_filtered({
        area = search_area,
        name = "spaceship-control-hub-car"
    })

    if #entities_in_area > 0 then
        control_hub_car = entities_in_area[1] -- Assume the first found entity is the control hub car
    end

    if control_hub_car and control_hub_car.valid then
        -- Restore the player's body
        if storage.player_body and storage.player_body.valid then
            -- Teleport the player to their body
            local body_surface = storage.player_body.surface
            local body_position = storage.player_body.position
            player.teleport(body_position, body_surface)

            -- Change the player's controller back to character
            player.set_controller({ type = defines.controllers.character, character = storage.player_body })
            storage.player_body = nil -- Clear the reference to the player's body
        else
            player.print("Error: Unable to restore the player's body.")
            return
        end

        -- Teleport the player to the control hub car and make them enter it
        player.teleport(control_hub_car.position, control_hub_car.surface)
        player.driving = true -- Make the player enter the vehicle
        player.print("You have entered the spaceship control hub car at the destination.")
    else
        player.print("Error: Unable to find the spaceship control hub car at the destination.")
    end

    -- Close the GUI
    if player.gui.screen["takeoff_confirmation_gui"] then
        player.gui.screen["takeoff_confirmation_gui"].destroy()
    end

    -- Destroy all renders in storage.highlight_data
    if storage.highlight_data then
        for _, rendering in pairs(storage.highlight_data) do
            if rendering.valid then
                rendering.destroy()
            end
        end
        storage.highlight_data[player.index] = nil -- Clear the player's highlight data
    end

    player.print("Takeoff confirmed! Ship cloned to orbit.")
    storage.spaceships[storage.opened_entity_id].taking_off = false -- Reset the taking off flag
    -- Search for the spaceship-control-hub-car in the newly cloned ship
    local entities_in_area = dest_surface.find_entities_filtered({
        area = search_area,
        name = "spaceship-control-hub"
    })
    storage.spaceships[storage.opened_entity_id].hub = entities_in_area[1]
end

-- Function to cancel spaceship takeoff
function SpaceShip.cancelTakeoff(player)
    local src_surface = game.surfaces["nauvis"] -- Assuming "nauvis" is the source surface.
    local player_index = storage.takeoff_player
    local player = game.get_player(player_index)

    if player then
        -- Restore the player's body
        if storage.player_body and storage.player_body.valid then
            -- Teleport the player to the surface where their body is located
            local body_surface = storage.player_body.surface
            local body_position = storage.player_body.position
            player.teleport(body_position, body_surface)

            -- Change the player's controller back to character
            player.set_controller({ type = defines.controllers.character, character = storage.player_body })
            storage.player_body = nil -- Clear the reference to the player's body
        else
            player.print("Error: Unable to restore the player's body.")
        end
    end

    -- Clear highlights and GUI.
    for _, id in ipairs(storage.takeoff_highlights or {}) do
        rendering.destroy(id)
    end
    storage.takeoff_highlights = nil
    if player.gui.screen["takeoff_confirmation_gui"] then
        player.gui.screen["takeoff_confirmation_gui"].destroy()
    end

    player.print("Takeoff canceled. Returning to the ship.")
    storage.spaceships[storage.opened_entity_id].taking_off = false -- Reset the taking off flag
end