#!/bin/bash
#
# Dotfiles deployment module
# Deploys bash, git, and GTK configurations
#

main_30_dotfiles() {
    log_section "Deploying Dotfiles"

    # Deploy bash configuration
    deploy_bash_config || {
        log_error "Failed to deploy bash configuration"
        return 1
    }

    # Deploy git configuration (if exists)
    if [[ -f "$SCRIPT_DIR/config/git/.gitconfig" ]]; then
        deploy_git_config
    else
        log_info "No git configuration found, skipping"
    fi

    # Deploy GTK configurations
    deploy_gtk_config || {
        log_warning "Failed to deploy GTK configuration (non-critical)"
    }

    log_success "Dotfiles deployed successfully"
    return 0
}

# Deploy bash configuration
deploy_bash_config() {
    log_info "Deploying bash configuration..."

    local bashrc_source="$SCRIPT_DIR/config/bash/.bashrc"
    local bashrc_target="$HOME/.bashrc"

    if [[ ! -f "$bashrc_source" ]]; then
        log_error "  .bashrc not found in repository"
        return 1
    fi

    # Deploy .bashrc
    if deploy_file "$bashrc_source" "$bashrc_target" ".bashrc"; then
        log_success "  ✓ .bashrc deployed"
    else
        log_error "  ✗ Failed to deploy .bashrc"
        return 1
    fi

    # Check if .bash_profile exists in repo
    if [[ -f "$SCRIPT_DIR/config/bash/.bash_profile" ]]; then
        deploy_file "$SCRIPT_DIR/config/bash/.bash_profile" "$HOME/.bash_profile" ".bash_profile"
    fi

    # Check if .profile exists in repo
    if [[ -f "$SCRIPT_DIR/config/bash/.profile" ]]; then
        deploy_file "$SCRIPT_DIR/config/bash/.profile" "$HOME/.profile" ".profile"
    fi

    log_success "Bash configuration deployed"
    return 0
}

# Deploy git configuration
deploy_git_config() {
    log_info "Deploying git configuration..."

    local gitconfig_source="$SCRIPT_DIR/config/git/.gitconfig"
    local gitconfig_target="$HOME/.gitconfig"

    if [[ -f "$gitconfig_target" ]]; then
        log_info "  Existing .gitconfig found"

        # Check if user wants to merge or replace
        if confirm "Replace existing .gitconfig?"; then
            deploy_file "$gitconfig_source" "$gitconfig_target" ".gitconfig"
            log_success "  ✓ .gitconfig replaced"
        else
            log_info "  Keeping existing .gitconfig"
            log_info "  You can manually merge settings from: $gitconfig_source"
        fi
    else
        deploy_file "$gitconfig_source" "$gitconfig_target" ".gitconfig"
        log_success "  ✓ .gitconfig deployed"
    fi

    log_warning "  Note: Review .gitconfig for personal information (name, email)"

    return 0
}

# Deploy GTK configuration
deploy_gtk_config() {
    log_info "Deploying GTK configuration..."

    local deployed=0

    # Deploy GTK 2.0 config
    if [[ -f "$SCRIPT_DIR/config/gtk/.gtkrc" ]]; then
        deploy_file "$SCRIPT_DIR/config/gtk/.gtkrc" "$HOME/.gtkrc" ".gtkrc"
        ((deployed++))
    fi

    if [[ -f "$SCRIPT_DIR/config/gtk/.gtkrc-2.0" ]]; then
        deploy_file "$SCRIPT_DIR/config/gtk/.gtkrc-2.0" "$HOME/.gtkrc-2.0" ".gtkrc-2.0"
        ((deployed++))
    fi

    # Deploy GTK 3.0 config
    if [[ -d "$SCRIPT_DIR/config/gtk/gtk-3.0" ]]; then
        log_info "  Deploying GTK 3.0 configuration..."
        mkdir -p "$HOME/.config/gtk-3.0"

        for file in "$SCRIPT_DIR/config/gtk/gtk-3.0"/*; do
            if [[ -f "$file" ]]; then
                local filename=$(basename "$file")
                cp "$file" "$HOME/.config/gtk-3.0/"
                log_info "    ✓ $filename"
                ((deployed++))
            elif [[ -d "$file" ]]; then
                local dirname=$(basename "$file")
                cp -r "$file" "$HOME/.config/gtk-3.0/"
                log_info "    ✓ $dirname/"
                ((deployed++))
            fi
        done
    fi

    # Deploy GTK 4.0 config
    if [[ -d "$SCRIPT_DIR/config/gtk/gtk-4.0" ]]; then
        log_info "  Deploying GTK 4.0 configuration..."
        mkdir -p "$HOME/.config/gtk-4.0"

        for file in "$SCRIPT_DIR/config/gtk/gtk-4.0"/*; do
            if [[ -f "$file" ]]; then
                local filename=$(basename "$file")
                cp "$file" "$HOME/.config/gtk-4.0/"
                log_info "    ✓ $filename"
                ((deployed++))
            elif [[ -d "$file" ]]; then
                local dirname=$(basename "$file")
                cp -r "$file" "$HOME/.config/gtk-4.0/"
                log_info "    ✓ $dirname/"
                ((deployed++))
            fi
        done
    fi

    if [[ $deployed -gt 0 ]]; then
        log_success "  ✓ Deployed $deployed GTK configuration items"
    else
        log_info "  No GTK configuration found in repository"
    fi

    return 0
}
