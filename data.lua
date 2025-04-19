local make_tile_area = function(area, name)
    local result = {}
    local left_top = area[1]
    local right_bottom = area[2]
    for x = left_top[1], right_bottom[1] do
        for y = left_top[2], right_bottom[2] do
            table.insert(result,
                {
                    position = { x, y },
                    tile = name
                })
        end
    end
    return result
end

local floorItem = table.deepcopy(data.raw["item"]["space-platform-foundation"])
local floorEntity = table.deepcopy(data.raw["tile"]["space-platform-foundation"])
local floorRecipe = table.deepcopy(data.raw["recipe"]["space-platform-foundation"])
local wallItem = table.deepcopy(data.raw["item"]["stone-wall"])
local wallRecipe = table.deepcopy(data.raw["recipe"]["stone-wall"])
local wallEntity = table.deepcopy(data.raw["wall"]["stone-wall"])
--local controlHubEntity = table.deepcopy(data.raw["container"]["steel-chest"])
local controlHubEntityHub = table.deepcopy(data.raw["space-platform-hub"]["space-platform-hub"])
local controlHubItem = table.deepcopy(data.raw["item"]["cargo-bay"])
local controlHubRecipe = table.deepcopy(data.raw["recipe"]["cargo-bay"])
--local controlHubEntityCar = table.deepcopy(data.raw["car"]["car"])
local controlHubItemCar = table.deepcopy(data.raw["item-with-entity-data"]["car"])

controlHubItemCar.name = "spaceship-control-hub-car"

controlHubItem.name = "spaceship-control-hub"
controlHubItem.localised_name = "Spaceship Control Hub"
controlHubItem.place_result = "spaceship-control-hub"
controlHubRecipe.name = "spaceship-control-hub"
controlHubRecipe.localised_name = "Spaceship Control Hub"
controlHubRecipe.ingredients = { { type = "item", name = "iron-plate", amount = 1 } }
controlHubRecipe.results = { { type = "item", name = "spaceship-control-hub", amount = 1 } }
controlHubRecipe.enabled = true

wallEntity.create_ghost_on_death = true
wallEntity.surface_conditions = nil
wallEntity.name = "spaceship-wall"
wallEntity.localised_name = "Spaceship Wall"
wallEntity.minable = { mining_time = 0.2, result = "spaceship-wall" }
wallItem.name = "spaceship-wall"
wallItem.localised_name = "Spaceship Wall"
wallItem.place_result = "spaceship-wall"
wallRecipe.name = "spaceship-wall"
wallRecipe.localised_name = "Spaceship Wall"
wallRecipe.ingredients = { { type = "item", name = "iron-plate", amount = 1 } }
wallRecipe.results = { { type = "item", name = "spaceship-wall", amount = 1 } }
wallRecipe.enabled = true

floorEntity.name = "spaceship-flooring"
floorEntity.minable = { mining_time = 0.2, result = "spaceship-flooring" }

floorItem.name = "spaceship-flooring"
floorItem.localised_name = "Spaceship Flooring"
floorItem.place_as_tile =
{ result = "spaceship-flooring", condition_size = 0, condition = { layers = {} } }

floorRecipe.name = "spaceship-flooring"
floorRecipe.localised_name = "Spaceship Flooring"
floorRecipe.ingredients = { { type = "item", name = "iron-plate", amount = 1 } }
floorRecipe.hidden = false
floorRecipe.enabled = true
floorRecipe.results = { { type = "item", name = "spaceship-flooring", amount = 10 } }
floorRecipe.main_product = "spaceship-flooring"

data:extend({
    {
        type                      = "container",
        name                      = "spaceship-control-hub",
        localised_name            = "Spaceship Control Hub",
        localised_description     = "Main control hub for the spaceship.",
        placeable_by              = data.raw["item"]["spaceship-control-hub"],
        flags                     = { "placeable-neutral", "player-creation", "not-rotatable" },
        icon                      = data.raw["space-platform-hub"]["space-platform-hub"].icon,
        circuit_connector         = data.raw["container"]["iron-chest"].circuit_connector,
        circuit_wire_max_distance = data.raw["container"]["iron-chest"].circuit_wire_max_distance,
        draw_circuit_wires        = true,
        inventory_size            = 50,
        create_ghost_on_death     = true,
        surface_conditions        = nil,
        collision_box             = { { -3.8, -3.8 }, { 3.8, 3.8 } },
        selection_box             = { { -3.8, -3.8 }, { 3.5, 3.8 } },
        minable                   = { mining_time = 0.2, result = "spaceship-control-hub" },
        picture                   = {
            layers =
            {
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
    {
        type = "surface",
        name = "space-ship-surface",
        icon = "__space-age__/graphics/icons/thruster.png",
        subgroup = "planets",
        order = "a[space-platform]",
        surface_properties =
        {
            gravity = 0,
            pressure = 0,
            ["magnetic-field"] = 0,
            ["day-night-cycle"] = 0
        }
    },
    {
        type = "recipe",
        name = "space-ship-starter-pack",
        localised_name = "Space Platform Starter Pack",
        ingredients = { { type = "item", name = "iron-plate", amount = 1 } },
        hidden = false,
        enabled = true,
        results = { { type = "item", name = "space-ship-starter-pack", amount = 10 } },
        main_product = "space-ship-starter-pack",
        icon = "__space-age__/graphics/icons/thruster.png",
        subgroup = "planets",
        order = "a[space-platform]",
        category = "crafting",
    },
    floorItem,
    floorRecipe,
    floorEntity,
    controlHubItem,
    controlHubRecipe,
    wallEntity,
    wallItem,
    wallRecipe,
    controlHubEntityHub,
    controlHubItemCar
})
