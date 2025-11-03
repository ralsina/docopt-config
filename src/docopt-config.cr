require "docopt"
require "yaml"

module Docopt
  class ConfigOptions
    property args : Hash(String, (Nil | String | Int32 | Bool | Array(String)))
    property config_file : Hash(String, YAML::Any)?
    property env_vars : Hash(String, String)

    def initialize(@args, @config_file = nil, @env_vars = Hash(String, String).new)
    end

    # Get a configuration value with precedence: CLI > env vars > config file
    def [](key : String) : (Nil | String | Int32 | Bool | Array(String))
      # Check command line arguments first (but only if not nil)
      if @args.has_key?(key) && !@args[key].nil?
        return @args[key]
      end

      # Check environment variables second
      if @env_vars.has_key?(key)
        return @env_vars[key]
      end

      # Check config file last
      if config = @config_file
        if config.has_key?(key)
          value = config[key]
          return case value.raw
                 when String
                   value.as_s
                 when Bool
                   value.as_bool
                 when Int64
                   value.as_i.to_i32
                 else
                   value.to_s
                 end
        end
      end

      # If not found anywhere, return nil
      nil
    end

    def []?(key : String) : (Nil | String | Int32 | Bool | Array(String))?
      result = self[key]
      result
    end

    def has_key?(key : String) : Bool
      @args.has_key?(key) ||
        @env_vars.has_key?(key) ||
        (@config_file && @config_file.not_nil!.has_key?(key))
    end
  end

  # Helper method to convert environment variable names to option format
  private def self.env_to_key(key : String) : String
    "--" + key.downcase.gsub(/_+/, "-")
  end

  # Main function to parse docopt with config file and environment variable support
  def self.docopt_config(doc : String,
                   argv : Array(String) = ARGV,
                   config_file_path : String? = nil,
                   env_prefix : String? = nil,
                   help : Bool = true,
                   version : String? = nil,
                   options_first : Bool = false) : ConfigOptions

    # Parse command line arguments using standard docopt
    args = Docopt.docopt(doc, argv: argv, help: help, version: version, options_first: options_first)

    # Parse config file if provided
    config_file : Hash(String, YAML::Any)? = nil
    if config_file_path && File.exists?(config_file_path)
      begin
        config_content = File.read(config_file_path)
        yaml_data = YAML.parse(config_content).as_h
        # Convert YAML keys to strings
        stringified_config = Hash(String, YAML::Any).new
        yaml_data.each do |key, value|
          stringified_config[key.as_s] = value
        end
        config_file = stringified_config
      rescue ex
        # If config file parsing fails, continue without it
        config_file = nil
      end
    end

    # Get relevant environment variables
    env_vars = Hash(String, String).new
    ENV.each do |key, value|
      # If env_prefix is provided, only include vars with that prefix
      if env_prefix
        if key.starts_with?(env_prefix + "_")
          # Remove prefix and convert to config key format
          env_part = key[env_prefix.size + 1..-1]
          config_key = env_to_key(env_part)
          env_vars[config_key] = value
        end
      else
        # Include all environment variables, convert to config key format
        config_key = env_to_key(key)
        env_vars[config_key] = value
      end
    end

    ConfigOptions.new(args, config_file, env_vars)
  end
end
