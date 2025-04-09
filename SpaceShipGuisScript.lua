local SpaceShipFunctions = require("SpaceShipFunctionsScript") -- Require the SpaceShipFunctions module
local SpaceShip = require("spacShip")
local SpaceShipGuis = {}

-- Function to create the custom spaceship control GUI
function SpaceShipGuis.create_spaceship_gui(player)
    local relative_gui = player.gui.relative

    if relative_gui["spaceship-controller-extended-gui"] then
        return
    end

    local custom_gui = relative_gui.add {
        type = "frame",
        name = "spaceship-controller-extended-gui",
        caption = "Spaceship Actions",
        direction = "vertical",
        anchor = {
            gui = defines.relative_gui_type.container_gui,
            position = defines.relative_gui_position.right
        }
    }

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

-- Function to close the spaceship control GUI
function SpaceShipGuis.close_spaceship_gui(player)
    -- Close the main GUI by setting the player's opened property to nil
    if player.opened then
        player.opened = nil
    end

    -- Destroy any GUI in the player's relative GUI
    if player.gui.relative["spaceship-controller-extended-gui"] then
        player.gui.relative["spaceship-controller-extended-gui"].destroy()
    end
end

-- Function to handle button clicks
function SpaceShipGuis.handle_button_click(player, button_name)
    if button_name == "scan-ship" then  -- Call the scan_ship function
        player.print("Scanning the ship...")
        SpaceShip.scan_ship(player)
    elseif button_name == "ship-takeoff" then -- Call the shipTakeoff function
        if storage.spaceships[storage.opened_entity_id].scanned then
            player.print("Spaceship takeoff initiated!")
            SpaceShip.shipTakeoff(player)
        else
            player.print("Error: You must scan the ship before taking off.")
        end
    elseif button_name == "ship-platform" then --travel mode
        player.print("Entering Travel Mode")
        SpaceShip.clone_ship_to_space_platform(player)
    elseif button_name == "close-spaceship-extended-gui" then
        SpaceShipGuis.close_spaceship_gui(player)
    elseif button_name == "confirm_takeoff" then
        player.print("Takeoff confirmed!")
        SpaceShip.finalizeTakeoff(player) -- Call the finalizeTakeoff function
    elseif button_name == "cancel_takeoff" then
        player.print("Takeoff canceled!")
        SpaceShip.cancelTakeoff(player) -- Call the cancelTakeoff function
    elseif button_name == "ship_dock" then
        player.print("Docking the spaceship...")
        SpaceShip.dock_ship(player)
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
