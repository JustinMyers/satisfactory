require "yaml"

@items = YAML.load_file("satisfactory_items.yml")

raw_materials = {
  "Bauxite" => {
    impure: 5,
    normal: 6,
    pure: 6,
  },
  "Caterium Ore" => {
    impure: 0,
    normal: 8,
    pure: 8,
  },
  "Coal" => {
    impure: 6,
    normal: 29,
    pure: 14,
  },
  "Copper Ore" => {
    impure: 9,
    normal: 28,
    pure: 12,
  },
  "Iron Ore" => {
    impure: 33,
    normal: 41,
    pure: 46,
  },
  "Limestone" => {
    impure: 12,
    normal: 47,
    pure: 27,
  },
  "Raw Quartz" => {
    impure: 0,
    normal: 11,
    pure: 5,
  },
  "Sulfur" => {
    impure: 1,
    normal: 7,
    pure: 3,
  },
  "Uranium" => {
    impure: 1,
    normal: 3,
    pure: 0,
  },
}

raw_crude_oil = [
  {
    impure: 10,
    normal: 12,
    pure: 8,
  },
  {
    impure: 6,
    normal: 3,
    pure: 3,
  },
]

raw_nitrogen_gas = {
  impure: 2,
  normal: 7,
  pure: 36,
}

# The maximum mining rate is 70380 / min or 1173 / sec.
# There are 33 Impure and 41 Normal Iron nodes on the world, which means 74 Miner Mk.3 to be built on them, each overclocked to 250%, which means 129.96 MW each.
# There are 46 Pure Iron nodes on the map, which means 46 Miner Mk.3 each overclocked to 162.5%, which means 65.24 MW each.
# The total power consumption is then 12618.24 MW. Recall that MW means MJ / sec.
# Dividing 12618.24 MJ / sec by 1173 / sec, we will get:
# The average extraction energy for Iron Ore is 10.76 MJ.

# outputs mined_per_second and MJ/unit
def mining_rate(nodes)
  mining_rates = {
    impure: 300,
    normal: 600,
    pure: 780,
  }
  mined_per_minute = 0
  number_of_pure_miners = nodes[:pure]
  number_of_impure_and_normal_miners = nodes[:impure] + nodes[:normal]
  nodes.each_pair do |type, count|
    mined_per_minute += mining_rates[type] * count
  end
  mined_per_second = mined_per_minute / 60.0
  maxed_miner_energy_in_MW = 129.96
  pure_miner_energy_in_MW = 65.24
  total_energy_in_MW = number_of_pure_miners * pure_miner_energy_in_MW
  total_energy_in_MW += number_of_impure_and_normal_miners * maxed_miner_energy_in_MW
  energy_per_unit_in_MJ = total_energy_in_MW / mined_per_second
  [mined_per_second, energy_per_unit_in_MJ]
end

def oil_extraction_rate(nodes)
  mined_per_second = 11700 / 60.0
  [mined_per_second, 33.32] # https://satisfactory.fandom.com/wiki/Crude_Oil
end

def resource_well_extraction_rate(nodes)
  mined_per_second = 12000 / 60.0
  [mined_per_second, 19.49] # https://satisfactory.fandom.com/wiki/Nitrogen_Gas
end

raw_materials.each_pair do |item_name, raw_material|
  mined_per_second, energy_per_unit_in_MJ = mining_rate(raw_material)
  item = @items.detect { |i| i[:name] == item_name }
  item[:mined_per_second] = mined_per_second
  item[:mj_cost] = energy_per_unit_in_MJ
end

crude_oil = @items.detect { |i| i[:name] == "Crude Oil" }
mined_per_second, energy_per_unit_in_MJ = oil_extraction_rate(raw_crude_oil)
crude_oil[:mined_per_second] = mined_per_second
crude_oil[:mj_cost] = energy_per_unit_in_MJ

nitrogen_gas = @items.detect { |i| i[:name] == "Nitrogen Gas" }
mined_per_second, energy_per_unit_in_MJ = oil_extraction_rate(raw_nitrogen_gas)
nitrogen_gas[:mined_per_second] = mined_per_second
nitrogen_gas[:mj_cost] = energy_per_unit_in_MJ

File.write("satisfactory_items.yml", @items.to_yaml)
