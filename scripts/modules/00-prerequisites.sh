#!/bin/bash
#
# Prerequisites module
# Checks system requirements before installation
#

main_00_prerequisites() {
    log_section "Checking Prerequisites"

    local checks_passed=0
    local checks_failed=0

    # Check 1: Debian-based system
    log_info "Checking if running on Debian-based distribution..."
    if is_debian_based; then
        local distro="$(detect_distro)"
        local version="$(get_distro_version)"
        log_success "  ✓ Detected: $distro $version"
        ((checks_passed++))
    else
        log_error "  ✗ This script requires a Debian-based distribution"
        log_error "    Supported: Debian, Ubuntu, Linux Mint, Pop!_OS, etc."
        ((checks_failed++))
        return 1
    fi

    # Check 2: Not running as root
    log_info "Checking user privileges..."
    if is_root; then
        log_error "  ✗ Don't run this script as root"
        log_error "    Run as regular user - sudo will be used when needed"
        ((checks_failed++))
        return 1
    else
        log_success "  ✓ Running as user: $USER"
        ((checks_passed++))
    fi

    # Check 3: Sudo access
    log_info "Checking sudo access..."
    if sudo -n true 2>/dev/null; then
        log_success "  ✓ Sudo access available (cached)"
        ((checks_passed++))
    elif sudo -v; then
        log_success "  ✓ Sudo access granted"
        ((checks_passed++))
    else
        log_error "  ✗ This script requires sudo access"
        log_error "    Please ensure your user is in the sudo group"
        ((checks_failed++))
        return 1
    fi

    # Check 4: Internet connection (if packages will be installed)
    if [[ "$SKIP_PACKAGES" == false ]]; then
        log_info "Checking internet connectivity..."
        if ping -c 1 -W 2 8.8.8.8 &> /dev/null || ping -c 1 -W 2 1.1.1.1 &> /dev/null; then
            log_success "  ✓ Internet connection available"
            ((checks_passed++))
        else
            log_error "  ✗ No internet connection detected"
            log_error "    Internet required for package installation"
            log_info "    Use --skip-packages to skip package installation"
            ((checks_failed++))
            return 1
        fi
    else
        log_info "  ⊙ Skipping internet check (--skip-packages enabled)"
    fi

    # Check 5: Repository integrity
    log_info "Verifying repository structure..."
    if check_repo_integrity; then
        log_success "  ✓ Repository structure valid"
        ((checks_passed++))
    else
        log_error "  ✗ Repository structure incomplete"
        ((checks_failed++))
        return 1
    fi

    # Check 6: Disk space
    log_info "Checking available disk space..."
    local available_mb=$(df "$HOME" | awk 'NR==2 {print int($4/1024)}')
    if [[ $available_mb -gt 500 ]]; then
        log_success "  ✓ Available space: ${available_mb} MB"
        ((checks_passed++))
    else
        log_warning "  ⚠ Low disk space: ${available_mb} MB"
        log_warning "    At least 500 MB recommended"
        if ! confirm "Continue anyway?"; then
            return 1
        fi
        ((checks_passed++))
    fi

    # Info: KDE Plasma detection
    log_info "Checking for KDE Plasma..."
    if command_exists plasmashell; then
        local plasma_version=$(plasmashell --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
        log_success "  ✓ KDE Plasma installed: $plasma_version"

        if is_kde_session; then
            log_info "  ℹ Currently running in KDE session"
            log_info "    Some changes may require logout to take effect"
        fi
    elif [[ "$SKIP_PACKAGES" == true ]]; then
        log_warning "  ⚠ KDE Plasma not detected (will not be installed with --skip-packages)"
        if ! confirm "Continue without KDE Plasma?"; then
            return 1
        fi
    else
        log_info "  ℹ KDE Plasma not detected (will be installed with packages)"
    fi

    # Summary
    echo ""
    print_separator
    if [[ $checks_failed -eq 0 ]]; then
        log_success "All prerequisite checks passed ($checks_passed/$checks_passed)"
        log_info "System is ready for installation"
        return 0
    else
        log_error "Some prerequisite checks failed ($checks_failed failed, $checks_passed passed)"
        return 1
    fi
}

# Check repository structure integrity
check_repo_integrity() {
    local required_dirs=(
        "config"
        "config/bash"
        "config/kde"
        "packages"
        "scripts"
        "scripts/modules"
    )

    local required_files=(
        "config/bash/.bashrc"
        "packages/apt-manual-packages.txt"
        "scripts/utils.sh"
    )

    local missing=0

    # Check directories
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$SCRIPT_DIR/$dir" ]]; then
            log_error "    Missing directory: $dir"
            ((missing++))
        fi
    done

    # Check files
    for file in "${required_files[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$file" ]]; then
            log_error "    Missing file: $file"
            ((missing++))
        fi
    done

    if [[ $missing -gt 0 ]]; then
        log_error "    Repository is missing $missing required items"
        return 1
    fi

    return 0
}
