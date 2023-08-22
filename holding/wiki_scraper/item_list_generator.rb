require "nokogiri"
require "open-uri"

urls = [
  "https://satisfactory.fandom.com/wiki/Category:Items",
  "https://satisfactory.fandom.com/wiki/Category:Resources",
  "https://satisfactory.fandom.com/wiki/Category:Ores",
  "https://satisfactory.fandom.com/wiki/Category:Weapons",
  "https://satisfactory.fandom.com/wiki/Category:Equipment",
  "https://satisfactory.fandom.com/wiki/Category:Ammo",
  "https://satisfactory.fandom.com/wiki/Category:Fluids",
  "https://satisfactory.fandom.com/wiki/Category:Advanced_Refinement",
  "https://satisfactory.fandom.com/wiki/Category:Crafting_components",
  "https://satisfactory.fandom.com/wiki/Category:Fuels",
  "https://satisfactory.fandom.com/wiki/Category:Oil_Products",
]

links = []

urls.each do |url|
  # Fetch and parse HTML document
  doc = Nokogiri::HTML(URI.open(url))

  doc.css("ul li a").each do |link|
    href = link["href"]
    if href =~ /^\/wiki/ and !href.include?("Category")
      links << "https://satisfactory.fandom.com" + href
    end
  end
end

require "yaml"

File.write("item_links.yml", links.sort.uniq.to_yaml)
