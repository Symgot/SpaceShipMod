local SpaceShipFunctions = require("SpaceShipFunctionsScript")
local SpaceShip = require("spacShip")
local SpaceShipGuis = {}

-- Function to create the custom spaceship control GUI
function SpaceShipGuis.create_spaceship_gui(player,ship)
    local relative_gui = player.gui.relative

    if relative_gui["spaceship-controller-extended-gui-"..ship.name] then
        return
    end
    if relative_gui["spaceship-controller-schedual-gui-"..ship.name] then
        return
    end

    -- Initialize storage if needed
    storage = storage or {}
    storage.spaceships = storage.spaceships or {}

    local custom_gui = relative_gui.add {
        type = "frame",
        name = "spaceship-controller-extended-gui-"..ship.name,
        caption = "Spaceship Actions",
        direction = "vertical",
        anchor = {
            gui = defines.relative_gui_type.container_gui,
            position = defines.relative_gui_position.left
        }
    }
    local schedual_gui = relative_gui.add {
        type = "frame",
        name = "spaceship-controller-schedual-gui-"..ship.name,
        caption = { "gui-train.schedule" },
        anchor = {
            gui = defines.relative_gui_type.container_gui,
            position = defines.relative_gui_position.right
        }
    }
    ship.schedule_gui = schedual_gui
    --main panel
    flow = schedual_gui.add { type = "flow", name = "vertical-flow", direction = "vertical" }
    --switch panel
    selector = flow.add { type = "flow", name = "switch-flow", direction = "horizontal" }
    selectorlabel = selector.add { type = "label", caption = "Automatic", name = "auto" }
    local switch = selector.add { 
        type = "switch",
        name = "auto-manual-switch",
        allow_none_state = false,
        switch_state = "left"  -- Default to automatic
    }
    selectorlabel = selector.add { type = "label", caption = "Paused", name = "paused" }

    -- Set switch state from storage if it exists
    if ship.automatic ~= nil then
        switch.switch_state = ship.automatic and "left" or "right"
    else
        ship.automatic = false
        switch.switch_state = ship.automatic and "left" or "right"
    end

    --schedual panel
    schedualflow = flow.add { type = "flow", name = "flow" }
    schedualscroll = schedualflow.add { type = "scroll-pane", style = "train_schedule_scroll_pane", vertical_scroll_policy = "always",name = "station-scroll-panel" }
    schedbutton = schedualscroll.add { type = "button", style = "train_schedule_add_station_button", name = "add-station", caption = { "gui-train.add-station" } }
    --test station

    if ship.schedule and ship.schedule.records then
        for _, value in pairs(ship.schedule.records) do
            SpaceShipGuis.add_station(schedualscroll)
        end
        -- Initialize all progress bars after creating stations
        SpaceShipGuis.initialize_progress_bars(ship)
    end

    -- Add a dropdown with only planet surfaces
    local planet_names = {}
    for _, surface in pairs(game.surfaces) do
        if not string.find(surface.name, "platform") then
            table.insert(planet_names, surface.name)
        end
    end

    custom_gui.add {
        type = "drop-down",
        name = "surface-dropdown",
        items = planet_names,
        selected_index = 1 -- Default to the first planet
    }

    custom_gui.add { type = "button", name = "scan-ship", caption = "Scan Ship" }
    custom_gui.add { type = "button", name = "ship-platform", caption = "Travel Mode" }
    custom_gui.add { type = "button", name = "ship-dock", caption = "Dock" }
    custom_gui.add { type = "button", name = "ship-takeoff", caption = "Takeoff" }
    custom_gui.add { type = "button", name = "close-spaceship-extended-gui", caption = "Close" }
end

function SpaceShipGuis.create_condition_gui(parent)
    -- Remove any existing GUI
    parent = parent.parent
    if parent["spaceship-condition-gui"] then
        parent["spaceship-condition-gui"].destroy()
    end

    -- Create main frame
    local frame = parent.add {
        type = "frame",
        name = "spaceship-condition-gui",
        direction = "vertical",
    }

    -- Create horizontal flow to hold logic buttons and conditions
    local main_container = frame.add {
        type = "flow",
        name = "main_container",
        direction = "horizontal"
    }

    -- Add flow for logic buttons on the left
    local logic_flow = main_container.add {
        type = "flow",
        name = "logic_flow",
        direction = "vertical"
    }
    logic_flow.style.vertical_align = "center"
    logic_flow.style.minimal_width = 50

    -- Add flow for conditions on the right
    local condition_flow = main_container.add {
        type = "flow",
        name = "condition_flow",
        direction = "vertical"
    }
    condition_flow.style.horizontal_align = "right"
    condition_flow.style.horizontally_stretchable = true

    -- Add the "Add wait condition" button at the bottom
    frame.add {
        type = "button",
        name = "add-wait-condition",
        caption = "+ Add wait condition",
        style = "train_schedule_add_wait_condition_button"
    }
    station_number = tonumber(parent.name:match("%d+"))
    local ship = storage.spaceships[tonumber(frame.parent.parent.parent.parent.parent.name:match("(%d+)$"))]
    -- Check if we have stored conditions to apply
    if ship.schedule then
        local schedule = ship.schedule
        if schedule.records and schedule.records[station_number].wait_conditions then
            -- First create all the condition rows
            for i, condition in pairs(schedule.records[station_number].wait_conditions) do
                -- Create a new condition row by simulating a button click
                local fake_event = {
                    element = frame["add-wait-condition"],
                    player_index = game.get_player(1).index -- Use first player as dummy
                }
                SpaceShipGuis.add_condition_row(fake_event)
            end

            -- Then set their values
            for i, condition in pairs(schedule.records[station_number].wait_conditions) do
                -- Set the AND/OR button state if it exists
                local logic_button = logic_flow["logic-operator-button_" .. i]
                if logic_button and condition.compare_type then
                    logic_button.caption = string.upper(condition.compare_type)
                end

                -- Set the signal chooser with the stored signal
                local signal_chooser = condition_flow["condition_row_" .. i]["input-flow"]["condition_type_chooser"]
                if signal_chooser and condition.condition.first_signal then
                    signal_chooser.elem_value = {
                        type = condition.condition.first_signal.type,
                        name = condition.condition.first_signal.name
                    }
                end

                -- Set the comparison dropdown
                local comparison = condition_flow["condition_row_" .. i]["input-flow"]["comparison_dropdown_"..i]
                if comparison and condition.condition.comparator then
                    local comparator_map = {
                        ["<"] = 1,
                        ["<="] = 2,
                        ["="] = 3,
                        [">="] = 4,
                        [">"] = 5
                    }
                    comparison.selected_index = comparator_map[condition.condition.comparator] or 3
                end

                -- Set the value field
                local value_field = condition_flow["condition_row_" .. i]["input-flow"]["condition_value_"..i]
                if value_field and condition.condition.constant then
                    value_field.text = tostring(condition.condition.constant)
                end
            end
        end
    end

    return frame
end

function SpaceShipGuis.add_condition_row(event)
    local frame = event.element.parent
    if not frame then return end

    local main_container = frame["main_container"]
    local logic_flow = main_container["logic_flow"]
    local condition_flow = main_container["condition_flow"]
    local num_conditions = #condition_flow.children

    -- If there are existing conditions, add an AND/OR button
    if num_conditions > 0 then
        -- If this is the first AND/OR button, add an empty widget for spacing
        if num_conditions == 1 and not logic_flow["logic_button_spacer"] then
            local spacer = logic_flow.add {
                type = "empty-widget",
                name = "logic_button_spacer",
            }
            spacer.style.minimal_height = 12 -- Adjust this value to control initial spacing
            spacer.style.natural_height = 12
        end
        local button_flow
        -- Create a centering flow for the AND/OR button on the left
        if not logic_flow["logic_button_flow_" .. num_conditions] then
            button_flow = logic_flow.add {
                type = "flow",
                direction = "vertical",
                name = "logic_button_flow_" .. num_conditions
            }
        end

        -- Adjust the vertical positioning
        button_flow.style.vertical_align = "center"
        button_flow.style.top_padding = 10    -- Add top padding to center between conditions
        button_flow.style.minimal_height = 30

        -- Add the AND/OR button
        local logic_button = button_flow.add {
            type = "button",
            name = "logic-operator-button_" .. num_conditions,
            caption = "AND",
            style = "train_schedule_comparison_type_button"
        }
        logic_button.style.minimal_height = 30
    end

    -- Create condition frame with progress bar
    local condition_frame = condition_flow.add {
        type = "frame",
        name = "condition_row_" .. num_conditions + 1,
        style = "train_schedule_station_frame"
    }
    condition_frame.style.horizontally_stretchable = true

    local progress = condition_frame.add {
        type = "progressbar",
        name = "condition_progress",
        value = 0,
        embed_text_in_bar = true,
        caption = "number"
    }
    progress.style.horizontally_stretchable = true
    progress.style.bar_width = 32
    progress.style.height = 32
    progress.style.color = { r = 0, g = 1, b = 0, a = 0.4 }
    progress.style.font_color = { r = 0, g = 0, b = 0 }
    progress.style.font = "default-bold"
    progress.style.horizontal_align = "center"
    progress.style.vertical_align = "center"

    local row = condition_frame.add {
        type = "flow",
        direction = "horizontal",
        name = "input-flow"
    }
    row.style.horizontal_align = "center"
    row.style.vertical_align = "center"

    row.add {
        type = "choose-elem-button",
        name = "condition_type_chooser",
        elem_type = "signal",
        style = "train_schedule_item_select_button"
    }

    row.add {
        type = "drop-down",
        name = "comparison_dropdown_" .. num_conditions + 1,
        items = { "<", "<=", "=", ">=", ">" },
        selected_index = 3,
        style = "train_schedule_circuit_condition_comparator_dropdown"
    }

    local value_field = row.add {
        type = "textfield",
        name = "condition_value_" .. num_conditions + 1,
        text = "0",
        numeric = true,
        allow_negative = true,
        style = "console_input_textfield"
    }
    value_field.style.minimal_width = 50
    value_field.style.maximal_width = 100

    row.add {
        type = "sprite-button",
        name = "delete_condition_button_" .. num_conditions + 1,
        sprite = "virtual-signal/signal-X",
        style = "train_schedule_delete_button"
    }

    -- Initialize the progress bar for the new condition
    SpaceShipGuis.check_condition_row(condition_frame)
end

-- Add this after setting up the condition row GUI elements
function SpaceShipGuis.check_condition_row(condition_frame)
    -- Get condition number from the frame name
    local condition_number = tonumber(condition_frame.name:match("%d+"))
    local ship = storage.spaceships[tonumber(condition_frame.parent.parent.parent.parent.parent.parent.parent.parent.name:match("(%d+)$"))]
    if not condition_number then return false end

    -- Get the signal button, comparison, and value elements
    local input_flow = condition_frame["input-flow"]
    if not input_flow then return false end

    local signal_button = input_flow["condition_type_chooser"]
    local comparison = input_flow["comparison_dropdown_" .. condition_number]
    local value_field = input_flow["condition_value_" .. condition_number]
    
    if not (signal_button and signal_button.elem_value and comparison and value_field) then 
        return false 
    end

    -- Get the signal name and target value
    local signal_name = signal_button.elem_value.name
    local comparison_type = comparison.items[comparison.selected_index]
    local target_value = tonumber(value_field.text) or 0

    -- Read the circuit signals and check the condition
    local signals = SpaceShip.read_circuit_signals(ship.hub)
    local current_value = signals[signal_name] or 0
    local parent_parent = condition_frame.parent.parent.parent.parent.name

    -- Update the progress bar
    local progress_bar = condition_frame["condition_progress"]
    if progress_bar then
        progress_bar.value = current_value / (target_value ~= 0 and target_value or 1)
        progress_bar.caption = tostring(current_value)
    end

    -- Return true if condition is met
    return SpaceShip.check_circuit_condition(
        ship.hub,
        signal_name,
        comparison_type,
        target_value
    )
end

function SpaceShipGuis.save_wait_conditions(condition_frame)
    -- Get station number from parent frame
    local station_number = tonumber(condition_frame.parent.name:match("(%d+)$"))
    local ship = storage.spaceships[tonumber(condition_frame.parent.parent.parent.parent.parent.name:match("(%d+)$"))]
    if not station_number then return end

    -- Initialize wait_conditions array if it doesn't exist
    if not ship.schedule.records[station_number].wait_conditions then
        ship.schedule.records[station_number].wait_conditions = {}
    end

    local wait_conditions = {}
    local condition_flow = condition_frame["main_container"]["condition_flow"]
    local logic_flow = condition_frame["main_container"]["logic_flow"]

    -- Iterate through all condition rows
    for i, child in pairs(condition_flow.children) do
        if child.name:match("^condition_row_%d+$") then
            local input_flow = child["input-flow"]
            if input_flow then
                local condition = {
                    type = "circuit",
                    compare_type = "and", -- Default to AND
                    condition = {
                        first_signal = nil,
                        comparator = "=",
                        constant = 0
                    }
                }

                -- Get AND/OR type from logic button if it exists
                local logic_button = logic_flow["logic_button_flow_" .. i] and 
                                   logic_flow["logic_button_flow_" .. i]["logic-operator-button_" .. i]
                if logic_button then
                    condition.compare_type = string.lower(logic_button.caption)
                end

                -- Get signal from chooser
                local signal_chooser = input_flow["condition_type_chooser"]
                if signal_chooser and signal_chooser.elem_value then
                    condition.condition.first_signal = {
                        type = signal_chooser.elem_value.type,
                        name = signal_chooser.elem_value.name
                    }
                end

                -- Get comparator from dropdown
                local comparison = input_flow["comparison_dropdown_" .. i]
                if comparison then
                    condition.condition.comparator = comparison.items[comparison.selected_index]
                end

                -- Get constant value from textfield
                local value_field = input_flow["condition_value_" .. i]
                if value_field then
                    condition.condition.constant = tonumber(value_field.text) or 0
                end

                table.insert(wait_conditions, condition)
            end
        end
    end

    -- Store the conditions
    ship.schedule.records[station_number].wait_conditions = wait_conditions
end

function SpaceShipGuis.add_station(parent)
    ship = storage.spaceships[tonumber(parent.parent.parent.parent.name:match("(%d+)$"))]
    local stop1holder
    for key, value in pairs(ship.schedule.records) do
        local found = false
        for _, value in pairs(parent.children_names) do
            if value == "station" .. key then
                found = true
            end
        end
        if not found then
            stop1holder = parent.add { type = "flow", direction = "vertical", name = "station" .. key }
            local stop1 = stop1holder.add { type = "frame", style = "train_schedule_station_frame" }
            SpaceShipGuis.create_condition_gui(stop1)
            stop1.style.natural_width = 400
            stop1.style.natural_height = 50
            stop1.style.horizontally_stretchable = true
            local sprite_button = stop1.add {
                type = "sprite-button",
                name = "planet-select-button",
                sprite = "space-location/nauvis", 
                tooltip = "Planet destination",
                style = "train_schedule_action_button"
            }

            -- Get list of planet surfaces
            local planet_names = {}
            for _, surface in pairs(game.surfaces) do
                if not string.find(surface.name, "platform") then
                    table.insert(planet_names, surface.name)
                end
            end

            -- Create the dropdown with stored selection
            local planet_dropdown = stop1.add {
                type = "drop-down",
                name = "station-planet-dropdown_" .. key,
                items = planet_names,
                selected_index = 1
            }
            planet_dropdown.style.horizontally_stretchable = true

            -- Set the stored planet if it exists
            if ship.schedule.records[key] and ship.schedule.records[key].station then
                -- Find the index of the stored planet
                for i, name in ipairs(planet_names) do
                    if name == ship.schedule.records[key].station then
                        planet_dropdown.selected_index = i
                        -- Also update the sprite
                        if helpers.is_valid_sprite_path("space-location/" .. name) then
                            sprite_button.sprite = "space-location/" .. name
                        end
                        break
                    end
                end
            end

            local movebuttonsflow = stop1.add { type = "flow", direction = "vertical" }
            local moveup = movebuttonsflow.add {
                type = "sprite-button",
                name = "moveup",
                sprite = "virtual-signal/signal-greater-than",
                tooltip = "This is a sprite button",
                style = "train_schedule_action_button"
            }
            moveup.style.size = { 20, 12 }
            local movedown = movebuttonsflow.add {
                type = "sprite-button",
                name = "movedown",
                sprite = "virtual-signal/signal-less-than",
                tooltip = "This is a sprite button",
                style = "train_schedule_action_button"
            }
            movedown.style.size = { 20, 12 }
            local sprite_button = stop1.add {
                type = "sprite-button",
                name = "delete-station",
                sprite = "virtual-signal/signal-X",
                tooltip = "This is a sprite button",
                style = "train_schedule_delete_button"
            }
        end
    end
end

function SpaceShipGuis.delete_station(event)
    if not event then
        return
    end
    local station_number = tonumber(string.match(event.element.parent.parent.name, "%d+"))
    local ship_id = tonumber(string.match(event.element.parent.parent.parent.parent.parent.parent.name, "%d+"))
    storage.spaceships[ship_id].schedule.records[station_number] = nil
    event.element.parent.parent.destroy()
end

-- Function to close the spaceship control GUI
function SpaceShipGuis.close_spaceship_gui(event)
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
        local custom_gui = player.gui.relative["spaceship-controller-extended-gui-"..ship.name]
        if custom_gui then
            custom_gui.destroy()
            player.print("extended GUI closed with the main GUI.")
        end
        local custom_gui = player.gui.relative["spaceship-controller-schedual-gui-"..ship.name]
        if custom_gui then
            custom_gui.destroy()
            ship.schedule_gui = nil
            player.print("schedual GUI closed with the main GUI.")
        end
    end
end

-- Function to handle button clicks
function SpaceShipGuis.handle_button_click(event)
    local button_name = event.element.name
    local player = game.get_player(event.player_index)
    if button_name == "scan-ship" then -- Call the scan_ship function
        player.print("Scanning the ship...")
        local ship = storage.spaceships[tonumber(event.element.parent.name:match("(%d+)$"))]
        SpaceShip.start_scan_ship(ship)
    elseif button_name == "ship-takeoff" then -- Call the shipTakeoff function
        if storage.spaceships[storage.opened_entity_id].scanned then
            player.print("Spaceship takeoff initiated!")
            SpaceShip.ship_takeoff(player)
        else
            player.print("Error: You must scan the ship before taking off.")
        end
    elseif button_name == "ship-platform" then --travel mode
        player.print("Entering Travel Mode")
        SpaceShip.clone_ship_to_space_platform(player)
    elseif button_name == "close-spaceship-extended-gui" then
        SpaceShipGuis.close_spaceship_gui(player)
    elseif button_name == "confirm-dock" then
        player.print("Docking confirmed!")
        SpaceShip.finalize_dock(player) -- Call the finalizeTakeoff function
    elseif button_name == "cancel-dock" then
        player.print("Docking canceled!")
        SpaceShip.cancel_dock(player) -- Call the cancelTakeoff function
    elseif button_name == "ship-dock" then
        player.print("Docking the spaceship...")
        SpaceShip.dock_ship(player)
    elseif button_name == "add-station" then
        local ship = storage.spaceships[tonumber(event.element.parent.parent.parent.parent.name:match("(%d+)$"))]
        SpaceShip.add_or_change_station(ship)
        SpaceShipGuis.add_station(event.element.parent)
    elseif button_name == "delete-station" then
        SpaceShipGuis.delete_station(event)
    elseif button_name == "add-wait-condition" then
        SpaceShipGuis.add_condition_row(event)
        SpaceShipGuis.save_wait_conditions(event.element.parent)
    elseif button_name:match("^delete_condition_button_%d+$") then
        local frame = event.element.parent.parent.parent.parent.parent
        SpaceShipGuis.delete_condition(event)
        SpaceShipGuis.save_wait_conditions(frame)
    elseif button_name:match("^logic%-operator%-button_%d+$") then
        -- Toggle between AND and OR
        event.element.caption = event.element.caption == "AND" and "OR" or "AND"
        SpaceShipGuis.save_wait_conditions(event.element.parent.parent.parent.parent)
    elseif button_name == "auto-manual-switch" then
        local switch = event.element
        local ship = storage.spaceships[tonumber(event.element.parent.parent.parent.name:match("(%d+)$"))]
        -- Save the state to storage (left = automatic = true, right = manual = false)
        ship.automatic = (switch.switch_state == "left")
    else
        player.print("Unknown button clicked: " .. button_name)
    end
end

-- Function to handle dropdown selection changes
function SpaceShipGuis.handle_dropdown_selection(event)
    player = game.get_player(event.player_index)
    dropdown = event.element
    local ship = storage.spaceships[tonumber(event.element.parent.parent.parent.parent.parent.parent.name:match("(%d+)$"))]
    if dropdown.name == "surface-dropdown" then
        if dropdown and dropdown.valid then
            local selected_planet = dropdown.items[dropdown.selected_index]
            if selected_planet then
                storage.player_ship_gui_target = selected_planet -- Update the target planet in storage
                player.print("Target planet set to: " .. selected_planet)
            else
                player.print("Error: Invalid planet selection.")
            end
        end
    elseif dropdown.name:match("^station%-planet%-dropdown_%d+$") then
        local station_number = tonumber(dropdown.name:match("%d+"))
        if station_number then
            local selected_planet = dropdown.items[dropdown.selected_index]
            if selected_planet then
                -- Initialize the record if it doesn't exist
                if not ship.schedule.records[station_number] then
                    ship.schedule.records[station_number] = {}
                end
                -- Update the station's target planet
                ship.schedule.records[station_number].station = selected_planet
                -- Update the sprite if available
                if helpers.is_valid_sprite_path("space-location/" .. selected_planet) then
                    dropdown.parent["planet-select-button"].sprite = "space-location/" .. selected_planet
                end
            end
        end
    end
end

function SpaceShipGuis.delete_condition(event)
    local condition_number = tonumber(event.element.name:match("%d+"))
    local row = event.element.parent
    local condition_frame = row.parent
    local condition_flow = condition_frame.parent
    local main_container = condition_flow.parent
    local logic_flow = main_container["logic_flow"]

    -- Calculate the number of conditions before deletion
    local num_conditions = #condition_flow.children

    -- If this is the second-to-last condition, remove its AND/OR button
    if num_conditions == 1 then
        local logic_button_flow = logic_flow["logic_button_flow_1"]
        if logic_button_flow then
            logic_button_flow.destroy()
        end
        -- Also remove the spacer since we'll only have one condition left
        local spacer = logic_flow["logic_button_spacer"]
        if spacer then
            spacer.destroy()
        end
        -- If this isn't the last condition, remove its AND/OR button
    elseif num_conditions == condition_number then
        local logic_button_flow = logic_flow["logic_button_flow_" .. condition_number - 1]
        if logic_button_flow then
            logic_button_flow.destroy()
        end
    elseif num_conditions > 1 then
        local logic_button_flow = logic_flow["logic_button_flow_" .. condition_number]
        if logic_button_flow then
            logic_button_flow.destroy()
        end
    end

    -- Remove the condition
    condition_frame.destroy()

    -- Renumber remaining conditions and their AND/OR buttons
    local new_number = 1
    for _, child in pairs(condition_flow.children) do
        if child.name:match("^condition_row_%d+$") then
            local old_number = tonumber(child.name:match("%d+"))
            child.name = "condition_row_" .. new_number

            -- Update the names of elements within the condition row
            local input_flow = child["input-flow"]
            if input_flow then
                -- Use old number to find elements, then rename with new number
                local delete_button = input_flow["delete_condition_button_" .. old_number]
                if delete_button then
                    delete_button.name = "delete_condition_button_" .. new_number
                end

                local comparison = input_flow["comparison_dropdown_" .. old_number]
                if comparison then
                    comparison.name = "comparison_dropdown_" .. new_number
                end

                local value = input_flow["condition_value_" .. old_number]
                if value then
                    value.name = "condition_value_" .. new_number
                end
            end
            new_number = new_number + 1
        end
    end

    -- Renumber logic button flows using the same old/new number approach
    new_number = 1
    for _, child in pairs(logic_flow.children) do
        if child.name:match("^logic_button_flow_%d+$") then
            local old_number = tonumber(child.name:match("%d+"))
            child.name = "logic_button_flow_" .. new_number

            -- Use old number to find the button, then rename with new number
            local logic_button = child["logic-operator-button_" .. old_number]
            if logic_button then
                logic_button.name = "logic-operator-button_" .. new_number
            end
            new_number = new_number + 1
        end
    end
end

function SpaceShipGuis.initialize_progress_bars(ship)
    if not ship.schedule then
        return
    end
    player  = ship.player
    for station_number, record in pairs(ship.schedule.records) do
        -- Find the condition frame for this station
        local station_frame = player.gui.relative["spaceship-controller-schedual-gui-"..ship.name]
            ["vertical-flow"]["flow"]["station-scroll-panel"]
            ["station" .. station_number]

        if station_frame then
            local condition_flow = station_frame["spaceship-condition-gui"]
                ["main_container"]["condition_flow"]
            
            -- Update each condition's progress bar
            for _, child in pairs(condition_flow.children) do
                if child.name:match("^condition_row_%d+$") then
                    SpaceShipGuis.check_condition_row(child)
                end
            end
        end
    end
end

return SpaceShipGuis
