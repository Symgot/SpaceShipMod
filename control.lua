local SpaceShipGuis = require("SpaceShipGuisScript")
local SpaceShipFunctions = require("SpaceShipFunctionsScript")
local SpaceShip = require("spacShip")
local Travel = require("travel")

storage.highlight_data = storage.highlight_data or {} -- Stores highlight data for each player

script.on_event(defines.events.on_gui_click, function(event)
    local elem = event.element
    local player = game.get_player(event.player_index)
    if not (elem and elem.valid) then return end

    -- Delegate button click handling to SpaceShipGuis
    SpaceShipGuis.handle_button_click(player, elem.name)
end)

script.on_event(defines.events.on_built_entity, function(event)
    local entity = event.entity
    if not (entity and entity.valid) then return end

    local surface = entity.surface

    -- Spawn the car on the spaceship controller:
    if entity.name == "spaceship-control-hub" then
        local player = game.get_player(event.player_index)
        storage.spaceships = storage.spaceships or {}
        count = table_size(storage.spaceships) + 1
        local my_ship = SpaceShip.new("Explorer" .. count, (table_size(storage.spaceships) + 1), player)
        my_ship.hub = entity
        storage.spaceships[entity.unit_number] = my_ship
        local car_position = { x = entity.position.x, y = entity.position.y + 4.5 } -- Car spawns slightly lower so player can enter it
        local car = surface.create_entity {
            name = "spaceship-control-hub-car",
            position = car_position,
            force = entity.force
        }
        if car then
            car.orientation = 0.0 -- Align the car with the controller orientation, if needed.
            player.print("Spaceship control hub car spawned!")
        else
            player.print("Error: Unable to spawn spaceship control hub car!")
        end
    end
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
    local entity = event.entity
    if not (entity and entity.valid) then return end

    local surface = entity.surface

    -- Spawn the car on the spaceship controller:
    if entity.name == "spaceship-control-hub" then
        local player = game.get_player(event.robot.force.players[1].index)
        storage.spaceships = storage.spaceships or {}
        local my_ship = SpaceShip.new("Explorer" .. (#storage.spaceships + 1), (#storage.spaceships + 1), player)
        my_ship.hub = entity
        storage.spaceships[entity.unit_number] = my_ship
        local car_position = { x = entity.position.x, y = entity.position.y + 4.5 } -- Car spawns slightly lower so player can enter it
        local car = surface.create_entity {
            name = "spaceship-control-hub-car",
            position = car_position,
            force = entity.force
        }
        if car then
            car.orientation = 0.0 -- Align the car with the controller orientation, if needed.
            player.print("Spaceship control hub car spawned!")
        else
            player.print("Error: Unable to spawn spaceship control hub car!")
        end
    end
end)

script.on_event(defines.events.on_space_platform_built_entity,function(event)
    local entity = event.entity
    if not (entity and entity.valid) then return end

    local surface = entity.surface

    -- Spawn the car on the spaceship controller:
    if entity.name == "spaceship-control-hub" then
        local player = game.get_player(event.platform.force.players[1].index)
        storage.spaceships = storage.spaceships or {}
        local my_ship = SpaceShip.new("Explorer" .. (#storage.spaceships + 1), (#storage.spaceships + 1), player)
        my_ship.hub = entity
        storage.spaceships[entity.unit_number] = my_ship
        local car_position = { x = entity.position.x, y = entity.position.y + 4.5 } -- Car spawns slightly lower so player can enter it
        local car = surface.create_entity {
            name = "spaceship-control-hub-car",
            position = car_position,
            force = entity.force
        }
        if car then
            car.orientation = 0.0 -- Align the car with the controller orientation, if needed.
            player.print("Spaceship control hub car spawned!")
        else
            player.print("Error: Unable to spawn spaceship control hub car!")
        end
    end
end)

script.on_event(defines.events.on_player_mined_entity, function(event)
    local entity = event.entity
    if not (entity and entity.valid) then return end
    -- Remove the car associated with the mined hub
    if entity.name == "spaceship-control-hub" then
        local area = {
            { entity.position.x - 2, entity.position.y },
            { entity.position.x + 2, entity.position.y + 6 }
        }
        local cars = entity.surface.find_entities_filtered {
            area = area,
            name = "spaceship-control-hub-car"
        }
        for _, car in pairs(cars) do
            car.destroy()
        end
        storage.spaceships[entity.unit_number] = nil
    end
end)

script.on_event(defines.events.on_robot_mined_entity, function(event)
    local entity = event.entity
    if not (entity and entity.valid) then return end
    -- Remove the car associated with the mined hub
    if entity.name == "spaceship-control-hub" then
        local area = {
            { entity.position.x - 2, entity.position.y },
            { entity.position.x + 2, entity.position.y + 6 }
        }
        local cars = entity.surface.find_entities_filtered {
            area = area,
            name = "spaceship-control-hub-car"
        }
        for _, car in pairs(cars) do
            car.destroy()
        end
        storage.spaceships[entity.unit_number] = nil
    end
end)

script.on_event(defines.events.on_space_platform_mined_entity, function(event)
    local entity = event.entity
    if not (entity and entity.valid) then return end
    -- Remove the car associated with the mined hub
    if entity.name == "spaceship-control-hub" then
        local area = {
            { entity.position.x - 2, entity.position.y },
            { entity.position.x + 2, entity.position.y + 6 }
        }
        local cars = entity.surface.find_entities_filtered {
            area = area,
            name = "spaceship-control-hub-car"
        }
        for _, car in pairs(cars) do
            car.destroy()
        end
        storage.spaceships[entity.unit_number] = nil
    end
end)

script.on_event(defines.events.on_gui_opened, function(event)
    local player = game.get_player(event.player_index)
    local opened_entity = event.entity

    if opened_entity and opened_entity.valid and opened_entity.name == "spaceship-control-hub" then
        SpaceShipGuis.create_spaceship_gui(player)
        storage.opened_entity_id = opened_entity.unit_number
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    local player = game.get_player(event.player_index)

    if event.entity and event.entity.name == "spaceship-control-hub" then
        -- Destroy the custom GUI when the main GUI for "spaceship-control-hub" is closed.
        local custom_gui = player.gui.relative["spaceship-controller-extended-gui"]
        if custom_gui then
            custom_gui.destroy()
            storage.opened_entity_id = nil
            player.print("Custom GUI closed with the main GUI.")
        end
    end
end)

script.on_event(defines.events.on_tick, function(event)
    -- Ensure storage.highlight_data is initialized
    --Astroid_spawn(event)
    storage.highlight_data = storage.highlight_data or {}

    -- Handle clearing hights after the timer expires
    if storage.scan_highlight_expire_tick and game.tick >= storage.scan_highlight_expire_tick then
        if storage.scan_highlights then
            for _, render_object in pairs(storage.scan_highlights) do
                if render_object.valid then
                    render_object.destroy() -- Destroy the highlight object
                end
            end
        end
        --rendering.clear()                        -- Remove all rendering highlights
        storage.scan_highlight_expire_tick = nil -- Reset the timer
        storage.scan_highlights = nil            -- Clear the highlights
    end

    if storage.SpaceShip and storage.SpaceShip[storage.opened_entity_id].scanned then
        return -- Exit f ship_data or reference_tile is missing
    end
    if not storage.spaceships or not storage.spaceships[storage.opened_entity_id] then return end
    if game.tick % 10 == 0 and
        storage.spaceships and
        storage.opened_entity_id and
        storage.spaceships[storage.opened_entity_id].taking_off then -- Update every 10 ticks
        local player = storage.spaceships[storage.opened_entity_id].player
        if not player or not player.valid then
            storage.highlight_data = nil
        end

        for _, rendering in pairs(storage.highlight_data) do
            if player and player.valid and rendering.valid then
                -- Calculate the offset between the stored position and the player's current position
                local offset_for_player = {
                    x = player.position.x - storage.player_position_on_render.x,
                    y = player.position.y - storage.player_position_on_render.y
                }

                -- Snap the offset to the grid
                local snapped_offset = {
                    x = math.floor(offset_for_player.x),
                    y = math.floor(offset_for_player.y)
                }

                -- Update the render position to follow the player and snap to grid
                rendering.left_top = {
                    x = math.floor(rendering.left_top.position.x + snapped_offset.x),
                    y = math.floor(rendering.left_top.position.y + snapped_offset.y)
                }
                rendering.right_bottom = {
                    x = math.floor(rendering.right_bottom.position.x + snapped_offset.x),
                    y = math.floor(rendering.right_bottom.position.y + snapped_offset.y)
                }
            end
        end
        -- Update the stored player position
        storage.player_position_on_render = {
            x = math.floor(player.position.x),
            y = math.floor(player.position.y)
        }
    end
end)

script.on_event(defines.events.on_player_driving_changed_state, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end

    local vehicle = player.vehicle

    if vehicle and vehicle.valid and vehicle.name == "spaceship-control-hub-car" then
        -- Player entered the cockpit, open the GUI
        SpaceShipGuis.create_spaceship_gui(player)
    else
        -- Player exited the cockpit, close all GUIs
        SpaceShipGuis.close_spaceship_gui(player)
    end
end)

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then return end

    local element = event.element
    if element and element.valid and element.name == "surface-dropdown" then
        SpaceShipGuis.handle_dropdown_selection(player, element.name, element.selected_index)
    end
end)

script.on_event(defines.events.on_selected_entity_changed, function(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then return end
    
    local selected_entity = player.selected -- The entity the player is currently hovering over

    -- Check if the player is hovering over the spaceship-control-hub
    if selected_entity and selected_entity.valid and selected_entity.name == "spaceship-control-hub" then
        storage.spaceships = storage.spaceships or {}
        if not storage.spaceships[selected_entity.unit_number] then return end
        ship = storage.spaceships[selected_entity.unit_number]
        -- Create a GUI if it doesn't already exist
        if not player.gui.screen["hovering_gui"] then
            local hovering_gui = player.gui.screen.add
                { type = "frame", name = "hovering_gui", caption = "Spaceship Info", direction = "vertical" }
            for key, value in pairs(ship) do
                if type(value) == "table" then
                    hovering_gui.add { type = "label", name = key .. table_size(value), caption = key .. ":" .. table_size(value) }
                elseif type(value) ~= "userdata" and type(value) ~= "boolean" then
                    hovering_gui.add { type = "label", name = key .. tostring(value), caption = key .. ":" .. tostring(value) }
                elseif type(value) == "boolean" then
                    if value then
                        value = "true"
                    else
                        value = "false"
                    end
                    hovering_gui.add { type = "label", ame = key .. tostring(value), caption = key .. ":" .. tostring(value) }
                elseif key == "surface" then
                    hovering_gui.add { type = "label", name = key .. tostring(value), caption = key .. ":" .. tostring(value.name) }
                end
            end
            hovering_gui.location = { x = 100, y = 100 } -- Position the GUI on the screen
        end
    else
        -- Destroy the GUI if the player is no longer hovering over the entity
        if player.gui.screen["hovering_gui"] then
            player.gui.screen["hovering_gui"].destroy()
        end
    end
end)


script.on_event(defines.events.on_entity_died, function(event)
    local entity = event.entity
    if not (entity and entity.valid) then return end

    -- Check if the destroyed entity is an asteroid
    if entity.name:find("asteroid") then
        local surface = entity.surface

        -- Check if the asteroid is on a spaceship surface
        for _, spaceship in pairs(storage.spaceships or {}) do
            if spaceship.own_surface and spaceship.surface == surface then
                -- Handle asteroid death
                --Travel.handle_asteroid_death(entity, event.force, event.cause)
                break
            end
        end
    end
end)

script.on_event(defines.events.on_player_driving_changed_state, function (event)
    local player = game.get_player(event.player_index)
    if event.entity.name == "space-platform-hub" then
        player.leave_space_platform()
    end
end)

script.on_event(defines.events.on_space_platform_changed_state, function (event)
    local plat = event.platform
    if plat.name == "SpaceShipExplorer1" and event.platform.state == defines.space_platform_state.waiting_at_station then
        game.print("Spaceship Explorer 1 has been changed state to:".. plat.state)
        hub = plat.surface.find_entities_filtered{name = "spaceship-control-hub"}
        ship = storage.spaceships[hub[1].unit_number]
        ship.planet_orbiting = plat.space_location.name
    elseif plat.name == "SpaceShipExplorer1" and event.platform.state == defines.space_platform_state.on_the_path then
        game.print("Spaceship Explorer 1 has been changed state to:".. plat.state)
        hub = plat.surface.find_entities_filtered{name = "spaceship-control-hub"}
        ship = storage.spaceships[hub[1].unit_number]
        ship.planet_orbiting = "none"
    end
end)
