include_recipe "espy"
node.set["mongodb"]["type"]["arbiter"] = true

advert = [node["project"], node["site"], "mongodb", "arbiter"].join("-")
advertise(advert, :port => node["mongodb"]["port"])
