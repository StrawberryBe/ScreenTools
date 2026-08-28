# Screen Tools — QA Report

**Date:** 2026-08-28
**Build:** Debug, local ad-hoc signed (`.scratch/DerivedData`), reinstalled to `/Applications/ScreenTools.app`
**Scope:** Verification after removing the Paint feature and renumbering Countdown to `⌥⌘4`.

## Summary

| Check | Result |
|---|---|
| Clean build (xcodegen + xcodebuild) | ✅ Build succeeded, 0 warnings, 0 errors |
| Stale references to removed Paint feature | ✅ None found (`grep -rni paint Sources` → no matches) |
| Hotkey / menu / settings shortcut numbering consistent | ✅ Halo=1, Magnifier=2, Spotlight=3, Countdown=4 across `HotKeyCenter.swift`, `MenuContent.swift`, `SettingsView.swift` |
| Launch/toggle/quit stability cycles | ✅ 20/20 passed |

## 20-cycle launch/toggle stability test

Each cycle launches the built app with a specific tool auto-enabled
(`SCREENTOOLS_DEBUG_TOOL=<tool>`), confirms the process stays alive for 1.2s,
checks for a fresh macOS crash report (`~/Library/Logs/DiagnosticReports`),
and scans stdout/stderr for fatal errors, then quits it. Tools rotate
halo → magnifier → spotlight → countdown, 5 full rotations = 20 cycles.

| Cycle | Tool | Result | Process alive | Crash report | Errors seen |
|---|---|---|---|---|---|
| 1 | halo | PASS | yes | no | — |
| 2 | magnifier | PASS | yes | no | — |
| 3 | spotlight | PASS | yes | no | — |
| 4 | countdown | PASS | yes | no | — |
| 5 | halo | PASS | yes | no | — |
| 6 | magnifier | PASS | yes | no | — |
| 7 | spotlight | PASS | yes | no | — |
| 8 | countdown | PASS | yes | no | — |
| 9 | halo | PASS | yes | no | — |
| 10 | magnifier | PASS | yes | no | — |
| 11 | spotlight | PASS | yes | no | — |
| 12 | countdown | PASS | yes | no | — |
| 13 | halo | PASS | yes | no | — |
| 14 | magnifier | PASS | yes | no | — |
| 15 | spotlight | PASS | yes | no | — |
| 16 | countdown | PASS | yes | no | — |
| 17 | halo | PASS | yes | no | — |
| 18 | magnifier | PASS | yes | no | — |
| 19 | spotlight | PASS | yes | no | — |
| 20 | countdown | PASS | yes | no | — |

**Result: 20/20 PASS.**

## Known limitations of this pass

- These cycles verify process stability (no crash on launch/toggle/quit) and
  static consistency of shortcut wiring. They do **not** verify pixel-level
  visual correctness (e.g. halo glow rendering, spotlight dimming, magnifier
  zoom image) — that still needs a human to look at the screen.
- Mouse-driven interaction (dragging the countdown HUD, clicking menu bar
  toggles) was not exercised by automation in this pass; only the
  `SCREENTOOLS_DEBUG_TOOL` auto-enable path was used.

## How to reproduce

```bash
xcodegen generate
xcodebuild -project ScreenTools.xcodeproj -scheme ScreenTools -configuration Debug \
  -derivedDataPath .scratch/DerivedData build
.scratch/qa/run_cycles.sh
cat .scratch/qa/results.tsv
```
