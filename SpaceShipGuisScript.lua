local SpaceShipFunctions = require("SpaceShipFunctionsScript") -- Require the SpaceShipFunctions module
local SpaceShip = require("spacShip")
local SpaceShipGuis = {}

-- Function to create the custom spaceship control GUI
function SpaceShipGuis.create_spaceship_gui(player)
    local relative_gui = player.gui.relative

    if relative_gui["spaceship-controller-extended-gui"] then
        return
    end
    if relative_gui["spaceship-controller-schedual-gui"] then
        return
    end

    local custom_gui = relative_gui.add {
        type = "frame",
        name = "spaceship-controller-extended-gui",
        caption = "Spaceship Actions",
        direction = "vertical",
        anchor = {
            gui = defines.relative_gui_type.container_gui,
            position = defines.relative_gui_position.left
        }
    }
    local schedual_gui = relative_gui.add {
        type = "frame",
        name = "spaceship-controller-schedual-gui",
        caption = "Schedual",
        anchor = {
            gui = defines.relative_gui_type.container_gui,
            position = defines.relative_gui_position.right
        }
    }
    ship_temp = storage.spaceships[storage.opened_entity_id]
    --main panel
    flow = schedual_gui.add { type = "flow", name = "vertical-flow", direction = "vertical" }
    --switch panel
    selector = flow.add { type = "flow", name = "switch-flow", direction = "horizontal" }
    selectorlabel = selector.add { type = "label", caption = "Automatic", name = "auto" }
    selectorlabel = selector.add { type = "switch", name = "auto-manual-switch" }
    selectorlabel = selector.add { type = "label", caption = "Paused", name = "paused" }
    --schedual panel
    schedualflow = flow.add { type = "flow", name = "flow" }
    schedualscroll = schedualflow.add { type = "scroll-pane", style = "train_schedule_scroll_pane", vertical_scroll_policy = "always" }
    schedbutton = schedualscroll.add { type = "button", style = "train_schedule_add_station_button", name = "add-station", caption = "Add Station" }
    --test station
    if storage.spaceships[storage.opened_entity_id].schedule and storage.spaceships[storage.opened_entity_id].schedule.records then
        for _, value in pairs(storage.spaceships[storage.opened_entity_id].schedule.records) do
            SpaceShipGuis.add_station(schedualscroll)
        end
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

function SpaceShipGuis.add_station(parent)
    local ship = storage.spaceships[storage.opened_entity_id]
    local count = 0
    local stop1holder
    for _ in pairs(ship.schedule.records) do
        local found = false
        count = count + 1
        for _, value in pairs(parent.children_names) do
            if value == "station" .. count then
                found = true
            end
        end
        if not found then
            stop1holder = parent.add { type = "flow", direction = "vertical", name = "station" .. count }
            local stop1 = stop1holder.add { type = "frame", style = "train_schedule_station_frame" }
            local addcondition = stop1holder.add { type = "button", style = "train_schedule_add_wait_condition_button", caption = "Add Condition" }
            stop1.style.natural_width = 400
            stop1.style.natural_height = 50
            stop1.style.horizontally_stretchable = true
            local sprite_button = stop1.add {
                type = "sprite-button",
                name = "my_sprite_button",
                sprite = "item/iron-plate",
                tooltip = "This is a sprite button",
                style = "train_schedule_action_button"
            }
            local labelstation = stop1.add { type = "label", style = "clickable_squashable_label", caption = "station" }
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
    event.element.parent.parent.destroy()
end

-- Function to close the spaceship control GUI
function SpaceShipGuis.close_spaceship_gui(event)
    local player = game.get_player(event.player_index)
    if event.entity and event.entity.name == "spaceship-control-hub" then
        -- Destroy the custom GUI when the main GUI for "spaceship-control-hub" is closed.
        local custom_gui = player.gui.relative["spaceship-controller-extended-gui"]
        if custom_gui then
            custom_gui.destroy()
            storage.opened_entity_id = nil
            player.print("extended GUI closed with the main GUI.")
        end
        local custom_gui = player.gui.relative["spaceship-controller-schedual-gui"]
        if custom_gui then
            custom_gui.destroy()
            storage.opened_entity_id = nil
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
        SpaceShip.start_scan_ship(player)
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
        SpaceShip.add_or_change_station(storage.spaceships[storage.opened_entity_id])
        SpaceShipGuis.add_station(event.element.parent)
    elseif button_name == "delete-station" then
        SpaceShipGuis.delete_station(event)
    else
        player.print("Unknown button clicked: " .. button_name)
    end
end

-- Function to handle dropdown selection changes
function SpaceShipGuis.handle_dropdown_selection(player, dropdown_name, selected_index)
    if dropdown_name == "surface-dropdown" then
        local dropdown = player.gui.relative["spaceship-controller-extended-gui"]["surface-dropdown"]
        if dropdown and dropdown.valid then
            local selected_planet = dropdown.items[selected_index]
            if selected_planet then
                storage.player_ship_gui_target = selected_planet -- Update the target planet in storage
                player.print("Target planet set to: " .. selected_planet)
            else
                player.print("Error: Invalid planet selection.")
            end
        end
    end
end

return SpaceShipGuis
