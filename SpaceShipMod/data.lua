-- =============================================================================
-- SPACESHIP MOD DATA DEFINITIONS
-- =============================================================================

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

local function make_tile_area(area, name)
    local result = {}
    local left_top = area[1]
    local right_bottom = area[2]
    for x = left_top[1], right_bottom[1] do
        for y = left_top[2], right_bottom[2] do
            table.insert(result, {
                position = { x, y },
                tile = name
            })
        end
    end
    return result
end

-- =============================================================================
-- PROTOTYPE COPIES (Base templates from existing game prototypes)
-- =============================================================================

-- Docking Port prototypes (based on constant-combinator and cargo-bay)
local dockingPortEntity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
local dockingPortRecipe = table.deepcopy(data.raw["recipe"]["cargo-bay"])
local dockingPortItem = table.deepcopy(data.raw["item"]["cargo-bay"])

-- Circuit Request Controller is now in a separate mod (CircuitRequestController)

-- Floor prototypes (based on space-platform-foundation)
local floorItem = table.deepcopy(data.raw["item"]["space-platform-foundation"])
local floorRecipe = table.deepcopy(data.raw["recipe"]["space-platform-foundation"])

-- Wall prototypes (based on stone-wall)
local wallEntity = table.deepcopy(data.raw["wall"]["stone-wall"])
local wallItem = table.deepcopy(data.raw["item"]["stone-wall"])
local wallRecipe = table.deepcopy(data.raw["recipe"]["stone-wall"])

-- Control Hub prototypes (based on various prototypes)
local controlHubItem = table.deepcopy(data.raw["item"]["cargo-bay"])
local controlHubRecipe = table.deepcopy(data.raw["recipe"]["cargo-bay"])
local controlHubEntityHub = table.deepcopy(data.raw["space-platform-hub"]["space-platform-hub"])
local controlHubItemCar = table.deepcopy(data.raw["item-with-entity-data"]["car"])

-- =============================================================================
-- DOCKING PORT MODIFICATIONS
-- =============================================================================

dockingPortRecipe.name = "spaceship-docking-port"
dockingPortRecipe.localised_name = "Spaceship Docking Port"
dockingPortRecipe.localised_description = "Docking port for spaceship."
dockingPortRecipe.ingredients = { { type = "item", name = "iron-plate", amount = 1 } }
dockingPortRecipe.results = { { type = "item", name = "spaceship-docking-port", amount = 1 } }
dockingPortRecipe.enabled = false

dockingPortItem.name = "spaceship-docking-port"
dockingPortItem.localised_name = "Spaceship Docking Port"
dockingPortItem.place_result = "spaceship-docking-port"
-- Create tinted icon for docking port using icons property
dockingPortItem.icon = nil
dockingPortItem.icon_size = nil
dockingPortItem.icons = {
    {
        icon = data.raw["item"]["constant-combinator"].icon,
        icon_size = data.raw["item"]["constant-combinator"].icon_size,
        tint = { r = 0.8, g = 0.8, b = 0.8, a = 1.0 }
    }
}

dockingPortEntity.name = "spaceship-docking-port"
dockingPortEntity.localised_name = "Spaceship Docking Port"
dockingPortEntity.minable = { mining_time = 0.2, result = "spaceship-docking-port" }

-- =============================================================================
-- CIRCUIT REQUEST CONTROLLER - Now in separate mod
-- =============================================================================
-- Circuit Request Controller entity, item, and recipe are now provided by the
-- CircuitRequestController mod

-- =============================================================================
-- CONTROL HUB MODIFICATIONS
-- =============================================================================

controlHubItem.name = "spaceship-control-hub"
controlHubItem.localised_name = "Spaceship Control Hub"
controlHubItem.place_result = "spaceship-control-hub"
-- Create tinted icon for control hub using icons property
controlHubItem.icon = nil
controlHubItem.icon_size = nil
controlHubItem.icons = {
    {
        icon = data.raw["item"]["space-platform-hub"].icon,
        icon_size = data.raw["item"]["space-platform-hub"].icon_size,
        tint = { r = 0.8, g = 0.8, b = 0.8, a = 1.0 }
    }
}

controlHubRecipe.name = "spaceship-control-hub"
controlHubRecipe.localised_name = "Spaceship Control Hub"
controlHubRecipe.ingredients = { { type = "item", name = "iron-plate", amount = 1 } }
controlHubRecipe.results = { { type = "item", name = "spaceship-control-hub", amount = 1 } }
controlHubRecipe.enabled = false

controlHubItemCar.name = "spaceship-control-hub-car"

-- =============================================================================
-- WALL MODIFICATIONS
-- =============================================================================

wallEntity.name = "spaceship-wall"
wallEntity.localised_name = "Spaceship Wall"
wallEntity.minable = { mining_time = 0.2, result = "spaceship-wall" }
wallEntity.create_ghost_on_death = true
wallEntity.surface_conditions = nil

wallItem.name = "spaceship-wall"
wallItem.localised_name = "Spaceship Wall"
wallItem.place_result = "spaceship-wall"

wallRecipe.name = "spaceship-wall"
wallRecipe.localised_name = "Spaceship Wall"
wallRecipe.ingredients = { { type = "item", name = "iron-plate", amount = 1 } }
wallRecipe.results = { { type = "item", name = "spaceship-wall", amount = 1 } }
wallRecipe.enabled = false

-- =============================================================================
-- FLOOR MODIFICATIONS
-- =============================================================================

floorItem.name = "spaceship-flooring"
floorItem.localised_name = "Spaceship Flooring"
floorItem.place_as_tile = { result = "spaceship-flooring", condition_size = 0, condition = { layers = {} } }
-- Use refined concrete icon for spaceship flooring
floorItem.icon = data.raw["item"]["refined-concrete"].icon
floorItem.icon_size = data.raw["item"]["refined-concrete"].icon_size

floorRecipe.name = "spaceship-flooring"
floorRecipe.localised_name = "Spaceship Flooring"
floorRecipe.ingredients = { { type = "item", name = "iron-plate", amount = 1 } }
floorRecipe.results = { { type = "item", name = "spaceship-flooring", amount = 10 } }
floorRecipe.main_product = "spaceship-flooring"
floorRecipe.hidden = false
floorRecipe.enabled = false

-- =============================================================================
-- SPACESHIP FLOORING TILE (Custom tile with refined concrete graphics)
-- =============================================================================

local space_foundation = data.raw.tile["space-platform-foundation"]
local refined_concrete = data.raw.tile["refined-concrete"]

local spaceship_flooring_tile = nil
if space_foundation and refined_concrete then
    spaceship_flooring_tile = table.deepcopy(space_foundation)

    -- Keep all space platform foundation properties (space-compatible)
    spaceship_flooring_tile.name = "spaceship-flooring"
    spaceship_flooring_tile.localised_name = "Spaceship Flooring"
    spaceship_flooring_tile.order = "z[spaceship-flooring]"
    spaceship_flooring_tile.minable = { mining_time = 0.2, result = "spaceship-flooring" }
    spaceship_flooring_tile.map_color = { r = 200, g = 200, b = 200 }

    -- Use refined concrete graphics (clean grey appearance, no dirt transitions)
    spaceship_flooring_tile.variants = table.deepcopy(refined_concrete.variants)
end

-- =============================================================================
-- DATA EXTEND - Register all prototypes with the game
-- =============================================================================

data:extend({
    -- Custom Control Hub Container Entity
    {
        type = "container",
        name = "spaceship-control-hub",
        localised_name = "Spaceship Control Hub",
        localised_description = "Main control hub for the spaceship.",
        placeable_by = data.raw["item"]["spaceship-control-hub"],
        flags = { "placeable-neutral", "player-creation", "not-rotatable" },
        icon = data.raw["space-platform-starter-pack"]["space-platform-starter-pack"].icon,
        icon_size = 64,
        circuit_connector = data.raw["container"]["iron-chest"].circuit_connector,
        circuit_wire_max_distance = data.raw["container"]["iron-chest"].circuit_wire_max_distance,
        draw_circuit_wires = true,
        inventory_size = 50,
        max_health = 500,
        corpse = "medium-remnants",
        dying_explosion = "medium-explosion",
        create_ghost_on_death = true,
        surface_conditions = nil,
        collision_box = { { -3.8, -3.8 }, { 3.8, 3.8 } },
        selection_box = { { -3.8, -3.8 }, { 3.5, 3.8 } },
        minable = { mining_time = 0.2, result = "spaceship-control-hub" },
        picture = {
            layers = {
                {
                    filename = "__SpaceShipMod__/graphics/control-hub.png",
                    priority = "high",
                    width = 500,
                    height = 500,
                    shift = { 0, 0 },
                    scale = .65
                },
            }
        },
    },

    -- Control Hub Car Entity (for driving mechanics)
    {
        type = "car",
        name = "spaceship-control-hub-car",
        icon = "__base__/graphics/icons/car.png",
        icon_size = 64,
        flags = { "hidden" },
        weight = 1,
        braking_force = 1,
        friction_force = 100,
        energy_per_hit_point = 1,
        effectivity = 0,
        consumption = "1W",
        rotation_speed = 0,
        inventory_size = 1,
        energy_source = { type = "void" },
        burner = nil,
        animation = {
            layers = {
                {
                    filename = "__base__/graphics/entity/car/car-1.png",
                    priority = "low",
                    width = 1,
                    height = 1,
                    frame_count = 1,
                    direction_count = 1,
                    scale = 0.01
                }
            }
        },
        allow_remote_driving = false,
        collision_box = { { -0.4, -0.05 }, { 0.4, 0.05 } },
        selection_box = { { -0.4, -0.05 }, { 0.4, 0.05 } },
    },
    -- Station Starter Pack
    {
        type = "space-platform-starter-pack",
        name = "space-station-starter-pack",
        localised_name = {"item-name.space-station-starter-pack"},
        icon = "__space-age__/graphics/icons/space-platform-foundation.png",
        subgroup = "space-rocket",
        stack_size = 1,
        weight = 1 * tons,
        surface = "space-platform",
        trigger =
        {
            {
                type = "direct",
                action_delivery =
                {
                    type = "instant",
                    source_effects =
                    {
                        {
                            type = "create-entity",
                            entity_name = "space-platform-hub"
                        }
                    }
                }
            }
        },
        tiles = make_tile_area({ { -5, -5 }, { 5, 5 } }, "space-platform-foundation"),
        initial_items = { { type = "item", name = "space-platform-foundation", amount = 50 } },
        create_electric_network = true,
    },
    -- Ship Starter Pack
    {
        type = "space-platform-starter-pack",
        name = "space-ship-starter-pack",
        localised_name = {"item-name.space-ship-starter-pack"},
        icon = "__space-age__/graphics/icons/thruster.png",
        subgroup = "space-rocket",
        stack_size = 1,
        weight = 1 * tons,
        surface = "space-ship-surface",
        trigger =
        {
            {
                type = "direct",
                action_delivery =
                {
                    type = "instant",
                    source_effects =
                    {
                        {
                            type = "create-entity",
                            entity_name = "spaceship-control-hub"
                        }
                    }
                }
            }
        },
        tiles = make_tile_area({ { -5, -5 }, { 5, 5 } }, "spaceship-flooring"),
        initial_items = { { type = "item", name = "spaceship-flooring", amount = 10 } },
        create_electric_network = true,
    },
    --[[
    {
        type = "recipe",
        name = "space-ship-starter-pack",
        localised_name = "Space Platform Starter Pack",
        ingredients = { { type = "item", name = "iron-plate", amount = 1 } },
        hidden = true,
        enabled = false,
        results = { { type = "item", name = "space-ship-starter-pack", amount = 10 } },
        main_product = "space-ship-starter-pack",
        icon = "__space-age__/graphics/icons/thruster.png",
        subgroup = "planets",
        order = "a[space-platform]",
        category = "crafting",
    },
    ]]--
    -- Custom Space Ship Surface
    {
        type = "surface",
        name = "space-ship-surface",
        icon = "__space-age__/graphics/icons/thruster.png",
        subgroup = "planets",
        order = "a[space-platform]",
        surface_properties = {
            gravity = 0,
            pressure = 0,
            ["magnetic-field"] = 0,
            ["day-night-cycle"] = 0
        }
    },

    -- Spaceship Construction Technology
    {
        type = "technology",
        name = "spaceship-construction",
        localised_name = "Spaceship Construction",
        localised_description = "Advanced spaceship components for interstellar travel.",
        icon = "__SpaceShipMod__/graphics/control-hub.png",
        icon_size = 500,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "spaceship-flooring"
            },
            {
                type = "unlock-recipe",
                recipe = "spaceship-control-hub"
            },
            {
                type = "unlock-recipe",
                recipe = "spaceship-docking-port"
            },
            {
                type = "unlock-recipe",
                recipe = "spaceship-armor"
            }
        },
        prerequisites = { "space-science-pack" },
        unit = {
            count = 1000,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "production-science-pack", 1 },
                { "utility-science-pack",    1 },
                { "space-science-pack",      1 }
            },
            time = 30
        },
        order = "e-g"
    },

    -- Modified prototype items/recipes/entities
    dockingPortItem,
    dockingPortRecipe,
    dockingPortEntity,
    floorItem,
    floorRecipe,
    controlHubItem,
    controlHubRecipe,
    wallEntity,
    wallItem,
    wallRecipe,
    controlHubEntityHub,
    controlHubItemCar,
})

-- Add the custom spaceship flooring tile if it was created successfully
if spaceship_flooring_tile then
    data:extend({ spaceship_flooring_tile })
end

-- =============================================================================
-- TECHNOLOGY MODIFICATIONS
-- =============================================================================

-- Modify existing technology prerequisites
if data.raw.technology["space-platform-thruster"] then
    data.raw.technology["space-platform-thruster"].prerequisites = { "spaceship-construction" }
end

-- Update power-armor-mk2 technology to reflect spaceship armor
if data.raw.technology["power-armor-mk2"] then
    -- Change the technology name and description to reflect spaceship armor
    data.raw.technology["power-armor-mk2"].localised_name = {"technology-name.spaceship-armor-tech"}
    data.raw.technology["power-armor-mk2"].localised_description = {"technology-description.spaceship-armor-tech"}
    
    -- Use the same dark grey-tinted icon as the spaceship armor
    data.raw.technology["power-armor-mk2"].icon = nil
    data.raw.technology["power-armor-mk2"].icons = {
        {
            icon = data.raw["armor"]["mech-armor"].icon,
            icon_size = data.raw["armor"]["mech-armor"].icon_size or 64,
            tint = {r = 0.4, g = 0.4, b = 0.4, a = 1.0}  -- Dark grey to match armor
        }
    }
end

-- Hide the original power-armor-mk2 from all discovery interfaces
if data.raw.armor["power-armor-mk2"] then
    data.raw.armor["power-armor-mk2"].hidden = true
    data.raw.armor["power-armor-mk2"].hidden_in_factoriopedia = true
end

if data.raw.item["power-armor-mk2"] then
    data.raw.item["power-armor-mk2"].hidden = true
    data.raw.item["power-armor-mk2"].hidden_in_factoriopedia = true
end

if data.raw.recipe["power-armor-mk2"] then
    data.raw.recipe["power-armor-mk2"].hidden = true
    data.raw.recipe["power-armor-mk2"].hidden_in_factoriopedia = true
end

-- =============================================================================
-- CORE GAME ENTITY MODIFICATIONS
-- =============================================================================

-- Modify thrusters to only be placeable on spaceship flooring
if data.raw.thruster and data.raw.thruster.thruster then
    -- Note: Tile placement restrictions for thrusters need to be handled in control.lua
    -- because tile_buildability_rules expects collision mask layers, not tile names

    -- Add localised description about placement requirement to the item
    if data.raw.item and data.raw.item.thruster then
        -- Add localised description about placement requirement
        data.raw.item.thruster.localised_description = { "",
            data.raw.item.thruster.localised_description or "",
            "\n[color=yellow]Can only be placed on Spaceship Flooring.[/color]"
        }
    end
end

-- =============================================================================
-- SPACESHIP ARMOR
-- =============================================================================

-- Create spaceship armor based on mech-armor with grey tint
local spaceshipArmor = table.deepcopy(data.raw["armor"]["mech-armor"])
spaceshipArmor.name = "spaceship-armor"
spaceshipArmor.icons = {
    {
        icon = data.raw["armor"]["mech-armor"].icon,
        icon_size = data.raw["armor"]["mech-armor"].icon_size or 64,
        tint = {r = 0.4, g = 0.4, b = 0.4, a = 1.0}  -- Darker grey to match character
    }
}
spaceshipArmor.icon = nil  -- Remove single icon since we're using icons array

-- Debug: Let's check ALL properties of both armors to understand how visuals work
local mech_armor = data.raw["armor"]["mech-armor"]
local power_armor_mk2 = data.raw["armor"]["power-armor-mk2"]

-- Now I understand how armor visuals work in Factorio 2.0!
-- Armor visuals are defined in the CharacterPrototype's animations array
-- Each CharacterArmorAnimation has an 'armors' property that lists which armors use those animations

-- Find the character prototype and add spaceship-armor to the mech-armor animation set
if data.raw["character"] and data.raw["character"]["character"] then
    local character = data.raw["character"]["character"]
    log("SpaceShipMod DEBUG: Found character prototype")
    
    if character.animations then
        log("SpaceShipMod DEBUG: Character has " .. #character.animations .. " animation sets")
        -- Look for the animation set that includes mech-armor
        for i, animation_set in ipairs(character.animations) do
            if animation_set.armors then
                log("SpaceShipMod DEBUG: Animation set " .. i .. " has armors list with " .. #animation_set.armors .. " armors")
                for j, armor_name in ipairs(animation_set.armors) do
                    log("SpaceShipMod DEBUG: Animation set " .. i .. " includes armor: " .. armor_name)
                    if armor_name == "mech-armor" then
                        -- Found the mech-armor animation set! 
                        -- First, create a deep copy of this animation set for spaceship armor
                        local spaceship_animation_set = table.deepcopy(animation_set)
                        
                        -- Set up the armors list to only include spaceship-armor
                        spaceship_animation_set.armors = {"spaceship-armor"}
                        
                        -- Apply grey tint to all animations in this set
                        local grey_tint = {r = 0.4, g = 0.4, b = 0.4, a = 1.0}  -- Darker grey
                        
                        -- Function to apply tint to a RotatedAnimation
                        local function apply_tint_to_animation(animation)
                            if animation then
                                if animation.layers then
                                    -- Animation has layers
                                    for _, layer in ipairs(animation.layers) do
                                        layer.tint = grey_tint
                                    end
                                elseif animation.filename then
                                    -- Single animation
                                    animation.tint = grey_tint
                                end
                            end
                        end
                        
                        -- Apply tint to all animation types
                        apply_tint_to_animation(spaceship_animation_set.idle)
                        apply_tint_to_animation(spaceship_animation_set.idle_with_gun)
                        apply_tint_to_animation(spaceship_animation_set.running)
                        apply_tint_to_animation(spaceship_animation_set.running_with_gun)
                        apply_tint_to_animation(spaceship_animation_set.mining_with_tool)
                        apply_tint_to_animation(spaceship_animation_set.flipped_shadow_running_with_gun)
                        apply_tint_to_animation(spaceship_animation_set.idle_in_air)
                        apply_tint_to_animation(spaceship_animation_set.idle_with_gun_in_air)
                        apply_tint_to_animation(spaceship_animation_set.flying)
                        apply_tint_to_animation(spaceship_animation_set.flying_with_gun)
                        apply_tint_to_animation(spaceship_animation_set.take_off)
                        apply_tint_to_animation(spaceship_animation_set.landing)
                        
                        -- Add the new grey-tinted animation set to the character
                        table.insert(character.animations, spaceship_animation_set)
                        
                        log("SpaceShipMod DEBUG: Created grey-tinted animation set for spaceship-armor!")
                        break
                    end
                end
            else
                log("SpaceShipMod DEBUG: Animation set " .. i .. " has no armors list (default/no armor)")
            end
        end
    else
        log("SpaceShipMod DEBUG: Character has no animations property")
    end
else
    log("SpaceShipMod DEBUG: Character prototype not found")
end

-- Create spaceship armor recipe (uses power-armor-mk2 ingredients since it's replacing it)
local spaceshipArmorRecipe = table.deepcopy(data.raw["recipe"]["mech-armor"])
spaceshipArmorRecipe.name = "spaceship-armor"
spaceshipArmorRecipe.results = { {type = "item", name = "spaceship-armor", amount = 1} }

-- Use the exact same ingredients as power-armor-mk2 since this is replacing it
spaceshipArmorRecipe.ingredients = {
    {type = "item", name = "efficiency-module-2", amount = 25},
    {type = "item", name = "electric-engine-unit", amount = 40},
    {type = "item", name = "low-density-structure", amount = 30},
    {type = "item", name = "processing-unit", amount = 60},
    {type = "item", name = "speed-module-2", amount = 25}
}
spaceshipArmorRecipe.energy_required = 25

data:extend({
    spaceshipArmor,
    spaceshipArmorRecipe
})

-- =============================================================================
-- RECIPE AND TECHNOLOGY MODIFICATIONS
-- =============================================================================

-- Replace power-armor-mk2 in technology effects (immediate replacements)
if data.raw.technology then
    for _, tech in pairs(data.raw.technology) do
        if tech.effects then
            for _, effect in pairs(tech.effects) do
                if effect.type == "unlock-recipe" and effect.recipe == "power-armor-mk2" then
                    effect.recipe = "spaceship-armor"
                end
            end
        end
    end
end

-- =============================================================================
-- NOTE: Global power-armor-mk2 replacement is handled in data-final-fixes.lua
-- =============================================================================

-- =============================================================================
-- UPGRADE BAY SYSTEM - Equipment Grids & Modules
-- =============================================================================

-- Equipment Grid Categories for different quality levels
local upgrade_bay_grids = {
    {
        name = "upgrade-bay-grid-common",
        width = 4,
        height = 4,
        equipment_categories = {"upgrade-module"}
    },
    {
        name = "upgrade-bay-grid-uncommon",
        width = 6,
        height = 4,
        equipment_categories = {"upgrade-module"}
    },
    {
        name = "upgrade-bay-grid-rare",
        width = 8,
        height = 4,
        equipment_categories = {"upgrade-module"}
    },
    {
        name = "upgrade-bay-grid-epic",
        width = 10,
        height = 4,
        equipment_categories = {"upgrade-module"}
    },
    {
        name = "upgrade-bay-grid-legendary",
        width = 12,
        height = 4,
        equipment_categories = {"upgrade-module"}
    }
}

-- Create equipment category for upgrade modules
data:extend({
    {
        type = "equipment-category",
        name = "upgrade-module"
    }
})

-- Create all equipment grids
for _, grid in ipairs(upgrade_bay_grids) do
    data:extend({
        {
            type = "equipment-grid",
            name = grid.name,
            width = grid.width,
            height = grid.height,
            equipment_categories = grid.equipment_categories
        }
    })
end

-- Upgrade Bay Vehicles (hidden car entities with equipment grid) - one per quality level
local quality_names = {"common", "uncommon", "rare", "epic", "legendary"}
local grid_names = {
    "upgrade-bay-grid-common",
    "upgrade-bay-grid-uncommon", 
    "upgrade-bay-grid-rare",
    "upgrade-bay-grid-epic",
    "upgrade-bay-grid-legendary"
}

for i, quality in ipairs(quality_names) do
    data:extend({
        {
            type = "car",
            name = "upgrade-bay-vehicle-" .. quality,
            flags = {"hidden", "not-on-map", "placeable-off-grid"},
            icon = "__base__/graphics/icons/car.png",
            icon_size = 64,
            collision_box = {{-0.01, -0.01}, {0.01, 0.01}},
            selection_box = {{-0.01, -0.01}, {0.01, 0.01}},
            weight = 1,
            braking_force = 1,
            friction_force = 100,
            energy_per_hit_point = 1,
            effectivity = 0,
            consumption = "1W",
            rotation_speed = 0,
            inventory_size = 0,
            equipment_grid = grid_names[i],
            energy_source = {type = "void"},
            animation = {
                layers = {
                    {
                        filename = "__base__/graphics/entity/car/car-1.png",
                        priority = "low",
                        width = 1,
                        height = 1,
                        frame_count = 1,
                        direction_count = 1,
                        scale = 0.01
                    }
                }
            },
            allow_remote_driving = false
        }
    })
end

-- =============================================================================
-- EQUIPMENT MODULES - Building Capacity Modules
-- =============================================================================

-- Helper function to create equipment module
local function create_equipment_module(params)
    return {
        type = "active-defense-equipment",
        name = params.name,
        sprite = {
            filename = params.icon or "__base__/graphics/equipment/battery-mk2-equipment.png",
            width = 64,
            height = 64,
            priority = "medium"
        },
        shape = {
            width = params.width or 2,
            height = params.height or 2,
            type = "full"
        },
        energy_source = {
            type = "void",
            usage_priority = "secondary-input"
        },
        automatic = false,
        attack_parameters = {
            type = "projectile",
            ammo_category = "melee",
            cooldown = 1,
            range = 0,
            ammo_type = {
                category = "melee",
                target_type = "entity",
                action = {
                    type = "direct",
                    action_delivery = {
                        type = "instant"
                    }
                }
            }
        },
        categories = {"upgrade-module"}
    }
end

-- Construction Core Module (+40 total building limit, cap +200)
data:extend({
    create_equipment_module({
        name = "construction-core-module",
        width = 2,
        height = 2,
        icon = "__base__/graphics/equipment/solar-panel-equipment.png"
    })
})

-- Supply Core Module (+20 power/roboport/storage entities, cap +120)
data:extend({
    create_equipment_module({
        name = "supply-core-module",
        width = 2,
        height = 2,
        icon = "__base__/graphics/equipment/battery-equipment.png"
    })
})

-- Manufacturing Core Module (+24 machines, cap +144)
data:extend({
    create_equipment_module({
        name = "manufacturing-core-module",
        width = 2,
        height = 2,
        icon = "__base__/graphics/equipment/energy-shield-equipment.png"
    })
})

-- Logistics Core Module (+30 chests/belts/inserters/pipes, cap +180)
data:extend({
    create_equipment_module({
        name = "logistics-core-module",
        width = 2,
        height = 2,
        icon = "__base__/graphics/equipment/battery-mk2-equipment.png"
    })
})

-- Defense Core Module (+16 turrets/shields/defense, cap +96)
data:extend({
    create_equipment_module({
        name = "defense-core-module",
        width = 1,
        height = 2,
        icon = "__base__/graphics/equipment/personal-laser-defense-equipment.png"
    })
})

-- =============================================================================
-- SPECIAL EQUIPMENT MODULES
-- =============================================================================

-- Thruster Efficiency Booster (+10% thrust, cap +50%)
data:extend({
    create_equipment_module({
        name = "thruster-efficiency-booster",
        width = 2,
        height = 2,
        icon = "__base__/graphics/equipment/exoskeleton-equipment.png"
    })
})

-- Pod Throughput Optimizer (+10% pod transfer speed, cap +50%)
data:extend({
    create_equipment_module({
        name = "pod-throughput-optimizer",
        width = 2,
        height = 2,
        icon = "__base__/graphics/equipment/belt-immunity-equipment.png"
    })
})

-- Pod Payload Compressor (+5% effective payload, cap +25%)
data:extend({
    create_equipment_module({
        name = "pod-payload-compressor",
        width = 2,
        height = 2,
        icon = "__base__/graphics/equipment/battery-mk2-equipment.png"
    })
})

-- Docking Buffer Extension (+1 simultaneous dock, cap +3)
data:extend({
    create_equipment_module({
        name = "docking-buffer-extension",
        width = 2,
        height = 2,
        icon = "__base__/graphics/equipment/fusion-reactor-equipment.png"
    })
})

-- Asteroid Shield Matrix (-10% platform damage, cap -60%)
data:extend({
    create_equipment_module({
        name = "asteroid-shield-matrix",
        width = 2,
        height = 2,
        icon = "__base__/graphics/equipment/energy-shield-mk2-equipment.png"
    })
})

-- Signal Multiplexer (+8 virtual control signals, cap +32)
data:extend({
    create_equipment_module({
        name = "signal-multiplexer",
        width = 2,
        height = 2,
        icon = "__base__/graphics/equipment/night-vision-equipment.png"
    })
})

-- =============================================================================
-- EQUIPMENT MODULE ITEMS
-- =============================================================================

local module_items = {
    {name = "construction-core-module", stack_size = 10},
    {name = "supply-core-module", stack_size = 10},
    {name = "manufacturing-core-module", stack_size = 10},
    {name = "logistics-core-module", stack_size = 10},
    {name = "defense-core-module", stack_size = 10},
    {name = "thruster-efficiency-booster", stack_size = 10},
    {name = "pod-throughput-optimizer", stack_size = 10},
    {name = "pod-payload-compressor", stack_size = 10},
    {name = "docking-buffer-extension", stack_size = 10},
    {name = "asteroid-shield-matrix", stack_size = 10},
    {name = "signal-multiplexer", stack_size = 10}
}

for _, item in ipairs(module_items) do
    data:extend({
        {
            type = "item",
            name = item.name,
            icon = "__base__/graphics/icons/processing-unit.png",
            icon_size = 64,
            subgroup = "equipment",
            order = "z[" .. item.name .. "]",
            stack_size = item.stack_size,
            placed_as_equipment_result = item.name
        }
    })
end

-- =============================================================================
-- EQUIPMENT MODULE RECIPES
-- =============================================================================

local module_recipes = {
    {name = "construction-core-module", ingredients = {{"iron-plate", 50}, {"copper-cable", 30}}},
    {name = "supply-core-module", ingredients = {{"iron-plate", 50}, {"battery", 20}}},
    {name = "manufacturing-core-module", ingredients = {{"steel-plate", 40}, {"electronic-circuit", 30}}},
    {name = "logistics-core-module", ingredients = {{"steel-plate", 40}, {"advanced-circuit", 20}}},
    {name = "defense-core-module", ingredients = {{"steel-plate", 30}, {"laser-turret", 5}}},
    {name = "thruster-efficiency-booster", ingredients = {{"processing-unit", 20}, {"rocket-fuel", 10}}},
    {name = "pod-throughput-optimizer", ingredients = {{"processing-unit", 15}, {"low-density-structure", 10}}},
    {name = "pod-payload-compressor", ingredients = {{"processing-unit", 15}, {"battery", 20}}},
    {name = "docking-buffer-extension", ingredients = {{"processing-unit", 25}, {"steel-plate", 50}}},
    {name = "asteroid-shield-matrix", ingredients = {{"processing-unit", 20}, {"energy-shield-equipment", 5}}},
    {name = "signal-multiplexer", ingredients = {{"processing-unit", 10}, {"copper-cable", 50}}}
}

for _, recipe in ipairs(module_recipes) do
    data:extend({
        {
            type = "recipe",
            name = recipe.name,
            enabled = false,
            energy_required = 10,
            ingredients = recipe.ingredients,
            results = {{type = "item", name = recipe.name, amount = 1}}
        }
    })
end

-- =============================================================================
-- RESEARCH TECHNOLOGIES FOR MODULES
-- =============================================================================

-- Base upgrade bay technology (unlocked with spaceship construction)
data:extend({
    {
        type = "technology",
        name = "upgrade-bay-system",
        icon = "__base__/graphics/technology/military.png",
        icon_size = 256,
        effects = {
            {type = "unlock-recipe", recipe = "construction-core-module"},
            {type = "unlock-recipe", recipe = "supply-core-module"}
        },
        prerequisites = {"spaceship-construction"},
        unit = {
            count = 500,
            ingredients = {
                {"automation-science-pack", 1},
                {"logistic-science-pack", 1},
                {"chemical-science-pack", 1},
                {"production-science-pack", 1},
                {"utility-science-pack", 1},
                {"space-science-pack", 1}
            },
            time = 30
        },
        order = "e-g-a"
    }
})

-- Fulgora: Pod Throughput Optimizer
data:extend({
    {
        type = "technology",
        name = "pod-throughput-optimization",
        icon = "__base__/graphics/technology/logistic-system.png",
        icon_size = 256,
        effects = {
            {type = "unlock-recipe", recipe = "pod-throughput-optimizer"}
        },
        prerequisites = {"upgrade-bay-system", "planet-discovery-fulgora"},
        unit = {
            count = 1000,
            ingredients = {
                {"automation-science-pack", 1},
                {"logistic-science-pack", 1},
                {"chemical-science-pack", 1},
                {"production-science-pack", 1},
                {"utility-science-pack", 1},
                {"space-science-pack", 1},
                {"electromagnetic-science-pack", 1}
            },
            time = 30
        },
        order = "e-g-b"
    }
})

-- Vulcanus: Manufacturing Core
data:extend({
    {
        type = "technology",
        name = "advanced-manufacturing-cores",
        icon = "__base__/graphics/technology/advanced-material-processing.png",
        icon_size = 256,
        effects = {
            {type = "unlock-recipe", recipe = "manufacturing-core-module"}
        },
        prerequisites = {"upgrade-bay-system", "planet-discovery-vulcanus"},
        unit = {
            count = 1000,
            ingredients = {
                {"automation-science-pack", 1},
                {"logistic-science-pack", 1},
                {"chemical-science-pack", 1},
                {"production-science-pack", 1},
                {"utility-science-pack", 1},
                {"space-science-pack", 1},
                {"metallurgic-science-pack", 1}
            },
            time = 30
        },
        order = "e-g-c"
    }
})

-- Gleba: Logistics Core
data:extend({
    {
        type = "technology",
        name = "advanced-logistics-cores",
        icon = "__base__/graphics/technology/logistics-2.png",
        icon_size = 256,
        effects = {
            {type = "unlock-recipe", recipe = "logistics-core-module"}
        },
        prerequisites = {"upgrade-bay-system", "planet-discovery-gleba"},
        unit = {
            count = 1000,
            ingredients = {
                {"automation-science-pack", 1},
                {"logistic-science-pack", 1},
                {"chemical-science-pack", 1},
                {"production-science-pack", 1},
                {"utility-science-pack", 1},
                {"space-science-pack", 1},
                {"agricultural-science-pack", 1}
            },
            time = 30
        },
        order = "e-g-d"
    }
})

-- Aquilo: Asteroid Shield Matrix & Defense Core
data:extend({
    {
        type = "technology",
        name = "asteroid-defense-systems",
        icon = "__base__/graphics/technology/laser.png",
        icon_size = 256,
        effects = {
            {type = "unlock-recipe", recipe = "asteroid-shield-matrix"},
            {type = "unlock-recipe", recipe = "defense-core-module"}
        },
        prerequisites = {"upgrade-bay-system", "planet-discovery-aquilo"},
        unit = {
            count = 1500,
            ingredients = {
                {"automation-science-pack", 1},
                {"logistic-science-pack", 1},
                {"chemical-science-pack", 1},
                {"production-science-pack", 1},
                {"utility-science-pack", 1},
                {"space-science-pack", 1},
                {"cryogenic-science-pack", 1}
            },
            time = 30
        },
        order = "e-g-e"
    }
})

-- Advanced modules (require multiple planets)
data:extend({
    {
        type = "technology",
        name = "advanced-upgrade-systems",
        icon = "__base__/graphics/technology/rocket-silo.png",
        icon_size = 256,
        effects = {
            {type = "unlock-recipe", recipe = "thruster-efficiency-booster"},
            {type = "unlock-recipe", recipe = "pod-payload-compressor"},
            {type = "unlock-recipe", recipe = "docking-buffer-extension"},
            {type = "unlock-recipe", recipe = "signal-multiplexer"}
        },
        prerequisites = {
            "pod-throughput-optimization",
            "advanced-manufacturing-cores",
            "advanced-logistics-cores",
            "asteroid-defense-systems"
        },
        unit = {
            count = 2000,
            ingredients = {
                {"automation-science-pack", 1},
                {"logistic-science-pack", 1},
                {"chemical-science-pack", 1},
                {"production-science-pack", 1},
                {"utility-science-pack", 1},
                {"space-science-pack", 1},
                {"electromagnetic-science-pack", 1},
                {"metallurgic-science-pack", 1},
                {"agricultural-science-pack", 1},
                {"cryogenic-science-pack", 1}
            },
            time = 60
        },
        order = "e-g-f"
    }
})
