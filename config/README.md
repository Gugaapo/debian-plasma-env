# Configuration Files

This directory contains all configuration files that will be deployed to your system.

## Structure

- **bash/** - Bash shell configuration (.bashrc, oh-my-bash custom files)
- **kde/** - KDE Plasma configuration files (panels, shortcuts, themes)
- **alacritty/** - Alacritty terminal emulator configuration
- **gtk/** - GTK theme settings for consistency
- **git/** - Git configuration (sanitized)

## Notes

- Files here will be copied to their respective locations in `$HOME/.config/` or `$HOME/`
- Existing configurations will be backed up before being replaced
- Sensitive data (passwords, API keys) should NOT be committed here
