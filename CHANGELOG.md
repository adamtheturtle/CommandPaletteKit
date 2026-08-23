# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.2] - 2026-08-04

### Fixed

- Materialize one result snapshot so display, navigation, and Return activation share the
  same ranking when a scorer is stateful.
- Measure custom row heights for Page Up/Down instead of assuming a fixed 36-point row.
- Reject stale async candidate loads after cancellation or a newer generation.
- Bound top-result selection so large catalogs are not fully sorted before `resultLimit`.
- Normalize non-finite and oversized palette width/height before layout.
- Make page-navigation arithmetic total for pathological heights.
- Deduplicate palette result IDs with first-candidate-wins semantics.
- Pass modified arrow keys through to the focused search field.
- Treat newline-only queries as empty searches.
- Clamp negative and oversized `resultLimit` values.

## [0.2.0] - 2026-07-18

### Added

- Swift Package Index documentation link and compatibility badges.
- Focus selection without hover on tvOS.

### Fixed

- Scope the macOS key monitor to the palette window.
- Snapshot extended keyboard-navigation flags for the escaping monitor closure.
- Suppress hover selection while keyboard-driven scrolling is in flight.

## [0.1.0] - 2026-06-24

### Added

- Dependency-free SwiftUI command palette for macOS and iPad.
- Fuzzy matching, keyboard navigation, custom rows, styling, and async candidate providers.
- DocC catalog and tests.

[Unreleased]: https://github.com/adamtheturtle/CommandPaletteKit/compare/v0.2.2...HEAD
[0.2.2]: https://github.com/adamtheturtle/CommandPaletteKit/compare/v0.2.0...v0.2.2
[0.2.0]: https://github.com/adamtheturtle/CommandPaletteKit/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/adamtheturtle/CommandPaletteKit/releases/tag/v0.1.0
