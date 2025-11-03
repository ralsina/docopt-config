# docopt-config

A Crystal library that extends docopt to support configuration files and environment variables, providing a unified way to handle command-line arguments, config files, and environment variables with proper precedence.

## Features

- Combines docopt command-line parsing with config file and environment variable support
- YAML configuration file support
- Environment variable support with optional prefixing
- Proper precedence order: CLI arguments > environment variables > config file
- Seamless integration with existing docopt usage patterns

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     docopt-config:
       github: your-github-user/docopt-config
   ```

2. Run `shards install`

## Usage

Replace your standard `Docopt.docopt` calls with `Docopt.docopt_config`:

```crystal
require "docopt-config"

doc = <<-DOC
My Awesome Application.

Usage:
  myapp [--verbose=<level>] [--output=<file>] [--force]

Options:
  --verbose=<level>  Verbosity level [default: 1]
  --output=<file>    Output file path
  --force            Force operation
  --help             Show this help message
DOC

# Parse with combined config sources
options = Docopt.docopt_config(
  doc,
  config_file_path: "config.yml",
  env_prefix: "MYAPP"
)

# Access options with normal docopt syntax
puts options["--verbose"]  # CLI argument takes precedence
puts options["--output"]   # Falls back to env var or config file
```

### Configuration File Format

Create a YAML configuration file (e.g., `config.yml`) to set fallback values for your options:

```yaml
# config.yml
verbose: 2
output: "results.txt"
force: true
input_file: "/path/to/input.txt"
count: 42
```

**Example:**

For the docopt usage pattern:
```
Usage: myapp [--verbose=<level>] [--output=<file>] [--force] [--input-file=<path>] [--count=<number>]
```

Your configuration file would look like:
```yaml
# Set fallback values for all options
verbose: "1"                      # String value (maps to --verbose)
output: "default_output.txt"      # String with quotes (maps to --output)
force: true                       # Boolean value (maps to --force)
input_file: "/data/input.csv"     # Path with quotes (maps to --input-file)
count: 10                         # Numeric value (maps to --count)
```

**Note**: The library automatically maps configuration keys to docopt options by:
- Converting snake_case to kebab-case (`input_file` → `--input-file`)
- Adding `--` prefix to option names (`verbose` → `--verbose`)

You can also use quoted keys if you prefer:
```yaml
"--verbose": "1"
"--output": "default_output.txt"
```

### Environment Variables

Environment variables are automatically converted from `UPPER_SNAKE_CASE` to `--kebab-case` options:

```bash
export MYAPP_VERBOSE=3
export MYAPP_OUTPUT_FILE="/path/to/output.txt"
export MYAPP_FORCE=true
```

### Precedence Order

The library follows this precedence order (highest to lowest):

1. **Command-line arguments** - Always take precedence when provided
2. **Environment variables** - Used when CLI argument is not provided
3. **Configuration file** - Used when neither CLI nor env vars are available
4. **Docopt defaults** - Used as final fallback (specified in docopt usage documentation)

**Important**: The docopt documentation remains the single source of truth for option definitions. The library enhances docopt by providing additional fallback sources (environment variables and config files) that are consulted before docopt's own defaults.

### Advanced Usage

```crystal
# Custom config file path
options = Docopt.docopt_config(doc, config_file_path: "/etc/myapp/config.yml")

# No environment variable prefix (uses all env vars)
options = Docopt.docopt_config(doc, env_prefix: nil)

# Only use command-line and config file (no env vars)
options = Docopt.docopt_config(doc, config_file_path: "config.yml", env_prefix: "")

# Pass custom argv for testing
options = Docopt.docopt_config(doc, argv: ["--verbose", "5"])
```

## Development

To run tests:

```bash
crystal spec
```

To install dependencies:

```bash
shards install
```

## Contributing

1. Fork it (<https://github.com/your-github-user/docopt-config/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Roberto Alsina](https://github.com/your-github-user) - creator and maintainer
