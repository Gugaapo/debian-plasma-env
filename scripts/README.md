# Scripts

This directory contains all installation and utility scripts.

## Main Scripts

- **backup.sh** - Backup existing configurations before installation
- **update-repo.sh** - Update repository with current system configuration
- **verify.sh** - Verify installation was successful
- **utils.sh** - Shared utility functions (logging, prompts, etc.)

## Module Scripts (modules/)

Installation modules executed by `setup.sh`:

1. **00-prerequisites.sh** - System checks and validation
2. **10-packages.sh** - Package installation (apt, flatpak, snap)
3. **20-oh-my-bash.sh** - oh-my-bash installation and configuration
4. **30-dotfiles.sh** - Deploy dotfiles (bashrc, gitconfig, etc.)
5. **40-kde-config.sh** - KDE Plasma configuration restoration
6. **50-alacritty.sh** - Alacritty terminal configuration
7. **99-finalize.sh** - Post-installation tasks and summary

## Module Structure

Each module should define a main function:

```bash
#!/bin/bash
# Module description

main_XX_module_name() {
    log_section "Module Name"

    # Module logic here

    log_success "Module completed"
    return 0
}
```

## Utility Functions

Available from `utils.sh`:

- `log_info()` - Info message
- `log_success()` - Success message
- `log_warning()` - Warning message
- `log_error()` - Error message
- `log_section()` - Section header
- `confirm()` - User confirmation prompt
- `command_exists()` - Check if command is available
