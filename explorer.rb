require "yaml"

@items = YAML.load_file("calculated_satisfactory_items.yml")
@recipes = YAML.load_file("calculated_satisfactory_recipes.yml")

def get_item(name)
  @items.detect { |i| i[:name] == name }
end

def get_recipe(name)
  @recipes.detect { |r| r[:name] == name }
end

def true_cost(item)
  build_cost, energy_cost = item[:build_cost]
  # 39 = Fuel
  # 36 = Uranium Fuel Rod
  # 26 = Plutonium Fuel Rod
  # 55 = MAGIC NUMBER
  energy_to_build_cost_ratio = 36.4 # fuel energy / build_cost
  build_cost + energy_cost / energy_to_build_cost_ratio
end

# mode = "energy"
mode = "costs"
# mode = ""

# @items.reject! { |i| i[:build_cost].nil? }

# @items.reject! { |i| i[:name].include?("Packaged") and i[:name] != "Packaged Fuel" and i[:name] != "Packaged Water" }

# @items.reject! { |i|
#   [
#     "Black Powder",
#     "Smokeless Powder",
#   ].include? i[:name]
# }

# puts "Rejecting these recipes because they're not used to efficiently build my items:"
recipe_names = @items.map { |i| i[:build_cost][2] }
@recipes.select! { |r|
  keep = recipe_names.include?(r[:name])
  # unless keep
  #   print "#{r[:name]} #{r[:alternate] ? "(alt)" : nil} - "
  #   puts r[:products].map { |p| p.last }.join(", ")
  # end
  keep
}

# puts "Rejecting these items because they're not used in the recipes I use:"
ingredient_names = []
@recipes.each do |r|
  ingredients = r[:ingredients].map { |i| i.last }
  ingredient_names += ingredients
end
ingredient_names.uniq!
@leaf_items = []
@items.select! { |i|
  keep = ingredient_names.include?(i[:name])
  # puts i[:name] if !keep
  if !keep
    @leaf_items << i
  end
  keep
}

def history(recipe_name, depth = 0, recipe_history = [])
  depth = depth + 1
  history = {}
  recipe = get_recipe(recipe_name)
  recipe[:ingredients].each do |quantity, ingredient_name|
    ingredient = get_item(ingredient_name)
    new_recipe = get_recipe(ingredient[:build_cost][2])
    if depth < 2 and !recipe_history.include?(new_recipe[:name])
      new_recipe_string = "#{new_recipe[:name]} #{new_recipe[:alternate] ? "(alt)" : nil}"
      history[new_recipe_string] = history(new_recipe[:name], depth, recipe_history + [recipe_name])
    else
    end
  end
  history
end

def print_history(history_hash, depth = 0)
  history_hash.each_pair do |key, value|
    print "  " * depth * 21
    puts key
    print_history(value, depth + 1)
  end
end

if mode == "costs"
  # puts "True cost  Build cost  Energy cost  Sink value  Item name                    Recipe name"
  puts "True cost  Item name                    Recipe name"
  puts
  @items.sort { |a, b| true_cost(a) <=> true_cost(b) }.each do |item|
    # puts "#{true_cost(item).round(2).to_s.ljust(11)}#{item[:build_cost][0].round(2).to_s.ljust(12)}#{item[:build_cost][1].round(2).to_s.ljust(13)}#{item[:sink_value].to_s.ljust(12)}#{item[:name].ljust(29)}#{item[:build_cost][2]} #{item[:build_cost][3] ? "(alt)" : nil}"
    # print "#{true_cost(item).round(2).to_s.ljust(11)}#{item[:name].ljust(29)}"
    # recipe_string = "#{item[:build_cost][2]} #{item[:build_cost][3] ? "(alt)" : nil}"
    # print_history({ recipe_string => history(item[:build_cost][2]) })
    # puts ""
    if item[:build_cost][3]
      puts "|#{item[:build_cost][2]}|#{item[:name]}|"
    end
  end
  # puts "Unused Items"
  # puts
  # @leaf_items.sort { |a, b| true_cost(b) <=> true_cost(a) }.each do |item|
  #   print "#{true_cost(item).round(2).to_s.ljust(11)}#{item[:name].ljust(29)}"
  #   recipe_string = "#{item[:build_cost][2]} #{item[:build_cost][3] ? "(alt)" : nil}"
  #   print_history({ recipe_string => history(item[:build_cost][2]) })
  #   puts ""
  # end
elsif mode == "energy"
  @most_energy_per_true_cost = nil
  @items.each do |item|
    next if item[:name] == "Turbo Motor"
    next if item[:name] == "Beacon"
    next if item[:energy] == 0
    next if item[:build_cost][0] == 0
    if item[:energy].nil?
      next
    else
      puts "#{item[:name].ljust(30)} #{item[:energy].to_s.ljust(10)} #{item[:build_cost][0].round(2).to_s.ljust(20)}#{(item[:energy] / item[:build_cost][0].to_f).round(2).to_s.ljust(20)}#{(item[:energy] / true_cost(item).to_f).round(2).to_s.ljust(20)}"
      if @most_energy_per_true_cost.nil?
        @most_energy_per_true_cost = item
      else
        if (@most_energy_per_true_cost[:energy] / true_cost(@most_energy_per_true_cost)) < (item[:energy] / true_cost(item))
          @most_energy_per_true_cost = item
        end
      end
    end
  end
  pp @most_energy_per_true_cost
end

# @items.select! do |item|
#   item[:build_cost] and item[:sink_value]
# end

# pp @items.sort { |a, b| (b[:sink_value].to_i / true_cost(b)) <=> (a[:sink_value].to_i / true_cost(a)) }[0..10]

# @recipes.select do |recipe|
#   recipe[:products].count > 1
# end.each do |recipe|
#   pp recipe
# end
