# ["Building Name", energy_in_MW]

buildings = [
  ["Assembler", 15],
  ["Blender", 75],
  ["Constructor", 4],
  ["Foundry", 16],
  ["Manufacturer", 55],
  ["Miner", 30],
  ["Oil Extractor", 40],
  ["Packager", 10],
  ["Particle Accelerator", 500],
  ["Refinery", 30],
  ["Smelter", 4],
  ["Water Extractor", 20],
  ["Nuclear Power Plant", -2500],
  ["Resource Well Extractor", 150],
  ["Gather", 0],
  ["Workshop", 0],
]

require "yaml"

File.write("satisfactory_buildings.yml", buildings.to_yaml)
