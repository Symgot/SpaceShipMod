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
        name = entity.surface.platform.space_location.name..table_size(storage.docking_ports)
    else
        name = "ship"
    end
    storage.docking_ports[entity.unit_number] = {
        entity = entity,
        position = entity.position,
        surface = entity.surface,
        name = name,      -- Will be set via GUI
        ship_limit = 1, -- Default limit
        ship_docked = nil
    }
end

function SpaceShip.create_combined_renders(player, tiles, scan, offset)
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

function SpaceShip.ship_takeoff(ship)
    local plat      = player.surface.platform
    local stationID = player.gui.relative["spaceship-controller-extended-gui"]
        ["surface-dropdown"].selected_index
    local station   = player.gui.relative["spaceship-controller-extended-gui"]
        ["surface-dropdown"].items[stationID]
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
    }
    ship.schedule   = schedual
    plat.schedule   = schedual
    plat.paused     = false
    game.print("Schedule applied and started for:" .. plat.name)
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

    dest_surface.request_to_generate_chunks(dest_center, 10)
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
    for _, entity in pairs(ship.entities) do
        if entity.valid and not excluded_types[entity.type] then --filter happens here
            table.insert(entities_to_clone, entity)
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
    SpaceShip.start_scan_ship(ship)
end

function SpaceShip.clone_ship_to_space_platform(ship)
    if not ship or not ship.player or not ship.player.valid then
        ship.game.print("Error: Invalid player.")
        return
    end

    if not ship.scanned then
        ship.game.print("Error: No scanned ship data found. Run a ship scan first.")
        return
    end

    local space_platform_temp
    for _, surface in pairs(ship.player.force.platforms) do
        space_platform_temp = surface
        break
    end

    local space_platform = ship.player.force.create_space_platform({
        name = "SpaceShip" .. ship.name,
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
    SpaceShip.start_scan_ship(ship)
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
        scan_per_tick = scan_per_tick or 60, -- how many tiles to scan per tick
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
            ship.planet_orbiting = state.surface.platform.space_location
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

    --[[ Print progress every 300 ticks
    if state.tick_counter % 10 == 0 then
        local player = state.player
        local total_tiles = table_size(state.scanned_tiles)
        local remaining_tiles = #state.tiles_to_check
        game.print("Scanning progress: " .. total_tiles .. " tiles scanned, " .. remaining_tiles .. " tiles remaining.")
    end]] --
end

function SpaceShip.dock_ship(player)
    local src_surface = player.surface
    local dest_surface
    local player_tile = src_surface.get_tile(player.position)
    if ship.player_in_cockpit then
    elseif player_tile and player_tile.name ~= "spaceship-flooring" then
    else
        game.print("Error: You must be in the cockpit or not on ship to initiate takeoff.")
        return
    end

    for id, plat in pairs(player.force.platforms) do
        if plat.space_location then
            if plat.space_location.name == ship.planet_orbiting then
                if plat.name ~= "SpaceShip" .. ship.name then
                    dest_surface = player.force.platforms[id]
                end
            end
        end
    end

    if not dest_surface then
        game.print("Error: No stations found, or not orbiting planet!")
        return
    end

    ship.taking_off = true -- Flag to indicate takeoff process has started

    if not ship.scanned then
        game.print("Error: No scanned ship data found. Run a ship scan first.")
        return
    end

    storage.player_body = player.character

    local player_pos = player.position
    local dest_center = { x = 0, y = 0 }
    player.set_controller({ type = defines.controllers.ghost }) -- Set the player to ghost contro
    player.teleport(dest_center, dest_surface.surface)

    storage.player_position_on_render = player.position
    storage.highlight_data = storage.highlight_data or {}
    --storage.highlight_data = SpaceShip.create_combined_renders(player, ship
    --    .floor, false, { x = 2, y = -4 })
    game.print("rends count: " .. #storage.highlight_data)
    storage.highlight_data_player_index = player.index

    storage.takeoff_player = player.index

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
    if not ship.scanned then
        game.print("Error: No scanned ship data found.")
        return
    end

    local src_surface = ship.surface -- Retrieve the source surface
    local dest_surface = player.surface
    local dest_center = { x = math.ceil(player.position.x), y = math.floor(player.position.y - 5) }

    local excluded_types = {
        ["logistic-robot"] = true,
        ["contruction-robot"] = true,
    }
    SpaceShip.clone_ship_area(src_surface.platform.surface, dest_surface, dest_center, excluded_types)

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
function SpaceShip.cancel_dock(player)
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
            SpaceShip.start_scan_ship(ship)
        elseif not ship.scanned then
            goto continue
        end

        if ship.own_surface or not ship.scanned then goto continue end
        if ship.surface.platform.space_location.name == current_station.station then
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
        end
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
end

return SpaceShip
