require "yaml"

@items = YAML.load_file("docs_parser/satisfactory_items.yaml")
@recipes = YAML.load_file("docs_parser/satisfactory_recipes.yaml")
@buildings = YAML.load_file("docs_parser/satisfactory_buildings.yaml")
@resource_limits = YAML.load_file("docs_parser/satisfactory_resource_limits.yaml")

# find recipes with more than one product

@recipes.select { |r| pp r if r[:products].count > 1 }
