# Sendable and concurrency

How ``CommandPaletteKit`` types interact with Swift concurrency.

## Overview

The palette runs on the main actor. Candidate providers, row actions, and activation
handlers are all `@MainActor` closures, so building and mutating ``PaletteResult`` values
should happen on the main actor in host apps.

### Sendable types

These value types are safe to pass across concurrency domains:

- ``CommandPaletteStyle``
- ``PaletteScorer`` (must be `@Sendable`; the default ``paletteFuzzyScore(_:_:)`` is)

### Non-Sendable by design

``PaletteResult`` carries a main-actor ``PaletteResult/action`` closure. It is marked
`@unchecked Sendable` only so candidate arrays can be stored in generic containers that
require a Sendable element type; callers remain responsible for keeping action closures
main-actor isolated and not sharing results across actors.

Do not pass ``PaletteResult`` instances into background tasks. Build candidates on the main
actor, present ``CommandPaletteView``, and run actions from activation on the main actor.
