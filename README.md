# Debian KDE Plasma Environment

Complete Debian KDE Plasma environment recreation from a single script.

## Overview

This repository contains everything needed to recreate my complete Debian KDE Plasma desktop environment on any Debian-based distribution. Simply clone and run the setup script to get a fully configured system with all my customizations, configurations, and preferences.

## Features

- **Single-command setup** - One script does it all
- **Complete KDE Plasma configuration** - Panels, widgets, shortcuts, themes
- **Custom bash environment** - oh-my-bash with custom aliases and scripts
- **Alacritty terminal** - Pre-configured with custom theming
- **Custom keyboard shortcuts** - All my KDE global shortcuts
- **Application configurations** - Dolphin, Gwenview, and more
- **Automatic backups** - Your existing configs are safely backed up
- **Idempotent** - Safe to run multiple times

## Quick Start

```bash
git clone <your-repo-url> ~/debian-plasma-env
cd ~/debian-plasma-env
./setup.sh
```

Then log out and log back in for full effect.

**For detailed instructions, see [QUICK_START.md](QUICK_START.md)**

## What's Included

### System Configuration
- [X] Package installation (apt)
- [X] KDE Plasma desktop configuration
- [X] Bash configuration with oh-my-bash
- [X] Alacritty terminal emulator
- [X] Claude Code CLI with custom agents
- [X] Custom aliases and scripts
- [X] Global keyboard shortcuts
- [X] GTK theme integration
- [X] Git configuration

### Applications Configured
- Dolphin (file manager)
- Gwenview (image viewer)
- Ark (archive manager)
- Alacritty (terminal)
- Claude Code (AI coding assistant with 17 custom agents)

## Requirements

- Debian-based distribution (Debian 11+, Ubuntu 20.04+, Linux Mint 20+, etc.)
- KDE Plasma desktop environment (will be installed if not present)
- Internet connection (for package installation)
- Sudo access

## Installation Options

```bash
# Full setup with prompts
./setup.sh

# Skip package installation (configs only)
./setup.sh --skip-packages

# Skip backups (not recommended)
./setup.sh --skip-backup

# Preview what would be done
./setup.sh --dry-run

# Non-interactive mode (for automation)
./setup.sh --non-interactive
```

## Documentation

- [Installation Guide](docs/INSTALLATION.md) - Detailed installation instructions
- [Customization](docs/CUSTOMIZATION.md) - How to customize for your needs
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Maintenance](docs/MAINTENANCE.md) - Keeping your repo updated

## Repository Structure

```
debian-plasma-env/
├── setup.sh                    # Main installation script
├── config/                     # Configuration files
│   ├── bash/                   # Bash and oh-my-bash configs
│   ├── kde/                    # KDE Plasma configurations
│   ├── alacritty/              # Alacritty terminal config
│   ├── gtk/                    # GTK theme settings
│   └── git/                    # Git configuration
├── claude-code/                # Claude Code setup
│   ├── agents/                 # 17 custom Claude agents
│   ├── config/                 # Claude settings
│   └── docs/                   # Claude documentation
├── packages/                   # Package lists
├── scripts/                    # Installation modules
│   ├── modules/                # Modular install scripts
│   ├── backup.sh               # Backup utility
│   ├── update-repo.sh          # Update configs from system
│   └── utils.sh                # Shared utilities
├── assets/                     # Wallpapers and screenshots
└── docs/                       # Documentation
```

## Updating Your Configuration

After making changes to your system, update the repository:

```bash
./scripts/update-repo.sh
git add -A
git commit -m "Update configurations"
git push
```

## Safety Features

- **Automatic backups** - Existing configs backed up to `~/.config-backup-<timestamp>/`
- **Dry-run mode** - Preview changes before applying
- **Interactive prompts** - Confirm important operations
- **Logging** - All operations logged to `setup.log`
- **Rollback info** - Backup locations clearly displayed

## Compatibility

Tested on:
- Debian 12 (Bookworm)
- Debian 11 (Bullseye)
- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS
- Linux Mint 21

Should work on any Debian-based distribution with KDE Plasma.

## Contributing

This is a personal configuration repository, but feel free to fork it and adapt it for your own use!

## License

MIT License - Feel free to use and modify for your own dotfiles setup.

## Credits

Created by: Gustavo
Based on personal Debian KDE Plasma setup

---

**Note**: This repository contains personal configurations. Review the configs before applying to ensure they match your preferences!
