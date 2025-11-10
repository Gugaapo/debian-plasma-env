#!/bin/bash
#
# Alacritty terminal configuration module
# Deploys Alacritty configuration and themes
#

main_50_alacritty() {
    log_section "Configuring Alacritty Terminal"

    # Check if Alacritty configuration exists in repo
    if [[ ! -d "$SCRIPT_DIR/config/alacritty" ]]; then
        log_info "No Alacritty configuration found in repository"
        return 0
    fi

    # Check if Alacritty is installed
    if ! command_exists alacritty; then
        log_warning "Alacritty not installed"

        if [[ "$SKIP_PACKAGES" == false ]]; then
            log_info "Alacritty may have been installed but not yet available"
            log_info "Configuration will be deployed anyway"
        else
            if confirm "Deploy Alacritty configuration anyway?"; then
                deploy_alacritty_config
                log_info "Configuration deployed - install Alacritty to use it"
            else
                log_info "Skipping Alacritty configuration"
            fi
            return 0
        fi
    fi

    # Deploy configuration
    deploy_alacritty_config || {
        log_warning "Failed to deploy Alacritty configuration"
        return 1
    }

    log_success "Alacritty configured successfully"
    return 0
}

# Deploy Alacritty configuration
deploy_alacritty_config() {
    log_info "Deploying Alacritty configuration..."

    local config_source="$SCRIPT_DIR/config/alacritty"
    local config_target="$HOME/.config/alacritty"

    # Create config directory
    mkdir -p "$config_target"

    local deployed=0

    # Deploy main configuration file
    if [[ -f "$config_source/alacritty.toml" ]]; then
        deploy_file "$config_source/alacritty.toml" "$config_target/alacritty.toml" "alacritty.toml"
        ((deployed++))
    elif [[ -f "$config_source/alacritty.yml" ]]; then
        deploy_file "$config_source/alacritty.yml" "$config_target/alacritty.yml" "alacritty.yml"
        ((deployed++))
    else
        log_warning "  No main Alacritty config file found (alacritty.toml or alacritty.yml)"
    fi

    # Deploy theme files
    if [[ -f "$config_source/binaryanomaly.theme.sh" ]]; then
        cp "$config_source/binaryanomaly.theme.sh" "$config_target/"
        log_info "  ✓ binaryanomaly.theme.sh"
        ((deployed++))
    fi

    # Deploy themes directory if it exists
    if [[ -d "$config_source/themes" ]]; then
        log_info "  Deploying theme files..."
        mkdir -p "$config_target/themes"

        local theme_count=0
        for theme_file in "$config_source/themes"/*.toml "$config_source/themes"/*.yml; do
            if [[ -f "$theme_file" ]]; then
                local filename=$(basename "$theme_file")
                cp "$theme_file" "$config_target/themes/"
                log_info "    ✓ $filename"
                ((theme_count++))
            fi
        done

        # Handle nested themes directory (themes/themes/)
        if [[ -d "$config_source/themes/themes" ]]; then
            for theme_file in "$config_source/themes/themes"/*.toml "$config_source/themes/themes"/*.yml; do
                if [[ -f "$theme_file" ]]; then
                    local filename=$(basename "$theme_file")
                    cp "$theme_file" "$config_target/themes/"
                    log_info "    ✓ $filename"
                    ((theme_count++))
                fi
            done
        fi

        if [[ $theme_count -gt 0 ]]; then
            log_success "  Deployed $theme_count theme file(s)"
            ((deployed++))
        fi
    fi

    # Deploy any other files in the alacritty config directory
    for file in "$config_source"/*; do
        if [[ -f "$file" ]]; then
            local filename=$(basename "$file")
            # Skip already deployed files
            if [[ "$filename" != "alacritty.toml" ]] && \
               [[ "$filename" != "alacritty.yml" ]] && \
               [[ "$filename" != "binaryanomaly.theme.sh" ]]; then
                cp "$file" "$config_target/"
                log_info "  ✓ $filename"
                ((deployed++))
            fi
        fi
    done

    if [[ $deployed -gt 0 ]]; then
        log_success "Deployed $deployed Alacritty configuration items"
    else
        log_warning "No Alacritty configuration files found to deploy"
    fi

    return 0
}
