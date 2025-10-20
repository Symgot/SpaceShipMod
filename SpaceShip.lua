local SpaceShip = {}
SpaceShip.__index = SpaceShip
local SpaceShipFunctions = require("SpaceShipFunctionsScript")

local DROP_COST = {
    ["rocket-fuel"] = 20,
    ["processing-unit"] = 20,
    ["low-density-structure"] = 20
}

SpaceShip.hub               = nil
SpaceShip.floor             = {}                         -- Table to store floor tiles
SpaceShip.walls             = {}                         -- Table to store wall tiles
SpaceShip.entities          = {}                         -- Table to store entities
SpaceShip.name              = nil or "Unnamed SpaceShip" -- Name of the spaceship
SpaceShip.id                = nil or 0                   -- Unique ID for the spaceship
SpaceShip.player_owner      = nil                        -- Reference to the player prototype
SpaceShip.referance_tile    = nil
SpaceShip.surface           = nil
SpaceShip.scanned           = false
SpaceShip.player_in_cockpit = nil
SpaceShip.taking_off        = false
SpaceShip.own_surface       = false
SpaceShip.planet_orbiting   = nil
SpaceShip.schedule          = {}
SpaceShip.traveling         = false
SpaceShip.automatic         = false
SpaceShip.port_records      = {}
SpaceShip.docking_port      = nil

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
    self.player_in_cockpit = nil
    self.taking_off        = false
    self.own_surface       = false
    self.planet_orbiting   = nil
    self.schedule          = {}
    self.traveling         = false
    self.automatic         = false
    self.port_records      = {}
    self.docking_port      = nil

    -- Store the spaceship in the global storage
    return self
end

SpaceShip.init_docking_ports = function()
    storage.docking_ports = storage.docking_ports or {}
end

SpaceShip.register_docking_port = function(entity)
    if not storage.docking_ports then SpaceShip.init_docking_ports() end
    local name
    if entity.surface.get_tile(entity.position.x, entity.position.y).name ~= "spaceship-flooring" then
        name = entity.surface.platform.space_location.name .. table_size(storage.docking_ports)
    else
        name = "ship"
    end
    storage.docking_ports[entity.unit_number] = {
        entity = entity,
        position = entity.position,
        surface = entity.surface,
        name = name,    -- Will be set via GUI
        ship_limit = 1, -- Default limit
        ship_docked = nil
    }
end

function SpaceShip.create_combined_renders(ship, tiles, scan, offset)
    local player = ship.player
    if not player or not player.valid then
        return
    end

    local processed_tiles = {}
    local combined_renders = {}

    if not scan then
        -- Calculate the offset to make the reference tile start at (0, 0)
        local reference_tile = ship.reference_tile
        if not reference_tile then
            game.print("Error: Reference tile is missing from ship data.")
            return
        end
        offset = {
            x = -reference_tile.position.x + offset.x,
            y = -reference_tile.position.y + offset.y
        }
    end
    local function is_processed(x, y)
        return processed_tiles[x .. "," .. y]
    end
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

    for _, tile_data in ipairs(sorted_tiles) do
        local x, y = tile_data.position.x, tile_data.position.y
        if not is_processed(x, y) then
            -- Start a new square area
            local square_size = 1
            local valid_square = true

            while valid_square do
                for dx = 0, square_size do
                    for dy = 0, square_size do
                        local check_x = x - dx
                        local check_y = y - dy
                        local tile_key = check_x .. "," .. check_y

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

            square_size = square_size - 1 -- Adjust to the last valid size
            for dx = 0, square_size - 1 do
                for dy = 0, square_size - 1 do
                    mark_processed(x - dx, y - dy)
                end
            end

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

    game.print("Total Renders: " ..
        #combined_renders ..
        " (combined from " .. table_size(tiles) .. " tiles)")
    return combined_renders
end

function SpaceShip.ship_takeoff(ship, dropdown)
    local stationID = dropdown.selected_index
    local station   = dropdown.items[stationID]
    schedual        = {
        current = 1,
        records = {
            {
                station = station,
                wait_conditions = {
                    {
                        type = "circuit",
                        compare_type = "and",
                        condition =
                        {
                            first_signal =
                            {
                                type = "virtual",
                                name = "signal-A"
                            },
                            comparator = "<",
                            constant = 10
                        }
                    }
                },
                temporary = true,
                created_by_interrupt = false,
                allows_unloading = false
            }
        }
    }
    ship.schedule   = schedual
    game.print("Schedule applied and started for:" .. ship.name)
end

function SpaceShip.add_or_change_station(ship, planet_name, index)
    ship.schedule = ship.schedule or {}
    if not ship.schedule.current then
        ship.schedule.current = 1 --default to 1 of not already set
    end
    if ship.schedule.records then
        record =
        {
            station = planet_name,
            wait_conditions = {
                {
                    type = "circuit",
                    compare_type = "and",
                    condition =
                    {
                        first_signal =
                        {
                            type = "virtual",
                            name = "signal-A"
                        },
                        comparator = ">",
                        constant = 10
                    }
                }
            },
            temporary = true,
            created_by_interrupt = false,
            allows_unloading = false
        }
        table.insert(ship.schedule.records, record)
    else
        ship.schedule.records = {
            {
                station = planet_name,
                wait_conditions = {
                    {
                        type = "circuit",
                        compare_type = "and",
                        condition =
                        {
                            first_signal =
                            {
                                type = "virtual",
                                name = "signal-A"
                            },
                            comparator = ">",
                            constant = 10
                        }
                    }
                },
                temporary = true,
                created_by_interrupt = false,
                allows_unloading = false
            }
        }
    end
    if ship.platform then
        ship.platform.schedule = ship.schedule
    end
    for key, value in pairs(storage.docking_ports) do

    end
end

function SpaceShip.delete_station(ship, station_index)
    if not ship or not ship.schedule or not ship.schedule.records then
        game.print("Error: Invalid ship or schedule.")
        return
    end

    if not ship.schedule.records[station_index] then
        game.print("Error: Station index " .. station_index .. " does not exist in the schedule.")
        return
    end

    table.remove(ship.schedule.records, station_index)

    local temp_schedule = {}
    for key, value in pairs(ship.schedule.records) do
        table.insert(temp_schedule, value)
    end

    ship.schedule.records = temp_schedule

    game.print("Station " .. station_index .. " removed from ship " .. ship.name .. ".")
end

function SpaceShip.clone_ship_area(ship, dest_surface, dest_center, excluded_types)
    local src_surface = ship.surface.platform.surface
    -- Create the offset between the source and destination areas
    local reference_tile = ship.reference_tile
    if not reference_tile then
        error("Reference tile is missing from ship data.")
    end

    local offset = {
        x = math.ceil(dest_center.x - reference_tile.position.x),
        y = math.ceil(dest_center.y - reference_tile.position.y)
    }

    -- Calculate the bounding box of the ship to ensure proper chunk generation
    local min_x, max_x = math.huge, -math.huge
    local min_y, max_y = math.huge, -math.huge
    
    -- Find the bounds of all ship tiles
    for _, tile in pairs(ship.floor) do
        local dest_x = tile.position.x + offset.x
        local dest_y = tile.position.y + offset.y
        min_x = math.min(min_x, dest_x)
        max_x = math.max(max_x, dest_x)
        min_y = math.min(min_y, dest_y)
        max_y = math.max(max_y, dest_y)
    end
    
    -- Add padding around the ship bounds
    local padding = 32 -- 32 tiles padding (1 chunk)
    min_x = min_x - padding
    max_x = max_x + padding
    min_y = min_y - padding
    max_y = max_y + padding
    
    -- Calculate chunk radius needed to cover the entire ship area
    local ship_width = max_x - min_x
    local ship_height = max_y - min_y
    local max_dimension = math.max(ship_width, ship_height)
    local chunk_radius = math.ceil(max_dimension / 32) + 2 -- +2 for extra safety
    
    game.print("Generating chunks for ship area: " .. ship_width .. "x" .. ship_height .. " (radius: " .. chunk_radius .. ")")
    
    -- Request chunk generation for the entire ship area
    dest_surface.request_to_generate_chunks(dest_center, chunk_radius)
    dest_surface.force_generate_chunk_requests()

    -- Clone tiles
    local tiles_to_set = {}
    for _, tile in pairs(ship.floor) do
        table.insert(tiles_to_set, {
            name = "spaceship-flooring",
            position = {
                x = tile.position.x + offset.x,
                y = tile.position.y + offset.y
            }
        })
    end
    dest_surface.set_tiles(tiles_to_set)
    -- Filter entities to exclude certain types, ex.(player,robots)
    local entities_to_clone = {}
    
    -- Explicitly ensure the hub is included in the clone list
    if ship.hub and ship.hub.valid then
        table.insert(entities_to_clone, ship.hub)
    end
    
    -- Add all other entities from the ship
    for _, entity in pairs(ship.entities) do
        if entity.valid and not excluded_types[entity.type] then --filter happens here
            -- Don't add hub twice if it's already in entities (prevents duplication)
            if not (ship.hub and entity.unit_number == ship.hub.unit_number) then
                table.insert(entities_to_clone, entity)
            end
        end
    end

    src_surface.clone_entities({
        entities = entities_to_clone,
        destination_surface = dest_surface,
        destination_offset = offset,
        snap_to_grid = true -- Ensure precise placement
    })

    for _, entity in pairs(ship.entities) do
        if entity and entity.valid then
            entity.destroy()
        end
    end

    local hidden_tiles_to_set = {}
    for _, tile in pairs(ship.floor) do
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
    
    -- Force chart refresh around the cloned area to ensure proper rendering
    if ship.player and ship.player.valid then
        -- Chart the area around the cloned ship for the player's force
        local chart_area = {
            left_top = {x = min_x, y = min_y},
            right_bottom = {x = max_x, y = max_y}
        }
        ship.player.force.chart(dest_surface, chart_area)
        game.print("Map charted after ship cloning.")
    end
    
    SpaceShip.start_scan_ship(ship)
end

function SpaceShip.clone_ship_to_space_platform(ship)
    if not ship or not ship.player or not ship.player.valid then
        ship.game.print("Error: Invalid player.")
        return
    end

    if not ship.scanned then
        game.print("Error: No scanned ship data found. Run a ship scan first.")
        return
    end

    local space_platform_temp
    for _, surface in pairs(ship.player.force.platforms) do
        space_platform_temp = surface
        break
    end

    local space_platform = ship.player.force.create_space_platform({
        name = ship.name .. "-ship",
        map_gen_settings = space_platform_temp.surface.map_gen_settings,
        planet = ship.planet_orbiting,
        starter_pack = "space-ship-starter-pack",
    })
    space_platform.apply_starter_pack()
    temp_entities = space_platform.surface.find_entities_filtered { area = { { -50, -50 }, { 50, 50 } }, name = "spaceship-control-hub" }
    temp_entities[1].destroy()
    local dest_center = { x = 0, y = 0 }

    -- Define the types of entities to exclude
    local excluded_types = {
        ["logistic-robot"] = true,
        ["construction-robot"] = true,
    }
    local OG_surface
    if ship.surface.platform then
        OG_surface = ship.surface.platform.space_location.name
    else
        OG_surface = ship.surface.name
    end

    if ship.surface.platform.surface then
        SpaceShip.clone_ship_area(
            ship,
            space_platform.surface,
            dest_center,
            excluded_types)
    elseif ship.surface.surface then
        SpaceShip.clone_ship_area(
            ship,
            space_platform.surface,
            dest_center,
            excluded_types)
    end

    if ship.player_in_cockpit then
        ship.player_in_cockpit.teleport(dest_center, space_platform.surface)

        local control_hub_car
        local search_area = {
            { x = dest_center.x - 50, y = dest_center.y - 50 }, -- Define a reasonable search area around the cloned ship
            { x = dest_center.x + 50, y = dest_center.y + 50 }
        }

        local entities_in_area = space_platform.surface.find_entities_filtered({
            area = search_area,
            name = "spaceship-control-hub-car"
        })

        if #entities_in_area > 0 then
            control_hub_car = entities_in_area[1] -- Assume the first found entity is the control hub car
        end

        if control_hub_car and control_hub_car.valid then
            ship.player_in_cockpit.teleport(control_hub_car.position, control_hub_car.surface)
            ship.player_in_cockpit.driving = true -- Make the player enter the vehicle
            ship.player_in_cockpit.print("You have entered the spaceship control hub car at the destination.")
        else
            ship.player_in_cockpit.print("Error: Unable to find the spaceship control hub car at the destination.")
        end
    end

    game.print("Ship successfully cloned to the new space platform: ")
    ship.own_surface = true
    ship.planet_orbiting = OG_surface
    ship.surface = space_platform.surface
    ship.traveling = true
end

function SpaceShip.start_scan_ship(ship, scan_per_tick, tick_amount)
    player = ship.player
    if storage.scan_state then
        game.print("Scan is in progress, please wait.")
        return
    end

    local surface = ship.hub.surface
    local start_pos = ship.hub.position
    local tiles_to_check = { start_pos }
    local scanned_tiles = {}
    local flooring_tiles = {}
    local entities_on_flooring = {}
    local reference_tile = nil -- Initialize reference_tile
    local scan_radius = 200    -- Limit to prevent excessive scans

    local count = table_size(storage.spaceships) + 1
    if not ship then
        ship = SpaceShip.new("Explorer" .. count, count, player)
    end

    ship.floor = nil
    ship.entities = nil
    ship.reference_tile = nil
    ship.surface = nil

    storage.scan_state = {
        player = player,
        ship_id = ship.id,
        surface = surface,
        tiles_to_check = tiles_to_check,
        scanned_tiles = scanned_tiles,
        flooring_tiles = flooring_tiles,
        entities_on_flooring = entities_on_flooring,
        reference_tile = reference_tile,
        docking_port = nil,
        scan_radius = scan_radius,
        start_pos = start_pos,
        scan_per_tick = scan_per_tick or 30, -- how many tiles to scan per tick
        tick_counter = 0,                    -- Counter to track ticks for progress updates
        tick_amount = tick_amount or 1       --how ofter to keep scanning, higher=slower
    }
    game.print("Ship scan started. Scanning up to " ..
        storage.scan_state.scan_per_tick .. " tiles per " .. storage.scan_state.tick_amount .. " tick(s).")
end

function SpaceShip.continue_scan_ship()
    local state = storage.scan_state
    if not state or #state.tiles_to_check == 0 then
        -- Scanning is completel
        if state then
            local temp_entities = {}
            for _, x in pairs(state.entities_on_flooring) do --check through x tables
                for _, y in pairs(x) do                      --check through y values
                    table.insert(temp_entities, y)
                end
            end
            local player = state.player
            local ship = storage.spaceships[state.ship_id]
            ship.floor = state.flooring_tiles
            ship.entities = temp_entities
            ship.reference_tile = state.reference_tile
            ship.surface = state.surface
            ship.scanned = true
            if state.surface.platform.space_location then
                ship.planet_orbiting = state.surface.platform.space_location.name
            else
                ship.planet_orbiting = "none"
            end
            storage.scan_highlight_expire_tick = game.tick + 60
            game.print("Ship scan completed! Found " ..
                table_size(state.flooring_tiles) ..
                " tiles and " .. table_size(temp_entities) .. " entities.")
            if state.docking_port then
                ship.docking_port = state.docking_port
            else
                game.print("No docking port found on the ship.")
            end
        end
        storage.scan_state = nil
        return
    end

    -- Process up to `scan_per_tick` tiles
    local processed_tiles = 0
    while processed_tiles < state.scan_per_tick and #state.tiles_to_check > 0 do
        local current_pos = table.remove(state.tiles_to_check)

        local tile_key = current_pos.x .. "," .. current_pos.y
        if state.scanned_tiles[tile_key] then
            goto continue
        end
        state.scanned_tiles[tile_key] = true

        local tile = state.surface.get_tile(current_pos.x, current_pos.y)
        if tile and tile.name == "spaceship-flooring" then
            -- Store the tile's name and position
            state.flooring_tiles[tile_key] = {
                name = tile.name,
                position = { x = current_pos.x, y = current_pos.y }
            }

            if not state.reference_tile then
                state.reference_tile = state.flooring_tiles[tile_key]
            end

            local area = {
                { x = current_pos.x - 0.5, y = current_pos.y - 0.5 },
                { x = current_pos.x + 0.5, y = current_pos.y + 0.5 }
            }
            local entities = state.surface.find_entities_filtered({ area = area })
            for _, entity in pairs(entities) do
                if entity.valid and entity.name ~= "spaceship-flooring" then
                    -- Check if the entity is on a "spaceship-flooring" tile
                    local entity_tile = state.surface.get_tile(entity.position.x, entity.position.y)
                    if entity_tile and entity_tile.name == "spaceship-flooring" then
                        if entity.type ~= "resource" and entity.type ~= "character" then
                            -- Make the values if they have not been made yet.
                            state.entities_on_flooring[entity.position.x] = state.entities_on_flooring
                                [entity.position.x] or {}
                            state.entities_on_flooring[entity.position.x][entity.position.y] =
                                state.entities_on_flooring[entity.position.x][entity.position.y] or {}

                            -- Check if the entity is already stored
                            local value = state.entities_on_flooring[entity.position.x][entity.position.y]
                            if value ~= entity then
                                -- Add entity to table[table]
                                state.entities_on_flooring[entity.position.x][entity.position.y] = entity
                                if entity.name == "spaceship-docking-port" then
                                    state.docking_port = entity
                                end
                            end
                        end
                    end
                end
            end

            -- Use get_connected_tiles to find all connected tiles of the same type in 1 hit, whaaat?!
            if #state.tiles_to_check == 0 then
                state.tiles_to_check = state.surface.get_connected_tiles({ x = current_pos.x, y = current_pos.y },
                    { "spaceship-flooring" })
            end
        end
        processed_tiles = processed_tiles + 1
        ::continue::
    end

    state.tick_counter = state.tick_counter + 1

    if state.tick_counter % 20 == 0 then
        local player = state.player
        local total_tiles = table_size(state.scanned_tiles)
        local remaining_tiles = #state.tiles_to_check
        local progress_percent = 0
        if total_tiles + remaining_tiles > 0 then
            progress_percent = math.floor((total_tiles / (total_tiles + remaining_tiles)) * 100)
        end
        game.print("Scanning progress: " .. progress_percent .. "% complete")
    end
end

function SpaceShip.dock_ship(ship)
    local player = ship.player
    local src_surface = player.surface
    local dest_surface
    local player_tile = src_surface.get_tile(player.position)
    if ship.player_in_cockpit then
    elseif player_tile and player_tile.name ~= "spaceship-flooring" then
    else
        game.print("Error: You must be in the cockpit or not on ship to initiate docking.")
        return
    end

    for id, plat in pairs(player.force.platforms) do
        if plat.space_location then
            if plat.space_location.name == ship.planet_orbiting then
                if plat.name ~= ship.name .. "-ship" then
                    dest_surface = player.force.platforms[id]
                end
            end
        end
    end

    if not dest_surface then
        game.print("Error: No stations found, or not orbiting planet!")
        return
    end

    if not ship.scanned and not storage.scan_state then
        game.print("Error: need to scan ship, starting scan now.")
        SpaceShip.start_scan_ship(ship)
        return
    elseif storage.scan_state then
        game.print("Error: Scan is in progress, please wait.")
        return
    end

    ship.docking = true -- Flag to indicate docking process has started

    storage.player_body = player.character

    local player_pos = player.position
    local dest_center = { x = 0, y = 0 }
    player.set_controller({ type = defines.controllers.ghost }) -- Set the player to ghost contro
    player.teleport(dest_center, dest_surface.surface)

    storage.player_position_on_render = { x = math.floor(player.position.x), y = math.floor(player.position.y) }
    storage.highlight_data = storage.highlight_data or {}
    storage.highlight_data = SpaceShip.create_combined_renders(ship, ship.floor, false, { x = 0, y = -5 })
    game.print("rends count: " .. #storage.highlight_data)
    storage.highlight_data_player_index = player.index

    storage.docking_player = player.index
    storage.docking_ship = ship.id

    local gui = player.gui.screen.add {
        type = "frame",
        name = "dock-confirmation-gui",
        caption = "Confirm Docking",
        direction = "vertical",
        tags = { ship = ship.id }
    }
    gui.location = { x = 10, y = 10 }

    gui.add {
        type = "button",
        name = "confirm-dock",
        caption = "Confirm",
        tags = { ship = ship.id }
    }
    gui.add {
        type = "button",
        name = "cancel-dock",
        caption = "Cancel",
        tags = { ship = ship.id }
    }
end

function SpaceShip.finalize_dock(ship)
    if not ship.scanned then
        game.print("Error: No scanned ship data found.")
        return
    end

    local src_surface = ship.surface -- Retrieve the source surface
    local player = ship.player
    local dest_surface = ship.player.surface

    -- Calculate spawn position using the same logic as render offset
    local reference_tile = ship.reference_tile
    if not reference_tile then
        game.print("Error: Reference tile is missing from ship data.")
        return
    end

    local dest_center = {
        x = math.floor(player.position.x - reference_tile.position.x + 0) - 1,
        y = math.floor(player.position.y - reference_tile.position.y + (-5)) - 1
    }

    local excluded_types = {
        ["logistic-robot"] = true,
        ["contruction-robot"] = true,
    }
    SpaceShip.clone_ship_area(ship, dest_surface, dest_center, excluded_types)

    local control_hub_car
    local search_area = {
        { x = dest_center.x - 50, y = dest_center.y - 50 }, -- Define a reasonable search area around the cloned ship
        { x = dest_center.x + 50, y = dest_center.y + 50 }
    }

    local entities_in_area = dest_surface.find_entities_filtered({
        area = search_area,
        name = "spaceship-control-hub-car"
    })

    if #entities_in_area > 0 then
        control_hub_car = entities_in_area[1] -- Assume the first found entity is the control hub car
    end

    if control_hub_car and control_hub_car.valid then
        if storage.player_body and storage.player_body.valid then
            local body_surface = storage.player_body.surface
            local body_position = storage.player_body.position
            player.teleport(body_position, body_surface)

            player.set_controller({ type = defines.controllers.character, character = storage.player_body })
            storage.player_body = nil
        else
            game.print("Error: Unable to restore the player's body.")
            return
        end

        player.teleport(control_hub_car.position, control_hub_car.surface)
        player.driving = true
        game.print("You have entered the spaceship control hub car at the destination.")
    else
        game.print("Error: Unable to find the spaceship control hub car at the destination.")
    end

    if player.gui.screen["dock-confirmation-gui"] then
        player.gui.screen["dock-confirmation-gui"].destroy()
    end

    if storage.highlight_data then
        for _, rendering in pairs(storage.highlight_data) do
            if rendering.valid then
                rendering.destroy()
            end
        end
        storage.highlight_data[player.index] = nil
    end

    game.print("Takeoff confirmed! Ship cloned to orbit.")
    local entities_in_area = dest_surface.find_entities_filtered({
        area = search_area,
        name = "spaceship-control-hub"
    })
    ship.hub = entities_in_area[1]
    ship.taking_off = false -- Reset the taking off flag
    ship.own_surface = false
    ship.surface = dest_surface
    src_surface.platform.destroy(1)
end

-- Function to cancel spaceship takeoff
function SpaceShip.cancel_dock(ship)
    local src_surface = game.surfaces["nauvis"] -- change this at some point
    local player_index = storage.takeoff_player
    local player = game.get_player(player_index)

    if player then
        if storage.player_body and storage.player_body.valid then
            local body_surface = storage.player_body.surface
            local body_position = storage.player_body.position
            player.teleport(body_position, body_surface)
            player.set_controller({ type = defines.controllers.character, character = storage.player_body })
            storage.player_body = nil -- Clear the reference to the player's body
        else
            game.print("Error: Unable to restore the player's body.")
        end
    end

    for _, id in ipairs(storage.takeoff_highlights or {}) do
        rendering.destroy(id)
    end
    storage.takeoff_highlights = nil
    if player.gui.screen["dock-confirmation-gui"] then
        player.gui.screen["dock-confirmation-gui"].destroy()
    end

    game.print("Takeoff canceled. Returning to the ship.")
    ship.taking_off = false -- Reset the taking off flag
end

function SpaceShip.read_circuit_signals(entity)
    -- Get the circuit network for red and green wires
    local red_network = entity.get_circuit_network(1)
    local green_network = entity.get_circuit_network(2)

    local signals = {}

    -- Read signals from red wire
    if red_network then
        local red_signals = red_network.signals
        if red_signals then
            for _, signal in pairs(red_signals) do
                -- Signal structure: {signal = {type="item", name="iron-plate"}, count = 42}
                signals[signal.signal.name] = signals[signal.signal.name] or 0
                signals[signal.signal.name] = signals[signal.signal.name] + signal.count
            end
        end
    end

    -- Read signals from green wire
    if green_network then
        local green_signals = green_network.signals
        if green_signals then
            for _, signal in pairs(green_signals) do
                signals[signal.signal.name] = signals[signal.signal.name] or 0
                signals[signal.signal.name] = signals[signal.signal.name] + signal.count
            end
        end
    end

    return signals
end

function SpaceShip.get_progress_values(ship, signals)
    if not ship or not ship.schedule or not ship.schedule.records then
        return {}
    end

    local progress = {}

    for station_index, station in pairs(ship.schedule.records) do
        if station.wait_conditions then
            progress[station_index] = {}

            for condition_index, condition in pairs(station.wait_conditions) do
                local progress_value = 0

                local signal_value = signals[condition.condition.first_signal.name]
                if signal_value then
                    local target_value = condition.condition.constant

                    -- Calculate progress value (0-1) for progress bar.
                    if condition.condition.comparator == ">" then
                        progress_value = signal_value / target_value
                    elseif condition.condition.comparator == ">=" then
                        progress_value = signal_value / target_value
                    elseif condition.condition.comparator == "<" then
                        progress_value = target_value / signal_value
                    elseif condition.condition.comparator == "<=" then
                        progress_value = target_value / signal_value
                    elseif condition.condition.comparator == "=" then
                        progress_value = signal_value / target_value
                    end
                end

                progress[station_index][condition_index] = progress_value
            end
        end
    end
    return progress
end

function SpaceShip.check_circuit_condition(entity, signal_name, comparison, value)
    local signals = SpaceShip.read_circuit_signals(entity)
    local signal_value = signals[signal_name] or 0

    if comparison == "<" then
        return signal_value < value
    elseif comparison == "<=" then
        return signal_value <= value
    elseif comparison == "=" then
        return signal_value == value
    elseif comparison == ">=" then
        return signal_value >= value
    elseif comparison == ">" then
        return signal_value > value
    end

    return false
end

function SpaceShip.check_schedule_conditions(ship)
    if not ship or not ship.schedule or not ship.schedule.records then
        return false
    end

    local current_station = ship.schedule.records[ship.schedule.current]
    if not current_station or not current_station.wait_conditions then
        return false
    end

    local result = true
    local temp_and_result = true

    for i, condition in ipairs(current_station.wait_conditions) do
        local condition_met = SpaceShip.check_circuit_condition(
            ship.hub,
            condition.condition.first_signal.name,
            condition.condition.comparator,
            tonumber(condition.condition.constant)
        )

        if condition.compare_type == "and" then
            -- Combine with the temporary `and` result
            temp_and_result = temp_and_result and condition_met
        elseif condition.compare_type == "or" then
            -- Apply the grouped `and` result to the main result
            result = result or temp_and_result
            temp_and_result = condition_met -- Reset for the next group
        else
            -- If no `and` or `or`, treat it as a standalone condition
            temp_and_result = condition_met
        end

        -- If the result is already false for `and`, or true for `or`, we can short-circuit
        if (condition.compare_type == "and" and not temp_and_result) or (condition.compare_type == "or" and result) then
            break
        end
    end

    -- Apply the final grouped `and` result to the main result
    if not result or not temp_and_result then
        result = false
    else
        result = result and temp_and_result
    end
    return result
end

function SpaceShip.check_automatic_behavior()
    SpaceShip.connect_adjacent_ports()
    for id, ship in pairs(storage.spaceships or {}) do
        if not ship.automatic then goto continue end
        if storage.scan_state then goto continue end

        local schedule = ship.schedule
        if not schedule or not schedule.records then goto continue end
        local current_station = schedule.records[schedule.current]
        if not current_station then goto continue end
        if not ship.scanned and not storage.scan_state then
            SpaceShip.start_scan_ship(ship,60,1)
        elseif not ship.scanned then
            goto continue
        end

        if ship.own_surface or not ship.scanned then goto continue end
        
        -- Check if platform is in station mode (movement disabled)
        if ship.hub and ship.hub.valid and ship.hub.surface.platform then
            local platform = ship.hub.surface.platform
            local Stations = require("Stations")
            if Stations.is_station_mode(platform) then
                -- Platform is in station mode, skip automatic movement
                goto continue
            end
        end
        
        local all_conditions_met = SpaceShip.check_schedule_conditions(ship)
        if all_conditions_met then
            SpaceShip.clone_ship_to_space_platform(ship)
            local next_station
            if schedule.records[schedule.current + 1] then
                schedule.current = schedule.current + 1
                next_station = schedule.records[schedule.current]
            else
                schedule.current = 1
                next_station = schedule.records[schedule.current]
            end
            local platform = ship.hub.surface.platform
            if platform then
                platform.schedule = schedule
                platform.paused = false
                game.print("Ship " .. ship.name .. " departing to " .. next_station.station)
            end
        end
        --end
        ::continue::
    end
end

function SpaceShip.connect_adjacent_ports()
    if not storage.docking_ports then return end

    local function are_adjacent(port1, port2)
        local dx = math.abs(port1.position.x - port2.position.x)
        local dy = math.abs(port1.position.y - port2.position.y)
        return (dx == 1 and dy == 0) or (dx == 0 and dy == 1)
    end

    for id1, port1 in pairs(storage.docking_ports) do
        for id2, port2 in pairs(storage.docking_ports) do
            if id1 ~= id2 and are_adjacent(port1, port2) then
                if port1.entity.valid and port2.entity.valid then
                    local red_connector1 = port1.entity.get_wire_connector(defines.wire_connector_id.circuit_red)
                    local green_connector1 = port1.entity.get_wire_connector(defines.wire_connector_id.circuit_green)
                    local red_connector2 = port2.entity.get_wire_connector(defines.wire_connector_id.circuit_red)
                    local green_connector2 = port2.entity.get_wire_connector(defines.wire_connector_id.circuit_green)

                    if red_connector1 and red_connector2 then
                        red_connector1.connect_to(red_connector2)
                    end

                    if green_connector1 and green_connector2 then
                        green_connector1.connect_to(green_connector2)
                    end
                end
            end
        end
    end
end

function SpaceShip.on_platform_state_change(event)
    local platform = event.platform
    if not platform or not platform.valid then
        game.print("Error: Invalid platform in state change event.")
        return
    end
    local hub = platform.surface.find_entities_filtered({
        name = "spaceship-control-hub",
        area = {
            { x = -20, y = -20 },
            { x = 20,  y = 20 }
        }
    })[1]
    local ship
    for key, value in pairs(storage.spaceships) do
        if value.hub.unit_number == hub.unit_number then
            ship = storage.spaceships[key]
        end
    end
    if not ship or not ship.docking_port then
        game.print("Error: No ship or docking port associated with the platform.")
        return
    end

    -- Check if the platform's state changed to 6 (waiting_at_station)
    if event.platform.state == 6 then
        local old_platform = platform
        platform.paused = true

        local schedule = ship.schedule
        if not schedule or not schedule.records or not schedule.records[schedule.current] then
            game.print("Error: Invalid schedule for ship " .. ship.name)
            return
        end
        local target_docking_port
        local storage_docking_port
        for key, port in pairs(storage.docking_ports) do
            if port.name == ship.port_records[schedule.current] then
                storage_docking_port = key
                target_docking_port = port.surface.find_entities_filtered({
                    name = "spaceship-docking-port",
                    area = {
                        { x = port.position.x - 5, y = port.position.y - 5 },
                        { x = port.position.x + 5, y = port.position.y + 5 }
                    }
                })[1]
            end
        end

        if not target_docking_port then
            game.print("Error: Target docking port not found on surface " .. schedule.records[schedule.current].station)
            return
        end

        if storage.docking_ports[storage_docking_port].ship_docked then
            game.print("Warning: Target docking port already has docked ship " .. ship.port_records[schedule.current])
            return
        end

        -- Align the ship's docking port with the target docking port
        local offset = {
            x = target_docking_port.position.x - ship.docking_port.position.x + 1,
            y = target_docking_port.position.y - ship.docking_port.position.y
        }

        SpaceShip.clone_ship_area(ship, target_docking_port.surface, offset, {})

        ship.surface = target_docking_port.surface
        ship.own_surface = false
        ship.traveling = false
        storage.docking_ports[storage_docking_port].ship_docked = true
        game.print("Ship " .. ship.name .. " successfully cloned to surface " .. target_docking_port.surface.name)

        -- Delete the old platform surface
        if old_platform and old_platform.valid then
            old_platform.destroy(1)
        end
    end
end

function SpaceShip.handle_cloned_storage_update(event)
    if not event or not event.source or not event.destination then
        return
    end

    if storage.spaceships then
        for key, value in pairs(storage.spaceships) do
            if value.hub and value.hub.unit_number == event.source.unit_number then
                storage.spaceships[key].hub = event.destination
            end
            if value.docking_port and value.docking_port.unit_number == event.source.unit_number then
                storage.spaceships[key].docking_port = event.destination
            end
        end
    end

    if storage.docking_ports and storage.docking_ports[event.source.unit_number] then
        local old_data = storage.docking_ports[event.source.unit_number]
        storage.docking_ports[event.source.unit_number] = nil
        storage.docking_ports[event.destination.unit_number] = {
            entity = event.destination,
            position = event.destination.position,
            surface = event.destination.surface,
            name = old_data.name or "",
            ship_limit = old_data.ship_limit or 1
        }
    end
end

function SpaceShip.add_wait_condition(ship, station_number, condition_type)
    if not ship.schedule.records[station_number].wait_conditions then
        ship.schedule.records[station_number].wait_conditions = {}
    end
    local wait_condition =
    {
        type = condition_type,
        compare_type = "and",
        condition =
        {
            first_signal =
            {
                type = "virtual",
                name = "signal-A"
            },
            comparator = ">",
            constant = 10
        }
    }
    table.insert(ship.schedule.records[station_number].wait_conditions, wait_condition)
end

function SpaceShip.remove_wait_condition(ship, station_index, condition_index)
    if not ship.schedule.records[station_index] or
        not ship.schedule.records[station_index].wait_conditions then
        return
    end

    ship.schedule.records[station_index].wait_conditions[condition_index] = nil

    local temp_conditions = {}
    for _, condition in pairs(ship.schedule.records[station_index].wait_conditions) do
        if condition then
            table.insert(temp_conditions, condition)
        end
    end

    ship.schedule.records[station_index].wait_conditions = temp_conditions
end

function SpaceShip.station_move_up(ship, station_index)
    if not ship.schedule.records or
        not ship.schedule.records[station_index] or
        station_index <= 1 then
        return
    end

    local current_station = ship.schedule.records[station_index]
    local previous_station = ship.schedule.records[station_index - 1]

    ship.schedule.records[station_index] = previous_station
    ship.schedule.records[station_index - 1] = current_station

    if ship.schedule.current == station_index then
        ship.schedule.current = station_index - 1
    elseif ship.schedule.current == station_index - 1 then
        ship.schedule.current = station_index
    end
end

function SpaceShip.station_move_down(ship, station_index)
    if not ship.schedule.records or
        not ship.schedule.records[station_index] or
        not ship.schedule.records[station_index + 1] then
        return
    end

    local current_station = ship.schedule.records[station_index]
    local next_station = ship.schedule.records[station_index + 1]

    ship.schedule.records[station_index] = next_station
    ship.schedule.records[station_index + 1] = current_station

    if ship.schedule.current == station_index then
        ship.schedule.current = station_index + 1
    elseif ship.schedule.current == station_index + 1 then
        ship.schedule.current = station_index
    end
end

function SpaceShip.condition_move_up(ship, station_index, condition_index)
    if not ship.schedule.records[station_index] or
        not ship.schedule.records[station_index].wait_conditions or
        not ship.schedule.records[station_index].wait_conditions[condition_index] or
        condition_index <= 1 then
        return
    end

    local current_condition = ship.schedule.records[station_index].wait_conditions[condition_index]
    local previous_condition = ship.schedule.records[station_index].wait_conditions[condition_index - 1]

    ship.schedule.records[station_index].wait_conditions[condition_index] = previous_condition
    ship.schedule.records[station_index].wait_conditions[condition_index - 1] = current_condition
end

function SpaceShip.condition_move_down(ship, station_index, condition_index)
    if not ship.schedule.records[station_index] or
        not ship.schedule.records[station_index].wait_conditions or
        not ship.schedule.records[station_index].wait_conditions[condition_index] or
        not ship.schedule.records[station_index].wait_conditions[condition_index + 1] then
        return
    end

    local current_condition = ship.schedule.records[station_index].wait_conditions[condition_index]
    local next_condition = ship.schedule.records[station_index].wait_conditions[condition_index + 1]

    ship.schedule.records[station_index].wait_conditions[condition_index] = next_condition
    ship.schedule.records[station_index].wait_conditions[condition_index + 1] = current_condition
end

function SpaceShip.constant_changed(ship, station_index, condition_index, value)
    if not ship.schedule.records[station_index] or
        not ship.schedule.records[station_index].wait_conditions or
        not ship.schedule.records[station_index].wait_conditions[condition_index] then
        return
    end

    ship.schedule.records[station_index].wait_conditions[condition_index].condition.constant = value
end

function SpaceShip.compair_changed(ship, station_index, condition_index, value)
    if not ship.schedule.records[station_index] or
        not ship.schedule.records[station_index].wait_conditions or
        not ship.schedule.records[station_index].wait_conditions[condition_index] then
        return
    end

    ship.schedule.records[station_index].wait_conditions[condition_index].condition.comparator = value
end

function SpaceShip.signal_changed(ship, station_index, condition_index, signal)
    if not ship.schedule.records[station_index] or
        not ship.schedule.records[station_index].wait_conditions or
        not ship.schedule.records[station_index].wait_conditions[condition_index] then
        return
    end

    ship.schedule.records[station_index].wait_conditions[condition_index].condition.first_signal = {
        type = signal.type,
        name = signal.name
    }
end

function SpaceShip.auto_manual_changed(ship)
    if ship.automatic == true then ship.automatic = false else ship.automatic = true end
    if ship.own_surface == true then
        if ship.automatic == true then
            ship.surface.platform.paused = false
        else
            ship.surface.platform.paused = true
        end
    end
    game.print("Ship " .. ship.name .. " automatic mode is now " .. tostring(ship.automatic))
end

function SpaceShip.drop_player_to_planet(ship)
    -- Helper: Check if the ship has the required drop cost
    local function check_drop_cost(ship)
        if not ship.hub or not ship.hub.valid then return false, "No hub" end
        local inventory = ship.hub.get_inventory(defines.inventory.chest)
        if not inventory then return false, "No inventory" end
        for item, count in pairs(DROP_COST) do
            if inventory.get_item_count(item) < count then
                return false, "[color=red]Not enough " .. item .. " (" .. count .. " required)[/color]"
            end
        end
        return true
    end

    -- Helper: Consume the drop cost from the ship's hub inventory
    local function consume_drop_cost(ship)
        if not ship.hub or not ship.hub.valid then return false end
        local inventory = ship.hub.get_inventory(defines.inventory.chest)
        if not inventory then return false end
        for item, count in pairs(DROP_COST) do
            local removed = inventory.remove{name=item, count=count}
            if removed < count then
                return false
            end
        end
        return true
    end

    local can_drop, cost_message = check_drop_cost(ship)
    if not can_drop then
        game.print(cost_message or "[color=red]Insufficient resources for drop![/color]")
        return
    end
    if not ship.planet_orbiting then
        game.print("[color=red]Error: Ship is not orbiting any planet![/color]")
        return
    end
    local player = ship.player_in_cockpit
    local target_surface_name = ship.planet_orbiting
    local target_surface = game.surfaces[target_surface_name]
    if not target_surface then
        target_surface = game.create_surface(target_surface_name)
    end
    if not player then
        game.print("[color=red]Error: No player in cockpit to drop![/color]")
        return
    end
    local drop_pod_position = { x = player.position.x, y = player.position.y - 5 }
    drop_pod_position.x = math.floor(drop_pod_position.x)
    drop_pod_position.y = math.floor(drop_pod_position.y)
    if not ship.hub.surface or not ship.hub.surface.valid then
        game.print("[color=red]Error: Invalid surface for drop pod launch![/color]")
        return
    end
    local pod_entity_types = {
        "cargo-pod-container",
        "steel-chest"
    }
    local drop_force = player.force
    local drop_pod = nil
    for _, entity_type in ipairs(pod_entity_types) do
        local success, result = pcall(function()
            return ship.hub.surface.create_entity {
                name = entity_type,
                position = drop_pod_position,
                force = drop_force,
                create_build_effect_smoke = false
            }
        end)
        if success and result then
            drop_pod = result
            break
        end
    end
    if not drop_pod then
        game.print("[color=red]Error: Failed to create drop pod![/color]")
        return
    end
    -- Only consume cost if all checks pass and drop will happen
    if not consume_drop_cost(ship) then
        game.print("[color=red]Failed to consume drop cost![/color]")
        return
    end
    player.driving = false
    ship.player_in_cockpit = nil
    local drop_data = {
        player = player,
        target_surface = target_surface,
        drop_pod = drop_pod,
        tick_to_execute = game.tick + 180, -- 3 second delay
        ship = ship,
        cargo_items = nil,
        has_cargo = false
    }
    storage.pending_drops = storage.pending_drops or {}
    table.insert(storage.pending_drops, drop_data)
    if drop_pod then
        local effect_force = player.force
        pcall(function()
            ship.hub.surface.create_entity {
                name = "explosion",
                position = drop_pod.position,
                force = effect_force
            }
        end)
        for i = 1, 5 do
            pcall(function()
                ship.hub.surface.create_entity {
                    name = "explosion-gunshot",
                    position = {
                        x = drop_pod.position.x + math.random(-2, 2),
                        y = drop_pod.position.y + math.random(-2, 2)
                    },
                    force = effect_force
                }
            end)
        end
    end
    game.print("[color=green]Launching drop pod with player to " .. target_surface_name .. "![/color]")
end

-- Handles dropping items as cargo pods (no player drop)
function SpaceShip.drop_items_to_planet(ship)
    -- Helper: Check if the ship has the required drop cost
    local function check_drop_cost(ship)
        if not ship.hub or not ship.hub.valid then return false, "No hub" end
        local inventory = ship.hub.get_inventory(defines.inventory.chest)
        if not inventory then return false, "No inventory" end
        for item, count in pairs(DROP_COST) do
            if inventory.get_item_count(item) < count then
                return false, "[color=red]Not enough " .. item .. " (" .. count .. " required)[/color]"
            end
        end
        return true
    end

    -- Helper: Consume the drop cost from the ship's hub inventory
    local function consume_drop_cost(ship)
        if not ship.hub or not ship.hub.valid then return false end
        local inventory = ship.hub.get_inventory(defines.inventory.chest)
        if not inventory then return false end
        for item, count in pairs(DROP_COST) do
            local removed = inventory.remove{name=item, count=count}
            if removed < count then
                return false
            end
        end
        return true
    end

    local can_drop, cost_message = check_drop_cost(ship)
    if not can_drop then
        game.print(cost_message or "[color=red]Insufficient resources for drop![/color]")
        return
    end
    if not ship.planet_orbiting then
        game.print("[color=red]Error: Ship is not orbiting any planet![/color]")
        return
    end
    local target_surface_name = ship.planet_orbiting
    local target_surface = game.surfaces[target_surface_name]
    if not target_surface then
        target_surface = game.create_surface(target_surface_name)
    end
    local cargo_items = {}
    local has_cargo = false
    if ship.hub and ship.hub.valid then
        local inventory = ship.hub.get_inventory(defines.inventory.chest)
        if inventory and not inventory.is_empty() then
            -- Blacklist drop cost items: do not allow them to be dropped as cargo
            for i = 1, #inventory do
                local stack = inventory[i]
                if stack.valid_for_read then
                    local item_name = stack.name
                    -- Explicitly skip cost items (blacklist)
                    if not DROP_COST[item_name] then
                        local item_data = {
                            name = stack.name,
                            count = stack.count
                        }
                        local success, value
                        success, value = pcall(function() return stack.quality end)
                        if success and value then item_data.quality = value end
                        success, value = pcall(function() return stack.health end)
                        if success and value and value < 1.0 then item_data.health = value end
                        success, value = pcall(function() return stack.durability end)
                        if success and value and value < 1.0 then item_data.durability = value end
                        success, value = pcall(function() return stack.ammo end)
                        if success and value then item_data.ammo = value end
                        success, value = pcall(function() return stack.custom_description end)
                        if success and value and value ~= "" then item_data.custom_description = value end
                        table.insert(cargo_items, item_data)
                        has_cargo = true
                    end
                end
            end
            -- Remove only the dropped items from inventory
            for _, item in ipairs(cargo_items) do
                inventory.remove({name = item.name, count = item.count})
            end
            if has_cargo then
                game.print("[color=yellow]Cargo extracted from spaceship control hub: " .. #cargo_items .. " item stacks![/color]")
            end
        end
    end
    if not has_cargo then
        game.print("[color=red]Error: No cargo to drop![/color]")
        return
    end
    local drop_pod_position = { x = ship.hub.position.x, y = ship.hub.position.y - 5 }
    drop_pod_position.x = math.floor(drop_pod_position.x)
    drop_pod_position.y = math.floor(drop_pod_position.y)
    if not ship.hub.surface or not ship.hub.surface.valid then
        game.print("[color=red]Error: Invalid surface for drop pod launch![/color]")
        return
    end
    local pod_entity_types = {
        "cargo-pod-container",
        "steel-chest",
        "rocket-silo-rocket",
        "rocket-silo",
        "space-platform-hub",
        "assembling-machine-1"
    }
    local drop_force = ship.hub.force
    local drop_pod = nil
    for _, entity_type in ipairs(pod_entity_types) do
        local success, result = pcall(function()
            return ship.hub.surface.create_entity {
                name = entity_type,
                position = drop_pod_position,
                force = drop_force,
                create_build_effect_smoke = false
            }
        end)
        if success and result then
            drop_pod = result
            break
        end
    end
    if not drop_pod then
        game.print("[color=red]Error: Failed to create drop pod![/color]")
        return
    end
    -- Only consume cost if all checks pass and drop will happen
    if not consume_drop_cost(ship) then
        game.print("[color=red]Failed to consume drop cost![/color]")
        return
    end
    local drop_data = {
        player = nil,
        target_surface = target_surface,
        drop_pod = drop_pod,
        tick_to_execute = game.tick + 180, -- 3 second delay
        ship = ship,
        cargo_items = cargo_items,
        has_cargo = has_cargo
    }
    storage.pending_drops = storage.pending_drops or {}
    table.insert(storage.pending_drops, drop_data)
    if drop_pod then
        local effect_force = ship.hub.force
        pcall(function()
            ship.hub.surface.create_entity {
                name = "explosion",
                position = drop_pod.position,
                force = effect_force
            }
        end)
        for i = 1, 5 do
            pcall(function()
                ship.hub.surface.create_entity {
                    name = "explosion-gunshot",
                    position = {
                        x = drop_pod.position.x + math.random(-2, 2),
                        y = drop_pod.position.y + math.random(-2, 2)
                    },
                    force = effect_force
                }
            end)
        end
    end
    game.print("[color=green]Launching cargo drop pod to " .. target_surface_name .. "![/color]")
end

function SpaceShip.process_pending_drops()
    if not storage.pending_drops then return end
    local current_tick = game.tick
    local completed_drops = {}
    for i, drop_data in ipairs(storage.pending_drops) do
        if current_tick >= drop_data.tick_to_execute then
            local player = drop_data.player
            local target_surface = drop_data.target_surface
            local drop_pod = drop_data.drop_pod
            -- Handle player drop
            if player and player.valid and target_surface and target_surface.valid then
                local landing_position = target_surface.find_non_colliding_position("character", {0, 0}, 100, 1) or {0, 0}
                player.teleport(landing_position, target_surface)
                game.print("[color=green]Player " .. player.name .. " has landed on " .. target_surface.name .. "![/color]")
            end
            -- Handle cargo drop
            if drop_data.has_cargo and drop_data.cargo_items and #drop_data.cargo_items > 0 and target_surface and target_surface.valid then
                local items_per_pod = 10
                local cargo_chunks = {}
                local current_chunk = {}
                for i, item_data in ipairs(drop_data.cargo_items) do
                    table.insert(current_chunk, item_data)
                    if #current_chunk >= items_per_pod then
                        table.insert(cargo_chunks, current_chunk)
                        current_chunk = {}
                    end
                end
                if #current_chunk > 0 then
                    table.insert(cargo_chunks, current_chunk)
                end
                local total_pods = #cargo_chunks
                local successful_pods = 0
                for pod_index, item_chunk in ipairs(cargo_chunks) do
                    local pod_position = nil
                    for attempt = 1, 10 do
                        local test_pos = {
                            x = math.random(-50, 50) + (pod_index * 5),
                            y = math.random(-50, 50) + (pod_index * 5)
                        }
                        pod_position = target_surface.find_non_colliding_position("cargo-pod-container", test_pos, 20, 1)
                        if pod_position then break end
                    end
                    if not pod_position then
                        pod_position = {x = pod_index * 5, y = pod_index * 5}
                    end
                    local pod_entity_types = {"cargo-pod-container", "steel-chest"}
                    local cargo_pod = nil
                    for _, entity_type in ipairs(pod_entity_types) do
                        local success, result = pcall(function()
                            return target_surface.create_entity{
                                name = entity_type,
                                position = pod_position,
                                force = (player and player.force) or "player"
                            }
                        end)
                        if success and result then
                            cargo_pod = result
                            break
                        end
                    end
                    if cargo_pod then
                        successful_pods = successful_pods + 1
                        local pod_inventory = cargo_pod.get_inventory(defines.inventory.chest)
                        if pod_inventory then
                            for _, item_data in ipairs(item_chunk) do
                                local item_to_insert = {name = item_data.name, count = item_data.count}
                                if item_data.quality then item_to_insert.quality = item_data.quality end
                                if item_data.health then item_to_insert.health = item_data.health end
                                if item_data.durability then item_to_insert.durability = item_data.durability end
                                if item_data.ammo then item_to_insert.ammo = item_data.ammo end
                                if item_data.custom_description then item_to_insert.custom_description = item_data.custom_description end
                                pod_inventory.insert(item_to_insert)
                            end
                        end
                        pcall(function()
                            target_surface.create_entity{
                                name = "explosion",
                                position = cargo_pod.position,
                                force = cargo_pod.force
                            }
                        end)
                    end
                end
                if successful_pods > 0 then
                    game.print("[color=green]" .. successful_pods .. "/" .. total_pods .. " cargo pods have landed on " .. target_surface.name .. "![/color]")
                else
                    game.print("[color=red]Failed to create cargo pods on " .. target_surface.name .. "![/color]")
                end
            end
            -- Clean up the launch pod if it exists
            if drop_data.drop_pod and drop_data.drop_pod.valid then
                drop_data.drop_pod.destroy()
            end
            table.insert(completed_drops, i)
        end
    end
    for i = #completed_drops, 1, -1 do
        table.remove(storage.pending_drops, completed_drops[i])
    end
end

function SpaceShip.handle_built_entity(entity, player)
    if not (entity and entity.valid) then return end

    local surface = entity.surface

    -- Check thruster placement restrictions
    if entity.name == "thruster" then
        -- Get the thruster's bounding box to check all tiles underneath
        local bounding_box = entity.bounding_box
        local left_top = { x = math.floor(bounding_box.left_top.x), y = math.floor(bounding_box.left_top.y) }
        local right_bottom = {
            x = math.ceil(bounding_box.right_bottom.x) - 1,
            y = math.ceil(bounding_box.right_bottom.y) -
                1
        }

        -- Check all tiles under the thruster
        local invalid_tiles = {}
        for x = left_top.x, right_bottom.x do
            for y = left_top.y, right_bottom.y do
                local tile = surface.get_tile({ x = x, y = y })
                if tile.name ~= "spaceship-flooring" then
                    table.insert(invalid_tiles, { x = x, y = y, name = tile.name })
                end
            end
        end

        -- If any tiles are not spaceship flooring, prevent placement
        if #invalid_tiles > 0 then
            local item_stack = { name = "thruster", count = 1 }

            -- Return the thruster to player inventory or spill on ground
            if player and player.valid then
                local inserted = player.insert(item_stack)
                if inserted == 0 then
                    -- If player inventory is full, spill on ground
                    surface.spill_item_stack(entity.position, item_stack, true, player.force, false)
                end

                -- Show error message to player
                player.print("[color=red]Thrusters can only be placed on Spaceship Flooring![/color]")
            else
                -- No player (robot built), spill on ground
                surface.spill_item_stack(entity.position, item_stack, true, entity.force, false)
            end

            -- Remove the incorrectly placed thruster
            entity.destroy()
            return
        end
    end

    -- Spawn the car on the spaceship controller:
    if entity.name == "spaceship-control-hub" then
        storage.spaceships = storage.spaceships or {}
        local count = table_size(storage.spaceships) + 1
        local my_ship = SpaceShip.new("Explorer" .. count, count, player)
        entity.tags = { id = 1 }
        my_ship.hub = entity
        storage.spaceships[my_ship.id] = my_ship
        local car_position = { x = entity.position.x + 2, y = entity.position.y + 3.5 } -- Car spawns slightly lower so player can enter it
        local car = surface.create_entity {
            name = "spaceship-control-hub-car",
            position = car_position,
            force = entity.force
        }
        if car then
            car.orientation = 0.0 -- Align the car with the controller orientation, if needed.
            game.print("Spaceship control hub car spawned!")
        else
            game.print("Eable to spawn spaceship control hub car!")
        end
    end
    if entity.name == "spaceship-docking-port" then
        SpaceShip.register_docking_port(entity)
    end
    
    -- Warn about transfer rules when cargo landing pads are placed
    if entity.name == "cargo-landing-pad" and entity.surface.platform then
        local platform = entity.surface.platform
        local platform_type = SpaceShip.get_platform_type(platform)
        if platform_type == "ship" and player and player.valid then
            player.print({"message.transfer-ship-to-ship-forbidden"})
        end
    end

    -- If built on a spaceship tile, mark scanned as false
    for _, ship in pairs(storage.spaceships or {}) do
        if ship.hub and ship.hub.valid and entity.surface == ship.hub.surface then
            -- Check if any tile under the entity is spaceship-flooring
            local bb = entity.bounding_box or { left_top = entity.position, right_bottom = entity.position }
            local found = false
            for x = math.floor(bb.left_top.x), math.ceil(bb.right_bottom.x) do
                for y = math.floor(bb.left_top.y), math.ceil(bb.right_bottom.y) do
                    local tile = entity.surface.get_tile(x, y)
                    if tile and tile.name == "spaceship-flooring" then
                        found = true
                        break
                    end
                end
                if found then break end
            end
            if found then
                ship.scanned = false
            end
        end
    end
end

function SpaceShip.handle_mined_entity(entity)
    if not (entity and entity.valid) then return end
    -- Remove the car associated with the mined hub
    if entity.name == "spaceship-control-hub" then
        local area = {
            { entity.position.x - 5, entity.position.y },
            { entity.position.x + 5, entity.position.y + 6 }
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
    if entity.name == "spaceship-docking-port" then
        if storage.docking_ports and storage.docking_ports[entity.unit_number] then
            storage.docking_ports[entity.unit_number] = nil
        end
    end
    -- If built on a spaceship tile, mark scanned as false
    for _, ship in pairs(storage.spaceships or {}) do
        if ship.hub and ship.hub.valid and entity.surface == ship.hub.surface then
            -- Check if any tile under the entity is spaceship-flooring
            local bb = entity.bounding_box or { left_top = entity.position, right_bottom = entity.position }
            local found = false
            for x = math.floor(bb.left_top.x), math.ceil(bb.right_bottom.x) do
                for y = math.floor(bb.left_top.y), math.ceil(bb.right_bottom.y) do
                    local tile = entity.surface.get_tile(x, y)
                    if tile and tile.name == "spaceship-flooring" then
                        found = true
                        break
                    end
                end
                if found then break end
            end
            if found then
                ship.scanned = false
            end
        end
    end
end

function SpaceShip.handle_ghost_entity(ghost, player)
    if not (ghost and ghost.valid) then return end

    -- Check thruster ghost placement restrictions
    if ghost.ghost_name == "thruster" then
        local surface = ghost.surface

        -- Get the thruster's bounding box to check all tiles underneath
        local bounding_box = ghost.bounding_box
        local left_top = { x = math.floor(bounding_box.left_top.x), y = math.floor(bounding_box.left_top.y) }
        local right_bottom = {
            x = math.ceil(bounding_box.right_bottom.x) - 1,
            y = math.ceil(bounding_box.right_bottom.y) -
                1
        }

        -- Check all tiles under the thruster ghost
        local invalid_tiles = {}
        for x = left_top.x, right_bottom.x do
            for y = left_top.y, right_bottom.y do
                local position = { x = x, y = y }
                local tile = surface.get_tile(position)
                local valid_tile = false

                -- Check if current tile is spaceship flooring
                if tile.name == "spaceship-flooring" then
                    valid_tile = true
                else
                    -- Check for spaceship flooring ghost tiles at this position
                    local ghost_tiles = surface.find_entities_filtered({
                        position = position,
                        type = "tile-ghost",
                        name = "tile-ghost"
                    })

                    for _, ghost_tile in pairs(ghost_tiles) do
                        if ghost_tile.ghost_name == "spaceship-flooring" then
                            valid_tile = true
                            break
                        end
                    end
                end

                if not valid_tile then
                    table.insert(invalid_tiles, { x = x, y = y, name = tile.name })
                end
            end
        end

        -- If any tiles are not spaceship flooring (actual or ghost), prevent ghost placement
        if #invalid_tiles > 0 then
            -- Show error message to player
            if player and player.valid then
                player.print("[color=red]Thrusters can only be placed on Spaceship Flooring![/color]")
            end

            -- Remove the incorrectly placed ghost
            ghost.destroy()
            return
        end
    end
end

-- Get platform type (station/ship) from platform
function SpaceShip.get_platform_type(platform)
    if not platform or not platform.valid then return nil end
    
    -- Check tags first
    if platform.tags and platform.tags.ship_type then
        return platform.tags.ship_type
    end
    
    -- Fallback to name-based detection
    if string.find(platform.name, "-station") then
        return "platform"
    elseif string.find(platform.name, "-ship") then
        return "ship"
    end
    
    return nil
end

-- Check if transfer between platforms is allowed
function SpaceShip.is_transfer_allowed(source_surface, dest_surface)
    -- Get platforms from surfaces
    local source_platform = source_surface.platform
    local dest_platform = dest_surface.platform
    
    if not source_platform or not dest_platform then
        return true -- At least one is not a platform, allow by default
    end
    
    -- Check if in same orbit
    if source_platform.space_location ~= dest_platform.space_location then
        return false, "Platforms must be in same orbit"
    end
    
    -- Get platform types
    local source_type = SpaceShip.get_platform_type(source_platform)
    local dest_type = SpaceShip.get_platform_type(dest_platform)
    
    -- Ship to Ship transfers are forbidden
    if source_type == "ship" and dest_type == "ship" then
        return false, {"message.transfer-ship-to-ship-forbidden"}
    end
    
    -- Station↔Station and Station↔Ship are allowed
    return true, nil
end

return SpaceShip