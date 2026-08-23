# Contributing

Bug reports and pull requests are welcome. Please open an issue before making a substantial
API change.

## Development

The package requires Swift 6.0. Before submitting a change, run:

```sh
swiftlint lint --strict
swift test
```

On macOS, CI also builds and tests for an iOS Simulator destination with Xcode 16.4.

Prose in tracked Markdown files is linted with Vale (see `.vale.ini`). Sync styles and lint
with:

```sh
uvx vale@3.13.0.0 sync
git ls-files '*.md' | xargs uvx vale@3.13.0.0
```

Add tests for observable behaviour and update DocC when changing public API.

## Pull requests

- Keep each pull request focused.
- Document user-visible behaviour in DocC and, when relevant, `CHANGELOG.md`.
- Prefer `Fixes #N` in the PR body when closing an issue.
