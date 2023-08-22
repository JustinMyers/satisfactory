# require "yaml"

# @items = YAML.load_file("satisfactory_items.yml")
# @recipes = YAML.load_file("satisfactory_recipes.yml")

# @items.reject! do |item|
#   [
#     "Lizard Doggo",
#     "Dark Matter",
#     "Vines",
#     "No item in foliage",
#     "Adequate Pioneering",
#     "Boom Box",
#     "Cup",
#     "Hard Drive",
#     "Mercer Sphere",
#     "Somersloop",
#   ].include?(item[:name])
# end

# @items.each do |item|
#   if item[:sink_value].to_i == 0
#     item[:sink_value] = nil
#   end
# end

# bonus_recipes = [
#   { name: "Iron Ore",
#     alternate: false,
#     building: ["Miner Mk.3", 1],
#     products: [[12, "Iron Ore"]],
#     ingredients: [],
#     sink_cost: nil },
#   { name: "Copper Ore",
#     alternate: false,
#     building: ["Miner Mk.3", 1],
#     products: [[12, "Copper Ore"]],
#     ingredients: [],
#     sink_cost: nil },
#   { name: "Limestone",
#     alternate: false,
#     building: ["Miner Mk.3", 1],
#     products: [[12, "Limestone"]],
#     ingredients: [],
#     sink_cost: nil },
#   { name: "Sulfur",
#     alternate: false,
#     building: ["Miner Mk.3", 1],
#     products: [[12, "Sulfur"]],
#     ingredients: [],
#     sink_cost: nil },
#   { name: "Raw Quartz",
#     alternate: false,
#     building: ["Miner Mk.3", 1],
#     products: [[12, "Raw Quartz"]],
#     ingredients: [],
#     sink_cost: nil },
#   { name: "Caterium Ore",
#     alternate: false,
#     building: ["Miner Mk.3", 1],
#     products: [[12, "Caterium Ore"]],
#     ingredients: [],
#     sink_cost: nil },
#   { name: "Uranium",
#     alternate: false,
#     building: ["Miner Mk.3", 1],
#     products: [[12, "Uranium"]],
#     ingredients: [],
#     sink_cost: nil },
#   { name: "Bauxite",
#     alternate: false,
#     building: ["Miner Mk.3", 1],
#     products: [[12, "Bauxite"]],
#     ingredients: [],
#     sink_cost: nil },
#   { name: "Nitrogen Gas",
#     alternate: false,
#     building: ["Resource Well Extractor", 1],
#     products: [[2, "Nitrogen Gas"]],
#     ingredients: [],
#     sink_cost: nil },
# ]

# @recipes = @recipes + bonus_recipes

# def get_recipe(name)
#   @recipes.detect { |r| r[:name] == name }
# end

# def get_item(name)
#   @items.detect { |r| r[:name] == name }
# end

# def set_recipe_sink_value(recipe)
#   product_values = 0
#   recipe[:products].each do |quantity, product_name|
#     product = get_item(product_name)
#     product_values += product[:sink_value].to_i * quantity
#   end
#   if product_values > 0
#     recipe[:sink_value] = product_values
#   end
# end

# def set_recipe_sink_cost(recipe)
#   ingredient_costs = 0
#   recipe[:ingredients].each do |quantity, ingredient_name|
#     ingredient = get_item(ingredient_name)
#     ingredient_costs += ingredient[:sink_value].to_i * quantity
#   end
#   if ingredient_costs > 0
#     recipe[:sink_cost] = ingredient_costs
#   end
# end

# def set_recipe_build_cost(recipe)
#   if !recipe[:ingredients].empty?
#     missing_build_cost = false
#     build_cost = 0
#     recipe[:ingredients].each do |quantity, ingredient_name|
#       ingredient = get_item(ingredient_name)
#       if ingredient[:build_cost]
#         build_cost += ingredient[:build_cost].first * quantity
#       else
#         missing_build_cost = true
#       end
#     end
#     unless missing_build_cost
#       recipe[:build_cost] = build_cost
#     end
#   end
# end

# def set_item_sink_cost(item)
#   ways_to_make_it = @recipes.select { |r| r[:products].map { |p| p.last }.include?(item[:name]) }
#   sink_costs = ways_to_make_it.map do |r|
#     product_quantities = r[:products].map { |p| p.first }.sum
#     if r[:sink_cost]
#       [r[:sink_cost] / product_quantities.to_f, r[:name], r[:alternate]]
#     end
#   end.compact
#   item[:sink_cost] = sink_costs.sort { |a, b| a.first <=> b.first }.first
# end

# def set_item_build_cost(item)
#   source = nil
#   ways_to_make_it = @recipes.select { |r| r[:products].map { |p| p.last }.include?(item[:name]) }
#   build_costs = ways_to_make_it.map do |r|
#     product_quantities = r[:products].map { |p| p.first }.sum
#     if r[:ingredients].empty?
#       source = [r[:sink_value] / product_quantities.to_f, r[:name], r[:alternate]]
#     else
#       if r[:build_cost]
#         build_cost = r[:build_cost] / product_quantities.to_f
#         if build_cost > 0
#           [build_cost, r[:name], r[:alternate]]
#         end
#       end
#     end
#   end.compact
#   if source
#     item[:build_cost] = source
#   elsif item[:build_cost].nil?
#     item[:build_cost] = build_costs.sort { |a, b| a.first <=> b.first }.first
#   else
#     cheapest = build_costs.sort { |a, b| a.first <=> b.first }.first
#     if cheapest[1] != item[:build_cost][1]
#       item[:build_cost] = cheapest
#     end
#   end
# end

# @logging = false

# def log(message)
#   if @logging
#     pp message
#   end
# end

# @recipes.reject! do |recipe|
#   skip_it_product, skip_it_ingredient, skip_it_build_gun = false
#   skip_it_build_gun = recipe[:building].first == "Build Gun"
#   recipe[:products].each do |quantity, product_name|
#     skip_it_product = get_item(product_name).nil?
#   end
#   recipe[:ingredients].each do |quantity, ingredient_name|
#     skip_it_ingredient = get_item(ingredient_name).nil?
#   end
#   skip_it_product || skip_it_ingredient || skip_it_build_gun
# end

# @items.each do |item|
#   item[:sink_cost] = nil
#   item[:build_cost] = nil
# end

# @recipes.each do |recipe|
#   recipe[:sink_cost] = nil
#   recipe[:build_cost] = nil
#   set_recipe_sink_value(recipe)
#   set_recipe_sink_cost(recipe)
# end

# anything_changed = true
# while anything_changed
#   anything_changed = false

#   item_changed = true
#   while item_changed
#     log("changing items")
#     @items.each do |item|
#       item_changed = false
#       isc = item[:sink_cost]
#       set_item_sink_cost(item)
#       item_sink_cost_changed = isc != item[:sink_cost]
#       if item_sink_cost_changed and @logging
#         log("Item sink cost changed: #{item[:name]}")
#         pp isc
#         pp item[:sink_cost]
#       end

#       ibc = item[:build_cost]
#       set_item_build_cost(item)
#       item_build_cost_changed = ibc != item[:build_cost]
#       if item_build_cost_changed and @logging
#         log("Item build cost changed: #{item[:name]}")
#         pp ibc
#         pp item[:build_cost]
#       end
#       item_changed = item_sink_cost_changed || item_build_cost_changed
#       anything_changed = item_changed || anything_changed
#     end

#     recipe_changed = true
#     while recipe_changed
#       log("changing recipes")
#       @recipes.each do |recipe|
#         recipe_changed = false
#         #   rsc = recipe[:sink_cost]
#         #   set_recipe_sink_cost(recipe)
#         #   recipe_changed = rsc != recipe[:sink_cost]

#         rbc = recipe[:build_cost]
#         set_recipe_build_cost(recipe)
#         recipe_build_cost_changed = rbc != recipe[:build_cost]
#         if recipe_build_cost_changed and @logging
#           log("Recipe build cost changed: #{recipe[:name]}")
#           pp rbc
#           pp recipe[:build_cost]
#         end
#         recipe_changed = recipe_build_cost_changed
#         anything_changed = recipe_changed || anything_changed
#       end
#     end
#   end
# end

# File.write("calculated_satisfactory_items.yml", @items.to_yaml)
# File.write("calculated_satisfactory_recipes.yml", @recipes.to_yaml)
