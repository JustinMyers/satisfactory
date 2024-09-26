# frozen_string_literal: true

require 'yaml'

$recipe_hashes = YAML.load_file('docs_parser/satisfactory_recipes.yaml')
$resource_limits = YAML.load_file('docs_parser/satisfactory_resource_limits.yaml')

class Ingredient
  attr_reader :name, :quantity

  def initialize(ingredient_array)
    @name = ingredient_array.first
    @quantity = ingredient_array.last
  end
end

class Recipe
  attr_reader :name, :ingredients, :product, :byproduct, :building, :alternate, :id

  def initialize(recipe_hash)
    @name = recipe_hash['name']
    @ingredients = recipe_hash['ingredients'].map { |i| Ingredient.new(i) }
    @product = recipe_hash['product']
    @byproduct = recipe_hash['byproduct']
    @building = recipe_hash['building']
    @alternate = recipe_hash['alternate']
    @id = recipe_hash['id']
  end

  def to_s
    name
  end

  def product_name
    product.first
  end

  def byproduct_name
    byproduct&.first
  end

  def product_quantity
    product.last
  end

  def byproduct_quantity
    byproduct&.last
  end

  def max_production(resource_limits, threshold = 1.0)
    if ingredients.empty?
      pp product_name if resource_limits[product_name].nil?
      production = resource_limits[product_name]
      resource_limits[product_name] = resource_limits[product_name] - resource_limits[product_name] * threshold
      return production
    else
      cost = {}
      ingredients.each do |ingredient|
        recipe_set = $recipe_sets[ingredient.name]
        # recipe_set = RecipeSet.new(ingredient.name)
        pp ingredient.name if recipe_set.nil?
        ingredient_unit_cost = recipe_set.unit_cost
        ingredient_unit_cost.each_pair do |resource, count|
          ingredient_unit_cost[resource] = count * ingredient.quantity / product_quantity.to_f
        end
        ingredient_unit_cost.each_pair do |resource, count|
          cost[resource] ||= 0
          cost[resource] += count
        end
      end
      max = Float::INFINITY
      cost.each_pair do |resource, count|
        unless resource == "Water"
          total = resource_limits[resource] * threshold / count.to_f
          max = [max, total].min
        end
      end
      cost.each_pair do |resource, count|
        resource_limits[resource] -= count * max
      end
      max  
    end
  end

  def production_values(resource_limits, threshold)
    return [max_production(resource_limits, threshold), resource_limits]
  end
end

class RecipeList
  attr_reader :recipes, :best_percentage

  def initialize(recipe_list)
    @recipes = recipe_list
  end

  def percentages
    granularity = 100.0 / @recipes.length.to_f
    granularity = 20 if granularity > 20
    granularity_array = []
    x = granularity
    while x <= 100
      granularity_array << x
      x += granularity
    end
    if granularity_array.length < @recipes.length
      granularity_array << 100
    end
    granularity_array.reject! { |x| x > 100 }
    percentages = granularity_array.permutation(@recipes.length).to_a
    # percentages.reject! { |p| p.sum != 100 }
    percentages.map! { |p| p.map! { |t| t.to_f / 100.0 } }
    percentages
  end

  def unit_cost
    @calculated_unit_cost if @cost
    resource_limits = $resource_limits.dup
    total_production = 0
    # pp percentages
    # pp @percentage
    pp @recipes.map(&:name) if @percentage.nil?
    @recipes.each_with_index do |recipe, index|
      production, resource_limits = recipe.production_values(resource_limits, @percentage[index])
      total_production += production
    end
    cost = {}
    $resource_limits.each_pair do |resource, count|
      spent = count - resource_limits[resource]
      if spent > 0
        cost[resource] = spent / total_production.to_f
      end
    end
    @calculated_unit_cost = cost
    @calculated_unit_cost
  end

  def max_production_units
    @cached_max_production_units if @cached_max_production_units
    max = Float::INFINITY
    unit_cost.each_pair do |resource, count|
      unless resource == "Water"
        total = $resource_limits[resource] / count.to_f
        max = [max, total].min
      end
    end
    @cached_max_production_units = max
    max
  end

  def max_production
    @cached_max if @cached_max
    max = 0
    percentages.each do |percentage|
      @percentage = percentage
      cached_max_production_units = max_production_units
      if cached_max_production_units > max
        max = cached_max_production_units
      end
    end
    @cached_max = max
    max
  end
end

class RecipeSet
  attr_reader :product_name

  def initialize(product_name)
    @product_name = product_name
    recipes = $recipes.select { |r| r.product_name == product_name }
    @permutations = []
    # for i in 1..(recipes.length) do
    #   @permutations += recipes.permutation(i).to_a.map { |p| RecipeList.new(p) }
    # end
    @permutations += recipes.permutation.to_a.map { |p| RecipeList.new(p) }
  end

  def best_recipe_list
    @best ||= @permutations.max_by { |p| p.max_production }
  end

  def max_production
    best_recipe_list.max_production
  end

  def unit_cost
    best_recipe_list.unit_cost
  end
  
  def report
    puts max_production
    puts best_recipe_list.best_percentage
    best_recipe_list.recipes.each do |recipe|
      puts recipe.name
    end
    nil
  end
end

$recipes = $recipe_hashes.map do |rh|
  Recipe.new(rh)
end

# $recipes.reject!(&:alternate)

$recipe_sets = {}
$recipes.each do |recipe|
  $recipe_sets[recipe.product_name] = RecipeSet.new(recipe.product_name)
  if recipe.byproduct_name
    $recipe_sets[recipe.byproduct_name] = RecipeSet.new(recipe.byproduct_name)
  end
end

$recipe_sets["Ballistic Warp Drive"].report

# RecipeSet.new("Iron Plate").report