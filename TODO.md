# TODO - Potential Enhancements

## Priority 1
- [ ] Support for multiple config files with cascade loading
  - System-wide config (`/etc/app/config.yml`)
  - User config (`~/.config/app/config.yml`)
  - Project config (`./config.yml` or `./.app-config.yml`)
  - Later files override earlier ones in the cascade

## Priority 2
- [ ] Add support for .env files via gdotdesign/cr-dotenv
  - Allow loading project-specific environment variables from .env files
  - Consider whether .env should be auto-detected or explicitly specified
  - Evaluate impact on current precedence hierarchy

## Future Considerations
- [ ] Config validation with schema support
- [ ] Support for other config formats (JSON, TOML)
- [ ] Config file hot-reloading
- [ ] Environment variable substitution in config files
- [ ] More comprehensive error reporting for invalid configurations

## Design Notes
- Keep the library focused and maintain the clean CLI > env > config > defaults precedence
- Ensure any new features don't break existing functionality
- Consider the added complexity vs. benefit for each feature