#!/bin/bash
#
# oh-my-bash installation and configuration module
# Installs oh-my-bash and deploys custom configurations
#

main_20_oh_my_bash() {
    log_section "Setting up oh-my-bash"

    local omb_dir="$HOME/.oh-my-bash"

    # Check if oh-my-bash is already installed
    if [[ -d "$omb_dir" ]]; then
        log_info "oh-my-bash already installed at: $omb_dir"

        if confirm "Reinstall oh-my-bash?"; then
            reinstall_oh_my_bash
        else
            log_info "Using existing oh-my-bash installation"
        fi
    else
        install_oh_my_bash || return 1
    fi

    # Deploy custom configurations
    deploy_custom_configs || return 1

    log_success "oh-my-bash setup completed"
    return 0
}

# Install oh-my-bash
install_oh_my_bash() {
    log_info "Installing oh-my-bash..."

    # Check if git and curl are available
    if ! command_exists git; then
        log_error "git is required to install oh-my-bash"
        return 1
    fi

    if ! command_exists curl; then
        log_error "curl is required to install oh-my-bash"
        return 1
    fi

    # Download and run oh-my-bash installer
    local install_script=$(mktemp)

    if curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh -o "$install_script"; then
        log_info "  Downloaded installer"
    else
        log_error "  Failed to download oh-my-bash installer"
        rm -f "$install_script"
        return 1
    fi

    # Run installer in unattended mode
    if bash "$install_script" --unattended >> "$LOG_FILE" 2>&1; then
        log_success "  ✓ oh-my-bash installed"
        rm -f "$install_script"
        return 0
    else
        log_error "  ✗ oh-my-bash installation failed"
        log_info "    Check $LOG_FILE for details"
        rm -f "$install_script"
        return 1
    fi
}

# Reinstall oh-my-bash
reinstall_oh_my_bash() {
    local omb_dir="$HOME/.oh-my-bash"

    log_info "Backing up current oh-my-bash installation..."
    if [[ -d "$omb_dir" ]]; then
        mv "$omb_dir" "$omb_dir.backup.$(date +%Y%m%d-%H%M%S)"
        log_success "  ✓ Backed up to: $omb_dir.backup.*"
    fi

    install_oh_my_bash
}

# Deploy custom configurations
deploy_custom_configs() {
    log_info "Deploying custom oh-my-bash configurations..."

    local omb_custom="$HOME/.oh-my-bash/custom"
    local repo_custom="$SCRIPT_DIR/config/bash/oh-my-bash/custom"

    if [[ ! -d "$repo_custom" ]]; then
        log_warning "  No custom configurations found in repository"
        return 0
    fi

    # Create custom directory if it doesn't exist
    mkdir -p "$omb_custom"

    # Deploy aliases
    if [[ -d "$repo_custom/aliases" ]]; then
        log_info "  Deploying custom aliases..."
        mkdir -p "$omb_custom/aliases"

        local alias_count=0
        for alias_file in "$repo_custom/aliases"/*.sh; do
            if [[ -f "$alias_file" ]]; then
                local filename=$(basename "$alias_file")
                cp "$alias_file" "$omb_custom/aliases/"
                log_success "    ✓ $filename"
                ((alias_count++))
            fi
        done

        if [[ $alias_count -gt 0 ]]; then
            log_success "  Deployed $alias_count alias file(s)"
        fi
    fi

    # Deploy scripts
    if [[ -d "$repo_custom/scripts" ]]; then
        log_info "  Deploying custom scripts..."
        mkdir -p "$omb_custom/scripts"

        local script_count=0
        for script_file in "$repo_custom/scripts"/*; do
            if [[ -f "$script_file" ]]; then
                local filename=$(basename "$script_file")
                cp "$script_file" "$omb_custom/scripts/"
                chmod +x "$omb_custom/scripts/$filename"
                log_success "    ✓ $filename (executable)"
                ((script_count++))
            fi
        done

        if [[ $script_count -gt 0 ]]; then
            log_success "  Deployed $script_count script file(s)"
        fi
    fi

    # Deploy themes
    if [[ -d "$repo_custom/themes" ]]; then
        log_info "  Deploying custom themes..."
        mkdir -p "$omb_custom/themes"

        local theme_count=0
        for theme_dir in "$repo_custom/themes"/*; do
            if [[ -d "$theme_dir" ]]; then
                local theme_name=$(basename "$theme_dir")
                cp -r "$theme_dir" "$omb_custom/themes/"
                log_success "    ✓ $theme_name/"
                ((theme_count++))
            fi
        done

        if [[ $theme_count -gt 0 ]]; then
            log_success "  Deployed $theme_count custom theme(s)"
        fi
    fi

    log_success "Custom configurations deployed"
    return 0
}
