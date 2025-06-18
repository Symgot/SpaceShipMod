-- =============================================================================
-- FINAL FIXES - Run after all mods have loaded their data
-- =============================================================================

-- Replace power-armor-mk2 with spaceship-armor in ALL recipes across all mods
local function replace_power_armor_mk2_globally()
    if not data.raw.recipe then return end
    
    log("SpaceShipMod: Starting global power-armor-mk2 replacement...")
    local replacements = 0
    
    for recipe_name, recipe in pairs(data.raw.recipe) do
        local function process_ingredients(ingredients)
            if not ingredients then return end
            
            for i, ingredient in ipairs(ingredients) do
                if type(ingredient) == "table" then
                    -- Format: {name = "item", amount = 1}
                    if ingredient.name == "power-armor-mk2" then
                        ingredient.name = "spaceship-armor"
                        replacements = replacements + 1
                        log("SpaceShipMod: Replaced power-armor-mk2 in recipe: " .. recipe_name)
                    -- Format: {"item", amount}
                    elseif ingredient[1] == "power-armor-mk2" then
                        ingredient[1] = "spaceship-armor"
                        replacements = replacements + 1
                        log("SpaceShipMod: Replaced power-armor-mk2 in recipe: " .. recipe_name)
                    end
                end
            end
        end
        
        -- Process main ingredients
        process_ingredients(recipe.ingredients)
        
        -- Process normal difficulty ingredients
        if recipe.normal then
            process_ingredients(recipe.normal.ingredients)
        end
        
        -- Process expensive difficulty ingredients
        if recipe.expensive then
            process_ingredients(recipe.expensive.ingredients)
        end
    end
    
    log("SpaceShipMod: Completed global replacement. Total replacements: " .. replacements)
end

-- Replace power-armor-mk2 in technology unlock effects
local function replace_power_armor_mk2_in_technologies()
    if not data.raw.technology then return end
    
    log("SpaceShipMod: Checking technology unlock effects...")
    local tech_replacements = 0
    
    for tech_name, tech in pairs(data.raw.technology) do
        if tech.effects then
            for _, effect in pairs(tech.effects) do
                if effect.type == "unlock-recipe" and effect.recipe == "power-armor-mk2" then
                    effect.recipe = "spaceship-armor"
                    tech_replacements = tech_replacements + 1
                    log("SpaceShipMod: Replaced power-armor-mk2 unlock in technology: " .. tech_name)
                end
            end
        end
    end
    
    log("SpaceShipMod: Technology replacements completed. Total: " .. tech_replacements)
end

-- Execute the replacements
replace_power_armor_mk2_globally()
replace_power_armor_mk2_in_technologies()

log("SpaceShipMod: All power-armor-mk2 replacements completed successfully!")
