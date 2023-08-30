require "json"
require "yaml"

doc_file = File.read("update_8_experimental_Docs.json")
doc_json = JSON.parse(doc_file)

class DocsParser
  attr_reader :data

  def initialize(doc_json)
    @data = doc_json
    @used_sections = []
  end

  def section(native_class)
    native_class_string = "/Script/CoreUObject.Class'/Script/FactoryGame.#{native_class}'"
    @used_sections << native_class_string
    s = data.detect { |e| e["NativeClass"] == native_class_string }
    s ? s["Classes"] : []
  end

  def sections
    data.map { |e| e["NativeClass"] }
  end

  def sections_report(only_used = true)
    report = {}
    sections.each do |section|
      used = @used_sections.include?(section)
      report[section] = @used_sections.include?(section) unless only_used && !used
    end
    report
  end
end

parser = DocsParser.new(doc_json)

class SatisfactoryEntity
  def class_name
    @data["ClassName"]
  end

  def method_missing(m, *args, &block)
    # strip data_
    key = m.to_s.gsub("data_", "")

    attribute_value = data[format_attribute_key(key)]
    if attribute_value.nil?
      super(m, args, block)
    else
      format_attribute_value(attribute_value)
    end
  end

  def format_attribute_key(key)
    "m" + key.to_s.split("_").map { |s| s.capitalize }.join
  end

  def format_attribute_value(value)
    value
  end
end

class Building < SatisfactoryEntity
  attr_reader :data

  def initialize(fg_buildable_manufacturer_hash)
    @data = fg_buildable_manufacturer_hash
  end

  def details
    {
      name: display_name,
      power_consumption: power_consumption.to_i,
    }
  end

  def power_consumption
    if ["Build_HadronCollider_C"].include?(class_name)
      # note the typos in this line - they are from the source file
      ((data_estimated_maximum_power_consumption.to_i - data_estimated_mininum_power_consumption.to_i) / 2.0)
    elsif ["Build_GeneratorNuclear_C"].include?(class_name)
      -power_production.to_i
    else
      data_power_consumption
    end
  end
end

$buildings = parser.section("FGBuildableManufacturer")
$buildings += parser.section("FGBuildableManufacturerVariablePower")
$buildings += parser.section("FGBuildableFrackingExtractor")
$buildings += parser.section("FGBuildableFrackingActivator")
$buildings += parser.section("FGBuildableGeneratorNuclear")
$buildings += parser.section("FGBuildableResourceExtractor")

$buildings.map! { |building| Building.new(building) }

workshop = Building.new({
  "mDisplayName" => "Equipment Workshop",
  "ClassName" => "BP_WorkshopComponent_C",
  "mPowerConsumption" => 0,
})

$buildings << workshop

gather = Building.new({
  "mDisplayName" => "Gather",
  "ClassName" => "Gather",
  "mPowerConsumption" => 0,
})

$buildings << gather

$item_count = 0

class Item < SatisfactoryEntity
  attr_reader :data
  attr_reader :id

  def initialize(fg_item_descriptor_hash)
    @data = fg_item_descriptor_hash
    @id = $item_count += 1
  end

  def details
    {
      "name" => display_name,
      "sink_value" => resource_sink_points.to_i,
      "energy" => energy_value.to_i,
      "id" => id,
    }
  end
end

$items = parser.section("FGItemDescriptor")
$items += parser.section("FGResourceDescriptor")
$items += parser.section("FGItemDescriptorBiomass")
$items += parser.section("FGItemDescriptorNuclearFuel")
$items += parser.section("FGConsumableDescriptor")
$items += parser.section("FGAmmoTypeProjectile")
$items += parser.section("FGAmmoTypeInstantHit")
$items += parser.section("FGEquipmentDescriptor")
$items += parser.section("FGAmmoTypeSpreadshot")

$items.map! { |item| Item.new(item) }

$recipe_count = 0

class Recipe < SatisfactoryEntity
  attr_reader :data
  attr_reader :id

  def initialize(fg_recipe_descriptor_hash)
    @data = fg_recipe_descriptor_hash
    @id = $recipe_count += 1
  end

  def details
    details = {
      "name" => display_name.split("Alternate: ").last,
      "ingredients" => ingredients,
      "product" => product,
      "byproduct" => byproduct,
      "building" => [building, manufactoring_duration.to_i],
      "alternate" => display_name.include?("Alternate:"),
      "id" => id,
    }

    # divide fluids by 1000
    details["ingredients"].each do |ingredient|
      ingredient[-1] = ingredient.last / 1000 if ingredient.last >= 1000
    end
    details["product"][-1] = product.last / 1000 if product.last >= 1000
    details["byproduct"][-1] = byproduct.last / 1000 if byproduct && byproduct.last >= 1000

    # custom recipe modifications
    case details["name"]
    when "Recycled Rubber"
      details["ingredients"] = [["Fuel", 6]]
      details["product"] = ["Rubber", 6]
    when "Recycled Plastic"
      details["ingredients"] = [["Fuel", 6]]
      details["product"] = ["Plastic", 6]
    end

    # Remove canisters from packaged and unpackaged products
    if details["name"].include?("Packaged ")
      details["ingredients"] = [details["ingredients"].first]
    end
    if details["name"].include?("Unpackage ")
      details["byproduct"] = nil
    end

    # I don't care about water as a byproduct
    if Array(details["byproduct"]).first == "Water"
      details["byproduct"] = nil
    end

    # subtract outputs from inputs
    details["ingredients"].each do |ingredient|
      if ingredient.first == product.first
        ingredient[-1] -= product.last
      end
      if details["byproduct"] && ingredient.first == byproduct.first
        ingredient[-1] -= details["byproduct"].last
        details["byproduct"] = nil
      end
    end

    details
  end

  def ingredients
    parse_items_list(data_ingredients)
  end

  def product
    parse_items_list(data_product).first
  end

  def byproduct
    products = parse_items_list(data_product)
    if products.count > 1
      products.last
    end
  end

  def parse_items_list(items_list_string)
    # remove the first and last parens
    raw_items_list_string = items_list_string[1..-2]
    # replace the ),( with )$$$(
    raw_items_list_string.gsub!("),(", ")$$$(")
    raw_items_list_string.split("$$$").map do |ingredient_string|
      parse_item_string(ingredient_string)
    end
  end

  def parse_item_string(item_string)
    item_class = item_string.split(".").last.split('"').first
    item_name = $items.detect { |i| i.class_name == item_class }.display_name
    amount = item_string.split("=").last.split(")").first.to_i
    [item_name, amount]
  end

  def building
    # building_class = produced_in.split(",").first.split(".").last.split('"').first
    # building_name = $buildings.detect { |b| b.class_name == building_class }.display_name
    $buildings.each do |building|
      if produced_in.include?(building.class_name)
        return building.display_name
        break
      end
    end
  end
end

$recipes = parser.section("FGRecipe")
$recipes.map! { |recipe| Recipe.new(recipe) }

uranium_waste = Recipe.new({
  "ClassName" => "Desc_NuclearWaste_C",
  "mDisplayName" => "Uranium Waste",
  "mManufactoringDuration" => "300.000000",
  "mIngredients" => "((ItemClass=/Script/Engine.BlueprintGeneratedClass'\"/Game/FactoryGame/Resource/Parts/NuclearFuelRod/Desc_NuclearFuelRod.Desc_NuclearFuelRod_C\"',Amount=1),(ItemClass=/Script/Engine.BlueprintGeneratedClass'\"/Game/FactoryGame/Resource/Parts/Water/Desc_Water.Desc_Water_C\"',Amount=1500000))",
  "mProduct" => "((ItemClass=/Script/Engine.BlueprintGeneratedClass'\"/Game/FactoryGame/Resource/Parts/NuclearWaste/Desc_NuclearWaste.Desc_NuclearWaste_C\"',Amount=50))",
  "mProducedIn" => "(\"/Game/FactoryGame/Buildable/Factory/GeneratorNuclear/Build_GeneratorNuclear.Build_GeneratorNuclear_C\")",
})

$recipes << uranium_waste

$recipes.reject! { |recipe| recipe.produced_in == "(\"/Game/FactoryGame/Equipment/BuildGun/BP_BuildGun.BP_BuildGun_C\")" }
$recipes.reject! { |recipe| recipe.data_product.include? "Building" }
$recipes.reject! { |recipe| recipe.data_product.include? "Buildable" }
$recipes.reject! { |recipe| recipe.data_display_name.include? "ackage" }
$recipes.reject! { |recipe| recipe.building == "Equipment Workshop" }
[
  "Charcoal",
  "Biomass",
  "Biocoal",
  "Protein",
  "Color Cartridge",
  "Liquid Biofuel",
  "Solid Biofuel",
  "Fabric",
  "Snowball",
  "FICSMAS",
  "Actual Snow",
  "Candy Cane",
  "Fireworks",
].each do |rejected_recipe_string|
  $recipes.reject! { |recipe| recipe.data_display_name.include? rejected_recipe_string }
end

File.write("satisfactory_items.yaml", $items.map(&:details).to_yaml)
File.write("satisfactory_recipes.yaml", $recipes.map(&:details).to_yaml)
File.write("satisfactory_buildings.yaml", $buildings.map(&:details).to_yaml)

# require "pp"
# PP.pp(parser.sections_report, $>, 100)
