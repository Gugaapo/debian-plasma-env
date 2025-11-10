#!/bin/bash
#
# Package installation module
# Installs packages from apt, flatpak, and snap
#

main_10_packages() {
    if [[ "$SKIP_PACKAGES" == true ]]; then
        log_section "Package Installation (SKIPPED)"
        log_info "Skipping package installation (--skip-packages flag)"
        return 0
    fi

    log_section "Installing Packages"

    # Update package lists first
    update_package_lists || return 1

    # Install apt packages
    install_apt_packages || {
        log_error "Package installation failed"
        if ! confirm "Continue despite package installation errors?"; then
            return 1
        fi
    }

    # Install flatpak packages if available
    if [[ -f "$SCRIPT_DIR/packages/flatpak-packages.txt" ]] && [[ -s "$SCRIPT_DIR/packages/flatpak-packages.txt" ]]; then
        install_flatpak_packages
    fi

    # Install snap packages if available
    if [[ -f "$SCRIPT_DIR/packages/snap-packages.txt" ]] && [[ -s "$SCRIPT_DIR/packages/snap-packages.txt" ]]; then
        install_snap_packages
    fi

    log_success "Package installation completed"
    return 0
}

# Update apt package lists
update_package_lists() {
    log_info "Updating package lists..."

    if sudo apt update >> "$LOG_FILE" 2>&1; then
        log_success "  ✓ Package lists updated"
        return 0
    else
        log_error "  ✗ Failed to update package lists"
        log_error "    Check your internet connection and /etc/apt/sources.list"
        return 1
    fi
}

# Install apt packages
install_apt_packages() {
    local package_file="$SCRIPT_DIR/packages/apt-manual-packages.txt"

    if [[ ! -f "$package_file" ]]; then
        log_error "Package list not found: $package_file"
        return 1
    fi

    log_info "Installing apt packages..."
    log_info "Reading from: apt-manual-packages.txt"

    local failed_packages=()
    local installed_count=0
    local skipped_count=0
    local unavailable_count=0
    local total_count=0

    # First pass: count total packages
    while IFS= read -r package; do
        # Skip comments and empty lines
        [[ "$package" =~ ^#.*$ ]] && continue
        [[ -z "$package" ]] && continue
        ((total_count++))
    done < "$package_file"

    log_info "Total packages to process: $total_count"
    echo ""

    # Second pass: install packages
    local current=0
    while IFS= read -r package; do
        # Skip comments and empty lines
        [[ "$package" =~ ^#.*$ ]] && continue
        [[ -z "$package" ]] && continue

        ((current++))

        # Check if package is available
        if ! apt-cache show "$package" &> /dev/null; then
            log_warning "  [$current/$total_count] Not available: $package"
            failed_packages+=("$package (not available)")
            ((unavailable_count++))
            continue
        fi

        # Check if already installed
        if package_installed "$package"; then
            log_info "  [$current/$total_count] Already installed: $package"
            ((skipped_count++))
            continue
        fi

        # Install package
        log_info "  [$current/$total_count] Installing: $package"
        if sudo apt install -y "$package" >> "$LOG_FILE" 2>&1; then
            ((installed_count++))
        else
            log_warning "  [$current/$total_count] Failed to install: $package"
            failed_packages+=("$package (install failed)")
        fi
    done < "$package_file"

    echo ""
    print_separator

    # Summary
    log_info "Installation Summary:"
    log_success "  • Installed: $installed_count packages"
    log_info "  • Already installed: $skipped_count packages"

    if [[ $unavailable_count -gt 0 ]]; then
        log_warning "  • Unavailable: $unavailable_count packages"
    fi

    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_warning "  • Failed: ${#failed_packages[@]} packages"
        echo ""
        log_warning "Failed packages:"
        for pkg in "${failed_packages[@]}"; do
            log_warning "    - $pkg"
        done

        if [[ $installed_count -eq 0 ]]; then
            log_error "No packages were installed successfully"
            return 1
        fi

        if ! confirm "Continue despite failures?"; then
            return 1
        fi
    fi

    return 0
}

# Install flatpak packages
install_flatpak_packages() {
    local package_file="$SCRIPT_DIR/packages/flatpak-packages.txt"

    log_info "Checking for Flatpak packages..."

    # Check if flatpak is installed
    if ! command_exists flatpak; then
        log_info "  Flatpak not installed, skipping Flatpak packages"
        return 0
    fi

    if [[ ! -s "$package_file" ]]; then
        log_info "  No Flatpak packages to install"
        return 0
    fi

    log_info "Installing Flatpak packages..."

    # Ensure Flathub is added
    if ! flatpak remote-list | grep -q flathub; then
        log_info "  Adding Flathub repository..."
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi

    local installed=0
    local failed=0

    while IFS= read -r package; do
        [[ "$package" =~ ^#.*$ ]] && continue
        [[ -z "$package" ]] && continue

        log_info "  Installing Flatpak: $package"
        if flatpak install -y flathub "$package" >> "$LOG_FILE" 2>&1; then
            ((installed++))
        else
            log_warning "  Failed to install Flatpak: $package"
            ((failed++))
        fi
    done < "$package_file"

    log_info "  Flatpak summary: $installed installed, $failed failed"
    return 0
}

# Install snap packages
install_snap_packages() {
    local package_file="$SCRIPT_DIR/packages/snap-packages.txt"

    log_info "Checking for Snap packages..."

    # Check if snap is installed
    if ! command_exists snap; then
        log_info "  Snap not installed, skipping Snap packages"
        return 0
    fi

    if [[ ! -s "$package_file" ]]; then
        log_info "  No Snap packages to install"
        return 0
    fi

    log_info "Installing Snap packages..."

    local installed=0
    local failed=0

    while IFS= read -r package; do
        [[ "$package" =~ ^#.*$ ]] && continue
        [[ -z "$package" ]] && continue

        log_info "  Installing Snap: $package"
        if sudo snap install "$package" >> "$LOG_FILE" 2>&1; then
            ((installed++))
        else
            log_warning "  Failed to install Snap: $package"
            ((failed++))
        fi
    done < "$package_file"

    log_info "  Snap summary: $installed installed, $failed failed"
    return 0
}
