# Screen Tools

**A lightweight macOS menu-bar app for presentations, demos, and screen recordings.**
It lives in your menu bar (🪄) and gives you four on-screen tools you can toggle instantly with global hotkeys — highlight your cursor, magnify part of the screen, spotlight an area, and run a countdown timer.

---

## What it does

| Tool | Hotkey | Description |
|------|--------|-------------|
| **Mouse Halo** | ⌥⌘1 | A soft pink glow that follows your cursor so the audience can find it. |
| **Magnifier** | ⌥⌘2 | A "looking glass" that zooms the area under your cursor. |
| **Spotlight** | ⌥⌘3 | Dims the whole screen except a bright circle around your cursor. |
| **Countdown** | ⌥⌘4 | A large countdown timer in the middle of the screen. |
| **Zoom in / out** | ⌥⌘= / ⌥⌘- | Change the magnifier's zoom level. |
| **Turn everything off** | Esc | Only active while a tool is on — never interferes with Esc elsewhere. |

You can also click the **🪄 menu-bar icon** to toggle tools, and open **Settings** there to change colors, sizes, dimming, zoom, and the default timer length.

---

## Install

### Option A — download the packaged app
1. Grab `ScreenTools.dmg` (or `.zip`) from the [latest release](https://github.com/StrawberryBe/ScreenTools/releases/latest).
2. Open the `.dmg` and drag the app to **Applications** (or unzip the `.zip` into Applications).
3. The first time, **right-click the app → Open** (not double-click) and confirm. This is required once because the app isn't signed by an identified Apple developer.
4. The 🪄 icon appears in your menu bar. There is no Dock icon.

### Option B — build it yourself from source
Requires **Xcode** (Mac App Store) and **XcodeGen** (`brew install xcodegen`).
```bash
cd ScreenTools
xcodegen generate
xcodebuild -project ScreenTools.xcodeproj -scheme ScreenTools -configuration Release build
```
The built app is under Xcode's DerivedData; copy it to `/Applications`.

### Maintainers — cutting a new release
`scripts/package.sh` builds a Release configuration, stages it with an
`Applications` symlink, and produces `dist/ScreenTools.dmg` / `dist/ScreenTools.zip`.
Upload those to a new [GitHub release](https://github.com/StrawberryBe/ScreenTools/releases)
so Option A above keeps working.

---

## First run: permissions

- **Screen Recording** — needed **only** by the Magnifier. The first time you turn the magnifier on, macOS asks for permission. Enable **Screen Tools** under *System Settings → Privacy & Security → Screen Recording*, then **quit and reopen** the app.
- **No Accessibility permission is required.** Global hotkeys and cursor tracking work without it.

---

## How to use

1. Start a presentation or screen share.
2. Press a hotkey (e.g. **⌥⌘3** for spotlight) — it works over any app, including full-screen.
3. Press the same hotkey again to turn it off, or **Esc** to turn everything off.
4. Drag the **Countdown** window anywhere; use the ± buttons to adjust and ▶ to start.

---

## Notes & current limitations

- Tools activate on the display where your cursor is (single-display at a time).
- Hotkeys are fixed in this version (Settings shows them; rebinding is not yet available).

---

## Troubleshooting

- **Magnifier shows nothing / a black circle:** Screen Recording permission isn't granted (or was reset by an update). Re-grant it under *System Settings → Privacy & Security → Screen Recording* and relaunch.
- **"App is damaged / from an unidentified developer":** Right-click the app → Open, or run `xattr -dr com.apple.quarantine /Applications/ScreenTools.app`.
- **A hotkey does nothing:** Another app may already use that shortcut. Use the menu-bar 🪄 menu instead.
