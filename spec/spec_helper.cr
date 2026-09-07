require "spec"
require "../src/docopt-config"

# Build a config hash the same way the library does from YAML text.
def config_from_yaml(raw : String) : Hash(String, YAML::Any)
  parsed = Hash(String, YAML::Any).new
  YAML.parse(raw).as_h.each do |key, value|
    parsed[key.as_s] = value
  end
  parsed
end
