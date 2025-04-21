local SpaceShipGuis = require("SpaceShipGuisScript")
local SpaceShipFunctions = require("SpaceShipFunctionsScript")
local SpaceShip = require("spacShip")

storage.highlight_data = storage.highlight_data or {} -- Stores highlight data for each player

local function handle_built_entity(entity, player)
    if not (entity and entity.valid) then return end

    local surface = entity.surface

    -- Spawn the car on the spaceship controller:
    if entity.name == "spaceship-control-hub" then
        storage.spaceships = storage.spaceships or {}
        local count = table_size(storage.spaceships) + 1
        local my_ship = SpaceShip.new("Explorer" .. count, count, player)
        entity.tags = { id = 1 }
        my_ship.hub = entity
        storage.spaceships[my_ship.id] = my_ship
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
end

local function handle_mined_entity(entity)
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
        for key, value in pairs(storage.spaceships) do
            if value.hub.unit_number == entity.unit_number then
                storage.spaceships[key] = nil
            end
        end
    end
end

script.on_event(defines.events.on_gui_click, function(event)
    SpaceShipGuis.handle_button_click(event)
end)

script.on_event(defines.events.on_built_entity, function(event)
    local player = game.get_player(event.player_index)
    handle_built_entity(event.entity, player)
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
    local player = game.get_player(event.robot.force.players[1].index)
    handle_built_entity(event.entity, player)
end)

script.on_event(defines.events.on_space_platform_built_entity, function(event)
    local player = game.get_player(event.platform.force.players[1].index)
    handle_built_entity(event.entity, player)
end)

script.on_event(defines.events.on_player_mined_entity, function(event)
    handle_mined_entity(event.entity)
end)

script.on_event(defines.events.on_robot_mined_entity, function(event)
    handle_mined_entity(event.entity)
end)

script.on_event(defines.events.on_space_platform_mined_entity, function(event)
    handle_mined_entity(event.entity)
end)

script.on_event(defines.events.on_gui_opened, function(event)
    local player = game.get_player(event.player_index)
    local opened_entity = event.entity
    local ship

    if opened_entity and opened_entity.valid and opened_entity.name == "spaceship-control-hub" then
        for _, value in pairs(storage.spaceships) do
            if value.hub.unit_number == opened_entity.unit_number then
                ship = storage.spaceships[value.id]
            end
        end
        SpaceShipGuis.create_spaceship_gui(player, ship)
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    SpaceShipGuis.close_spaceship_gui(event)
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
        goto continue
    end
    if not storage.spaceships or not storage.spaceships[storage.opened_entity_id] then goto continue end
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
    ::continue::
    if game.tick % 10 == 0 and storage.scan_state then
        SpaceShip.continue_scan_ship()
    end

    if game.tick % 60 == 0 then
        for _, ship in pairs(storage.spaceships or {}) do
            if ship.schedule_gui and ship.schedule_gui.valid then
                local station_scroll = ship.schedule_gui["vertical-flow"]["flow"]["station-scroll-panel"]
                if station_scroll then
                    for _, station in pairs(station_scroll.children) do
                        if station.name:match("^station%d+$") then
                            local condition_gui = station["spaceship-condition-gui"]
                            if condition_gui then
                                local condition_flow = condition_gui["main_container"]["condition_flow"]
                                if condition_flow then
                                    for _, condition in pairs(condition_flow.children) do
                                        if condition.name:match("^condition_row_%d+$") then
                        SpaceShipGuis.check_condition_row(condition)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        SpaceShip.check_automatic_behavior()
    end
end)

script.on_event(defines.events.on_player_driving_changed_state, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end

    local vehicle = event.entity
    if not vehicle or not vehicle.valid then return end

    if vehicle.name == "spaceship-control-hub-car" then
        local search_area = {
            { x = vehicle.position.x - 50, y = vehicle.position.y - 50 }, -- Define a reasonable search area around the cloned ship
            { x = vehicle.position.x + 50, y = vehicle.position.y + 50 }
        }
        hub = event.entity.surface.find_entities_filtered { area = search_area, name = "spaceship-control-hub" }
        local ship
        for _, value in pairs(storage.spaceships) do
            if value.hub.unit_number == hub[1].unit_number then
                ship = storage.spaceships[value.id]
            end
        end
        -- Player entered/exited the cockpit
        if player.vehicle then
            ship.player_in_cockpit = player
            -- Player entered the cockpit
            --SpaceShipGuis.create_spaceship_gui(player)
        else
            ship.player_in_cockpit = nil
        end
    elseif vehicle.name == "space-platform-hub" then
        player.leave_space_platform()
    end
end)

script.on_event(defines.events.on_selected_entity_changed, function(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then return end

    local selected_entity = player.selected -- The entity the player is currently hovering over
    -- Check if the player is hovering over the spaceship-control-hub
    if selected_entity and selected_entity.valid and selected_entity.name == "spaceship-control-hub" then
        storage.spaceships = storage.spaceships or {}
        local ship
        for _, value in pairs(storage.spaceships) do
            if value.hub.unit_number == selected_entity.unit_number then
                ship = storage.spaceships[value.id]
            end
        end
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
                    hovering_gui.add { type = "label", name = key .. tostring(value), caption = key .. ":" .. tostring(value) }
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

script.on_event(defines.events.on_space_platform_changed_state, function(event)
    local plat = event.platform
    if plat.name == "SpaceShipExplorer1" and event.platform.state == defines.space_platform_state.waiting_at_station then
        game.print("Spaceship Explorer 1 has been changed state to:" .. plat.state)
        hub = plat.surface.find_entities_filtered {name = "spaceship-control-hub" }
        local ship
        for _, value in pairs(storage.spaceships) do
            if value.hub.unit_number == hub[1].unit_number then
                ship = storage.spaceships[value.id]
            end
        end
        ship.planet_orbiting = plat.space_location.name
    elseif plat.name == "SpaceShipExplorer1" and event.platform.state == defines.space_platform_state.on_the_path then
        game.print("Spaceship Explorer 1 has been changed state to:" .. plat.state)
        hub = plat.surface.find_entities_filtered {name = "spaceship-control-hub" }
        local ship
        for _, value in pairs(storage.spaceships) do
            if value.hub.unit_number == hub[1].unit_number then
                ship = storage.spaceships[value.id]
            end
        end
        ship.planet_orbiting = "none"
    end
end)


-- Add handlers for signal chooser and value changes
script.on_event(defines.events.on_gui_elem_changed, function(event)
    if event.element.name == "condition_type_chooser" then
        SpaceShipGuis.save_wait_conditions(event.element.parent.parent.parent.parent.parent)
    end
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
    if event.element.name:match("^condition_value_%d+$") then
        SpaceShipGuis.save_wait_conditions(event.element.parent.parent.parent.parent.parent)
    end
end)

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    if event.element.name:match("^comparison_dropdown_%d+$") then
        SpaceShipGuis.save_wait_conditions(event.element.parent.parent.parent.parent.parent)
    end
    SpaceShipGuis.handle_dropdown_selection(event)
end)

script.on_event(defines.events.on_gui_switch_state_changed, function(event)
    if event.element.name == "auto-manual-switch" then
        SpaceShipGuis.handle_button_click(event)
    end
end)
