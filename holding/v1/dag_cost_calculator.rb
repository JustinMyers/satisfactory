require "yaml"

@items = YAML.load_file("satisfactory_items.yml")
@recipes = YAML.load_file("satisfactory_recipes.yml")
@buildings = YAML.load_file("satisfactory_buildings.yml")

@logging = true

def log(message)
  puts message if @logging
end

def log_object(obj)
  pp obj if @logging
end

@items.reject! do |item|
  [
    "Lizard Doggo",
    "Dark Matter",
    "Vines",
    "No item in foliage",
    "Adequate Pioneering",
    "Boom Box",
    "Cup",
    "Hard Drive",
    "Mercer Sphere",
    "Somersloop",
    "Alien DNA Capsule",
  ].include?(item[:name])
end

@recipes.reject! do |recipe|
  [
    "Biomass (Alien Protein)",
    "Alien DNA Capsule",
  ].include?(recipe[:name]) or false
  # [
  #   "Equipment Workshop",
  # ].include?(recipe[:building].first)
end

@items.each do |item|
  if item[:sink_value].to_i == 0
    item[:sink_value] = nil
  end
end

# replace coal and crude oil from recipes.
bonus_recipes = [
  { name: "Iron Ore",
    alternate: false,
    building: ["Miner", 1],
    products: [[1, "Iron Ore"]],
    ingredients: [],
    sink_cost: nil },
  { name: "Coal",
    alternate: false,
    building: ["Miner", 1],
    products: [[1, "Coal"]],
    ingredients: [],
    sink_cost: nil },
  { name: "Copper Ore",
    alternate: false,
    building: ["Miner", 1],
    products: [[1, "Copper Ore"]],
    ingredients: [],
    sink_cost: nil },
  { name: "Limestone",
    alternate: false,
    building: ["Miner", 1],
    products: [[1, "Limestone"]],
    ingredients: [],
    sink_cost: nil },
  { name: "Sulfur",
    alternate: false,
    building: ["Miner", 1],
    products: [[1, "Sulfur"]],
    ingredients: [],
    sink_cost: nil },
  { name: "Raw Quartz",
    alternate: false,
    building: ["Miner", 1],
    products: [[1, "Raw Quartz"]],
    ingredients: [],
    sink_cost: nil },
  { name: "Caterium Ore",
    alternate: false,
    building: ["Miner", 1],
    products: [[1, "Caterium Ore"]],
    ingredients: [],
    sink_cost: nil },
  { name: "Uranium",
    alternate: false,
    building: ["Miner", 1],
    products: [[1, "Uranium"]],
    ingredients: [],
    sink_cost: nil },
  { name: "Bauxite",
    alternate: false,
    building: ["Miner", 1],
    products: [[1, "Bauxite"]],
    ingredients: [],
    sink_cost: nil },
  { name: "Nitrogen Gas",
    alternate: false,
    building: ["Resource Well Extractor", 1],
    products: [[1, "Nitrogen Gas"]],
    ingredients: [],
    sink_cost: nil },
  { name: "Crude Oil",
    alternate: false,
    building: ["Oil Extractor", 1],
    products: [[1, "Crude Oil"]],
    ingredients: [],
    sink_cost: nil },
  { name: "Hog Remains", building: ["Gather", 1], products: [[1, "Hog Remains"]], ingredients: [], alternate: false },
  { name: "Mycelia", building: ["Gather", 1], products: [[1, "Mycelia"]], ingredients: [], alternate: false },
  { name: "Wood", building: ["Gather", 1], products: [[1, "Wood"]], ingredients: [], alternate: false },
  { name: "Leaves", building: ["Gather", 1], products: [[1, "Leaves"]], ingredients: [], alternate: false },
  { name: "Paleberry", building: ["Gather", 1], products: [[1, "Paleberry"]], ingredients: [], alternate: false },
  { name: "Bacon Agaric", building: ["Gather", 1], products: [[1, "Bacon Agaric"]], ingredients: [], alternate: false },
  { name: "Beryl Nut", building: ["Gather", 1], products: [[1, "Beryl Nut"]], ingredients: [], alternate: false },
  { name: "Flower Petals", building: ["Gather", 1], products: [[1, "Flower Petals"]], ingredients: [], alternate: false },
]

@recipes = @recipes + bonus_recipes

def get_recipe(name)
  @recipes.detect { |r| r[:name] == name }
end

def get_item(name)
  @items.detect { |r| r[:name] == name }
end

bonus_items = []

@recipes.each do |recipe|
  recipe[:products].each do |quantity, product_name|
    if get_item(product_name).nil? and !product_name.include?("FICSMAS") and recipe[:building].first != "Build Gun"
      # Make a new fake item.
      bonus_items << {
        name: product_name,
        sink_value: 1,
        energy: 0,
      }
    end
  end
end

@items = @items + bonus_items

@recipes.reject! { |r|
  ["Fabric", "Portable Miner"].include?(r[:name])
}

@recipes.reject! do |recipe|
  skip_it_product, skip_it_ingredient, skip_it_build_gun = false
  skip_it_build_gun = recipe[:building].first == "Build Gun"
  recipe[:products].each do |quantity, product_name|
    skip_it_product = get_item(product_name).nil?
  end
  recipe[:ingredients].each do |quantity, ingredient_name|
    skip_it_ingredient = get_item(ingredient_name).nil?
  end

  skip_alternate_recipes = false
  skip_it_alternate = recipe[:alternate] && skip_alternate_recipes

  skip_it_product || skip_it_ingredient || skip_it_build_gun || skip_it_alternate
end

def set_recipe_sink_value(recipe)
  product_values = 0
  recipe[:products].each do |quantity, product_name|
    product = get_item(product_name)
    product_values += product[:sink_value].to_i * quantity
  end
  if product_values > 0
    recipe[:sink_value] = product_values
  end
end

def set_recipe_sink_cost(recipe)
  ingredient_costs = 0
  recipe[:ingredients].each do |quantity, ingredient_name|
    ingredient = get_item(ingredient_name)
    ingredient_costs += ingredient[:sink_value].to_i * quantity
  end
  if ingredient_costs > 0
    recipe[:sink_cost] = ingredient_costs
  end
end

# or polymer resin
# TODO: this does funny things when the products have variable quantities like Empty Fluid Tanks
def set_item_sink_cost(item)
  ways_to_make_it = @recipes.select { |r| r[:products].map { |p| p.last }.include?(item[:name]) }
  sink_costs = ways_to_make_it.map do |r|
    product_quantities = r[:products].map { |p| p.first }.sum
    if r[:sink_cost]
      [r[:sink_cost] / product_quantities.to_f, r[:name], r[:alternate]]
    end
  end.compact
  item[:sink_cost] = sink_costs.sort { |a, b| a.first <=> b.first }.first
end

def set_recipe_energy(recipe)
  building_name, building_seconds = recipe[:building]
  building_energy_in_MW = @buildings.detect { |b| b.first == building_name }.last
  conversion_MJ_to_MW = 0.0002777778
  building_energy_in_MJ = building_energy_in_MW / conversion_MJ_to_MW
  building_mj_per_second = building_energy_in_MJ / 60.0 / 60.0
  recipe[:mj_cost] = building_seconds * building_mj_per_second
end

@items.each do |item|
  item[:sink_cost] = nil
  item[:build_cost] = nil
  set_item_sink_cost(item)
end

@recipes.each do |recipe|
  recipe[:sink_value] = nil
  recipe[:sink_cost] = nil
  recipe[:build_cost] = nil
  set_recipe_sink_value(recipe)
  set_recipe_sink_cost(recipe)
  set_recipe_energy(recipe)
end

def get_recipe_ingredients(recipe, recipe_history)
  recipe_ingredients = recipe[:ingredients].map { |i| get_item(i.last) }
  recipe_ingredients.map! { |i| calculate_item(i, recipe_history) }
end

def calculate_recipe(recipe, recipe_history)
  ingredients = get_recipe_ingredients(recipe, recipe_history)

  if ingredients.include?(nil)
    log("Calculate recipe: #{recipe[:name]} returning nil because an ingredient couldn't be made.")
    return nil
  end

  build_cost = 0
  energy_cost = 0
  if ingredients.empty? and recipe[:products].count == 1
    recipe[:products].each do |quantity, product_name|
      product = get_item(product_name)
      if product_name == "Water"
        build_cost = 0
        energy_cost = 20 # divided by 2 later
      else
        if product[:mined_per_second]
          build_cost = 1 / product[:mined_per_second].to_f * 10000
        else
          build_cost = 0
        end
        # Uranium is more valuable than its rarity suggests.
        if product[:name] == "Uranium"
          build_cost = build_cost * 10
        end
        if product[:mj_cost]
          energy_cost = product[:mj_cost]
        end
      end
    end
  else
    if ["Recycled Rubber", "Recycled Plastic"].include?(recipe[:name])
      recipe[:ingredients].each do |quantity, ingredient_name|
        if ingredient_name == "Fuel"
          ingredient = ingredients.detect { |i| i[:name] == ingredient_name }
          build_cost += ingredient[:build_cost][0] * quantity
          energy_cost += ingredient[:build_cost][1] * quantity
          # add the opportunity cost of energy.
          # if ingredient[:energy]
          #   energy_cost += ingredient[:energy] * quantity
          # end
        else
          ingredient = ingredients.detect { |i| i[:name] == ingredient_name }
          energy_cost += ingredient[:build_cost][1] * quantity
        end
      end
      energy_cost = energy_cost + recipe[:mj_cost]
    else
      recipe[:ingredients].each do |quantity, ingredient_name|
        ingredient = ingredients.detect { |i| i[:name] == ingredient_name }
        build_cost += ingredient[:build_cost][0] * quantity
        energy_cost += ingredient[:build_cost][1] * quantity
        # add the opportunity cost of energy.
        # if ingredient[:energy] and recipe[:building].first != "Nuclear Power Plant" and !["Battery", "Heavy Oil Residue", "Fabric"].include?(ingredient_name)
        #   energy_cost += ingredient[:energy] * quantity
        # end
      end
      energy_cost = energy_cost + recipe[:mj_cost]
    end
  end
  recipe[:build_cost] = build_cost
  recipe[:energy_cost] = energy_cost
  recipe[:build_costs] = {}
  recipe[:energy_costs] = {}
  recipe[:products].each do |quantity, product_name|
    recipe[:build_costs][product_name] = build_cost / quantity.to_f
    recipe[:energy_costs][product_name] = energy_cost / quantity.to_f
  end

  store_recipe(recipe) # if recipe_history.count == 1
  recipe
end

def get_item_recipes(item, recipe_history)
  source = nil
  item_recipes = @recipes.select do |recipe|
    produces_item = recipe[:products].detect do |product|
      product.last == item[:name]
    end
    if produces_item and recipe[:ingredients].empty?
      source = recipe
    end
    !recipe_history.include?(recipe[:name]) and produces_item
  end
  return [source] if source
  item_recipes.reject! { |r| r[:name].include?("Unpackage") }
  # item_recipes.reject! { |r| r[:name].include?("Pure") }
  item_recipes
end

def calculate_item(item, recipe_history = [])
  item_recipes = get_item_recipes(item, recipe_history)
  # log("Fetched recipes for #{item[:name].ljust(20)} with history: #{recipe_history}")
  # log_object(item_recipes.map { |i| i[:name] })

  if item_recipes.empty?
    log("Calculate item: #{item[:name]} returning nil because no recipes could be found.")
    return nil
  end

  item_recipes.map! { |r| calculate_recipe(r, recipe_history + [r[:name]]) }

  if item_recipes.include?(nil)
    log("Calculate item: #{item[:name]} returning nil a recipe could not be completed.")
    return nil
  end

  item[:build_cost] = item_recipes.map do |r|
    [
      r[:build_costs][item[:name]],
      r[:energy_costs][item[:name]],
      r[:name],
      r[:alternate],
    ]
  end.sort { |a, b| true_cost(a) <=> true_cost(b) }.first

  store_item(item) # if recipe_history.empty?
  item
end

def true_cost(recipe_array)
  build_cost, energy_cost = recipe_array
  energy_to_build_cost_ratio = 36.4 # fuel energy / build_cost
  build_cost + energy_cost / energy_to_build_cost_ratio
end

@calculated_recipes = {}
@calculated_items = {}

def store_item(item)
  if @calculated_items[item[:name]].nil?
    @calculated_items[item[:name]] = item.dup
  else
    if (true_cost(@calculated_items[item[:name]][:build_cost]) > true_cost(item[:build_cost]))
      @calculated_items[item[:name]] = item.dup
    end
  end
end

def store_recipe(recipe)
  recipe[:true_cost] = true_cost([recipe[:build_cost], recipe[:energy_cost]])
  recipe[:true_costs] = {}
  recipe[:products].each do |quantity, product_name|
    recipe[:true_costs][product_name] = true_cost([recipe[:build_costs][product_name], recipe[:energy_costs][product_name]])
  end
  existing = @calculated_recipes[recipe[:name]]
  if existing.nil?
    @calculated_recipes[recipe[:name]] = recipe.dup
  else
    if existing[:true_cost] > recipe[:true_cost]
      # log("Updating Recipe: #{recipe[:name]}")
      @calculated_recipes[recipe[:name]] = recipe.dup
    end
  end
end

@items.shuffle.each do |item|
  calculate_item(item)
end

File.write("calculated_satisfactory_items.yml", @calculated_items.values.to_yaml)
File.write("calculated_satisfactory_recipes.yml", @calculated_recipes.values.to_yaml)
