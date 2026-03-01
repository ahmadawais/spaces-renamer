<h1 align="center">
  <img src="/SpacesRenamer/Assets.xcassets/AppIcon.appiconset/Icon-1.png?raw=true" width="20%" alt=""/>
  <p align="center">Spaces Renamer</p>
</h1>

Spaces Renamer is a combination of a **SwiftUI menu bar app** and a **SIMBL plugin** that lets you rename your macOS desktop spaces (virtual desktops).

> **v2.0** — rebuilt from scratch with SwiftUI, Swift 5.9+, and native Apple Silicon (M1/M2/M3) support. Requires **macOS 14 (Sonoma)** or later.

<p align="center">
  <img src="smallView.jpg" height="45" ><br>
  <i>The compressed view after pressing F3</i>
</p>

<p align="center">
  <img src="largeView.jpg" height="80" ><br>
  <i>The expanded view after hovering</i>
</p>

<p align="center">
  <img src="renameView.jpg" height="100" ><br>
  <i>The interface for renaming the spaces</i>
</p>

Spaces Renamer supports multiple monitors, and highlights the current space in each monitor with an outline.  Here it is [in a video](https://vimeo.com/264878100) if you want to see it in action.

## What Changed in v2

| Before (v1) | After (v2) |
|---|---|
| AppKit + Storyboards + XIBs | **SwiftUI** with `MenuBarExtra` |
| Swift 4 / macOS 10.11+ | **Swift 5.9+ / macOS 14+** |
| x86_64 only | **Universal (arm64 + x86_64)** — native M1/M2/M3 |
| LetsMove.framework + AppleScript login items | **`SMAppService`** (ServiceManagement) |
| 8 source files + storyboard + XIB | **4 lean Swift files** |

## Requirements

- **macOS 14 (Sonoma)** or later
- **Xcode 15+** to build from source
- [MacForge](https://www.macenhance.com/macforge) (for the SIMBL bundle that patches the Dock)
- SIP partially disabled (see installation steps below)

## Building from Source

```bash
# Clone the repo
git clone https://github.com/dado3212/spaces-renamer.git
cd spaces-renamer

# Open in Xcode
open spaces-renamer.xcodeproj
```

Select the **SpacesRenamer** scheme and build (`⌘B`). The project contains two targets:

| Target | Product | Description |
|--------|---------|-------------|
| `SpacesRenamer` | `SpacesRenamer.app` | SwiftUI menu bar app for renaming spaces |
| `spaces-renamer` | `spaces-renamer.bundle` | SIMBL plugin injected into the Dock |

Both targets build as Universal Binaries (arm64 + x86_64) by default.

## Installation

1. Download or build the latest **SpacesRenamer.app** and **spaces-renamer.bundle**.
2. Download [MacForge](https://www.macenhance.com/macforge). For Apple Silicon Macs, use the [MacForge 1.2.2 (4) beta](https://github.com/user-attachments/files/20972723/spaces-renamer.zip).
3. Partially disable SIP. Boot into Recovery Mode and run:
   ```
   csrutil disable
   ```
   After installation you can partially re-enable:
   ```
   csrutil enable --without debug --without fs --without nvram --without kext
   ```
4. Install the bundle by opening `spaces-renamer.bundle` with MacForge, or copy it to:
   ```
   /Library/Application Support/MacEnhance/Plugins
   ```
5. Restart the Dock:
   ```bash
   killall -9 Dock
   ```
6. Run **SpacesRenamer.app**. It will automatically register as a login item.
7. Click the Spaces Renamer icon in the menu bar, name your spaces, and press **Update Names**.

## Architecture

```
SpacesRenamer/
├── SpacesRenamerApp.swift     # @main SwiftUI App with MenuBarExtra
├── SpaceManager.swift         # @Observable model — workspace monitoring & plist I/O
├── ContentView.swift          # Main popover UI
├── DesktopSnippetView.swift   # Individual desktop card view
├── SpacesRenamerBridge.h      # Bridging header for private CGS APIs
├── Assets.xcassets            # App icon, status bar icon, monitor images
├── Info.plist
└── SpacesRenamer.entitlements

spaces-renamer/                # SIMBL bundle (Objective-C)
├── spacesRenamer.m            # Dock injection via ZKSwizzle
├── ZKSwizzle.{h,m}           # Runtime method swizzling
└── Info.plist
```

## Uninstall

1. Quit SpacesRenamer from Activity Monitor (or click Quit in the menu bar popover).
2. Delete `SpacesRenamer.app` from `/Applications`.
3. Remove the bundle from MacForge, or delete it:
   ```bash
   sudo rm -rf "/Library/Application Support/MacEnhance/Plugins/spaces-renamer.bundle"
   ```
4. Clean up saved data:
   ```bash
   rm -rf ~/Library/Containers/com.alexbeals.SpacesRenamer
   ```

---

Donations [are always appreciated](https://www.paypal.com/paypalme2/AlexBeals), but in no way expected.
