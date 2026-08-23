# Documentation

Where to read the hosted API reference for CommandPaletteKit.

## Overview

The package ships a DocC catalog under `Sources/CommandPaletteKit/CommandPaletteKit.docc`.
Symbol-level doc comments in source feed the generated reference.

### Hosted documentation

Documentation is published automatically on every push to `main`:

- [Swift Package Index](https://swiftpackageindex.com/adamtheturtle/CommandPaletteKit/documentation/commandpalettekit)
- [GitHub Pages](https://adamtheturtle.github.io/CommandPaletteKit/documentation/commandpalettekit)

The README links to SPI by default. Both sites are built from the same DocC sources using
the Swift-DocC plugin in `.github/workflows/docs.yml`.

### Local preview

```sh
SWIFT_PACKAGE_ENABLE_DOCC=1 swift package \
  generate-documentation \
  --target CommandPaletteKit \
  --output-path ./docs-preview
open ./docs-preview/data/documentation/commandpalettekit/index.html
```

## Topics

- <doc:GettingStarted>
- <doc:Customization>
- <doc:KeyboardNavigation>
