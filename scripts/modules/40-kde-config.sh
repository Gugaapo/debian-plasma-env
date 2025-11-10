#!/bin/bash
#
# KDE Plasma configuration restoration module
# Restores KDE Plasma settings, shortcuts, and layouts
#

main_40_kde_config() {
    log_section "Restoring KDE Plasma Configuration"

    # Check if KDE is installed
    if ! command_exists plasmashell; then
        log_warning "KDE Plasma not detected on this system"

        if [[ "$SKIP_PACKAGES" == false ]]; then
            log_info "KDE may be installed but not yet available in this session"
            log_info "Configuration will be deployed for next login"
        else
            if ! confirm "Continue deploying KDE configuration anyway?"; then
                log_info "Skipping KDE configuration"
                return 0
            fi
        fi
    fi

    # Check if running in KDE session
    if is_kde_session; then
        log_warning "Currently running in KDE Plasma session"
        log_warning "For best results, configuration should be applied from TTY or different DE"
        log_info ""
        log_info "Options:"
        log_info "  1. Continue anyway (may require logout to take full effect)"
        log_info "  2. Exit now and run from TTY (Ctrl+Alt+F2)"
        echo ""

        if confirm "Continue with live KDE session?"; then
            restore_kde_config_live
        else
            log_info "Skipping KDE configuration"
            log_info "To apply later: Log out, switch to TTY (Ctrl+Alt+F2), and re-run setup"
            return 0
        fi
    else
        restore_kde_config_safe
    fi

    log_success "KDE Plasma configuration restored"
    log_info "Log out and log back in for all changes to take effect"

    return 0
}

# Restore KDE config safely (not in KDE session)
restore_kde_config_safe() {
    log_info "Restoring KDE configuration files (safe mode)..."

    local config_source="$SCRIPT_DIR/config/kde/config"
    local config_target="$HOME/.config"

    if [[ ! -d "$config_source" ]]; then
        log_error "KDE configuration directory not found in repository"
        return 1
    fi

    # Count files to restore
    local file_count=$(find "$config_source" -type f | wc -l)
    log_info "Found $file_count KDE configuration files"

    if [[ $file_count -eq 0 ]]; then
        log_warning "No KDE configuration files found in repository"
        return 0
    fi

    # Restore each configuration file
    local restored=0
    for config_file in "$config_source"/*; do
        if [[ -f "$config_file" ]]; then
            local filename=$(basename "$config_file")
            deploy_file "$config_file" "$config_target/$filename" "$filename"
            ((restored++))
        fi
    done

    log_success "Restored $restored KDE configuration files"

    # Restore Plasma data if exists
    restore_plasma_data

    return 0
}

# Restore KDE config in live session (more cautious)
restore_kde_config_live() {
    log_warning "Applying configuration while KDE is running..."
    log_info "This may require a Plasma restart or full logout"

    # Use same restoration as safe mode
    restore_kde_config_safe

    echo ""
    if confirm "Restart Plasma shell now to apply some changes?"; then
        restart_plasma
        log_info "Plasma restarted - some changes may still require full logout"
    else
        log_info "Plasma shell not restarted"
        log_info "Some changes will only take effect after logout/login"
    fi

    return 0
}

# Restore Plasma-specific data
restore_plasma_data() {
    local data_source="$SCRIPT_DIR/config/kde/local/plasma"
    local data_target="$HOME/.local/share/plasma"

    if [[ ! -d "$data_source" ]]; then
        log_info "No Plasma data found in repository"
        return 0
    fi

    log_info "Restoring Plasma data..."

    mkdir -p "$data_target"

    # Restore plasmoids (widgets)
    if [[ -d "$data_source/plasmoids" ]]; then
        log_info "  Restoring custom plasmoids..."
        mkdir -p "$data_target/plasmoids"
        cp -r "$data_source/plasmoids/"* "$data_target/plasmoids/" 2>/dev/null || true

        local plasmoid_count=$(find "$data_target/plasmoids" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
        if [[ $plasmoid_count -gt 0 ]]; then
            log_success "  ✓ Restored $plasmoid_count custom plasmoid(s)"
        fi
    fi

    # Restore other Plasma data
    for item in "$data_source"/*; do
        if [[ -d "$item" ]] && [[ $(basename "$item") != "plasmoids" ]]; then
            local dirname=$(basename "$item")
            cp -r "$item" "$data_target/"
            log_info "  ✓ Restored: $dirname/"
        fi
    done

    return 0
}

# List important KDE configurations being restored
list_kde_configs() {
    log_info "KDE configurations included:"
    log_info "  • Global settings (theme, colors, fonts)"
    log_info "  • Keyboard shortcuts"
    log_info "  • Panel layout and widgets"
    log_info "  • Window manager settings"
    log_info "  • Application preferences"
}
