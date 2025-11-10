#!/bin/bash
#
# Backup existing configuration
# Creates backup of existing configs before making changes
#

main_backup() {
    log_section "Creating Configuration Backup"

    if [[ "$SKIP_BACKUP" == true ]]; then
        log_warning "Backup skipped (--skip-backup flag)"
        return 0
    fi

    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    log_info "Backup directory: $BACKUP_DIR"

    local backed_up=0

    # Backup critical files
    log_info "Backing up configuration files..."

    backup_if_exists "$HOME/.bashrc" && ((backed_up++))
    backup_if_exists "$HOME/.bash_profile" && ((backed_up++))
    backup_if_exists "$HOME/.profile" && ((backed_up++))
    backup_if_exists "$HOME/.gitconfig" && ((backed_up++))
    backup_if_exists "$HOME/.gtkrc" && ((backed_up++))
    backup_if_exists "$HOME/.gtkrc-2.0" && ((backed_up++))

    # Backup directories
    log_info "Backing up configuration directories..."

    backup_dir_if_exists "$HOME/.config/alacritty" && ((backed_up++))
    backup_dir_if_exists "$HOME/.config/gtk-3.0" && ((backed_up++))
    backup_dir_if_exists "$HOME/.config/gtk-4.0" && ((backed_up++))
    backup_dir_if_exists "$HOME/.oh-my-bash/custom" && ((backed_up++))

    # Backup KDE configs
    log_info "Backing up KDE Plasma configurations..."

    local kde_configs=(
        "kdeglobals"
        "kglobalshortcutsrc"
        "plasma-org.kde.plasma.desktop-appletsrc"
        "plasmashellrc"
        "kwinrc"
        "kwinrulesrc"
        "kded5rc"
        "plasma-localerc"
        "plasmanotifyrc"
        "breezerc"
        "bluedevilglobalrc"
        "xdg-desktop-portal-kderc"
        "dolphinrc"
        "gwenviewrc"
        "arkrc"
        "katerc"
        "konsolerc"
        "spectaclerc"
    )

    for config in "${kde_configs[@]}"; do
        if backup_if_exists "$HOME/.config/$config"; then
            ((backed_up++))
        fi
    done

    # Create backup manifest
    create_backup_manifest

    if [[ $backed_up -gt 0 ]]; then
        log_success "Backup created successfully"
        log_info "Files backed up: $backed_up"
        log_info "Location: $BACKUP_DIR"
    else
        log_info "No existing configuration files found to backup"
    fi

    return 0
}

# Backup file if it exists
backup_if_exists() {
    local file="$1"

    if [[ -f "$file" ]]; then
        local filename="$(basename "$file")"
        local dest="$BACKUP_DIR/$filename"

        # Create subdirectory if needed for .config files
        if [[ "$file" == *"/.config/"* ]]; then
            local subdir="config"
            mkdir -p "$BACKUP_DIR/$subdir"
            dest="$BACKUP_DIR/$subdir/$filename"
        fi

        cp "$file" "$dest"
        log_info "  ✓ Backed up: $filename"
        return 0
    fi

    return 1
}

# Backup directory if it exists
backup_dir_if_exists() {
    local dir="$1"

    if [[ -d "$dir" ]]; then
        local dirname="$(basename "$dir")"
        local dest="$BACKUP_DIR/$dirname"

        # For .config subdirectories, preserve structure
        if [[ "$dir" == *"/.config/"* ]]; then
            mkdir -p "$BACKUP_DIR/config"
            dest="$BACKUP_DIR/config/$dirname"
        fi

        cp -r "$dir" "$dest"
        log_info "  ✓ Backed up: $dirname/"
        return 0
    fi

    return 1
}

# Create backup manifest file
create_backup_manifest() {
    local manifest="$BACKUP_DIR/BACKUP_MANIFEST.txt"

    cat > "$manifest" << EOF
Backup Manifest
Created: $(date)
Hostname: $(hostname)
User: $USER
Home: $HOME

Backup Location: $BACKUP_DIR

Files and directories backed up:
EOF

    find "$BACKUP_DIR" -type f -o -type d | while read -r item; do
        echo "  - ${item#$BACKUP_DIR/}" >> "$manifest"
    done

    cat >> "$manifest" << EOF

Restoration Instructions:
------------------------
To restore from this backup:

1. Individual files:
   cp $BACKUP_DIR/filename ~/

2. Configuration directories:
   cp -r $BACKUP_DIR/dirname ~/.config/

3. Full restoration (use with caution):
   cp -r $BACKUP_DIR/* ~/

Note: Review files before restoring to avoid overwriting newer configurations.
EOF

    log_info "  ✓ Created backup manifest"
}

# If script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Set up basic variables if run standalone
    BACKUP_DIR="${HOME}/.config-backup-$(date +%Y%m%d-%H%M%S)"
    LOG_FILE="backup.log"
    SKIP_BACKUP=false

    # Source utils
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/utils.sh"

    # Run backup
    main_backup
fi
