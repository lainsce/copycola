# Copycola

## A calm, spatial canvas for ideas

![Copycola in English with sample canvases and cards](data/Copycola-English.png)

Copycola is a native macOS app for arranging images and their captions on canvases. Each canvas keeps a simple four-column rhythm, an optional dot grid, and an open vertical workspace so related ideas can stay visible together.

## What you can make

- **Image** cards with captions and optional links
- **Header** cards generated automatically for naming and grouping each canvas

Headers are structural; images are the only user-creatable card. Canvases are persisted locally with SwiftData, and the sidebar provides compact previews of each board.

## Requirements

- macOS 27 or later
- Xcode 27 or later
- Swift 6

Copycola is currently an unsigned development project. Signing, notarization, and App Store distribution are intentionally not configured yet.

## Build

Clone the repository and open the Xcode project:

```bash
git clone https://github.com/lainsce/copycola.git
cd copycola
open Copycola.xcodeproj
```

To build an unsigned macOS app from Terminal:

```bash
xcodebuild \
  -project Copycola.xcodeproj \
  -scheme Copycola \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/Copycola-DerivedData \
  build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO
```

Focused Swift Testing sources are kept in `tests/` alongside the application source.

## Project layout

```text
src/                         application source
  Canvas/                    canvas layout, gestures, grid, and card creation
  Card/                      shared card shell and type-specific card views
  Sidebar/                   canvas list and preview artwork
  PrivacyPolicy/             privacy policy window
tests/                       Swift Testing tests
data/                        asset catalog, icon, localization, privacy, entitlements
Copycola.xcodeproj/           Xcode project and shared scheme
```

The `data/` folder is part of the repository so a fresh checkout contains every resource required by the project.

## Development checks

For a fast source-only parse:

```bash
find src tests -name '*.swift' -print0 | \
  xargs -0 xcrun swiftc -frontend -parse \
  -sdk /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
```

Resource metadata and privacy files can be checked with:

```bash
find data/Copycola.xcassets data/Copycola.icon -name '*.json' -print0 | \
  xargs -0 -n1 jq empty
plutil -lint data/Copycola.entitlements data/PrivacyInfo.xcprivacy
```

## Privacy

Copycola includes a privacy policy window in the macOS Help menu and ships its required privacy manifest in [`data/PrivacyInfo.xcprivacy`](data/PrivacyInfo.xcprivacy).
