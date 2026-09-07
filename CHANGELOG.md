# Changelog

All notable changes to this project are documented in this file.
## Unreleased

### Miscellaneous
- Lint only on the latest Crystal job: ameba requires a recent compiler to build
- Build ameba from source in CI instead of relying on its postinstall

## 0.3.0 - 2026-09-07

### Bug Fixes
- Print usage errors with their message to stderr and exit with status 1 (#2)
- Fix nil-narrowing compile error in usage error output
- Detect help and version from parsed options like docopt, not a blind argv scan (#7)
- Strip [default: ...] annotations case-insensitively so env and config can override any casing (#3)
- Treat zero counts of repeatable flags as not provided so config and env can set them (#15)
- Coerce env var values to the option's type: booleans for flags, counts for repeatable flags, arrays for repeatable options; support short-option keys (#4)
- Make has_key? consider the same tiers and config key fallbacks as [], including docopt defaults (#5)
- Keep config and default values faithful: preserve floats and large integers instead of truncating or stringifying (#6)
- Warn on stderr when a config file exists but cannot be parsed, instead of ignoring it silently (#9)
- Honor empty env prefix as 'no env vars' and document the nil-prefix legacy behavior (#10)

### Features
- Add exit: false and io parameters so applications and tests can handle help, version and errors themselves (#8)
- Add opt-in print_config_option that dumps the fully-resolved configuration as YAML and exits (#14)

### Miscellaneous
- Remove accidentally committed .zcode plan file and ignore the directory
- Remove dead responds_to? guards and name the docopt value union explicitly (#11)
- Unique tempfiles in specs and direct ConfigOptions unit tests (#12)
- Fix README placeholders, untrack local settings, add ameba dev-dependency and CI workflow (#13)
- Point CI at the ameba binary shards installs

## 0.2.0 - 2026-09-07

### Bug Fixes
- Fix critical bug: support multiline option descriptions with defaults
- Fix help display to show default values using exit: false
- Fix help display to show defaults

### Miscellaneous
- Initial empty code
- Implement docopt-config library with config file and environment variable support
- Implement docopt-config library with unified configuration from multiple sources
- Replace regex-based default extraction with docopt's built-in functionality
- Remove accidentally committed debug files
- Refactor to hybrid approach: parse twice, use docopt for default extraction
- Add TODO file with potential enhancements
- Support arrays, flags and repeatable options from config files

