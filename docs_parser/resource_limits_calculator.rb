require "yaml"

ores = {
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

crude_oil = [
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

nitrogen_gas = {
  impure: 2,
  normal: 7,
  pure: 36,
}

# outputs mined_per_second and MJ/unit
def node_mining_rate(nodes)
  mining_rates = {
    impure: 300,
    normal: 600,
    pure: 780,
  }
  mined_per_minute = 0
  nodes.each_pair do |type, count|
    mined_per_minute += mining_rates[type] * count
  end
  mined_per_minute
end

def oil_well_extraction_rate(nodes)
  extraction_rates = {
    impure: 150,
    normal: 300,
    pure: 600,
  }
  extracted_per_minute = 0
  nodes.each_pair do |type, count|
    extracted_per_minute += extraction_rates[type] * count
  end
  extracted_per_minute
end

def resource_well_extraction_rate(nodes)
  extraction_rates = {
    impure: 75,
    normal: 150,
    pure: 300,
  }
  extracted_per_minute = 0
  nodes.each_pair do |type, count|
    extracted_per_minute += extraction_rates[type] * count
  end
  extracted_per_minute
end

@resource_limits = {}

ores.each_pair do |item_name, resource_nodes|
  mined_per_minute = node_mining_rate(resource_nodes)
  @resource_limits[item_name] = mined_per_minute
end

@resource_limits["Crude Oil"] = oil_well_extraction_rate(crude_oil.first) + resource_well_extraction_rate(crude_oil.last)

@resource_limits["Nitrogen Gas"] = resource_well_extraction_rate(nitrogen_gas)

@resource_limits["Water"] = Float::INFINITY

File.write("satisfactory_resource_limits.yaml", @resource_limits.to_yaml)
