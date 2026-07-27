# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- Macros `deftrans` and `defbypass` are now usable without parenthesis when
  importing the dependency in your `.formatter.exs` file.
- Macros `deftrans` and `defbypass` now supports `when` clause.


### Fixed

- Detect output states from transition with multiple function heads correctly
  which fixes the returned output state of the `fsm/0` function.

### Changed

- **BREAKING**: the reserved Elixir `@doc` attribute used to add documentation
  transitions and bypasses was removed as it emitted warnings when used on
  a transition or bypasss with several heads. Instead use the `@transition_doc`
  for transition and the `@bypass_doc` for bypasses.
