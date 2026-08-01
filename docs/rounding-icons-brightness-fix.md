# Fix: Rounding, Icons, and Brightness

## Symptoms

1. **Window corner rounding not applied**: Changing the rounding value in the dashboard had no effect on the windows.
2. **Kora icon theme not loading**: App icons showed fallback Phosphor icons instead of the themed Kora icons.
3. **Brightness control not working in dashboard**: The slider in the bar was unresponsive or did not change the screen brightness, despite the CLI working.

## Root Cause Analysis

### 1. Rounding Issue
`CompositorConfig.qml` was correctly calculating the `hyprctl` batch command but never executing it. It only refreshed the `axctl.toml` file. While `axctl` might read this file at startup, live changes require direct compositor communication.

### 2. Kora Icon Theme Issue
The `ambxst` launcher wrapper was exporting a restricted `XDG_DATA_DIRS` that omitted the user's profile and Home Manager paths. Since icon themes are typically installed in the user profile, Quickshell could not find them. Additionally, there was no explicit propagation of the GTK icon theme name to the Qt environment.

### 3. Brightness Issue
The brightness detection logic for internal screens was using a brittle `sh -c` wrapper around `brightnessctl` and had a limited list of internal display name patterns. If the monitor detection failed or the shell wrapper failed to parse, the monitor would never reach the `ready` state required for the slider to work.

## Fixes Applied

### Compositor Rounding
Modified `modules/services/CompositorConfig.qml` to execute the assembled `batchCommand` using `hyprctl batch`. This ensures that all decoration changes (rounding, borders, gaps, etc.) are applied live to the compositor.

### Icon Theme
Updated `nix/packages/default.nix` to:
- Include `$HOME/.nix-profile/share` and `/etc/profiles/per-user/$USER/share` in `XDG_DATA_DIRS`.
- Add a check for the current GTK icon theme using `gsettings` and export it as `QS_ICON_THEME` and `XCURSOR_THEME` to help Quickshell/Qt resolve icons correctly.

### Brightness Backend
Improved `modules/services/Brightness.qml` by:
- Expanding the internal screen detection patterns (adding `lcd`, `internal`).
- Replacing the brittle `sh -c` initialization with a direct call to `brightnessctl -m` (machine-readable output).
- Adding a robust CSV parser for `brightnessctl -m` output to ensure the monitor state is correctly initialized.

## Verification

These fixes require a system rebuild to take effect as they involve changes to the Nix package wrapper and the QML services bundled in the Nix store.

- **Rounding**: Verify by changing rounding in Dashboard > Compositor and observing immediate window changes.
- **Icons**: Verify that app icons in the Taskbar/Workspaces match the Kora theme.
- **Brightness**: Verify that the bar slider changes the screen brightness and matches the CLI behavior.
