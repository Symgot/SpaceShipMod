local SpaceShipFunctions = require("SpaceShipFunctionsScript")
local SpaceShip = require("SpaceShip")
local SpaceShipGuis = {}
local gui_maker = require("__ship-gui__.spaceship_gui.spaceship_gui")

-- Define event handlers
function SpaceShipGuis.on_station_selected(event)
    local ship = storage.spaceships[event.ship_id]
    if ship then
        game.print("Station " .. event.selected_station .. " selected for ship " .. ship.name)
        SpaceShip.add_or_change_station(ship, event.selected_station)
        SpaceShipGuis.gui_maker_handler(ship, event.player_index)
    end
end

function SpaceShipGuis.on_station_move_up(event)
    local ship = storage.spaceships[event.ship_id]
    if ship then
        game.print("Ship " .. ship.name .. " moving station up")
    end
    SpaceShip.station_move_up(ship, event.station_index)
    SpaceShipGuis.gui_maker_handler(ship, event.player_index)
end

function SpaceShipGuis.on_station_move_down(event)
    local ship = storage.spaceships[event.ship_id]
    if ship then
        game.print("Ship " .. ship.name .. " moving station down")
    end
    SpaceShip.station_move_down(ship, event.station_index)
    SpaceShipGuis.gui_maker_handler(ship, event.player_index)
end

function SpaceShipGuis.on_station_dock_selected(event)
    local ship = storage.spaceships[event.ship_id]
    if ship then
        game.print("Ship " .. ship.name .. " handling dock")
        if not ship.port_records[event.station_index] then
            ship.port_records[event.station_index] = {}
        end
        ship.port_records[event.station_index] = event.selected_dock
        SpaceShipGuis.gui_maker_handler(ship, event.player_index)
    end
end

function SpaceShipGuis.on_station_unload_check_changed(event)
    local ship = storage.spaceships[event.ship_id]
    if ship then
        game.print("Ship " .. ship.name .. " handling unload")
    end
    SpaceShipGuis.gui_maker_handler(ship, event.player_index)
end

function SpaceShipGuis.on_station_condition_add(event)
    local ship = storage.spaceships[event.ship_id]
    if ship then
        game.print("Ship " .. ship.name .. " handling add condition")
    end
    local condition_type = string.lower(string.gsub(event.selected_item, " condition", ""))
    SpaceShip.add_wait_condition(ship, event.station_index, condition_type)
    SpaceShipGuis.gui_maker_handler(ship, event.player_index)
end

function SpaceShipGuis.on_station_goto(event)
    local ship = storage.spaceships[event.ship_id]
    if ship then
        game.print("Ship " .. ship.name .. " handling goto")
    end
    SpaceShipGuis.gui_maker_handler(ship, event.player_index)
end

function SpaceShipGuis.on_condition_move_up(event)
    local ship = storage.spaceships[event.ship_id]
    if ship then
        game.print("Ship " .. ship.name .. " handling move condition up")
    end
    SpaceShip.condition_move_up(ship, event.station_index, event.condition_index)
    SpaceShipGuis.gui_maker_handler(ship, event.player_index)
end

function SpaceShipGuis.on_condition_move_down(event)
    local ship = storage.spaceships[event.ship_id]
    if ship then
        game.print("Ship " .. ship.name .. " handling move condition down")
    end
    SpaceShip.condition_move_down(ship, event.station_index, event.condition_index)
    SpaceShipGuis.gui_maker_handler(ship, event.player_index)
end

function SpaceShipGuis.on_station_delete(event)
    local ship = storage.spaceships[event.ship_id]
    if ship then
        game.print("Ship " .. ship.name .. " handling delete station")
    end
    SpaceShip.delete_station(ship, event.station_index)
    SpaceShipGuis.gui_maker_handler(ship, event.player_index)
end

function SpaceShipGuis.on_condition_delete(event)
    local ship = storage.spaceships[event.ship_id]
    if ship then
        game.print("Ship " .. ship.name .. " handling delete condition")
    end
    SpaceShip.remove_wait_condition(ship, event.station_index, event.condition_index)
    SpaceShipGuis.gui_maker_handler(ship, event.player_index)
end

function SpaceShipGuis.on_condition_constant_confirmed(event)
    local ship = storage.spaceships[event.ship_id]
    if ship then
        game.print("Ship " .. ship.name .. " handling constant changed")
    end
    SpaceShip.constant_changed(ship, event.station_index, event.condition_index, event.amount)
end

function SpaceShipGuis.on_comparison_sign_changed(event)
    local ship = storage.spaceships[event.ship_id]
    if ship then
        game.print("Ship " .. ship.name .. " handling compair changed")
    end
    SpaceShip.compair_changed(ship, event.station_index, event.condition_index, event.comparator)
    SpaceShipGuis.gui_maker_handler(ship, event.player_index)
end

function SpaceShipGuis.on_bool_changed(event)
    local ship = storage.spaceships[event.ship_id]
    if ship then
        game.print("Ship " .. ship.name .. " handling bool changed")
    end
    SpaceShipGuis.gui_maker_handler(ship, event.player_index)
end

function SpaceShipGuis.on_first_signal_selected(event)
    local ship = storage.spaceships[event.ship_id]
    if ship then
        game.print("Ship " .. ship.name .. " handling signal check")
    end
    SpaceShip.signal_changed(ship, event.station_index, event.condition_index, event.selected_signal)
    SpaceShipGuis.gui_maker_handler(ship, event.player_index)
end

function SpaceShipGuis.on_ship_rename_confirmed(event)
    local ship = storage.spaceships[event.ship_id]
    if ship then
        game.print("Ship " .. ship.name .. " handling rename")
    end
    SpaceShipGuis.gui_maker_handler(ship, event.player_index)
end

function SpaceShipGuis.on_ship_paused_unpaused(event)
    local ship = storage.spaceships[event.ship_id]
    if ship then
        game.print("Ship " .. ship.name .. " handling paused")
    end
    SpaceShip.auto_manual_changed(ship)
    SpaceShipGuis.gui_maker_handler(ship, event.player_index)
end

-- Function to create the custom spaceship control GUI
function SpaceShipGuis.create_spaceship_gui(player, ship)
    local relative_gui = player.gui.relative

    if relative_gui["spaceship-controller-extended-gui-" .. ship.name] then
        return
    end
    if relative_gui["spaceship-controller-schedual-gui-" .. ship.name] then
        return
    end
    local ship_tag_number = tonumber(ship.id)
    -- Initialize storage if needed
    storage = storage or {}
    storage.spaceships = storage.spaceships or {}

    local custom_gui = relative_gui.add {
        type = "frame",
        name = "spaceship-controller-extended-gui-" .. ship.name,
        caption = "Spaceship Actions",
        direction = "vertical",
        anchor = {
            gui = defines.relative_gui_type.container_gui,
            position = defines.relative_gui_position.left
        },
        tags = { ship = ship_tag_number }
    }

    -- Add a dropdown with researched planets (even if not yet visited)
    local planet_names = {}
    local force = ship.hub.force

    -- Always include Nauvis (starting planet)
    table.insert(planet_names, "nauvis")

    -- Check for researched Space Age planets
    local planet_research_map = {
        ["vulcanus"] = "planet-discovery-vulcanus",
        ["fulgora"] = "planet-discovery-fulgora",
        ["gleba"] = "planet-discovery-gleba",
        ["aquilo"] = "planet-discovery-aquilo"
    }

    -- Add planets that have been researched
    for planet_name, research_tech in pairs(planet_research_map) do
        local tech = force.technologies[research_tech]
        if tech and tech.researched then
            table.insert(planet_names, planet_name)
        end
    end

    -- Check for modded planets with discovery technologies
    -- Look through all technologies for ones that follow the planet-discovery pattern
    for tech_name, technology in pairs(force.technologies) do
        if string.match(tech_name, "^planet%-discovery%-(.+)$") and technology.researched then
            local planet_name = string.match(tech_name, "^planet%-discovery%-(.+)$")
            -- Don't add duplicates from the standard planets above
            local already_added = false
            for _, existing_planet in pairs(planet_names) do
                if existing_planet == planet_name then
                    already_added = true
                    break
                end
            end
            if not already_added then
                table.insert(planet_names, planet_name)
            end
        end
    end

    -- Also add any existing surfaces that are clearly planets (visited planets)
    -- This catches any edge cases or planets that don't follow the research pattern
    for surface_name, surface in pairs(game.surfaces) do
        if not string.find(surface_name, "platform") and
            not string.find(surface_name, "space%-") and
            not string.find(surface_name, "orbit") and
            surface_name ~= "nauvis" then -- Don't duplicate nauvis
            -- Check if it's not already in our list
            local already_added = false
            for _, existing_planet in pairs(planet_names) do
                if existing_planet == surface_name then
                    already_added = true
                    break
                end
            end
            if not already_added then
                table.insert(planet_names, surface_name)
            end
        end
    end

    custom_gui.add {
        type = "drop-down",
        name = "surface-dropdown",
        items = planet_names,
        selected_index = 1,
        tags = { ship = ship_tag_number }
    }
    custom_gui.add { type = "button", name = "ship-dock", caption = "Dock", tags = { ship = ship_tag_number } }
    custom_gui.add { type = "button", name = "ship-takeoff", caption = "Takeoff", tags = { ship = ship_tag_number } }
    custom_gui.add { type = "button", name = "drop-player-to-planet", caption = "Drop player to Planet", tags = { ship = ship_tag_number } }
    custom_gui.add { type = "button", name = "drop-items-to-planet", caption = "Drop items to Planet", tags = { ship = ship_tag_number } }
    custom_gui.add { type = "button", name = "open-upgrade-bay", caption = "Open Upgrade Bay", tags = { ship = ship_tag_number, hub_unit_number = ship.hub.unit_number } }
end

-- Function to close the spaceship control GUI
function SpaceShipGuis.close_spaceship_gui(event)
    if not event.entity then return end
    if event.entity.name ~= "spaceship-control-hub" then return end
    if not event.player_index then return end
    local ship
    for _, value in pairs(storage.spaceships) do
        if value.hub.unit_number == event.entity.unit_number then
            ship = storage.spaceships[value.id]
        end
    end
    local player = game.get_player(event.player_index)
    if event.entity and event.entity.name == "spaceship-control-hub" then
        -- Destroy the custom GUI when the main GUI for "spaceship-control-hub" is closed.
        local custom_gui = player.gui.relative["spaceship-controller-extended-gui-" .. ship.name]
        if custom_gui then
            custom_gui.destroy()
            game.print("extended GUI closed with the main GUI.")
        end
        local custom_gui = player.gui.relative["spaceship-controller-schedual-gui-" .. ship.name]
        if custom_gui then
            custom_gui.destroy()
            ship.schedule_gui = nil
            game.print("schedual GUI closed with the main GUI.")
        end
    end
end

-- Function to handle button clicks
function SpaceShipGuis.handle_button_click(event)
    local button_name = event.element.name
    local player = game.get_player(event.player_index)
    if button_name == "ship-takeoff" then -- Call the shipTakeoff function
        local ship = storage.spaceships[event.element.tags.ship]
        game.print("Spaceship takeoff initiated!")
        local dropdown = event.element.parent["surface-dropdown"]
        SpaceShip.ship_takeoff(ship, dropdown)
        SpaceShipGuis.gui_maker_handler(ship, event.player_index)
        SpaceShip.auto_manual_changed(ship)
    elseif button_name == "confirm-dock" then
        local ship = storage.spaceships[event.element.tags.ship]
        game.print("Docking confirmed!")
        SpaceShip.finalize_dock(ship)
    elseif button_name == "cancel-dock" then
        local ship = storage.spaceships[event.element.tags.ship]
        game.print("Docking canceled!")
        SpaceShip.cancel_dock(ship)
    elseif button_name == "ship-dock" then
        game.print("Docking the spaceship...")
        local ship = storage.spaceships[event.element.tags.ship]
        SpaceShip.dock_ship(ship)
    elseif button_name == "drop-player-to-planet" then
        game.print("dropping player to planet")
        local ship = storage.spaceships[event.element.tags.ship]
        SpaceShip.drop_player_to_planet(ship)
    elseif button_name == "drop-items-to-planet" then
        game.print("dropping items to planet")
        local ship = storage.spaceships[event.element.tags.ship]
        SpaceShip.drop_items_to_planet(ship)
    elseif button_name == "open-upgrade-bay" then
        game.print("Opening upgrade bay...")
        local hub_unit_number = event.element.tags.hub_unit_number
        if hub_unit_number then
            local UpgradeBay = require("UpgradeBay")
            UpgradeBay.open_gui(player, hub_unit_number)
        else
            player.print("[color=red]Upgrade bay not found![/color]")
        end
    else
        game.print("Unknown button clicked: " .. button_name)
    end
end

function SpaceShipGuis.create_docking_port_gui(player, docking_port)
    local tile = docking_port.surface.get_tile(docking_port.position)
    if tile.name ~= "space-platform-foundation" then
        game.print("Space ship docking ports cannot be modified")
        if player.gui.screen["docking-port-gui"] then
            player.gui.screen["docking-port-gui"].destroy()
        end
        return
    end
    -- Store the selected docking port for reference
    storage.selected_docking_port = docking_port

    -- First close any existing GUI
    if player.gui.screen["docking-port-gui"] then
        player.gui.screen["docking-port-gui"].destroy()
    end

    -- Create new custom GUI in screen instead of relative
    local dock_gui = player.gui.screen.add {
        type = "frame",
        name = "docking-port-gui",
        caption = "Docking Port Settings",
        direction = "vertical"
    }

    -- Center the GUI on screen
    dock_gui.force_auto_center()

    -- Add name label and textbox
    local name_flow = dock_gui.add {
        type = "flow",
        direction = "horizontal"
    }
    name_flow.add {
        type = "label",
        caption = "Name:"
    }
    name_flow.add {
        type = "textfield",
        name = "dock-name-input",
        text = ""
    }

    -- Add ship limit label and textbox
    local limit_flow = dock_gui.add {
        type = "flow",
        direction = "horizontal"
    }
    limit_flow.add {
        type = "label",
        caption = "Ship Limit:"
    }
    limit_flow.add {
        type = "textfield",
        name = "dock-limit-input",
        text = "1",
        numeric = true,
        allow_decimal = false,
        allow_negative = false
    }

    -- Load existing values if they exist
    if storage.docking_ports[docking_port.unit_number] then
        local port_data = storage.docking_ports[docking_port.unit_number]
        name_flow["dock-name-input"].text = port_data.name or ""
        limit_flow["dock-limit-input"].text = tostring(port_data.ship_limit or 1)
    end

    -- Add close button at the bottom
    dock_gui.add {
        type = "button",
        name = "close-dock-gui",
        caption = "Close",
        style = "back_button" -- Using a built-in button style
    }
end

function SpaceShipGuis.handle_text_changed_docking_port(event)
    local text_field = event.element
    local player = game.get_player(event.player_index)
    local docking_port = storage.selected_docking_port

    if not docking_port then return end

    -- Handle dock name changes
    if text_field.name == "dock-name-input" then
        storage.docking_ports[docking_port.unit_number].name = text_field.text

        -- Handle ship limit changes
    elseif text_field.name == "dock-limit-input" then
        local limit = tonumber(text_field.text)
        if limit then
            storage.docking_ports[docking_port.unit_number].ship_limit = limit
        end
    end
end

function SpaceShipGuis.gui_maker_handler(ship, player_id)
    local docks_table = {}
    if not storage.docking_ports then
        storage.docking_ports = {}
    end
    for key, value in pairs(storage.docking_ports) do
        if value.name ~= "ship" then
            if not docks_table[value.surface.platform.space_location.name] then
                docks_table[value.surface.platform.space_location.name] =
                {
                    names = {}
                }
                table.insert(docks_table[value.surface.platform.space_location.name].names, value.name)
            else
                table.insert(docks_table[value.surface.platform.space_location.name].names, value.name)
            end
        end
    end
    local player = game.get_player(player_id)
    local schedule = ship.schedule
    local paused = ship.autom
    local ship_name = ship.name
    local ship_id = ship.id

    -- Ensure port_records exists, initialize if nil
    if not ship.port_records then
        ship.port_records = {}
    end
    local stations_docks = ship.port_records

    local gui_anchor = {
        gui = defines.relative_gui_type.container_gui,
        position = defines.relative_gui_position
            .right
    }

    -- Only set platform schedule if it's properly structured
    if ship.own_surface and schedule and type(schedule) == "table" then
        -- Check if schedule has the required structure
        local valid_schedule = false
        if schedule.records and type(schedule.records) == "table" and #schedule.records > 0 then
            -- Check if at least one record has the required fields
            for _, record in pairs(schedule.records) do
                if record.station and type(record.station) == "string" and record.station ~= "" then
                    valid_schedule = true
                    break
                end
            end
        end

        if valid_schedule then
            ship.surface.platform.schedule = schedule
        end
    end

    gui_maker.make_gui(
        player,
        schedule,
        paused,
        ship_name,
        ship_id,
        docks_table,
        stations_docks,
        { mod = "pig-ex", },
        gui_anchor
    )
end

-- Create mode toggle GUI for space platform hub
function SpaceShipGuis.create_hub_mode_gui(player, hub_entity)
    if not player or not player.valid then return end
    if not hub_entity or not hub_entity.valid then return end
    
    local surface = hub_entity.surface
    if not surface or not surface.platform then return end
    
    local platform = surface.platform
    local Stations = require("Stations")
    
    -- Check platform type
    local platform_type = platform.tags and platform.tags.ship_type or "unknown"
    if platform_type == "unknown" then
        return -- Only show for tagged platforms
    end
    
    -- Close existing GUI if present
    if player.gui.relative["hub-mode-toggle-gui"] then
        player.gui.relative["hub-mode-toggle-gui"].destroy()
    end
    
    -- Create GUI
    local gui_anchor = {
        gui = defines.relative_gui_type.space_platform_hub_gui,
        position = defines.relative_gui_position.right,
        name = hub_entity.name
    }
    
    local main_frame = player.gui.relative.add({
        type = "frame",
        name = "hub-mode-toggle-gui",
        anchor = gui_anchor,
        direction = "vertical",
        caption = "Platform Mode"
    })
    
    local is_station_mode = Stations.is_station_mode(platform)
    local mode_text = is_station_mode and "Station Mode (Paused)" or "Ship Mode (Mobile)"
    local button_text = is_station_mode and "Switch to Ship Mode" or "Switch to Station Mode"
    
    main_frame.add({
        type = "label",
        caption = "Current: " .. mode_text
    })
    
    main_frame.add({
        type = "button",
        name = "toggle-hub-mode-button",
        caption = button_text,
        tags = {hub_unit_number = hub_entity.unit_number}
    })
end

-- Handle mode toggle button click
function SpaceShipGuis.handle_hub_mode_toggle(event)
    local button = event.element
    if not button or button.name ~= "toggle-hub-mode-button" then return end
    
    local hub_unit = button.tags and button.tags.hub_unit_number
    if not hub_unit then return end
    
    local player = game.get_player(event.player_index)
    if not player then return end
    
    -- Find the hub entity by searching through all spaceships
    local hub = nil
    for _, ship in pairs(storage.spaceships or {}) do
        if ship.hub and ship.hub.valid and ship.hub.unit_number == hub_unit then
            hub = ship.hub
            break
        end
    end
    
    -- If not found in spaceships, search all space-platform-hub entities across all platforms
    if not hub then
        for _, force_platform in pairs(player.force.platforms) do
            local hubs = force_platform.surface.find_entities_filtered({name = "space-platform-hub"})
            for _, found_hub in ipairs(hubs) do
                if found_hub.unit_number == hub_unit then
                    hub = found_hub
                    break
                end
            end
            if hub then break end
        end
    end
    
    if not hub or not hub.valid then return end
    if not hub.surface.platform then return end
    
    local platform = hub.surface.platform
    local Stations = require("Stations")
    
    -- Toggle mode
    local current_mode = Stations.is_station_mode(platform)
    Stations.set_station_mode(platform, not current_mode)
    
    -- Refresh GUI
    SpaceShipGuis.create_hub_mode_gui(player, hub)
end

-- Create transfer request GUI for cargo landing pad
function SpaceShipGuis.create_transfer_request_gui(player, landing_pad_entity)
    if not player or not player.valid then return end
    if not landing_pad_entity or not landing_pad_entity.valid then return end
    
    local surface = landing_pad_entity.surface
    if not surface or not surface.platform then return end
    
    local platform = surface.platform
    local TransferRequest = require("TransferRequest")
    
    -- Check if platform is in orbit
    local orbit = TransferRequest.get_platform_orbit(platform)
    
    -- Close existing GUI if present
    if player.gui.screen["transfer-request-gui"] then
        player.gui.screen["transfer-request-gui"].destroy()
    end
    
    -- Create main frame
    local main_frame = player.gui.screen.add({
        type = "frame",
        name = "transfer-request-gui",
        direction = "vertical",
        caption = "Platform Transfer Requests"
    })
    main_frame.auto_center = true
    
    -- Add orbit status
    local status_flow = main_frame.add({
        type = "flow",
        direction = "horizontal"
    })
    status_flow.add({
        type = "label",
        caption = "Orbit Status: "
    })
    status_flow.add({
        type = "label",
        caption = orbit or "Traveling (no transfers available)",
        style = orbit and "heading_3_label" or "invalid_label"
    })
    
    -- Add requests list
    local requests = TransferRequest.get_requests(platform)
    
    local list_frame = main_frame.add({
        type = "frame",
        style = "inside_shallow_frame",
        direction = "vertical"
    })
    
    local list_header = list_frame.add({
        type = "flow",
        direction = "horizontal"
    })
    list_header.add({type = "label", caption = "Item", style = "bold_label"})
    list_header.add({type = "label", caption = " - Min: ", style = "bold_label"})
    list_header.add({type = "label", caption = " - Requested: ", style = "bold_label"})
    
    for item_name, request in pairs(requests) do
        local item_flow = list_frame.add({
            type = "flow",
            direction = "horizontal"
        })
        
        item_flow.add({
            type = "sprite-button",
            sprite = "item/" .. item_name,
            tooltip = item_name
        })
        
        item_flow.add({
            type = "label",
            caption = item_name
        })
        
        item_flow.add({
            type = "label",
            caption = " (Min: " .. request.minimum_quantity .. ", Req: " .. request.requested_quantity .. ")"
        })
        
        item_flow.add({
            type = "button",
            name = "remove-transfer-request",
            caption = "Remove",
            tags = {platform_index = platform.index, item_name = item_name}
        })
    end
    
    -- Add new request section
    main_frame.add({
        type = "label",
        caption = "Add New Request",
        style = "heading_2_label"
    })
    
    local input_table = main_frame.add({
        type = "table",
        column_count = 2
    })
    
    input_table.add({type = "label", caption = "Item:"})
    input_table.add({
        type = "choose-elem-button",
        name = "transfer-request-item-chooser",
        elem_type = "item"
    })
    
    input_table.add({type = "label", caption = "Minimum Quantity:"})
    input_table.add({
        type = "textfield",
        name = "transfer-request-min-quantity",
        text = "100",
        numeric = true
    })
    
    input_table.add({type = "label", caption = "Requested Quantity:"})
    input_table.add({
        type = "textfield",
        name = "transfer-request-requested-quantity",
        text = "1000",
        numeric = true
    })
    
    -- Add buttons
    local button_flow = main_frame.add({
        type = "flow",
        direction = "horizontal"
    })
    
    button_flow.add({
        type = "button",
        name = "add-transfer-request-button",
        caption = "Add Request",
        tags = {platform_index = platform.index}
    })
    
    button_flow.add({
        type = "button",
        name = "close-transfer-request-gui",
        caption = "Close"
    })
end

-- Handle transfer request GUI buttons
function SpaceShipGuis.handle_transfer_request_buttons(event)
    local button = event.element
    if not button then return end
    
    local player = game.get_player(event.player_index)
    if not player then return end
    
    local TransferRequest = require("TransferRequest")
    
    if button.name == "add-transfer-request-button" then
        local gui = player.gui.screen["transfer-request-gui"]
        if not gui then return end
        
        local platform_index = button.tags and button.tags.platform_index
        if not platform_index then return end
        
        -- Find platform
        local platform = nil
        for _, force in pairs(game.forces) do
            for _, p in pairs(force.platforms) do
                if p.valid and p.index == platform_index then
                    platform = p
                    break
                end
            end
            if platform then break end
        end
        
        if not platform then return end
        
        -- Helper function to find GUI element by name recursively
        local function find_element(parent, target_name)
            if parent.name == target_name then
                return parent
            end
            if parent.children then
                for _, child in pairs(parent.children) do
                    local found = find_element(child, target_name)
                    if found then return found end
                end
            end
            return nil
        end
        
        -- Get input values
        local item_chooser = find_element(gui, "transfer-request-item-chooser")
        local min_field = find_element(gui, "transfer-request-min-quantity")
        local req_field = find_element(gui, "transfer-request-requested-quantity")
        
        if not item_chooser or not item_chooser.elem_value then
            player.print("[color=red]Please select an item[/color]")
            return
        end
        
        if not min_field or not req_field then
            player.print("[color=red]Error: Invalid GUI state[/color]")
            return
        end
        
        local item_name = item_chooser.elem_value
        local min_quantity = tonumber(min_field.text) or 1
        local requested_quantity = tonumber(req_field.text) or min_quantity
        
        if min_quantity <= 0 or requested_quantity < min_quantity then
            player.print("[color=red]Invalid quantities. Requested must be >= minimum[/color]")
            return
        end
        
        -- Register request
        if TransferRequest.register_request(platform, item_name, min_quantity, requested_quantity) then
            player.print({"message.transfer-request-registered", item_name, min_quantity, requested_quantity})
            -- Refresh GUI
            local landing_pad = platform.surface.find_entities_filtered({name = "cargo-landing-pad", limit = 1})[1]
            if landing_pad then
                SpaceShipGuis.create_transfer_request_gui(player, landing_pad)
            end
        end
        
    elseif button.name == "remove-transfer-request" then
        local platform_index = button.tags and button.tags.platform_index
        local item_name = button.tags and button.tags.item_name
        
        if not platform_index or not item_name then return end
        
        -- Find platform
        local platform = nil
        for _, force in pairs(game.forces) do
            for _, p in pairs(force.platforms) do
                if p.valid and p.index == platform_index then
                    platform = p
                    break
                end
            end
            if platform then break end
        end
        
        if not platform then return end
        
        if TransferRequest.remove_request(platform, item_name) then
            player.print({"message.transfer-request-removed", item_name})
            -- Refresh GUI
            local landing_pad = platform.surface.find_entities_filtered({name = "cargo-landing-pad", limit = 1})[1]
            if landing_pad then
                SpaceShipGuis.create_transfer_request_gui(player, landing_pad)
            end
        end
        
    elseif button.name == "close-transfer-request-gui" then
        if player.gui.screen["transfer-request-gui"] then
            player.gui.screen["transfer-request-gui"].destroy()
        end
    end
end

-- =============================================================================
-- CIRCUIT REQUEST CONTROLLER GUI
-- =============================================================================

-- Create GUI for circuit request controller
function SpaceShipGuis.create_circuit_controller_gui(player, controller_entity)
    if not player or not player.valid then return end
    if not controller_entity or not controller_entity.valid then return end
    
    local surface = controller_entity.surface
    if not surface or not surface.platform then return end
    
    local platform = surface.platform
    local CircuitRequestController = require("CircuitRequestController")
    
    -- Close existing GUI if present
    if player.gui.screen["circuit-controller-gui"] then
        player.gui.screen["circuit-controller-gui"].destroy()
    end
    
    -- Get controller data
    local controller_data = CircuitRequestController.get_controller(controller_entity.unit_number)
    
    -- Create main frame
    local main_frame = player.gui.screen.add({
        type = "frame",
        name = "circuit-controller-gui",
        direction = "vertical",
        caption = "Circuit Request Controller"
    })
    main_frame.auto_center = true
    
    -- Add info section
    local info_flow = main_frame.add({
        type = "flow",
        direction = "vertical"
    })
    
    info_flow.add({
        type = "label",
        caption = "Configure this controller to manage logistics requests via circuit signals.",
        style = "heading_3_label"
    })
    
    info_flow.add({
        type = "label",
        caption = "Connect red or green wires to send item signals. Signal value = requested quantity."
    })
    
    -- Add current status
    if controller_data then
        local status_flow = main_frame.add({
            type = "flow",
            direction = "vertical"
        })
        
        status_flow.add({
            type = "label",
            caption = "Status: Active",
            style = "heading_2_label"
        })
        
        local group = CircuitRequestController.get_group(controller_data.group_id)
        if group then
            status_flow.add({
                type = "label",
                caption = "Logistics Group: " .. group.name
            })
            
            status_flow.add({
                type = "label",
                caption = "Target Planet: " .. (controller_data.target_planet or "none")
            })
            
            -- Show current requests
            if group.requests and next(group.requests) then
                status_flow.add({
                    type = "label",
                    caption = "Active Requests:",
                    style = "bold_label"
                })
                
                for item_name, request in pairs(group.requests) do
                    local req_flow = status_flow.add({
                        type = "flow",
                        direction = "horizontal"
                    })
                    
                    req_flow.add({
                        type = "sprite-button",
                        sprite = "item/" .. item_name,
                        tooltip = item_name
                    })
                    
                    req_flow.add({
                        type = "label",
                        caption = item_name .. ": " .. request.requested_quantity
                    })
                end
            else
                status_flow.add({
                    type = "label",
                    caption = "No active requests (connect circuit signals)",
                    style = "invalid_label"
                })
            end
        end
        
        -- Add unregister button
        main_frame.add({
            type = "button",
            name = "unregister-circuit-controller",
            caption = "Unregister Controller",
            tags = {controller_unit_number = controller_entity.unit_number}
        })
    else
        -- Not configured yet, show configuration UI
        local config_frame = main_frame.add({
            type = "frame",
            style = "inside_shallow_frame",
            direction = "vertical"
        })
        
        config_frame.add({
            type = "label",
            caption = "Configuration",
            style = "heading_2_label"
        })
        
        -- Get available groups
        local groups = CircuitRequestController.get_platform_groups(platform)
        
        -- Group selection
        local group_table = config_frame.add({
            type = "table",
            column_count = 2
        })
        
        group_table.add({type = "label", caption = "Logistics Group:"})
        
        local group_dropdown_items = {"[Create New Group]"}
        local group_id_map = {"_new_"}
        
        for _, group in ipairs(groups) do
            if not group.locked then
                table.insert(group_dropdown_items, group.name)
                table.insert(group_id_map, group.id)
            end
        end
        
        local group_dropdown = group_table.add({
            type = "drop-down",
            name = "circuit-controller-group-dropdown",
            items = group_dropdown_items,
            selected_index = 1
        })
        
        -- Store the group ID map in the GUI
        storage.circuit_controller_group_map = storage.circuit_controller_group_map or {}
        storage.circuit_controller_group_map[player.index] = group_id_map
        
        -- New group name (shown when creating new)
        group_table.add({type = "label", caption = "New Group Name:"})
        group_table.add({
            type = "textfield",
            name = "circuit-controller-new-group-name",
            text = "Logistics Group"
        })
        
        -- Planet selection
        group_table.add({type = "label", caption = "Target Planet:"})
        
        -- Get list of planets
        local planet_items = {}
        for name, surface in pairs(game.surfaces) do
            if surface.planet then
                table.insert(planet_items, surface.planet.name)
            end
        end
        
        if #planet_items == 0 then
            planet_items = {"nauvis", "vulcanus", "gleba", "fulgora", "aquilo"}
        end
        
        group_table.add({
            type = "drop-down",
            name = "circuit-controller-planet-dropdown",
            items = planet_items,
            selected_index = 1
        })
        
        -- Register button
        main_frame.add({
            type = "button",
            name = "register-circuit-controller",
            caption = "Register Controller",
            tags = {
                controller_unit_number = controller_entity.unit_number,
                platform_index = platform.index
            }
        })
    end
    
    -- Close button
    main_frame.add({
        type = "button",
        name = "close-circuit-controller-gui",
        caption = "Close"
    })
end

-- Handle circuit controller GUI buttons
function SpaceShipGuis.handle_circuit_controller_buttons(event)
    local button = event.element
    if not button then return end
    
    local player = game.get_player(event.player_index)
    if not player then return end
    
    local CircuitRequestController = require("CircuitRequestController")
    
    if button.name == "register-circuit-controller" then
        local gui = player.gui.screen["circuit-controller-gui"]
        if not gui then return end
        
        local controller_unit_number = button.tags and button.tags.controller_unit_number
        local platform_index = button.tags and button.tags.platform_index
        
        if not controller_unit_number or not platform_index then return end
        
        -- Find controller entity
        local controller_entity = nil
        for _, surface in pairs(game.surfaces) do
            for _, entity in pairs(surface.find_entities_filtered({name = "circuit-request-controller"})) do
                if entity.valid and entity.unit_number == controller_unit_number then
                    controller_entity = entity
                    break
                end
            end
            if controller_entity then break end
        end
        
        if not controller_entity then
            player.print("[color=red]Controller entity not found[/color]")
            return
        end
        
        -- Find platform
        local platform = nil
        for _, force in pairs(game.forces) do
            for _, p in pairs(force.platforms) do
                if p.valid and p.index == platform_index then
                    platform = p
                    break
                end
            end
            if platform then break end
        end
        
        if not platform then
            player.print("[color=red]Platform not found[/color]")
            return
        end
        
        -- Helper function to find GUI element by name recursively
        local function find_element(parent, target_name)
            if parent.name == target_name then
                return parent
            end
            if parent.children then
                for _, child in pairs(parent.children) do
                    local found = find_element(child, target_name)
                    if found then return found end
                end
            end
            return nil
        end
        
        -- Get input values
        local group_dropdown = find_element(gui, "circuit-controller-group-dropdown")
        local new_group_name_field = find_element(gui, "circuit-controller-new-group-name")
        local planet_dropdown = find_element(gui, "circuit-controller-planet-dropdown")
        
        if not group_dropdown or not planet_dropdown then
            player.print("[color=red]Error: Invalid GUI state[/color]")
            return
        end
        
        local selected_index = group_dropdown.selected_index
        local group_id_map = storage.circuit_controller_group_map and storage.circuit_controller_group_map[player.index]
        
        if not group_id_map then
            player.print("[color=red]Error: Group map not found[/color]")
            return
        end
        
        local group_id = group_id_map[selected_index]
        
        -- Create new group if needed
        if group_id == "_new_" then
            local new_group_name = new_group_name_field and new_group_name_field.text or "Logistics Group"
            group_id = CircuitRequestController.create_logistics_group(platform, new_group_name)
            
            if not group_id then
                player.print("[color=red]Failed to create logistics group[/color]")
                return
            end
        end
        
        -- Get target planet
        local target_planet = planet_dropdown.items[planet_dropdown.selected_index]
        
        -- Register controller
        local success, message = CircuitRequestController.register_controller(
            controller_entity,
            group_id,
            target_planet
        )
        
        if success then
            player.print({"message.circuit-controller-registered"})
            SpaceShipGuis.create_circuit_controller_gui(player, controller_entity)
        else
            player.print("[color=red]" .. message .. "[/color]")
        end
        
    elseif button.name == "unregister-circuit-controller" then
        local controller_unit_number = button.tags and button.tags.controller_unit_number
        
        if not controller_unit_number then return end
        
        if CircuitRequestController.unregister_controller(controller_unit_number) then
            player.print({"message.circuit-controller-unregistered"})
            
            -- Find controller entity to refresh GUI
            local controller_entity = nil
            for _, surface in pairs(game.surfaces) do
                for _, entity in pairs(surface.find_entities_filtered({name = "circuit-request-controller"})) do
                    if entity.valid and entity.unit_number == controller_unit_number then
                        controller_entity = entity
                        break
                    end
                end
                if controller_entity then break end
            end
            
            if controller_entity then
                SpaceShipGuis.create_circuit_controller_gui(player, controller_entity)
            else
                if player.gui.screen["circuit-controller-gui"] then
                    player.gui.screen["circuit-controller-gui"].destroy()
                end
            end
        end
        
    elseif button.name == "close-circuit-controller-gui" then
        if player.gui.screen["circuit-controller-gui"] then
            player.gui.screen["circuit-controller-gui"].destroy()
        end
    end
end

return SpaceShipGuis
