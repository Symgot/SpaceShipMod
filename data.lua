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
        circuit_connector = data.raw["container"]["iron-chest"].circuit_connector,
        circuit_wire_max_distance = data.raw["container"]["iron-chest"].circuit_wire_max_distance,
        draw_circuit_wires = true,
        inventory_size = 50,
        create_ghost_on_death = true,
        surface_conditions = nil,
        collision_box = { { -3.8, -3.8 }, { 3.8, 3.8 } },
        selection_box = { { -3.8, -3.8 }, { 3.5, 3.8 } },
        minable = { mining_time = 0.2, result = "spaceship-control-hub" },
        picture = {
            layers = {
                {
                    filename = "__SpaceShipMod__/control-hub.png",
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
        weight = 1,
        braking_force = 1,
        friction_force = 100,
        energy_per_hit_point = 1,
        effectivity = 0,
        consumption = "1W",
        rotation_speed = 0,
        inventory_size = 1,
        energy_source = { type = "void" },
        allow_remote_driving = false,
        collision_box = { { -0.4, -0.05 }, { 0.4, 0.05 } },
    },
    {
        type = "space-platform-starter-pack",
        name = "space-ship-starter-pack",
        localised_name = "Space Platform Starter Pack",
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
        icon = "__SpaceShipMod__/control-hub.png",
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
