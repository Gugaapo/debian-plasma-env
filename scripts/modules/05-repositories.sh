#!/bin/bash
#
# Module: 05-repositories
# Description: Adds third-party APT repositories
#

main_05_repositories() {
    if [[ "$SKIP_PACKAGES" == true ]]; then
        log_section "Third-party Repositories (SKIPPED)"
        log_info "Skipping repository setup (--skip-packages flag)"
        return 0
    fi

    log_section "Setting Up Third-party Repositories"

    local repos_added=0
    local repos_skipped=0

    # Docker Repository
    if needs_docker_repo; then
        log_step "Setting up Docker repository..."
        if setup_docker_repo; then
            log_success "Docker repository added"
            ((repos_added++))
        else
            log_warning "Failed to add Docker repository"
            log_info "Docker packages may not install correctly"
        fi
    else
        log_info "Docker repository already configured or not needed"
        ((repos_skipped++))
    fi

    # GitHub CLI Repository
    if needs_github_cli_repo; then
        log_step "Setting up GitHub CLI repository..."
        if setup_github_cli_repo; then
            log_success "GitHub CLI repository added"
            ((repos_added++))
        else
            log_warning "Failed to add GitHub CLI repository"
        fi
    else
        log_info "GitHub CLI repository already configured or not needed"
        ((repos_skipped++))
    fi

    # VS Code Repository
    if needs_vscode_repo; then
        log_step "Setting up VS Code repository..."
        if setup_vscode_repo; then
            log_success "VS Code repository added"
            ((repos_added++))
        else
            log_warning "Failed to add VS Code repository"
        fi
    else
        log_info "VS Code repository already configured or not needed"
        ((repos_skipped++))
    fi

    echo ""
    log_info "Repository setup summary:"
    log_success "  • Added: $repos_added repositories"
    log_info "  • Skipped: $repos_skipped repositories"

    # Update package lists if we added any repos
    if [[ $repos_added -gt 0 ]]; then
        log_step "Updating package lists..."
        if sudo apt update >> "$LOG_FILE" 2>&1; then
            log_success "Package lists updated"
        else
            log_warning "Failed to update package lists"
        fi
    fi

    return 0
}

# Check if Docker repository is needed
needs_docker_repo() {
    # Check if docker-ce is in the package list
    if grep -q "^docker-ce$" "$SCRIPT_DIR/packages/apt-manual-packages.txt" 2>/dev/null; then
        # Check if repository is already configured
        if [[ -f /etc/apt/sources.list.d/docker.list ]] || \
           grep -r "download.docker.com" /etc/apt/sources.list.d/ &>/dev/null || \
           grep "download.docker.com" /etc/apt/sources.list &>/dev/null; then
            return 1  # Already configured
        fi
        return 0  # Needed
    fi
    return 1  # Not needed
}

# Setup Docker repository
setup_docker_repo() {
    log_info "  Installing prerequisites..."
    sudo apt-get update >> "$LOG_FILE" 2>&1
    sudo apt-get install -y ca-certificates curl >> "$LOG_FILE" 2>&1 || return 1

    log_info "  Adding Docker GPG key..."
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc >> "$LOG_FILE" 2>&1 || return 1
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    log_info "  Adding Docker repository..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    return 0
}

# Check if GitHub CLI repository is needed
needs_github_cli_repo() {
    if grep -q "^gh$" "$SCRIPT_DIR/packages/apt-manual-packages.txt" 2>/dev/null; then
        if [[ -f /etc/apt/sources.list.d/github-cli.list ]] || \
           grep -r "cli.github.com" /etc/apt/sources.list.d/ &>/dev/null; then
            return 1  # Already configured
        fi
        return 0  # Needed
    fi
    return 1  # Not needed
}

# Setup GitHub CLI repository
setup_github_cli_repo() {
    log_info "  Adding GitHub CLI GPG key..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
      sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

    log_info "  Adding GitHub CLI repository..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
      sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

    return 0
}

# Check if VS Code repository is needed
needs_vscode_repo() {
    if grep -q "^code$" "$SCRIPT_DIR/packages/apt-manual-packages.txt" 2>/dev/null; then
        if [[ -f /etc/apt/sources.list.d/vscode.list ]] || \
           grep -r "packages.microsoft.com" /etc/apt/sources.list.d/ &>/dev/null; then
            return 1  # Already configured
        fi
        return 0  # Needed
    fi
    return 1  # Not needed
}

# Setup VS Code repository
setup_vscode_repo() {
    log_info "  Installing prerequisites..."
    sudo apt-get install -y wget gpg >> "$LOG_FILE" 2>&1 || return 1

    log_info "  Adding Microsoft GPG key..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    rm packages.microsoft.gpg

    log_info "  Adding VS Code repository..."
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
      sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

    return 0
}
