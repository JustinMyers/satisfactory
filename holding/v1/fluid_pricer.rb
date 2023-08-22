require "yaml"

items = YAML.load_file("satisfactory_items.yml")

packaged_items = items.select { |i| i[:name].include?("Packaged ") }
packaged_items.each do |packaged_item|
  if packaged_item[:name] == "Packaged Oil"
    unpackaged_item = items.detect { |i| i[:name] == "Crude Oil" }
  else
    unpackaged_item = items.detect { |i| i[:name] == packaged_item[:name].split("Packaged ").last }
  end
  empty_canister = items.detect { |i| i[:name] == "Empty Canister" }
  unpackaged_item[:sink_value] = packaged_item[:sink_value] - empty_canister[:sink_value]
  # divide it by five because packaging things adds value.
  unpackaged_item[:sink_value] = unpackaged_item[:sink_value] / 2.0
end

File.write("satisfactory_items.yml", items.to_yaml)
