# frozen_string_literal: true

require 'yaml'

@item_hashes = YAML.load_file('docs_parser/satisfactory_items.yaml')
@recipe_hashes = YAML.load_file('docs_parser/satisfactory_recipes.yaml')
$building_hashes = YAML.load_file('docs_parser/satisfactory_buildings.yaml')
$resource_limits = YAML.load_file('docs_parser/satisfactory_resource_limits.yaml')

$total_consumption = 0

class Recipe
  attr_reader :name, :ingredients, :product, :byproduct, :building, :alternate, :id
  attr_accessor :lineage

  def initialize(recipe_hash)
    @name = recipe_hash['name']
    @ingredients = recipe_hash['ingredients']
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

  def unit_cost(resource_limits = $resource_limits.dup)
    output = {}
    if precursors.empty?
      output[product_name] = product_quantity
    else
      precursors.each do |precursor|
        puts "Calculating chain: "
        precursor.map { |p| puts p.name }
        precursor_sequence_resource_limits = resource_limits.dup
        precursor_sequence_global_cost = {}
        precursor_sequence_max_production = 0
        precursor.each do |recipe|
          precursor_unit_cost = recipe.unit_cost(precursor_sequence_resource_limits)
          precursor_max_production = recipe.max_production(precursor_sequence_resource_limits)
          precursor_sequence_max_production += precursor_max_production
          precursor_unit_cost.each_pair do |resource, count|
            precursor_sequence_resource_limits[resource] -= count * precursor_max_production
            precursor_sequence_global_cost[resource] ||= 0
            precursor_sequence_global_cost[resource] += count * precursor_max_production
          end
        end
        precursor_sequence_global_cost.each_pair do |resource, count|
          if precursor_sequence_max_production > 0
            output[resource] ||= 0
            output[resource] += count / precursor_sequence_max_production.to_f
          end
        end
      end
    end
    output
  end

  def global_cost(resource_limits = $resource_limits.dup)
    output = {}
    unit_cost.each_pair do |resource, count|
      output[resource] = count * max_production(resource_limits)
    end
    output
  end

  def total_wp_consumption(resource_limits = $resource_limits.dup)
    total = 0
    unit_cost(resource_limits).each_pair do |resource, count|
      next if resource == 'Water'

      total += (count / $resource_limits[resource].to_f)
    end
    total
  end

  def max_production(resource_limits = $resource_limits.dup)
    max = Float::INFINITY
    unit_cost(resource_limits).each_pair do |resource, count|
      if count <= 0
        max = 0
        break
      end
      total = resource_limits[resource] / count.to_f
      max = [max, total].min
    end
    max
  end

  def print_precursors(index = 0)
    puts '  ' * index + name + (alternate ? '*' : '') if !$resource_limits.keys.include?(name) # + lineage.to_s
    precursors.each do |precursor_array|
      precursor_array.each do |precursor|
        precursor.print_precursors(index + 1)
      end
    end
    ingredients.each do |ingredient|
      puts '  ' * (index + 1) + ingredient.first if $resource_limits.keys.include?(ingredient.first)
    end
  end

  def building_report(max_production_target, building_output = {}, report_on_precursors = true, depth = 0)
    building_name, seconds = building
    runs_per_minute = 60 / seconds.to_f
    quantity_per_minute = product_quantity * runs_per_minute
    number_of_buildings_needed = max_production_target / quantity_per_minute.to_f
    spacer = '| ' * depth

    building_output[building_name] ||= {}
    building_output[building_name][name] ||= 0
    building_output[building_name][name] += number_of_buildings_needed
    building_output['items'] ||= {}
    building_output['items'][product_name] ||= 0
    building_output['items'][product_name] += max_production_target
    building_output['byproducts'] ||= {}
    building_output['byproducts'][byproduct_name] ||= 0
    building_output['byproducts'][byproduct_name] += number_of_buildings_needed * byproduct_quantity.to_f * runs_per_minute

    building = $building_hashes.detect do |h|
      h[:name] == building_name
    end
    consumption = building[:power_consumption].to_i
    $total_consumption += number_of_buildings_needed * consumption

    recipe_name_clause = name == product_name ? '' : "via '#{name}' "
    puts "#{spacer}#{product_name} #{max_production_target.ceil(1)}/min. #{recipe_name_clause}> #{number_of_buildings_needed.ceil} '#{building_name}'"
    precursors.each do |precursor_recipe|
      item_name = precursor_recipe.product_name
      item_quantity = ingredients.detect { |i| i.first == item_name }&.last
      target_item_quantity = item_quantity.to_f * (max_production_target / product_quantity.to_f)
      precursor_recipe.building_report(target_item_quantity, building_output, report_on_precursors, depth + 1)
    end
  end

  def precursors
    return @precursors || @temp_precursors if @precursors || @temp_precursors
    max = 0
    chains.each do |chain|
      @temp_precursors = chain
      cached_max_production = max_production
      if cached_max_production > max
        puts "New max: #{cached_max_production}"
        max = cached_max_production
        @precursors = chain
      end
      @temp_precursors = nil
    end
    @precursors ||= []
  end
 
  def chains
    return @chains_output if @chains_output
    preceding_recipes = ingredients.map do |ingredient|
      ingredient_name, ingredient_quantity = ingredient
      recipes = $recipes.select do |r|
        r.product_name == ingredient_name || r.byproduct_name == ingredient_name
      end.map(&:dup)
      combinations = []
      for i in 1..(recipes.length) do
        combinations += recipes.permutation(i).to_a
      end
      combinations
    end
    preceding_recipes.reject! { |r| r.empty? }
    @chains_output = []
    Array(preceding_recipes[0]).each do |ingredient_one_recipe|
      @chains_output << [ingredient_one_recipe] unless preceding_recipes[1]
      Array(preceding_recipes[1]).each do |ingredient_two_recipe|
        @chains_output << [ingredient_one_recipe, ingredient_two_recipe] unless preceding_recipes[2]
        Array(preceding_recipes[2]).each do |ingredient_three_recipe|
          unless preceding_recipes[3]
            @chains_output << [ingredient_one_recipe, ingredient_two_recipe, ingredient_three_recipe]
          end
          Array(preceding_recipes[3]).each do |ingredient_four_recipe|
            @chains_output << [ingredient_one_recipe, ingredient_two_recipe, ingredient_three_recipe,
                              ingredient_four_recipe]
          end
        end
      end
    end
    @chains_output
  end
end

$recipes = @recipe_hashes.map do |rh|
  Recipe.new(rh)
end

# $recipes.reject!(&:alternate)

def recipe_report(recipe, print_precursors = false)
  if print_precursors
    recipe.print_precursors
    puts
  end
  max_production = recipe.max_production
  puts "Recipe '#{recipe.name}#{recipe.alternate ? '*' : ''}' makes #{max_production} #{recipe.product.first} per minute, consuming:"
  puts
  unit_cost = recipe.unit_cost
  $resource_limits.each_pair do |resource, count|
    next if resource == 'Water'

    consumed = (unit_cost[resource].to_f * max_production)
    consumed_percent = consumed / count.to_f * 100
    puts resource.ljust(20) + consumed.round(2).to_s.ljust(10) + ' / ' + count.round(2).to_s.ljust(10) + consumed_percent.round(2).to_s + '%'
  end
  puts
end

test_product_name = 'Iron Ingot'
test_recipe_hash = {
  'name' => "Test Recipe: #{test_product_name}",
  'ingredients' => [[test_product_name, 1]],
  'product' => [test_product_name, 1],
  'byproduct' => nil,
  'building' => ['Constructor', 1],
  'alternate' => false,
  'id' => 0
}
recipe_report(Recipe.new(test_recipe_hash), true)
