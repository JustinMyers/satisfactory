require "yaml"

@item_hashes = YAML.load_file("docs_parser/satisfactory_items.yaml")
@recipe_hashes = YAML.load_file("docs_parser/satisfactory_recipes.yaml")
@building_hashes = YAML.load_file("docs_parser/satisfactory_buildings.yaml")
$resource_limits = YAML.load_file("docs_parser/satisfactory_resource_limits.yaml")

class Recipe
  attr_reader :name, :ingredients, :product, :byproduct, :building, :alternate, :id
  attr_accessor :lineage

  def initialize(recipe_hash)
    @name = recipe_hash["name"]
    @ingredients = recipe_hash["ingredients"]
    @product = recipe_hash["product"]
    @byproduct = recipe_hash["byproduct"]
    @building = recipe_hash["building"]
    @alternate = recipe_hash["alternate"]
    @id = recipe_hash["id"]
  end

  def product_name
    product.first
  end

  def product_quantity
    product.last
  end

  def unit_cost
    output = {}
    (@temp_precursors || precursors).each do |precursor|
      precursor.unit_cost.each_pair do |resource, count|
        output[resource] ||= 0
        ingredient_count = ingredients.detect { |i| i.first == precursor.product.first }.last / product.last.to_f
        output[resource] += count * ingredient_count
      end
    end
    ingredients.each do |ingredient, count|
      if $resource_limits[ingredient]
        output[ingredient] ||= 0
        output[ingredient] += count / product.last.to_f
      end
    end
    output
  end

  def global_cost
    output = {}
    max_p = max_production
    unit_cost.each_pair do |resource, count|
      output[resource] = count * max_production
    end
    output
  end

  def average_consumption
    total = 0
    unit_cost.each_pair do |resource, count|
      next if resource == "Water"
      total = total + (count / $resource_limits[resource].to_f)
    end
    total
  end

  def max_production
    max = Float::INFINITY
    unit_cost.each_pair do |resource, count|
      total = $resource_limits[resource] / count
      max = [max, total].min
    end
    max
  end

  def print_precursors(index = 0)
    puts "  " * index + name + (alternate ? "*" : "") # + lineage.to_s
    precursors.each do |precursor|
      precursor.print_precursors(index + 1)
    end
    ingredients.each do |ingredient|
      if $resource_limits.keys.include?(ingredient.first)
        puts "  " * (index + 1) + ingredient.first
      end
    end
  end

  def building_report(max_production_target, building_output = {}, report_on_precursors = true, depth = 0)
    building_name, seconds = building
    runs_per_minute = 60 / seconds.to_f
    quantity_per_minute = product_quantity * runs_per_minute
    number_of_buildings_needed = max_production_target / quantity_per_minute.to_f
    spacer = "  " * depth

    building_output[building_name] ||= {}
    building_output[building_name][name] ||= 0
    building_output[building_name][name] += number_of_buildings_needed.ceil

    puts "#{spacer}To make #{max_production_target.ceil(1)} #{product_name} per minute with recipe '#{name}' you need #{number_of_buildings_needed.ceil} '#{building_name}'"
    precursors.each do |precursor_recipe|
      item_name = precursor_recipe.product_name
      item_quantity = ingredients.detect { |i| i.first == item_name }.last
      target_item_quantity = item_quantity * (max_production_target / product_quantity.to_f)
      precursor_recipe.building_report(target_item_quantity, building_output, report_on_precursors, depth + 1)
    end
  end

  def precursors
    return @precursors if @precursors
    max = 0
    chains.each do |chain|
      @temp_precursors = chain
      if max_production > max
        max = max_production
        @precursors = chain
      elsif max > 0 && max_production == max
        switch = true
        @precursors.each_with_index do |precursor, index|
          challenger = chain[index]
          next if challenger.name == precursor.name
          if challenger.average_consumption > precursor.average_consumption
            switch = false
          end
        end
        if switch
          # puts "#{name} [#{lineage}] - replacing precursors!"
          # pp @precursors.map &:name
          # pp chain.map &:name
          @precursors = chain
        end
      end
      @temp_precursors = nil
    end
    @precursors ||= []
  end

  def chains
    chains_output = []
    preceding_recipes = ingredients.map do |ingredient|
      ingredient_name, ingredient_quatity = ingredient
      recipes = $recipes.select { |r| r.product_name == ingredient_name && !Array(lineage).include?(r.name) }.map &:dup
      recipes.each do |recipe|
        recipe.lineage = [name] + Array(lineage)
      end
    end

    preceding_recipes.reject! { |r| r.empty? }

    Array(preceding_recipes[0]).each do |ingredient_one_recipe|
      unless preceding_recipes[1]
        chains_output << [ingredient_one_recipe]
      end
      Array(preceding_recipes[1]).each do |ingredient_two_recipe|
        unless preceding_recipes[2]
          chains_output << [ingredient_one_recipe, ingredient_two_recipe]
        end
        Array(preceding_recipes[2]).each do |ingredient_three_recipe|
          unless preceding_recipes[3]
            chains_output << [ingredient_one_recipe, ingredient_two_recipe, ingredient_three_recipe]
          end
          Array(preceding_recipes[3]).each do |ingredient_four_recipe|
            chains_output << [ingredient_one_recipe, ingredient_two_recipe, ingredient_three_recipe, ingredient_four_recipe]
          end
        end
      end
    end
    chains_output
  end
end

$recipes = @recipe_hashes.map do |rh|
  Recipe.new(rh)
end

$recipes.reject! &:alternate

def recipe_report(recipe, print_precursors = false)
  if print_precursors
    recipe.print_precursors
    puts
  end
  max_production = recipe.max_production
  puts "Recipe '#{recipe.name}' makes #{max_production} #{recipe.product.first} per minute, consuming:"
  puts
  unit_cost = recipe.unit_cost
  $resource_limits.each_pair do |resource, count|
    next if resource == "Water"
    consumed = (unit_cost[resource].to_f * max_production)
    consumed_percent = consumed / count.to_f * 100
    puts resource.ljust(20) + consumed.round(2).to_s.ljust(10) + " / " + count.round(2).to_s.ljust(10) + consumed_percent.round(2).to_s + "%"
  end
  puts
end

def priority_list
  products = [
    "Uranium Fuel Rod",
    "Plutonium Fuel Rod",
  # "Thermal Propulsion Rocket",
  ]

  products.each do |product|
    recipes = $recipes.select { |r| r.product_name == product }

    recipe = recipes[recipes.map(&:max_production).each_with_index.max[1]]

    recipe_report(recipe, true)

    $resource_limits[product] = recipe.max_production

    recipe.global_cost.each_pair do |resource, count|
      $resource_limits[resource] -= count
    end
  end
end

# priority_list

recipes = $recipes.select { |r| r.product.first == "Plutonium Fuel Rod" }

recipes.each do |r|
  building_output = {}
  r.building_report(r.max_production, building_output)
  pp building_output
  recipe_report(r, true)
  puts
end

# recipes = $recipes.select { |r| r.product.first == "Aluminum Ingot" }
# recipes = $recipes.select { |r| r.product.first == "Reinforced Iron Plate" }
# recipes = $recipes.select { |r| r.product.first == "Copper Ingot" }
# recipes = $recipes.select { |r| r.product.first == "Steel Ingot" }

# recipes.each do |recipe|
#   recipe_report(recipe, true)
# end

# NOTES

# satisfactorytools.com shows a strange combination of recipes for maximizing Iron Plate
# can I duplicate or beat this?

# put byproducts into global resource list?

# a permutation technique to find "best order of recipes for same product to maximize production"
# the Iron Plate problem.
