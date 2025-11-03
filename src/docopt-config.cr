require "docopt"
require "yaml"

module Docopt
  class ConfigOptions
    property args : Hash(String, (Nil | String | Int32 | Bool | Array(String)))
    property docopt_defaults : Hash(String, (Nil | String | Int32 | Bool | Array(String)))
    property config_file : Hash(String, YAML::Any)?
    property env_vars : Hash(String, String)

    def initialize(@args, @docopt_defaults, @config_file = nil, @env_vars = Hash(String, String).new)
    end

    # Get a configuration value with precedence: CLI > env vars > config file > docopt defaults
    def [](key : String) : (Nil | String | Int32 | Bool | Array(String))
      # Check CLI arguments first (any non-nil value in args is from CLI since we parsed without defaults)
      if @args.has_key?(key) && !@args[key].nil?
        return @args[key]
      end

      # Check environment variables second
      if @env_vars.has_key?(key)
        return @env_vars[key]
      end

      # Check config file third
      if config = @config_file
        # First try exact key match (for quoted keys like "--verbose")
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

        # Then try clean key match (for unquoted keys like "verbose" or "input_file")
        clean_key = key.gsub(/^--+/, "")
        if config.has_key?(clean_key)
          value = config[clean_key]
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

        # Finally try snake_case key (for "input_file" matching "--input-file")
        snake_key = key.gsub(/^--/, "").gsub(/-/, "_")
        if config.has_key?(snake_key)
          value = config[snake_key]
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

      # Finally return docopt default
      if @docopt_defaults.has_key?(key)
        return @docopt_defaults[key]
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

    # Create a modified docopt string without defaults so we can handle them ourselves
    doc_without_defaults = remove_docopt_defaults(doc)

    # Parse command line arguments using docopt without defaults
    args = Docopt.docopt(doc_without_defaults, argv: argv, help: help, version: version, options_first: options_first)

    # Parse original docopt to extract defaults using docopt's built-in functionality
    docopt_defaults = extract_docopt_defaults_using_docopt(doc)

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

    ConfigOptions.new(args, docopt_defaults, config_file, env_vars)
  end

  # Remove default specifications from docopt string
  private def self.remove_docopt_defaults(doc : String) : String
    doc.gsub(/\s*\[default:\s*([^\]]+)\]/, "")
  end

  # Extract default values using docopt's built-in parse_defaults functionality
  private def self.extract_docopt_defaults_using_docopt(doc : String) : Hash(String, (Nil | String | Int32 | Bool | Array(String)))
    defaults = Hash(String, (Nil | String | Int32 | Bool | Array(String))).new

    # Use docopt's own parse_defaults to get Option objects with default values
    option_objects = Docopt.parse_defaults(doc)

    option_objects.each do |option|
      if option.responds_to?(:long) && option.responds_to?(:value) && option.responds_to?(:argcount)
        long_name = option.long
        default_value = option.value
        argcount = option.argcount

        # Only include options that have arguments (argcount > 0) and have default values
        if long_name && argcount > 0 && default_value
          # Convert the default value to the appropriate type
          parsed_value = parse_default_value(default_value.to_s)
          defaults[long_name.to_s] = parsed_value if parsed_value
        end
      end
    end

    defaults
  end

  # Parse default value to appropriate type
  private def self.parse_default_value(value : String) : (Nil | String | Int32 | Bool | Array(String))
    case value.downcase
    when "true", "yes"
      true
    when "false", "no"
      false
    when /^\d+$/
      value.to_i32
    when /^\d+\.\d+$/
      value.to_f.to_i32  # Convert to int32 to match expected type
    when /^".*"$/, /^'.*'$/
      value[1..-2]  # Remove quotes
    else
      value
    end
  end
end
