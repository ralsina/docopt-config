require "docopt"
require "yaml"

module Docopt
  # The type of a docopt option value: what Docopt.docopt returns in its hash.
  alias OptionValue = String | Int32 | Bool | Array(String)

  # Raised instead of exiting when docopt_config is called with exit: false
  # and the process would have terminated normally (help or version request).
  # Note: this class deliberately has no custom initialize — adding one breaks
  # Docopt's internal exception-class dispatch.
  class ConfigExit < DocoptException; end

  class ConfigOptions
    property args : Hash(String, OptionValue?)
    property docopt_defaults : Hash(String, OptionValue?)
    property config_file : Hash(String, YAML::Any)?
    property env_vars : Hash(String, String)

    def initialize(@args, @docopt_defaults, @config_file = nil, @env_vars = Hash(String, String).new)
    end

    # Get a configuration value with precedence: CLI > env vars > config file > docopt defaults
    def [](key : String) : OptionValue?
      # Check CLI arguments first. Flags not given parse as false and
      # repeatable options not given parse as [], so neither counts as
      # user-provided and the lower tiers get a chance to answer.
      return @args[key] if provided_by_cli?(key)

      # Check environment variables second (env keys are always long form)
      return env_value(key) if @env_vars.has_key?(long_key(key))

      # Check config file third
      if config = @config_file
        # First try exact key match (for quoted keys like "--verbose" or "-v")
        return config_value(config[key]) if config.has_key?(key)

        # Then try clean key match (for unquoted keys like "verbose" or "v")
        clean_key = key.gsub(/^-+/, "")
        return config_value(config[clean_key]) if config.has_key?(clean_key)

        # Finally try snake_case key (for "input_file" matching "--input-file")
        snake_key = clean_key.gsub(/-/, "_")
        return config_value(config[snake_key]) if config.has_key?(snake_key)
      end

      # Finally return docopt default
      if @docopt_defaults.has_key?(key)
        return @docopt_defaults[key]
      end

      # If not found anywhere, return nil
      nil
    end

    def []?(key : String) : OptionValue?
      self[key]
    end

    def has_key?(key : String) : Bool
      return true if provided_by_cli?(key)
      return true if @env_vars.has_key?(long_key(key))
      config = @config_file
      !config.nil? && config.has_key?(key)
    end

    # Normalize an option key to long form ("-v" becomes "--v"), which is
    # the shape environment variables are stored under.
    private def long_key(key : String) : String
      key.starts_with?("--") ? key : "--" + key.lstrip('-')
    end

    # Whether the key was actually given on the command line, as opposed to
    # being docopt's representation of "not given" (false for flags, [] for
    # repeatable options, 0 for repeatable flags/commands).
    private def provided_by_cli?(key : String) : Bool
      return false unless @args.has_key?(key)
      case value = @args[key]
      when Bool  then value == true
      when Int32 then value != 0
      when Array then !value.empty?
      else            !value.nil?
      end
    end

    # Environment variables are strings; coerce them to the type docopt
    # would produce for the option, based on how the CLI parse typed the
    # key: Bool for flags, Int32 for repeatable flags/commands, arrays
    # (comma separated) for repeatable options, raw strings otherwise.
    private def env_value(key : String) : OptionValue?
      raw = @env_vars[long_key(key)]
      case @args[key]?
      when Bool
        case raw.downcase
        when "true", "yes", "1" then true
        when "false", "no", "0" then false
        else                         raw
        end
      when Int32
        raw.to_i32? || raw
      when Array
        raw.split(",").map(&.strip).reject(&.empty?)
      else
        raw
      end
    end

    # Convert a YAML config value to an option value. Sequences become
    # Array(String) so repeatable options can be set from the config file.
    private def config_value(value : YAML::Any) : OptionValue?
      case value.raw
      when String
        value.as_s
      when Bool
        value.as_bool
      when Int64
        value.as_i.to_i32
      when Array
        value.as_a.map do |element|
          element.raw.is_a?(String) ? element.as_s : element.to_s
        end
      else
        value.to_s
      end
    end
  end

  # Helper method to convert environment variable names to option format
  private def self.env_to_key(key : String) : String
    "--" + key.downcase.gsub(/_+/, "-")
  end

  # Collect the environment variables relevant to options, converted to
  # option format. With a prefix, only variables starting with
  # "#{env_prefix}_" are used (prefix stripped); without one, all are.
  private def self.collect_env_vars(env_prefix : String?) : Hash(String, String)
    env_vars = Hash(String, String).new
    ENV.each do |key, value|
      if env_prefix
        next unless key.starts_with?(env_prefix + "_")
        env_vars[env_to_key(key[env_prefix.size + 1..-1])] = value
      else
        env_vars[env_to_key(key)] = value
      end
    end
    env_vars
  end

  # Handle --help / --version based on the parsed arguments, like docopt's
  # own extras(): only options actually declared in the doc trigger them,
  # and tokens after "--" (parsed as positionals) never do. Exits (or
  # raises ConfigExit when exit is false) after writing to io.
  private def self.handle_help_and_version(args : Hash(String, OptionValue?), doc : String,
                                           help : Bool, version : String?, exit : Bool, io : IO) : Nil
    if help && (args["--help"]? == true || args["-h"]? == true)
      io.puts doc
      Process.exit(0) if exit
      raise ConfigExit.new("help requested")
    end

    if version && args["--version"]? == true
      io.puts version
      Process.exit(0) if exit
      raise ConfigExit.new("version requested")
    end
  end

  # Main function to parse docopt with config file and environment variable support
  def self.docopt_config(doc : String,
                         argv : Array(String) = ARGV,
                         config_file_path : String? = nil,
                         env_prefix : String? = nil,
                         help : Bool = true,
                         version : String? = nil,
                         options_first : Bool = false,
                         exit : Bool = true,
                         io : IO = STDOUT) : ConfigOptions
    # Create a modified docopt string without defaults for parsing
    doc_without_defaults = remove_docopt_defaults(doc)

    begin
      # Parse with exit=false to prevent automatic termination
      args = Docopt.docopt(
        doc_without_defaults,
        argv: argv,
        help: false,  # Disable help since we handle it ourselves
        version: nil, # Disable version since we handle it ourselves
        options_first: options_first,
        exit: false
      )

      handle_help_and_version(args, doc, help, version, exit, io)

      # Extract defaults using docopt's built-in functionality
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
        rescue
          # If config file parsing fails, continue without it
          config_file = nil
        end
      end

      # Get relevant environment variables
      env_vars = collect_env_vars(env_prefix)

      ConfigOptions.new(args, docopt_defaults, config_file, env_vars)
    rescue ex : DocoptExit
      # Usage error: docopt convention is an optional message plus the usage
      # summary on stderr, and a non-zero exit status.
      if exit
        message = ex.message
        STDERR.puts message if message && !message.empty?
        STDERR.puts DocoptExit.usage unless DocoptExit.usage.empty?
        Process.exit(1)
      end
      raise ex
    rescue ex
      # Handle other exceptions
      if exit
        STDERR.puts "Error: #{ex.message}"
        Process.exit(1)
      end
      raise ex
    end
  end

  # Remove default specifications from docopt string. Case-insensitive to
  # match docopt's own [default: ...] parsing.
  private def self.remove_docopt_defaults(doc : String) : String
    doc.gsub(/\s*\[default:\s*([^\]]+)\]/i, "")
  end

  # Extract default values using docopt's built-in parse_defaults functionality
  private def self.extract_docopt_defaults_using_docopt(doc : String) : Hash(String, OptionValue?)
    defaults = Hash(String, OptionValue?).new

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
  private def self.parse_default_value(value : String) : OptionValue?
    case value.downcase
    when "true", "yes"
      true
    when "false", "no"
      false
    when /^\d+$/
      value.to_i32
    when /^\d+\.\d+$/
      value.to_f.to_i32 # Convert to int32 to match expected type
    when /^".*"$/, /^'.*'$/
      value[1..-2] # Remove quotes
    else
      value
    end
  end
end
