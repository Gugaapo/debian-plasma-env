# Quick Start Guide - New Machine Setup

This guide will help you recreate your complete Debian KDE Plasma environment on a new machine.

## Prerequisites

- Fresh Debian-based installation (Debian 11+, Ubuntu 20.04+, Linux Mint 20+)
- Internet connection
- Sudo/root access
- Git installed (if not: `sudo apt update && sudo apt install -y git`)

## One-Command Setup

```bash
# Clone the repository
git clone <your-repo-url> ~/debian-plasma-env

# Run the setup script
cd ~/debian-plasma-env
./setup.sh

# Log out and log back in
```

That's it! Your complete environment will be recreated including:
- All packages (apt, flatpak, snap)
- KDE Plasma configuration (panels, widgets, shortcuts, themes)
- Bash environment (oh-my-bash with custom aliases)
- Alacritty terminal
- Claude Code CLI with 17 custom agents
- All application configurations

## Step-by-Step Walkthrough

### 1. Clone the Repository

```bash
git clone <your-repo-url> ~/debian-plasma-env
cd ~/debian-plasma-env
```

### 2. Review Setup Options

```bash
# Preview what will be done (recommended)
./setup.sh --dry-run

# See all available options
./setup.sh --help
```

### 3. Run the Setup

**Full automated setup:**
```bash
./setup.sh
```

**Custom options:**
```bash
# Skip package installation (just configs)
./setup.sh --skip-packages

# Non-interactive mode (for automation)
./setup.sh --non-interactive

# Combination of options
./setup.sh --skip-packages --non-interactive
```

### 4. Post-Setup

```bash
# Log out and log back in for KDE changes to take effect
# Open a new terminal to see bash configuration

# Verify installations
claude --version      # Check Claude Code
alacritty --version   # Check Alacritty
```

## What Gets Installed

### Packages
- **APT packages** - All manually installed packages from your previous system
- **Flatpak** - Applications from Flathub
- **Snap** - Snap packages (if any were used)

### KDE Plasma
- Panel layouts and widgets
- Global keyboard shortcuts
- Window management settings
- Themes and color schemes
- Application-specific settings (Dolphin, Gwenview, etc.)

### Development Tools
- **Claude Code CLI** - Latest version installed to `~/.local/bin/claude`
- **17 Custom Agents** - All your specialized Claude agents
  - sysadmin, api-architect, security-auditor, etc.
- **Agent Configuration** - Permission policies and settings

### Terminal Environment
- **Alacritty** - Terminal emulator with your custom config
- **oh-my-bash** - Bash framework with custom aliases and scripts
- Custom bash aliases and functions
- Git configuration

## Manual Steps (If Needed)

### Claude Code API Key

Claude Code will prompt you for your API key on first use:
```bash
claude
# Follow the prompts to enter your Anthropic API key
```

Or set it manually:
```bash
# The credentials file is intentionally NOT backed up for security
# You'll need to authenticate again
claude auth login
```

### Wallpaper

If wallpaper wasn't auto-detected:
1. Right-click desktop → Configure Desktop and Wallpaper
2. Choose from `~/debian-plasma-env/assets/wallpapers/` (if any)
3. Or select your preferred wallpaper

### SSH Keys

Your SSH keys are not backed up for security. Restore them manually:
```bash
# Copy your SSH keys to the new machine
cp /path/to/backup/id_* ~/.ssh/
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/id_*.pub
```

## Troubleshooting

### KDE Changes Not Applying
```bash
# Log out completely and log back in (don't just lock screen)
# Or restart plasmashell:
kquitapp5 plasmashell && plasmashell &
```

### Bash Changes Not Visible
```bash
# Open a NEW terminal window or reload:
source ~/.bashrc
```

### Claude Code Not in PATH
```bash
# Add to current session:
export PATH="$HOME/.local/bin:$PATH"

# This should already be in ~/.bashrc, but you can add it manually:
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

### Package Installation Failed
```bash
# Update package lists and try again:
sudo apt update
./setup.sh
```

### Permission Errors
```bash
# Ensure setup.sh is executable:
chmod +x setup.sh

# Some operations may need sudo (you'll be prompted)
```

## Backup Information

All existing configurations are automatically backed up to:
```
~/.config-backup-<timestamp>/
```

To restore a backup:
```bash
cp -r ~/.config-backup-<timestamp>/* ~/
```

## Updating Your Configuration

After making changes on your system, update the repository:

```bash
cd ~/debian-plasma-env

# Capture current configuration
./scripts/update-repo.sh

# Review changes
git status
git diff

# Commit and push
git add -A
git commit -m "Update configuration - $(date +%Y-%m-%d)"
git push
```

This captures:
- All package changes
- KDE Plasma configurations
- Bash customizations
- Claude Code agents and settings
- And more!

## Setup Script Options Reference

| Option | Description |
|--------|-------------|
| `--skip-packages` | Only deploy configs, skip package installation |
| `--skip-backup` | Don't backup existing configs (not recommended) |
| `--dry-run` | Show what would be done without executing |
| `--non-interactive` | Don't prompt for confirmations |
| `-h, --help` | Show help message |
| `-v, --version` | Show version |

## Common Scenarios

### Setting Up a Work Machine (No Personal Packages)
```bash
# Install only configurations, skip packages
./setup.sh --skip-packages
```

### Automated VM Setup
```bash
# Fully automated, no prompts
./setup.sh --non-interactive
```

### Testing Configuration Changes
```bash
# See what would happen without making changes
./setup.sh --dry-run
```

## Support

- **Log File**: `~/debian-plasma-env/setup.log`
- **Backup Location**: `~/.config-backup-<timestamp>/`
- **Documentation**: `~/debian-plasma-env/docs/`

## Next Steps

After setup completes:

1. **Verify Everything Works**
   - Test keyboard shortcuts
   - Open applications (Dolphin, Alacritty, etc.)
   - Run `claude --help` to test Claude Code

2. **Customize Further**
   - See `docs/CUSTOMIZATION.md` for customization tips
   - Modify configs as needed
   - Run `./scripts/update-repo.sh` to capture changes

3. **Set Up Sync** (Optional)
   - Push to GitHub/GitLab for cloud backup
   - Set up on multiple machines
   - Keep configurations in sync

---

**Your complete development environment, one script away!** 🚀
