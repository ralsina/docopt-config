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

Create a YAML configuration file (e.g., `config.yml`):

```yaml
--verbose: 2
--output: "results.txt"
--force: true
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
1. **Command-line arguments** - Always take precedence
2. **Environment variables** - Override config file settings
3. **Configuration file** - Provides defaults

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
