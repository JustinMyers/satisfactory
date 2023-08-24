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
    (@temp_precursors || precursors).map do |precursor|
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
    # puts name
    # pp output
    output
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
    puts "  " * index + name + (alternate ? "*" : "")
    precursors.each do |precursor|
      precursor.print_precursors(index + 1)
    end
  end

  def precursors
    return @precursors if @precursors
    max = 0
    max_precursors = nil
    chains.each do |chain|
      @temp_precursors = chain
      if max_production > max
        max = max_production
        @precursors = chain
      end
    end
    @precursors ||= []
  end

  def chains
    chains_output = []
    preceding_recipes = ingredients.map do |ingredient|
      ingredient_name, ingredient_quatity = ingredient
      recipes = $recipes.select { |r| r.product_name == ingredient_name && !Array(lineage).include?(r.name) }
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

recipes = $recipes.select { |r| r.product.first == "Plutonium Fuel Rod" }

recipes.each do |r|
  puts r.max_production
  r.print_precursors
end
