local Stations = {}

-- Function to check if a platform name indicates it's a station
local function is_station_platform(platform_name)
    return string.find(platform_name, "-station") ~= nil
end

-- Function to check if a platform name indicates it's a ship
local function is_ship_platform(platform_name)
    return string.find(platform_name, "-ship") ~= nil
end

-- Function to get ship_type from platform tags or name
local function get_platform_type(platform)
    -- Check if platform has tags with ship_type
    if platform.tags and platform.tags.ship_type then
        return platform.tags.ship_type
    end
    
    -- Fallback to name-based detection
    if is_station_platform(platform.name) then
        return "platform"
    elseif is_ship_platform(platform.name) then
        return "ship"
    end
    
    return nil
end

-- Function to set platform type
local function set_platform_type(platform, platform_type)
    if not platform or not platform.valid then return end
    
    -- Store type in platform tags
    platform.tags = platform.tags or {}
    platform.tags.ship_type = platform_type
    
    -- Initialize mode state (default: station mode is active for platforms, ship mode for ships)
    if platform_type == "platform" then
        platform.tags.station_mode = true
    else
        platform.tags.station_mode = false
    end
end

-- Function to get the planet name from a station platform name
local function get_planet_from_station_name(station_name)
    local planet_name = string.match(station_name, "(.+)-station")
    return planet_name
end

-- Function to count existing stations orbiting a planet
local function count_stations_for_planet(force, planet_name)
    local station_count = 0
    local station_platforms = {}
    
    for _, platform in pairs(force.platforms) do
        if platform.space_location and platform.space_location.name == planet_name then
            if is_station_platform(platform.name) then
                station_count = station_count + 1
                table.insert(station_platforms, platform)
            end
        end
    end
    
    return station_count, station_platforms
end

-- Main function to handle new platform creation and station management
function Stations.handle_platform_state_change(event)
    local platform = event.platform
    local old_state = event.old_state
    local new_state = platform.state
    
    -- Check for state change from 0 (waiting for starter pack) to 8 (ready)
    if old_state == 0 and new_state == 8 then
        -- Determine platform type based on hub entity
        local hub = platform.surface.find_entities_filtered({name = "space-platform-hub"})
        local custom_hub = platform.surface.find_entities_filtered({name = "spaceship-control-hub"})
        
        if custom_hub and #custom_hub > 0 then
            -- This is a ship (has custom hub)
            set_platform_type(platform, "ship")
            if not is_ship_platform(platform.name) then
                -- Rename if not already named as ship
                platform.name = (platform.name or "Ship") .. "-ship"
            end
            game.print("[color=green]Created ship: " .. platform.name .. "[/color]")
            return
        elseif hub and #hub > 0 then
            -- This is a station (has standard hub)
            set_platform_type(platform, "platform")
        else
            return -- No hub found, can't determine type
        end
        
        -- Handle station creation logic
        local space_location = platform.space_location
        if not space_location then
            return -- No location, can't process
        end
        
        local planet_name = space_location.name
        local force = platform.force
        
        -- Count existing stations for this planet
        local station_count, existing_stations = count_stations_for_planet(force, planet_name)
        
        if station_count == 0 then
            -- This is the first station for this planet, rename it appropriately
            local new_station_name = planet_name .. "-station"
            platform.name = new_station_name
            game.print("[color=green]Created first station for " .. planet_name .. ": " .. new_station_name .. "[/color]")
            
            -- Set station mode (paused)
            Stations.set_station_mode(platform, true)
        else
            -- There's already a station for this planet, delete the new one
            game.print("[color=yellow]A station already exists for " .. planet_name .. ". Removing duplicate station platform.[/color]")
            
            -- Give feedback about the existing station
            if existing_stations[1] then
                game.print("[color=cyan]Existing station: " .. existing_stations[1].name .. "[/color]")
            end
            
            -- Destroy the duplicate platform
            platform.destroy()
            return
        end
    end
end

-- Check if player has required armor to get off planet
function Stations.has_spaceship_armor(player)
    if not player or not player.valid then return false end
    
    -- Get player armor inventory
    local armor_inventory = player.get_inventory(defines.inventory.character_armor)
    if not armor_inventory or armor_inventory.is_empty() then return false end
    
    -- Check if player is wearing spaceship armor
    local armor = armor_inventory[1]
    if not armor or not armor.valid_for_read then return false end
    
    -- Check if armor is the required type (spaceship-armor)
    return armor.name == "spaceship-armor" or armor.name == "space-armor"
end

-- Set station mode on/off for a platform
function Stations.set_station_mode(platform, enabled)
    if not platform or not platform.valid then return end
    
    -- Update tags
    platform.tags = platform.tags or {}
    platform.tags.station_mode = enabled
    
    -- In station mode, pause the platform to prevent movement
    if enabled then
        -- Pause platform - this stops all movement
        platform.paused = true
        game.print("[color=yellow]" .. platform.name .. " is now in Station Mode (movement paused, thrusters ineffective)[/color]")
    else
        -- Unpause platform to allow movement
        platform.paused = false
        game.print("[color=green]" .. platform.name .. " is now in Ship Mode (movement enabled)[/color]")
    end
end

-- Check if platform is in station mode
function Stations.is_station_mode(platform)
    if not platform or not platform.valid then return false end
    if not platform.tags then return false end
    return platform.tags.station_mode == true
end

-- Validate cargo pod transfer between platforms
-- Note: This validation function is available for manual checks or future integration
-- Factorio's cargo landing pad system doesn't expose events for automatic validation
function Stations.validate_transfer(source_platform, destination_platform)
    if not source_platform or not source_platform.valid then return false, "Invalid source platform" end
    if not destination_platform or not destination_platform.valid then return false, "Invalid destination platform" end
    
    -- Check if platforms are in the same orbit
    if source_platform.space_location ~= destination_platform.space_location then
        return false, "Platforms must be in the same orbit"
    end
    
    -- Get platform types - use the exported function from SpaceShip for consistency
    local SpaceShip = require("scripts.spaceship")
    local source_type = SpaceShip.get_platform_type(source_platform)
    local dest_type = SpaceShip.get_platform_type(destination_platform)
    
    -- Ship to Ship transfers are forbidden
    if source_type == "ship" and dest_type == "ship" then
        return false, {"message.transfer-ship-to-ship-forbidden"}
    end
    
    -- Station↔Station and Station↔Ship are allowed
    return true, "Transfer allowed"
end

-- Function to get platform type (public wrapper around local function)
function Stations.get_platform_type(platform)
    return get_platform_type(platform)
end

-- Function to initialize station management (call this from control.lua)
function Stations.init()
    -- Any initialization logic can go here
    if not storage.stations then
        storage.stations = {}
    end
end

return Stations
