-- =============================================================================
-- UPGRADE BAY SYSTEM
-- Manages equipment grids, module effects, and building capacity limits
-- =============================================================================

local UpgradeBay = {}

-- =============================================================================
-- CONSTANTS
-- =============================================================================

-- Base building capacities by quality level
UpgradeBay.BASE_CAPACITY = {
    ["normal"] = 150,    -- Common quality
    ["uncommon"] = 200,
    ["rare"] = 260,
    ["epic"] = 330,
    ["legendary"] = 410
}

-- Equipment grid names by quality
UpgradeBay.GRID_BY_QUALITY = {
    ["normal"] = "upgrade-bay-grid-common",
    ["uncommon"] = "upgrade-bay-grid-uncommon",
    ["rare"] = "upgrade-bay-grid-rare",
    ["epic"] = "upgrade-bay-grid-epic",
    ["legendary"] = "upgrade-bay-grid-legendary"
}

-- Vehicle names by quality
UpgradeBay.VEHICLE_BY_QUALITY = {
    ["normal"] = "upgrade-bay-vehicle-common",
    ["uncommon"] = "upgrade-bay-vehicle-uncommon",
    ["rare"] = "upgrade-bay-vehicle-rare",
    ["epic"] = "upgrade-bay-vehicle-epic",
    ["legendary"] = "upgrade-bay-vehicle-legendary"
}

-- Module effects and caps
UpgradeBay.MODULE_EFFECTS = {
    ["construction-core-module"] = {
        type = "total_capacity",
        value = 40,
        cap = 200
    },
    ["supply-core-module"] = {
        type = "energy_capacity",
        value = 20,
        cap = 120
    },
    ["manufacturing-core-module"] = {
        type = "machine_capacity",
        value = 24,
        cap = 144
    },
    ["logistics-core-module"] = {
        type = "logistics_capacity",
        value = 30,
        cap = 180
    },
    ["defense-core-module"] = {
        type = "defense_capacity",
        value = 16,
        cap = 96
    },
    ["thruster-efficiency-booster"] = {
        type = "thruster_efficiency",
        value = 0.10,  -- 10% per module
        cap = 0.50     -- 50% cap
    },
    ["pod-throughput-optimizer"] = {
        type = "pod_throughput",
        value = 0.10,  -- 10% per module
        cap = 0.50     -- 50% cap
    },
    ["pod-payload-compressor"] = {
        type = "pod_payload",
        value = 0.05,  -- 5% per module
        cap = 0.25     -- 25% cap
    },
    ["docking-buffer-extension"] = {
        type = "docking_buffer",
        value = 1,     -- +1 per module
        cap = 3        -- +3 cap
    },
    ["asteroid-shield-matrix"] = {
        type = "asteroid_shield",
        value = 0.10,  -- -10% damage per module
        cap = 0.60     -- -60% cap
    },
    ["signal-multiplexer"] = {
        type = "signal_count",
        value = 8,     -- +8 signals per module
        cap = 32       -- +32 cap
    }
}

-- Entity categories for capacity calculations
UpgradeBay.ENTITY_CATEGORIES = {
    energy = {
        "accumulator", "solar-panel", "solar-panel-equipment", "generator",
        "electric-energy-interface", "electric-pole", "roboport"
    },
    machine = {
        "assembling-machine", "furnace", "rocket-silo",
        "chemical-plant", "oil-refinery", "centrifuge"
    },
    logistics = {
        "container", "logistic-container", "linked-container",
        "transport-belt", "underground-belt", "splitter", "loader",
        "inserter", "pipe", "pipe-to-ground", "pump", "storage-tank"
    },
    defense = {
        "ammo-turret", "electric-turret", "fluid-turret", "artillery-turret",
        "wall", "gate", "land-mine", "radar"
    }
}

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

function UpgradeBay.init()
    storage.upgrade_bays = storage.upgrade_bays or {}
end

-- =============================================================================
-- UPGRADE BAY CREATION AND MANAGEMENT
-- =============================================================================

-- Create an upgrade bay for a space hub
function UpgradeBay.create_for_hub(hub_entity)
    if not hub_entity or not hub_entity.valid then
        return nil
    end
    
    -- Get the quality of the hub (if quality mod is active)
    local quality = "normal"
    if hub_entity.quality and hub_entity.quality.name then
        quality = hub_entity.quality.name
    end
    
    -- Get vehicle name for this quality
    local vehicle_name = UpgradeBay.VEHICLE_BY_QUALITY[quality] or "upgrade-bay-vehicle-common"
    
    -- Create the upgrade bay vehicle near the hub (hidden)
    local upgrade_bay = hub_entity.surface.create_entity({
        name = vehicle_name,
        position = hub_entity.position,
        force = hub_entity.force,
        create_build_effect_smoke = false
    })
    
    if not upgrade_bay then
        game.print("[color=red]Failed to create upgrade bay![/color]")
        return nil
    end
    
    -- Store the upgrade bay data
    storage.upgrade_bays = storage.upgrade_bays or {}
    storage.upgrade_bays[hub_entity.unit_number] = {
        hub = hub_entity,
        vehicle = upgrade_bay,
        quality = quality
    }
    
    -- Make the vehicle non-interactable except through GUI
    upgrade_bay.destructible = false
    upgrade_bay.operable = false
    
    return upgrade_bay
end

-- Destroy upgrade bay when hub is destroyed
function UpgradeBay.destroy_for_hub(hub_unit_number)
    if not storage.upgrade_bays then return end
    
    local bay_data = storage.upgrade_bays[hub_unit_number]
    if bay_data and bay_data.vehicle and bay_data.vehicle.valid then
        bay_data.vehicle.destroy()
    end
    
    storage.upgrade_bays[hub_unit_number] = nil
end

-- =============================================================================
-- MODULE EFFECT CALCULATIONS
-- =============================================================================

-- Calculate all module effects for a given hub
function UpgradeBay.calculate_effects(hub_unit_number)
    if not storage.upgrade_bays then return nil end
    
    local bay_data = storage.upgrade_bays[hub_unit_number]
    if not bay_data or not bay_data.vehicle or not bay_data.vehicle.valid then
        return nil
    end
    
    local grid = bay_data.vehicle.grid
    if not grid then return nil end
    
    -- Initialize effect counters
    local effects = {
        total_capacity = 0,
        energy_capacity = 0,
        machine_capacity = 0,
        logistics_capacity = 0,
        defense_capacity = 0,
        thruster_efficiency = 0,
        pod_throughput = 0,
        pod_payload = 0,
        docking_buffer = 0,
        asteroid_shield = 0,
        signal_count = 0
    }
    
    -- Count each module type and calculate effects
    local module_counts = {}
    for _, equipment in pairs(grid.equipment) do
        local module_name = equipment.name
        module_counts[module_name] = (module_counts[module_name] or 0) + 1
    end
    
    -- Apply module effects with caps
    for module_name, count in pairs(module_counts) do
        local module_config = UpgradeBay.MODULE_EFFECTS[module_name]
        if module_config then
            local effect_type = module_config.type
            local raw_value = module_config.value * count
            local capped_value = math.min(raw_value, module_config.cap)
            effects[effect_type] = capped_value
        end
    end
    
    return effects
end

-- =============================================================================
-- CAPACITY MANAGEMENT
-- =============================================================================

-- Get the base capacity for a hub based on quality
function UpgradeBay.get_base_capacity(hub_unit_number)
    if not storage.upgrade_bays then return 150 end
    
    local bay_data = storage.upgrade_bays[hub_unit_number]
    if not bay_data then return 150 end
    
    return UpgradeBay.BASE_CAPACITY[bay_data.quality] or 150
end

-- Get total capacity including modules
function UpgradeBay.get_total_capacity(hub_unit_number)
    local base = UpgradeBay.get_base_capacity(hub_unit_number)
    local effects = UpgradeBay.calculate_effects(hub_unit_number)
    
    if not effects then return base end
    
    return base + effects.total_capacity
end

-- Get capacity for a specific category
function UpgradeBay.get_category_capacity(hub_unit_number, category)
    local effects = UpgradeBay.calculate_effects(hub_unit_number)
    if not effects then return 0 end
    
    if category == "energy" then
        return effects.energy_capacity
    elseif category == "machine" then
        return effects.machine_capacity
    elseif category == "logistics" then
        return effects.logistics_capacity
    elseif category == "defense" then
        return effects.defense_capacity
    end
    
    return 0
end

-- =============================================================================
-- ENTITY COUNTING AND VALIDATION
-- =============================================================================

-- Count entities on a surface by category
function UpgradeBay.count_entities_by_category(surface, area)
    local counts = {
        total = 0,
        energy = 0,
        machine = 0,
        logistics = 0,
        defense = 0,
        other = 0
    }
    
    local entities = surface.find_entities(area)
    for _, entity in pairs(entities) do
        if entity.valid and not string.match(entity.name, "^upgrade%-bay%-vehicle") then
            counts.total = counts.total + 1
            
            local categorized = false
            for category, types in pairs(UpgradeBay.ENTITY_CATEGORIES) do
                for _, type_name in pairs(types) do
                    if entity.type == type_name then
                        counts[category] = counts[category] + 1
                        categorized = true
                        break
                    end
                end
                if categorized then break end
            end
            
            if not categorized then
                counts.other = counts.other + 1
            end
        end
    end
    
    return counts
end

-- Check if placing an entity would exceed capacity limits
function UpgradeBay.can_place_entity(hub_unit_number, entity_type, surface, area)
    -- Get current counts
    local counts = UpgradeBay.count_entities_by_category(surface, area)
    
    -- Get capacity limits
    local total_capacity = UpgradeBay.get_total_capacity(hub_unit_number)
    
    -- Check total capacity
    if counts.total >= total_capacity then
        return false, "Total building capacity reached"
    end
    
    -- Check category-specific capacity
    for category, types in pairs(UpgradeBay.ENTITY_CATEGORIES) do
        for _, type_name in pairs(types) do
            if entity_type == type_name then
                local category_capacity = UpgradeBay.get_category_capacity(hub_unit_number, category)
                if category_capacity > 0 and counts[category] >= category_capacity then
                    return false, category .. " capacity reached"
                end
                break
            end
        end
    end
    
    return true, "OK"
end

-- =============================================================================
-- GUI INTEGRATION
-- =============================================================================

-- Open the upgrade bay GUI for a player
function UpgradeBay.open_gui(player, hub_unit_number)
    if not storage.upgrade_bays then return end
    
    local bay_data = storage.upgrade_bays[hub_unit_number]
    if not bay_data or not bay_data.vehicle or not bay_data.vehicle.valid then
        player.print("[color=red]Upgrade bay not found![/color]")
        return
    end
    
    -- Open the vehicle's equipment grid
    player.opened = bay_data.vehicle
end

-- =============================================================================
-- SPECIAL MODULE EFFECTS
-- =============================================================================

-- Apply thruster efficiency bonus
function UpgradeBay.get_thruster_efficiency_bonus(hub_unit_number)
    local effects = UpgradeBay.calculate_effects(hub_unit_number)
    if not effects then return 0 end
    return effects.thruster_efficiency
end

-- Apply pod throughput bonus
function UpgradeBay.get_pod_throughput_bonus(hub_unit_number)
    local effects = UpgradeBay.calculate_effects(hub_unit_number)
    if not effects then return 0 end
    return effects.pod_throughput
end

-- Apply pod payload bonus
function UpgradeBay.get_pod_payload_bonus(hub_unit_number)
    local effects = UpgradeBay.calculate_effects(hub_unit_number)
    if not effects then return 0 end
    return effects.pod_payload
end

-- Get docking buffer bonus
function UpgradeBay.get_docking_buffer_bonus(hub_unit_number)
    local effects = UpgradeBay.calculate_effects(hub_unit_number)
    if not effects then return 0 end
    return effects.docking_buffer
end

-- Get asteroid shield reduction
function UpgradeBay.get_asteroid_shield_reduction(hub_unit_number)
    local effects = UpgradeBay.calculate_effects(hub_unit_number)
    if not effects then return 0 end
    return effects.asteroid_shield
end

-- Get additional signal count
function UpgradeBay.get_signal_count_bonus(hub_unit_number)
    local effects = UpgradeBay.calculate_effects(hub_unit_number)
    if not effects then return 0 end
    return effects.signal_count
end

-- =============================================================================
-- DEBUG AND UTILITY
-- =============================================================================

-- Print upgrade bay info for debugging
function UpgradeBay.debug_info(hub_unit_number)
    if not storage.upgrade_bays then
        game.print("No upgrade bays initialized")
        return
    end
    
    local bay_data = storage.upgrade_bays[hub_unit_number]
    if not bay_data then
        game.print("No upgrade bay for hub " .. hub_unit_number)
        return
    end
    
    game.print("=== Upgrade Bay Info ===")
    game.print("Quality: " .. bay_data.quality)
    game.print("Grid: " .. bay_data.grid_name)
    game.print("Base Capacity: " .. UpgradeBay.get_base_capacity(hub_unit_number))
    game.print("Total Capacity: " .. UpgradeBay.get_total_capacity(hub_unit_number))
    
    local effects = UpgradeBay.calculate_effects(hub_unit_number)
    if effects then
        game.print("=== Module Effects ===")
        for effect_type, value in pairs(effects) do
            if value > 0 then
                game.print(effect_type .. ": " .. value)
            end
        end
    end
end

return UpgradeBay
