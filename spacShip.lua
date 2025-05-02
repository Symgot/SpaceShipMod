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

-- Add new function to handle docking port creation
SpaceShip.register_docking_port = function(entity)
    if not storage.docking_ports then SpaceShip.init_docking_ports() end
    local tile = entity.surface.get_tile(entity.position)
    storage.docking_ports[entity.unit_number] = {
        entity = entity,
        position = entity.position,
        surface = entity.surface,
        name = "",     -- Will be set via GUI
        ship_limit = 1 -- Default limit
    }
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
        local reference_tile = ship.reference_tile
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

function SpaceShip.add_or_change_station(ship, to, from)
    ship.schedule = ship.schedule or {}
    if not ship.schedule.current then
        ship.schedule.current = 1 --default to 1 of not already set
    end
    if ship.schedule.records and ship.schedule.records[to] then
        ship.schedule.records[to] = from
    elseif ship.schedule.records then
        records =
        {
            station = "nauvis",
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
        table.insert(ship.schedule.records, records)
    else
        ship.schedule.records = {
            {
                station = "nauvis",
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
end

-- Clone all tiles and entities from the old ship to the new ship
function SpaceShip.clone_ship_area(ship, dest_surface, dest_center, excluded_types)
    local src_surface = ship.surface.platform.surface
    -- Caate the offset between the source and destination areas
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
    -- Filter entities to exclude certain types
    local entities_to_clone = {}
    for _, entity in pairs(ship.entities) do
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
        { x = dest_center.x - 50, y = dest_center.y - 50 }, -- someday i need to change this to on cloned event
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
    ship.hub = control_hub

    --working on this, need to find a way ot detect new docking port and restore it to storage.
    local docking_port = dest_surface.find_entities_filtered({
        area = search_area,
        name = "spaceship-docking-port"
    })
    
    -- Remove entities from the original surface
    for _, entity in pairs(ship.entities) do
        if entity and entity.valid then
            entity.destroy()
        end
    end

    -- Change tiles in the original area to hidden tiles
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
    SpaceShip.start_scan_ship(ship, 50, 1)
end

-- Function to clone the ship to a new space platform surface
function SpaceShip.clone_ship_to_space_platform(ship)
    -- Ensure the player is valid
    if not ship or not ship.player or not ship.player.valid then
        ship.player.print("Error: Invalid player.")
        return
    end

    if not ship.scanned then
        ship.player.print("Error: No scanned ship data found. Run a ship scan first.")
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
    -- Define the destination center position
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

    -- Clone the ship area to the new space platform surface
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
        -- Teleport the player to the new space platform surface
        ship.player_in_cockpit.teleport(dest_center, space_platform.surface)



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
            -- Teleport the player to the control hub car and make them enter it
            ship.player_in_cockpit.teleport(control_hub_car.position, control_hub_car.surface)
            ship.player_in_cockpit.driving = true -- Make the player enter the vehicle
            ship.player_in_cockpit.print("You have entered the spaceship control hub car at the destination.")
        else
            ship.player_in_cockpit.print("Error: Unable to find the spaceship control hub car at the destination.")
        end
    end

    local search_area = {
        { x = dest_center.x - 50, y = dest_center.y - 50 }, -- Define a reasonable search area around the cloned ship
        { x = dest_center.x + 50, y = dest_center.y + 50 }
    }

    local entities_in_area2 = space_platform.surface.find_entities_filtered({
        area = search_area,
        name = "spaceship-control-hub"
    })

    if #entities_in_area2 > 0 then
        control_hub_car = entities_in_area2[1] -- Assume the first found entity is the control hub car
    end

    player.print("Ship successfully cloned to the new space platform: ")
    ship.own_surface = true
    ship.planet_orbiting = OG_surface
    ship.surface = space_platform.surface
    ship.hub = entities_in_area2[1]
    ship.traveling = true
    SpaceShip.start_scan_ship(ship, 50, 1)
end

function SpaceShip.start_scan_ship(ship, scan_per_tick, tick_amount)
    player = ship.player
    if storage.scan_state then
        player.print("Scan is in progress, please wait.")
        return
    end
    local search_area = {
        { x = ship.hub.position.x - 50, y = ship.hub.position.y - 50 }, -- Define a reasonable search area around the cloned ship
        { x = ship.hub.position.x + 50, y = ship.hub.position.y + 50 }
    }
    local temp_entity = player.surface.find_entities_filtered { area = search_area, name = "spaceship-control-hub" }
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

    local count = table_size(storage.spaceships) + 1
    if not ship then
        ship = SpaceShip.new("Explorer" .. count, count, player)
    end

    ship.floor = nil
    ship.entities = nil
    ship.reference_tile = nil
    ship.surface = nil

    -- Initialize scan state
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
        scan_per_tick = scan_per_tick or 1, -- how many tiles to scan per tick
        tick_counter = 0,                   -- Counter to track ticks for progress updates
        tick_amount = tick_amount or 1      --how ofter to keep scanning, higher=slower
    }
    -- Start the scanning process
    player.print("Ship scan started. Scanning up to " ..
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
            player.print("Ship scan completed! Found " ..
                table_size(state.flooring_tiles) ..
                " tiles and " .. table_size(temp_entities) .. " entities.")
            if state.docking_port then
                ship.docking_port = state.docking_port
            else
                player.print("No docking port found on the ship.")
            end
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

            -- Use get_connected_tiles to find all connected tiles of the wame type in 1 hit, whaaat?!
            if #state.tiles_to_check == 0 then
                state.tiles_to_check = state.surface.get_connected_tiles({ x = current_pos.x, y = current_pos.y },
                    { "spaceship-flooring" })
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
    if ship.player_in_cockpit then
        -- Player is in the cockpit, proceed
    elseif player_tile and player_tile.name ~= "spaceship-flooring" then
        -- Player is not standing on ship flooring, proceed
    else
        player.print("Error: You must be in the cockpit or not on ship to initiate takeoff.")
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
        player.print("Error: No stations found, or not orbiting planet!")
        return
    end

    ship.taking_off = true -- Flag to indicate takeoff process has started

    if not ship.scanned then
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
    --storage.highlight_data = SpaceShip.create_combined_renders(player, ship
    --    .floor, false, { x = 2, y = -4 })
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
    if not ship.scanned then
        player.print("Error: No scanned ship data found.")
        return
    end

    local src_surface = ship.surface -- Retrieve the source surface
    local dest_surface = player.surface
    local dest_center = { x = math.ceil(player.position.x), y = math.floor(player.position.y - 5) }

    -- Define the types of entities to exclude
    local excluded_types = {
        ["logistic-robot"] = true,
        ["contruction-robot"] = true,
    }
    --ship.planet_orbiting = src_surface.name
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
    ship.hub = entities_in_area[1]
    ship.taking_off = false -- Reset the taking off flag
    ship.own_surface = false
    ship.surface = dest_surface
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
    ship.taking_off = false -- Reset the taking off flag
end

function SpaceShip.read_circuit_signals(entity)
    -- Get the circuit network for red and green wires
    local red_network = entity.get_circuit_network(defines.wire_type.red)
    local green_network = entity.get_circuit_network(defines.wire_type.green)

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
                signals[signal.signal.name] = signal[signal.signal.name] + signal.count
            end
        end
    end

    return signals
end

-- Example usage:
function SpaceShip.check_circuit_condition(entity, signal_name, comparison, value)
    local signals = SpaceShip.read_circuit_signals(entity)
    local signal_value = signals[signal_name] or 0

    -- Compare the signal value based on the comparison operator
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

function SpaceShip.check_automatic_behavior()
    SpaceShip.connect_adjacent_ports()
    -- Check each ship in storage
    for id, ship in pairs(storage.spaceships or {}) do
        -- Skip if not in automatic mode
        if not ship.automatic then goto continue end

        -- Get current station from schedule
        local schedule = ship.schedule
        if not schedule or not schedule.records then goto continue end

        local current_station = schedule.records[schedule.current]
        if not current_station then goto continue end

        if not ship.scanned and not storage.scan_state then
            SpaceShip.start_scan_ship(ship, 50)
        elseif not ship.scanned then
            goto continue
        end

        -- Check if ship is orbiting the current station
        if ship.own_surface or not ship.scanned then goto continue end
        if ship.surface.platform.space_location.name == current_station.station then
            -- Check all wait conditions for current station
            local all_conditions_met = true
            for _, condition in pairs(current_station.wait_conditions) do
                if not SpaceShip.check_circuit_condition(
                        ship.hub,
                        condition.condition.first_signal.name,
                        condition.condition.comparator,
                        condition.condition.constant
                    ) then
                    all_conditions_met = false
                    break
                end
            end

            -- If all conditions are met, prepare for travel
            if all_conditions_met then
                SpaceShip.clone_ship_to_space_platform(ship)
                -- Set next station in schedule
                local next_station
                if schedule.records[schedule.current + 1] then
                    schedule.current = schedule.current + 1
                    next_station = schedule.records[schedule.current]
                else
                    schedule.current = 1
                    next_station = schedule.records[schedule.current]
                end

                -- Update platform schedule and start travel
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
                -- Ensure both entities are valid
                if port1.entity.valid and port2.entity.valid then
                    -- Get the wire connectors for both ports
                    local red_connector1 = port1.entity.get_wire_connector(defines.wire_connector_id.circuit_red)
                    local green_connector1 = port1.entity.get_wire_connector(defines.wire_connector_id.circuit_green)
                    local red_connector2 = port2.entity.get_wire_connector(defines.wire_connector_id.circuit_red)
                    local green_connector2 = port2.entity.get_wire_connector(defines.wire_connector_id.circuit_green)

                    -- Connect red wires
                    if red_connector1 and red_connector2 then
                        red_connector1.connect_to(red_connector2)
                    end

                    -- Connect green wires
                    if green_connector1 and green_connector2 then
                        green_connector1.connect_to(green_connector2)
                    end
                end
            end
        end
    end
end

function SpaceShip.on_platform_state_change(event)
    -- Get the platform and its associated ship
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

    -- Check if the platform's state changed to 6
    if event.platform.state == 6 then
        -- Pause the platform
        platform.paused = true

        -- Get the target docking port from the current schedule
        local schedule = ship.schedule
        if not schedule or not schedule.records or not schedule.records[schedule.current] then
            game.print("Error: Invalid schedule for ship " .. ship.name)
            return
        end
        local target_docking_port
        for _, port in pairs(storage.docking_ports) do
            if port.name == ship.port_records[schedule.current] then --port records keys are tied to station number.
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

        -- Align the ship's docking port with the target docking port
        local offset = {
            x = target_docking_port.position.x - ship.docking_port.position.x +1,
            y = target_docking_port.position.y - ship.docking_port.position.y
        }

        -- Clone the ship to the target surface
        SpaceShip.clone_ship_area(ship, target_docking_port.surface, offset, {})

        -- Update the ship's surface and docking port
        ship.surface = target_docking_port.surface

        game.print("Ship " .. ship.name .. " successfully cloned to surface " .. target_docking_port.surface.name)
    end
end

return SpaceShip
