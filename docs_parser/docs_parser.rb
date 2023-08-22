require "json"
require "yaml"

doc_file = File.read("update_8_experimental_Docs.json")
doc_json = JSON.parse(doc_file)

class DocsParser
  attr_reader :data

  def initialize(doc_json)
    @data = doc_json
  end

  def section(native_class)
    native_class_string = "/Script/CoreUObject.Class'/Script/FactoryGame.#{native_class}'"
    s = data.detect { |e| e["NativeClass"] == native_class_string }
    s ? s["Classes"] : []
  end

  def sections
    data.map { |e| e["NativeClass"] }
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

class Item < SatisfactoryEntity
  attr_reader :data

  def initialize(fg_item_descriptor_hash)
    @data = fg_item_descriptor_hash
  end

  def details
    {
      name: display_name,
      sink_value: resource_sink_points.to_i,
      energy: energy_value.to_i,
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

class Recipe < SatisfactoryEntity
  attr_reader :data

  def initialize(fg_item_descriptor_hash)
    @data = fg_item_descriptor_hash
  end

  def details
    {
      "name": display_name.split("Alternate: ").last,
      "ingredients": ingredients,
      "products": product,
      "building": [building, manufactoring_duration.to_i],
      "alternate": display_name.include?("Alternate:"),
    }
  end

  def ingredients
    parse_items_list(data_ingredients)
  end

  def product
    parse_items_list(data_product)
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
    building_class = produced_in.split(",").first.split(".").last.split('"').first
    building_name = $buildings.detect { |b| b.class_name == building_class }.display_name
  end
end

$recipes = parser.section("FGRecipe")
$recipes.map! { |recipe| Recipe.new(recipe) }
$recipes.reject! { |recipe| recipe.produced_in == "(\"/Game/FactoryGame/Equipment/BuildGun/BP_BuildGun.BP_BuildGun_C\")" }
$recipes.reject! { |recipe| recipe.data_product.include? "Building" }
$recipes.reject! { |recipe| recipe.data_product.include? "Buildable" }

File.write("satisfactory_items.yaml", $items.map(&:details).to_yaml)
File.write("satisfactory_recipes.yaml", $recipes.map(&:details).to_yaml)
File.write("satisfactory_buildings.yaml", $buildings.map(&:details).to_yaml)
