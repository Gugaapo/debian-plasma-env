# KDE Plasma Configuration

This directory contains KDE Plasma desktop environment configurations.

## Structure

- **config/** - Configuration files from `~/.config/`
  - `kdeglobals` - Global KDE settings (theme, colors, fonts)
  - `kglobalshortcutsrc` - Keyboard shortcuts
  - `plasma-org.kde.plasma.desktop-appletsrc` - Panel layout and widgets
  - `plasmashellrc` - Plasma shell settings
  - `kwinrc` - Window manager configuration
  - Application-specific configs (dolphinrc, gwenviewrc, etc.)

- **local/** - Data files from `~/.local/share/`
  - Custom widgets (plasmoids)
  - Custom themes
  - Other Plasma data

## Important Notes

- KDE configuration is best applied when NOT logged into KDE
- After applying configs, log out and log back in
- Some settings may require `plasmashell` restart
- Panel layouts are screen-specific and may need adjustment

## Configuration Files Reference

| File | Purpose |
|------|---------|
| kdeglobals | Theme, colors, fonts, global settings |
| kglobalshortcutsrc | All keyboard shortcuts |
| plasma-org.kde.plasma.desktop-appletsrc | Desktop/panel layout, widgets |
| plasmashellrc | Shell behavior, screen configs |
| kwinrc | Window manager rules, effects, compositing |
| dolphinrc | File manager settings |
| breezerc | Breeze theme customizations |
