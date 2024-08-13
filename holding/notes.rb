# Examples on limiting available resources
# $resource_limits['Coal'] = 780
# $resource_limits['Iron Ore'] = 780
# $resource_limits['Copper Ore'] = 780

# def priority_list
#   products = [
#     'Screw',
#     'Screw',
#     'Screw',
#     'Screw'
#     # 'Uranium Fuel Rod',
#     # 'Plutonium Fuel Rod',
#     # 'Turbofuel',
#     # 'Turbofuel'
#   ]

#   products.each do |product|
#     recipes = $recipes.select { |r| r.product_name == product }

#     recipe = recipes[recipes.map(&:max_production).each_with_index.max[1]]

#     recipe_report(recipe, true)

#     $resource_limits[product] = recipe.max_production

#     recipe.global_cost.each_pair do |resource, count|
#       $resource_limits[resource] -= count
#     end
#   end
# end

# priority_list

# recipes = $recipes.select { |r| r.product.first == 'Iron Plate' }

# recipes.each do |r|
#   # building_output = {}
#   # r.building_report(r.max_production, building_output)
#   # pp building_output
#   recipe_report(r, true)
#   # puts
# end

# recipes = $recipes.select { |r| r.product.first == "Aluminum Ingot" }
# recipes = $recipes.select { |r| r.product.first == "Reinforced Iron Plate" }
# recipes = $recipes.select { |r| r.product.first == "Copper Ingot" }
# recipes = $recipes.select { |r| r.product.first == "Steel Ingot" }

# item_names = [
#   ['Supercomputer', 5],
#   ['Fused Modular Frame', 10],
#   ['Turbo Motor', 3],
#   ['Battery', 40],
#   # ['Uranium Waste', 40]
#   ['Plutonium Waste', 2]
# ]

# building_report = {}

# item_names.each do |item_name, target_production|
#   recipes = $recipes.select { |r| r.product.first == item_name }
#   recipes.sort! { |a, b| b.max_production <=> a.max_production }
#   r = recipes.first
#   r.building_report(target_production, building_report)
# end

# puts "Total power consumption: #{$total_consumption} MW"

# pp building_report

# recipes = $recipes

# recipes.each do |recipe|
#   recipe_report(recipe.dup, true)
# end

# max_sink_value = 0
# sink_value_recipe = nil
# recipes.each do |recipe|
#   item_hash = @item_hashes.detect { |i| i["name"] == recipe.product_name }
#   total_sink_value = recipe.max_production * item_hash["sink_value"].to_i
#   if total_sink_value > max_sink_value
#     max_sink_value = total_sink_value
#     sink_value_recipe = recipe
#   end
#   if total_sink_value > 30000000
#     puts "#{recipe.name} sinks #{total_sink_value.round} points per minute."
#   end
# end

# recipe_report(sink_value_recipe)

# SORTED BY PRODUCT

# $recipes.sort! { |b, a| b.product_name <=> a.product_name }

# $recipes.each do |recipe|
#   recipe_report(recipe, true) # if $recipes.select { |r| r.product_name == recipe.product_name }.count > 1
# end

# NOTES

# satisfactorytools.com shows a strange combination of recipes for maximizing Iron Plate
# can I duplicate or beat this?

# put byproducts into global resource list?

# put energy into 'byproducts' or something?

# a permutation technique to find "best order of recipes for same product to maximize production"
# the Iron Plate problem.

# needed optimizations are global priority list of resources
# and ability to make output with more than one recipe

# The way to make an item is to find the combos that make the most,
# figure out how much they make,
# what the unit cost is over all recipes,
# what the production rates need to be.
