# Copycola agent guide

This file is the short, reusable orientation for agents working on Copycola. Read it before exploring the project. Preserve unrelated user changes in the worktree.

## Project identity

- Native macOS SwiftUI + SwiftData app named Copycola.
- Swift 6, macOS deployment target 27.0, AppKit integration.
- The project is intentionally unsigned until Apple notarization/signing is available. Do not sign, notarize, submit, or change the team/signing policy unless explicitly asked.
- Xcode project: `Copycola.xcodeproj/project.pbxproj`.

## Repository layout

This checkout follows the project-wide layout convention:

```text
src/                         application source
  Canvas/                    canvas model, layout, gestures, grid, direct image creation
  Card/
    Shared/                  Card model, kind/sizing, chrome, CardView, shared editors
    Header/ Image/            type-specific card implementations
  Sidebar/                   sidebar views, previews, and native material
  PrivacyPolicy/             privacy policy window views
  *.swift                    app shell, commands, shared color helpers
tests/                       Swift Testing tests
data/                       non-Swift files and resources in this checkout
```

`data/` is part of this repository. It contains `Copycola.xcassets`, `Copycola.icon`, `Copycola.entitlements`, `Localizable.xcstrings`, and `PrivacyInfo.xcprivacy`.

The Xcode project uses `PBXFileSystemSynchronizedRootGroup` for `src/` and `tests/`, so files placed below those roots are automatically target-managed. The `data` group is explicit because it contains resources outside the synchronized source roots; update the project file when adding or moving data resources.

## Architecture

### Canvas

- `src/Canvas/CanvasView.swift` owns board presentation, vertical scrolling, card placement, selection, drag/drop, sheets, creation, deletion, and canvas commands.
- `CanvasCardLayer.swift` owns repeated card interaction/gesture/accessibility wiring; `CardView` owns card chrome and type routing.
- The canvas is fixed-width (four card columns plus 40-point margins) with unbounded vertical space. Do not reintroduce x-axis panning.
- Dot-grid visibility persists through `@AppStorage("copycola.canvas.shows-dot-grid")`.
- Sheet presentation uses `Identifiable` payloads carrying the actual `Card`; avoid target-ID lookups that can race sheet presentation.
- `CanvasPlacement` is pure placement logic and has tests in `tests/CanvasPlacementTests.swift`.

### Cards

`CardKind` currently contains `header` and `image`. Header is structural and generated automatically; Image is the only user-creatable kind. Image cards may carry optional outbound URL metadata.

- `Card/Shared/Card.swift` is the SwiftData model. It keeps only shared fields used by the supported kinds; changes to persisted properties still require deliberate migration review.
- `Card/Shared/CardView.swift` is shared shell/routing/selection chrome. Keep type-specific layouts in their matching `Card/<Kind>/` folder.
- `Card/Shared/CardChrome.swift` is the single source of truth for card and populated-preview treatment:
  - black outline opacity `0.06`
  - white-to-clear inner highlight, starting at opacity `0.22`, 1 point
  - shadow equivalent to `0 2px 3px 0 alpha(#000, 0.03)`
  - normal radius `24`; only 2×2 cards use the larger radius (`28`)
  - sidebar preview radius is `10`
- Empty previews and drag drop ghosts intentionally stay flat and do not receive card chrome.
- Header cards intentionally use a divider-only treatment rather than card shadow/corners.
- `CanvasMetrics` is the geometry source of truth: 40-point gutter, 5-point fine grid, 2-point regular dots, 3-point major dots, 175-point 1×1 cell, 60-point header, 8-point header-to-content spacing, and 16-point content inset.

### Sidebar and policy

- `src/Sidebar/SidebarMaterialBackground.swift` uses AppKit `NSVisualEffectView.Material.sidebar`; do not replace it with a generic SwiftUI material when native sidebar parity matters.
- `src/Sidebar/` owns canvas list editing, thumbnails, previews, and sidebar background.
- Privacy Policy is a separate macOS window/menu route, not an extra in-canvas UI surface.

## UI and accessibility invariants

- Use the bundled `.accent` color; do not introduce `.accentColor`.
- Image-only buttons must remain image-only visually. Put the action name in `.help(...)` and an accessibility label, not visible button text.
- Respect `accessibilityReduceMotion` for animations, including card drag tilt and the image-cutout preview shimmer.
- The add-image anchor is a direct toolbar plus button that opens the image importer.
- While dragging a card, hide the delete control and card action bar.
- Keep the native macOS menu/toolbar action hierarchy intact; route global actions through focused scene values/commands.

## Data, localization, and privacy

- Keep user-facing strings in `data/Localizable.xcstrings`; use SwiftUI localization APIs and translator comments for interpolated strings.
- Keep `PrivacyInfo.xcprivacy` in the data resource set. Do not remove it during resource moves.
- Entitlements are referenced by both Debug and Release as `data/Copycola.entitlements`.
- Asset catalog and icon composer resources are explicit members of the app Resources build phase.

## Validation

Run focused checks after source/layout changes:

```sh
# Parse all app and test Swift files without requiring macro plugins.
find src tests -name '*.swift' -print0 | xargs -0 xcrun swiftc -frontend -parse \
  -sdk /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk

git diff --check

plutil -lint data/Copycola.entitlements
plutil -lint data/PrivacyInfo.xcprivacy
```

For a string catalog check, compile to a temporary output directory:

```sh
catalog_tmp=$(mktemp -d /tmp/Copycola-xcstrings.XXXXXX)
xcrun xcstringstool compile data/Localizable.xcstrings \
  --output-directory "$catalog_tmp" --dry-run
```

For asset metadata, run `find data/Copycola.xcassets data/Copycola.icon -name '*.json' -print0 | xargs -0 -n1 jq empty`; `xcrun actool --compile` can validate the catalog.

Use an unsigned macOS build when the host permits it:

```sh
xcodebuild -project Copycola.xcodeproj -scheme Copycola \
  -configuration Release -destination 'platform=macOS' build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

This host has repeatedly failed `xcodebuild`/`CoreSimulatorService` discovery with exit 143, even for macOS-only project inspection. Treat those errors as environment failures unless compiler diagnostics follow them; report what actually validated.

## Editing rules

- Use `apply_patch` for content edits. Physical file moves are appropriate for requested organization changes.
- Do not use destructive resets or discard unrelated dirty/staged work.
- Prefer small, focused SwiftUI view types with narrow inputs over large computed-property sections.
- After moving files, check the synchronized-root paths and any explicit data/resource references in `project.pbxproj`.
