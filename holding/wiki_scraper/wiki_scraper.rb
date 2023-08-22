require "nokogiri"
require "open-uri"
require "yaml"

item_urls = YAML.load(File.read("item_links.yml"))
recipes = []
items = []

# item_urls = ["https://satisfactory.fandom.com/wiki/Uranium_Fuel_Rod"]

# five_item_recipes = [
#   "Drone",
#   "Drone Port",
#   "Nuclear Power Plant",
#   "Fluid Freight Platform",
#   "Freight Platform",
#   "Truck",
#   "Fuel Generator",
#   "Particle Accelerator",
#   "Geothermal Generator",
#   "Miner Mk.3",
#   "Snowman",
# ]

item_urls.each do |wiki_url|
  # Fetch and parse HTML document
  doc = Nokogiri::HTML(URI.open(wiki_url))
  sleep(3)
  recipes.uniq!
  items.uniq!
  File.write("satisfactory_recipes.yml", recipes.to_yaml)
  File.write("satisfactory_items.yml", items.to_yaml)
  puts "items: #{items.count}, recipes: #{recipes.count}"
  puts "fetched #{wiki_url}"

  if item_name_node = doc.xpath("//*/aside/h2").first
    item_name = item_name_node.content
  end
  if sink_value_node = doc.xpath("//*/aside/section[1]/div[2]/div").first
    sink_value = sink_value_node.content.gsub(" ", "").to_i
  else
    sink_value = nil
  end

  # if radioactivity_node = doc.xpath("//*/aside/section[1]/div[3]/div").first
  #   radioactivity = radioactivity_node.content
  # end

  if energy_node = doc.xpath("//*/aside/section[2]/div[1]/div").first
    energy = energy_node.content.gsub(" ", "").split("MJ").first.to_i
  end

  unless item_name.nil?
    items << { name: item_name, sink_value: sink_value, energy: energy }
  end

  def parse_recipe(node)
    name = node.children.first.content
    alternate = !node.children[2].nil?
    [name, alternate]
  end

  def parse_building(node)
    building_name = node.children[0].content
    unless building_name == "Build Gun"
      build_time = node.children[2].content.split.first.to_i
    else
      build_time = 0
    end
    [building_name, build_time]
  end

  def parse_product(node)
    if node.css("div div").children.first
      count = node.css("div div").children.first.content.split(" x ").first.to_i
      item = node.css("div div").children.last.content
      [count, item]
    else
      nil
    end
  end

  def parse_prerequisites(node)
    node.content
  end

  tables = doc.css("table.wikitable tbody")
  tables.each do |table|
    if table.children.first.children.map { |th| th.content } == ["Recipe", "Ingredients", "Building", "Products", "Prerequisites"]
      recipe_rows = table.children
      recipe_rows[1..-1].each_with_index do |row, index|
        recipe = {}
        ingredients = []
        products = []

        if row.children.count >= 5
          recipe[:name], recipe[:alternate] = parse_recipe(row.children[0])

          number_of_ingredient_cols = 12 / row.children[1]["colspan"].to_i

          number_of_ingredient_cols.times do |i|
            ingredients << parse_product(row.children[1 + i])
          end

          if recipe_rows[index + 2] && recipe_rows[index + 2].children.count < 5
            recipe_rows[index + 2].children.to_a.compact.each do |ingredient_node|
              ingredients << parse_product(ingredient_node)
            end
          end

          recipe[:building] = parse_building(row.children[1 + number_of_ingredient_cols])

          number_of_product_cols = 2 / row.children[2 + number_of_ingredient_cols]["colspan"].to_i

          number_of_product_cols.times do |i|
            products << parse_product(row.children[2 + number_of_ingredient_cols + i])
          end

          recipe[:prerequisites] = parse_prerequisites(row.children[-1])
        else
          next
        end

        recipe[:products] = products.compact
        recipe[:ingredients] = ingredients.compact
        recipes << recipe
      end
    end
  end
end

File.write("satisfactory_recipes.yml", recipes.to_yaml)
File.write("satisfactory_items.yml", items.to_yaml)
