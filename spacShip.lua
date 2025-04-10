local SpaceShip = {}
SpaceShip.__index = SpaceShip
local SpaceShipFunctions = require("SpaceShipFunctionsScript")
--[[
local SpaceShip = require("spacShip")
example script for how to Create a new spaceship

local player = game.get_player(1) -- Example: Get player with index 1
local my_ship = SpaceShip.new("Explorer", 1, player)
]] --

SpaceShip.hub               = nil
SpaceShip.floor             = {}                         -- Table to store floor tiles
SpaceShip.walls             = {}                         -- Table to store wall tiles
SpaceShip.entities          = {}                         -- Table to store entities
SpaceShip.name              = nil or "Unnamed SpaceShip" -- Name of the spaceship
SpaceShip.id                = nil or 0                   -- Unique ID for the spaceship
SpaceShip.player            = nil                        -- Reference to the player prototype
SpaceShip.referance_tile    = nil
SpaceShip.surface           = nil
SpaceShip.scanned           = false
SpaceShip.player_in_cockpit = false
SpaceShip.taking_off        = false
SpaceShip.own_surface       = false
SpaceShip.planet_orbiting   = nil

-- Constructor for creating a new SpaceShip
function SpaceShip.new(name, id, player)
    local self             = setmetatable({}, SpaceShip)

    -- Initialize spaceship parameters
    self.floor             = {}                          -- Table to store floor tiles
    self.walls             = {}                          -- Table to store wall tiles
    self.entities          = {}                          -- Table to store entities
    self.name              = name or "Unnamed SpaceShip" -- Name of the spaceship
    self.id                = id or 0                     -- Unique ID for the spaceship
    self.player            = player                      -- Reference to the player prototype
    self.hub               = nil
    self.referance_tile    = nil
    self.surface           = nil
    self.scanned           = false
    self.player_in_cockpit = false
    self.taking_off        = false
    self.own_surface       = false
    self.planet_orbiting   = nil

    -- Store the spaceship in the global storage
    return self
end

-- Create combined renders for grouped tiles
function SpaceShip.create_combined_renders(player, tiles, scan, offset)
    -- Ensure the player is valid
    if not player or not player.valid then
        return
    end

    local processed_tiles = {}
    local combined_renders = {}

    if not scan then
        -- Calculate the offset to make the reference tile start at (0, 0)
        local reference_tile = storage.spaceships[storage.opened_entity_id].reference_tile
        if not reference_tile then
            player.print("Error: Reference tile is missing from ship data.")
            return
        end
        offset = {
            x = -reference_tile.position.x + offset.x,
            y = -reference_tile.position.y + offset.y
        }
    end

    -- Helper function to check if a tile is already processed
    local function is_processed(x, y)
        return processed_tiles[x .. "," .. y]
    end

    -- Helper function to mark tiles as processed
    local function mark_processed(x, y)
        processed_tiles[x .. "," .. y] = true
    end

    -- Sort tiles by their position, starting from the bottom-right
    local sorted_tiles = {}
    for _, tile_data in pairs(tiles) do
        table.insert(sorted_tiles, tile_data)
    end
    table.sort(sorted_tiles, function(a, b)
        if a.position.y == b.position.y then
            return a.position.x > b.position.x -- Sort by x descending
        end
        return a.position.y > b.position.y     -- Sort by y descending
    end)

    -- Iterate over all tiles to group them into square areas
    for _, tile_data in ipairs(sorted_tiles) do
        local x, y = tile_data.position.x, tile_data.position.y
        if not is_processed(x, y) then
            -- Start a new square area
            local square_size = 1
            local valid_square = true

            -- Attempt to expand the square upward and to the left
            while valid_square do
                for dx = 0, square_size do
                    for dy = 0, square_size do
                        local check_x = x - dx
                        local check_y = y - dy
                        local tile_key = check_x .. "," .. check_y

                        -- Check if the tile exists and is not already processed
                        if not tiles[tile_key] or is_processed(check_x, check_y) then
                            valid_square = false
                            break
                        end
                    end
                    if not valid_square then
                        break
                    end
                end

                if valid_square then
                    square_size = square_size + 1
                end
            end

            -- Create a render for the square area
            square_size = square_size - 1 -- Adjust to the last valid size
            for dx = 0, square_size - 1 do
                for dy = 0, square_size - 1 do
                    mark_processed(x - dx, y - dy)
                end
            end

            -- Snap the highlight to the grid
            local snapped_left_top = {
                x = math.floor(x - square_size + 0.5 + offset.x),
                y = math.floor(y - square_size + 0.5 + offset.y)
            }
            local snapped_right_bottom = {
                x = math.floor(x + 0.5 + offset.x),
                y = math.floor(y + 0.5 + offset.y)
            }

            local render_id = rendering.draw_rectangle({
                color = { r = 0.5, g = 0.5, b = 1, a = 0.4 }, -- Light blue tint
                surface = player.surface,
                left_top = snapped_left_top,
                right_bottom = snapped_right_bottom,
                filled = true,
                players = { player.index },
                only_in_alt_mode = false
            })

            table.insert(combined_renders, render_id)
        end
    end

    -- Handle any remaining unprocessed tiles (shouldn't happen, but just in case)
    for _, tile_data in pairs(tiles) do
        local x, y = tile_data.position.x, tile_data.position.y
        if not is_processed(x, y) then
            -- Create a render for the single tile
            local left_top = { x = x - 0.5 + offset.x, y = y - 0.5 + offset.y }
            local right_bottom = { x = x + 0.5 + offset.x, y = y + 0.5 + offset.y }

            local render_id = rendering.draw_rectangle({
                color = { r = 0.5, g = 0.5, b = 1, a = 0.4 }, -- Light blue tint
                surface = player.surface,
                left_top = left_top,
                right_bottom = right_bottom,
                filled = true,
                players = { player.index },
                only_in_alt_mode = false
            })

            table.insert(combined_renders, render_id)
            mark_processed(x, y)
        end
    end

    -- Store the combined renders for later updates
    player.print("Total Renders: " ..
        #combined_renders ..
        " (combined from " .. table_size(tiles) .. " tiles)")
    return combined_renders
end

function SpaceShip.ship_takeoff(player)
    local plat      = player.surface.platform
    local stationID = player.gui.relative["spaceship-controller-extended-gui"]["surface-dropdown"].selected_index
    local station   = player.gui.relative["spaceship-controller-extended-gui"]["surface-dropdown"].items[stationID]
    schedual        = {
        current = 1,
        records = {
            {
                station = station,
                wait_conditions = {
                    { type = "time", compare_type = "and", ticks = 600 }
                },
                temporary = true,
                created_by_interrupt = false,
                allows_unloading = false
            }
        }
    }
    plat.schedule   = schedual
    plat.paused     = false
    game.print("Schedule applied and started for:" .. plat.name)
end

-- Clone all tiles and entities from the old ship to the new ship
function SpaceShip.clone_ship_area(src_surface, dest_surface, dest_center, excluded_types)
    -- Caate the offset between the source and destination areas
    local reference_tile = storage.spaceships[storage.opened_entity_id].reference_tile
    if not reference_tile then
        error("Reference tile is missing from ship data.")
    end

    local offset = {
        x = math.ceil(dest_center.x - reference_tile.position.x),
        y = math.ceil(dest_center.y - reference_tile.position.y)
    }

    dest_surface.request_to_generate_chunks(dest_center, 10)
    dest_surface.force_generate_chunk_requests()

    -- Clone tiles
    local tiles_to_set = {}
    for _, tile in pairs(storage.spaceships[storage.opened_entity_id].floor) do
        table.insert(tiles_to_set, {
            name = "spaceship-flooring",
            position = {
                x = tile.position.x + offset.x,
                y = tile.position.y + offset.y
            }
        })
    end
    dest_surface.set_tiles(tiles_to_set)
    -- Filter entities to exclude certain types
    local entities_to_clone = {}
    for _, entity in pairs(storage.spaceships[storage.opened_entity_id].entities) do
        if entity.valid and not excluded_types[entity.type] then
            table.insert(entities_to_clone, entity)
        end
    end

    -- Clone entities using clone_entities
    src_surface.clone_entities({
        entities = entities_to_clone,
        destination_surface = dest_surface,
        destination_offset = offset,
        snap_to_grid = true -- Ensure precise placement
    })

    local search_area = {
        { x = dest_center.x - 50, y = dest_center.y - 50 }, -- Define a reasonable search area around the cloned ship
        { x = dest_center.x + 50, y = dest_center.y + 50 }
    }

    -- Search for the spaceship-control-hub-car in the newly cloned ship
    local entities_in_area = dest_surface.find_entities_filtered({
        area = search_area,
        name = "spaceship-control-hub"
    })

    if #entities_in_area > 0 then
        control_hub = entities_in_area[1] -- Assume the first found entity is the control hub
    end
    if control_hub.unit_number ~= storage.opened_entity_id then
        storage.spaceships[control_hub.unit_number] = storage.spaceships[storage.opened_entity_id]
        storage.spaceships[storage.opened_entity_id] = nil
        storage.opened_entity_id = control_hub.unit_number
    end

    -- Remove entities from the original surface
    for _, entity in pairs(storage.spaceships[storage.opened_entity_id].entities) do
        if entity and entity.valid then
            entity.destroy()
        end
    end

    -- Change tiles in the original area to hidden tiles
    local hidden_tiles_to_set = {}
    for _, tile in pairs(storage.spaceships[storage.opened_entity_id].floor) do
        local hidden_tile_name = src_surface.get_hidden_tile({ x = tile.position.x, y = tile.position.y })
        if hidden_tile_name then
            table.insert(hidden_tiles_to_set, {
                name = hidden_tile_name,
                position = { x = tile.position.x, y = tile.position.y }
            })
        else
            game.print("Error: No hidden tile found for position (" ..
                tile.position.x .. ", " .. tile.position.y .. ").")
        end
    end

    if #hidden_tiles_to_set > 0 then
        src_surface.set_tiles(hidden_tiles_to_set)
    else
        game.print("Error: No valid hidden tiles to set.")
    end
    --SpaceShip.scan_ship(storage.spaceships[storage.opened_entity_id].player)
end

-- Function to clone the ship to a new space platform surface
function SpaceShip.clone_ship_to_space_platform(player)
    -- Ensure the player is valid
    if not player or not player.valid then
        player.print("Error: Invalid player.")
        return
    end

    if not storage.spaceships[storage.opened_entity_id].scanned then
        player.print("Error: No scanned ship data found. Run a ship scan first.")
        return
    end

    local space_platform_temp
    for _, surface in pairs(player.force.platforms) do
        space_platform_temp = surface
        break
    end
    --[[
    -- Create a new space platform surface
    local platform_name = "SpaceShip" .. storage.spaceships[storage.opened_entity_id].name
    local space_platform = game.create_surface(platform_name, space_platform_temp.surface.map_gen_settings)
    space_platform.set_property("pressure", 0)
    if not space_platform then
        player.print("Error: Failed to create a new space platform surface.")
        return
    end]] --

    local space_platform = player.force.create_space_platform({
        name = "SpaceShip" .. storage.spaceships[storage.opened_entity_id].name,
        map_gen_settings = space_platform_temp.surface.map_gen_settings,
        planet = player.surface.platform.space_location.name,
        starter_pack = "space-ship-starter-pack",
    })
    space_platform.apply_starter_pack()
    temp_entities = space_platform.surface.find_entities_filtered { name = "spaceship-control-hub" }
    temp_entities[1].destroy()
    -- Define the destination center position
    local dest_center = { x = 0, y = 0 }

    -- Define the types of entities to exclude
    local excluded_types = {
        ["logistic-robot"] = true,
        ["construction-robot"] = true,
    }

    -- Teleport the player to the new space platform surface
    player.teleport(dest_center, space_platform.surface)
    local OG_surface
    if storage.spaceships[storage.opened_entity_id].surface.platform then
        OG_surface = storage.spaceships[storage.opened_entity_id].surface.platform.space_location.name
    else
        OG_surface = storage.spaceships[storage.opened_entity_id].surface.name
    end
    -- Clone the ship area to the new space platform surface
    if storage.spaceships[storage.opened_entity_id].surface.platform.surface then
        SpaceShip.clone_ship_area(storage.spaceships[storage.opened_entity_id].surface.platform.surface,
            space_platform.surface,
            dest_center,
            excluded_types)
    elseif storage.spaceships[storage.opened_entity_id].surface.surface then
        SpaceShip.clone_ship_area(storage.spaceships[storage.opened_entity_id].surface.surface,
            space_platform.surface,
            dest_center,
            excluded_types)
    end

    -- Teleport the player to the spaceship control hub car and make them enter it
    local control_hub_car
    local search_area = {
        { x = dest_center.x - 50, y = dest_center.y - 50 }, -- Define a reasonable search area around the cloned ship
        { x = dest_center.x + 50, y = dest_center.y + 50 }
    }

    -- Search for the spaceship-control-hub-car in the newly cloned ship
    local entities_in_area = space_platform.surface.find_entities_filtered({
        area = search_area,
        name = "spaceship-control-hub-car"
    })

    if #entities_in_area > 0 then
        control_hub_car = entities_in_area[1] -- Assume the first found entity is the control hub car
    end

    if control_hub_car and control_hub_car.valid then
        -- Restore the player's body

        -- Teleport the player to the control hub car and make them enter it
        player.teleport(control_hub_car.position, control_hub_car.surface)
        player.driving = true -- Make the player enter the vehicle
        player.print("You have entered the spaceship control hub car at the destination.")
    else
        player.print("Error: Unable to find the spaceship control hub car at the destination.")
    end

    player.print("Ship successfully cloned to the new space platform: ")
    storage.spaceships[storage.opened_entity_id].own_surface = true
    storage.spaceships[storage.opened_entity_id].planet_orbiting = OG_surface
    storage.spaceships[storage.opened_entity_id].surface = space_platform.surface
    storage.spaceships[storage.opened_entity_id].hub = entities_in_area[1]
end

function SpaceShip.start_scan_ship(player, scan_per_tick)
    if not storage.opened_entity_id then
        player.print("Error: No valid spaceship control hub entity is open.")
        return
    end
    if storage.scan_state then
        player.print("Scan is in progress, please wait.")
        return
    end
    local temp_entity = player.surface.find_entities_filtered { name = "spaceship-control-hub" }
    if not temp_entity or #temp_entity == 0 then
        player.print("Error: No spaceship control hub found.")
        return
    end

    local surface = temp_entity[1].surface
    local start_pos = temp_entity[1].position
    local tiles_to_check = { start_pos }
    local scanned_tiles = {}
    local flooring_tiles = {}
    local entities_on_flooring = {}
    local reference_tile = nil -- Initialize reference_tile
    local scan_radius = 200    -- Limit to prevent excessive scans

    if not storage.spaceships[storage.opened_entity_id] then
        storage.spaceships[storage.opened_entity_id] = SpaceShip.new("Ship", storage.opened_entity_id, player)
    end

    storage.spaceships[storage.opened_entity_id].floor = nil
    storage.spaceships[storage.opened_entity_id].entities = nil
    storage.spaceships[storage.opened_entity_id].reference_tile = nil
    storage.spaceships[storage.opened_entity_id].surface = nil

    -- Initialize scan state
    storage.scan_state = {
        player = player,
        surface = surface,
        tiles_to_check = tiles_to_check,
        scanned_tiles = scanned_tiles,
        flooring_tiles = flooring_tiles,
        entities_on_flooring = entities_on_flooring,
        reference_tile = reference_tile,
        scan_radius = scan_radius,
        start_pos = start_pos,
        scan_per_tick = scan_per_tick or 50, -- Default to 1 if not provided
        tick_counter = 0,                   -- Counter to track ticks for progress updates
        entity_id = storage.opened_entity_id,
        tick_amount = 1
    }
    -- Start the scanning process
    script.on_nth_tick(storage.scan_state.tick_amount, SpaceShip.continue_scan_ship)
    player.print("Ship scan started. Scanning up to " ..
        storage.scan_state.scan_per_tick .. " tiles per " .. storage.scan_state.tick_amount .. " tick(s).")
end

function SpaceShip.continue_scan_ship()
    local state = storage.scan_state
    if not state or #state.tiles_to_check == 0 then
        -- Scanning is complete
        script.on_nth_tick(storage.scan_state.tick_amount, nil) -- Stop the scanning process
        if state then
            local temp_entities = {}
            for _, x in pairs(state.entities_on_flooring) do --check through x tables
                for _, y in pairs(x) do --check through y values
                    table.insert(temp_entities,y)
                end
            end
            local player = state.player
            storage.spaceships[storage.scan_state.entity_id].floor = state.flooring_tiles
            storage.spaceships[storage.scan_state.entity_id].entities = temp_entities
            storage.spaceships[storage.scan_state.entity_id].reference_tile = state.reference_tile
            storage.spaceships[storage.scan_state.entity_id].surface = state.surface
            storage.spaceships[storage.scan_state.entity_id].scanned = true

            -- Create combined renders for the scanned ship area
            storage.scan_highlights = SpaceShip.create_combined_renders(player,
                storage.spaceships[storage.scan_state.entity_id].floor, true, { x = 0, y = 0 })
            storage.scan_highlight_expire_tick = game.tick + 60
            player.print("Ship scan completed! Found " ..
                table_size(state.flooring_tiles) ..
                " tiles and " .. table_size(temp_entities) .. " entities.")
        end
        storage.scan_state = nil
        return
    end

    -- Process up to `scan_per_tick` tiles
    local processed_tiles = 0
    while processed_tiles < state.scan_per_tick and #state.tiles_to_check > 0 do
        local current_pos = table.remove(state.tiles_to_check)

        -- Use unique coordinates as a key to avoid rescanning
        local tile_key = current_pos.x .. "," .. current_pos.y
        if state.scanned_tiles[tile_key] then
            goto continue
        end
        state.scanned_tiles[tile_key] = true

        -- Check if the current tile is "spaceship-flooring"
        local tile = state.surface.get_tile(current_pos.x, current_pos.y)
        if tile and tile.name == "spaceship-flooring" then
            -- Store the tile's name and position
            state.flooring_tiles[tile_key] = {
                name = tile.name,
                position = { x = current_pos.x, y = current_pos.y }
            }

            -- Set the reference_tile if it hasn't been set yet
            if not state.reference_tile then
                state.reference_tile = state.flooring_tiles[tile_key]
            end

            -- Find entities directly on this tile
            local area = {
                { x = current_pos.x - 0.5, y = current_pos.y - 0.5 },
                { x = current_pos.x + 0.5, y = current_pos.y + 0.5 }
            }
            local entities = state.surface.find_entities_filtered({ area = area })
            for _, entity in pairs(entities) do
                if entity.valid and entity.name ~= "spaceship-flooring" then
                    if entity.type ~= "resource" and entity.type ~= "character" then
                        --Make the values if they have not been made yet.
                        state.entities_on_flooring[entity.position.x] = state.entities_on_flooring[entity.position.x] or {}
                        state.entities_on_flooring[entity.position.x][entity.position.y] = state.entities_on_flooring[entity.position.x][entity.position.y] or {}
                        -- Check if the entity is already stored
                        local value = state.entities_on_flooring[entity.position.x][entity.position.y]
                        if value ~= entity then
                            --Add entity to table[table]
                            state.entities_on_flooring[entity.position.x][entity.position.y] = entity
                        end
                    end
                end
            end

            -- Use get_connected_tiles to find all connected tiles of the wame type in 1 hit, whaaat?!
            if #state.tiles_to_check == 0 then
                state.tiles_to_check = state.surface.get_connected_tiles({ x = current_pos.x, y = current_pos.y },{ "spaceship-flooring" })
            end
        end
        processed_tiles = processed_tiles + 1
        ::continue::
    end

    -- Increment the tick counter
    state.tick_counter = state.tick_counter + 1

    -- Print progress every 300 ticks
    if state.tick_counter % 10 == 0 then
        local player = state.player
        local total_tiles = table_size(state.scanned_tiles)
        local remaining_tiles = #state.tiles_to_check
        player.print("Scanning progress: " .. total_tiles .. " tiles scanned, " .. remaining_tiles .. " tiles remaining.")
    end
end

function SpaceShip.dock_ship(player)
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
            if plat.space_location.name == storage.spaceships[storage.opened_entity_id].planet_orbiting then
                if plat.name ~= "SpaceShip" .. storage.spaceships[storage.opened_entity_id].name then
                    dest_surface = player.force.platforms[id]
                end
            end
        end
    end

    if not dest_surface then
        player.print("Error: No stations found, or not orbiting planet!")
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
        name = "dock-confirmation-gui",
        caption = "Confirm Takeoff",
        direction = "vertical"
    }
    gui.location = { x = 10, y = 10 }

    gui.add {
        type = "button",
        name = "confirm-dock",
        caption = "Confirm"
    }
    gui.add {
        type = "button",
        name = "cancel-dock",
        caption = "Cancel"
    }
end

-- Usage in finalizeTakeoff
function SpaceShip.finalize_dock(player)
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
    --storage.spaceships[storage.opened_entity_id].planet_orbiting = src_surface.name
    -- Clone the ship area to the destination surface
    SpaceShip.clone_ship_area(src_surface.platform.surface, dest_surface, dest_center, excluded_types)

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
    if player.gui.screen["dock-confirmation-gui"] then
        player.gui.screen["dock-confirmation-gui"].destroy()
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
    -- Search for the spaceship-control-hub-car in the newly cloned ship
    local entities_in_area = dest_surface.find_entities_filtered({
        area = search_area,
        name = "spaceship-control-hub"
    })
    storage.spaceships[storage.opened_entity_id].hub = entities_in_area[1]
    storage.spaceships[storage.opened_entity_id].taking_off = false -- Reset the taking off flag
    storage.spaceships[storage.opened_entity_id].own_surface = false
    storage.spaceships[storage.opened_entity_id].surface = dest_surface
    src_surface.platform.destroy(1)
end

-- Function to cancel spaceship takeoff
function SpaceShip.cancel_dock(player)
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
    if player.gui.screen["dock-confirmation-gui"] then
        player.gui.screen["dock-confirmation-gui"].destroy()
    end

    player.print("Takeoff canceled. Returning to the ship.")
    storage.spaceships[storage.opened_entity_id].taking_off = false -- Reset the taking off flag
end

return SpaceShip
