Create 13 GitHub issues on ralsina/docopt-config via `gh issue create`, in this order (so cross-references as #N resolve). Labels: default `bug`/`enhancement`/`documentation` sets.

**Bugs:**
1. `bug` — **Env vars and config files can never enable boolean flags**. Absent flags come back `false` (not nil) from docopt, so the `!@args[key].nil?` check (src/docopt-config.cr:16-18) short-circuits and env/config are never consulted for flags. Repro: `Usage: test [--force]` + `MYAPP_FORCE=true` → `options["--force"]` is `false`. Suggests tracking CLI-provided keys explicitly; notes the spec suite has zero flag coverage.
2. `bug` — **Usage errors exit with status 0 and swallow the error message**. `rescue DocoptExit` (src/docopt-config.cr:182-185) prints the full doc and `Process.exit(0)`; the raised message (e.g. "--verbose requires argument") is dropped. Should exit 1 and print message + usage.
3. `bug` — **Case-insensitive `[DEFAULT: ...]` breaks precedence**. `remove_docopt_defaults` (:195) lacks `/i` while docopt.cr's default parsing is case-insensitive, so `[DEFAULT: 3]` leaks into args and is treated as a CLI value env/config can't override.
4. `bug` — **Boolean env vars arrive as Strings; "false" is truthy**. `env_vars` is `Hash(String, String)`; `MYAPP_FORCE=false` yields truthy `"false"` while config-file bools are converted — type inconsistency across sources. Suggests coercion for flag options.
5. `bug` — **`has_key?` disagrees with `[]`**. Misses clean_key/snake_key config fallbacks and never checks docopt_defaults (:90-98).
6. `bug` — **Lossy type conversions**. Float defaults truncated via `to_f.to_i32` (:233), Int64→Int32 narrowing (:37), YAML arrays/nested values stringified via `to_s` (:39/55/71).

**Design/robustness:**
7. `enhancement` — **`--help` detection is positional-blind**. Any argv containing `--help`/`-h` triggers help (:118), even after `--` or when the doc defines no help option; diverges from docopt semantics.
8. `enhancement` — **`Process.exit` in library paths makes help/version/error untestable**. Early exits (:118-126) and both rescues (:182, :186-189) hard-exit and print to stdout; suggest a `exit: false`-style mode like docopt.cr so specs can cover these paths (unblocks #2).
9. `enhancement` — **Malformed config file is silently ignored**. `rescue ex → nil` (:157-160); at minimum warn on stderr. Makes the TODO.md "better error reporting" item concrete.
10. `enhancement` — **`env_prefix: nil` hoovers all env vars into option keys** (PATH → `--path`, :174-178); collision footgun.

**Code quality / tests / repo:**
11. `enhancement` — **Code quality cleanup**: dedupe triplicated YAML value-conversion case blocks (:31-40/47-56/63-72), add a `Value` type alias (union spelled out 6×), remove dead `responds_to?` guards (:206-208), simplify `has_key?` conditional.
12. `enhancement` — **Test coverage gaps**: boolean flags, help/version/error paths, malformed YAML, `has_key?`, direct `ConfigOptions` unit tests; ENV-mutation and fixed /tmp-path hygiene.
13. `documentation` — **Repo hygiene**: `your-github-user` README placeholders, committed `.claude/settings.local.json`, no CI workflow, no Ameba dev-dependency/config.

Each body will include the evidence with file:line references, a reproduction where applicable, and a suggested fix direction. No AI attribution in bodies. After creation I'll report the issue URLs.