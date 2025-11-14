#!/bin/bash
#
# Module: 60-claude-code
# Description: Installs Claude Code CLI and restores agents/configuration
#

main_60_claude_code() {
    log_header "Setting up Claude Code"

    # Check if Claude Code binary should be installed
    local install_binary=false
    if ! command -v claude &> /dev/null; then
        log_info "Claude Code not found in PATH"
        if [[ "$INTERACTIVE" == true ]]; then
            if confirm "Install Claude Code CLI?" "y"; then
                install_binary=true
            fi
        else
            log_warning "Claude Code not installed, skipping (non-interactive mode)"
            log_info "To install Claude Code later, visit: https://docs.claude.com/claude-code"
            return 0
        fi
    else
        local current_version=$(claude --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        log_success "Claude Code already installed (version: $current_version)"
    fi

    # Install Claude Code if requested
    if [[ "$install_binary" == true ]]; then
        log_step "Installing Claude Code..."

        # Download and install via official installer
        if ! curl -fsSL https://install.claude.com | bash; then
            log_error "Failed to install Claude Code"
            if [[ "$INTERACTIVE" == true ]]; then
                if ! confirm "Continue without Claude Code?"; then
                    return 1
                fi
            fi
            return 0
        fi

        # Add to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"

        log_success "Claude Code installed successfully"
    fi

    # Restore agents
    if [[ -d "$SCRIPT_DIR/claude-code/agents" ]]; then
        log_step "Restoring Claude agents..."

        mkdir -p "$HOME/.claude/agents"

        if cp -r "$SCRIPT_DIR/claude-code/agents/"* "$HOME/.claude/agents/"; then
            local agent_count=$(find "$SCRIPT_DIR/claude-code/agents" -name "*.md" | wc -l)
            log_success "Restored $agent_count Claude agents"
        else
            log_warning "Failed to restore Claude agents"
        fi
    else
        log_warning "No Claude agents found in repository"
    fi

    # Restore configuration
    if [[ -d "$SCRIPT_DIR/claude-code/config" ]]; then
        log_step "Restoring Claude Code configuration..."

        mkdir -p "$HOME/.claude"

        # Copy settings files
        if [[ -f "$SCRIPT_DIR/claude-code/config/settings.json" ]]; then
            cp "$SCRIPT_DIR/claude-code/config/settings.json" "$HOME/.claude/"
            log_success "Restored settings.json"
        fi

        if [[ -f "$SCRIPT_DIR/claude-code/config/settings.local.json" ]]; then
            cp "$SCRIPT_DIR/claude-code/config/settings.local.json" "$HOME/.claude/"
            log_success "Restored settings.local.json"
        fi
    else
        log_warning "No Claude Code configuration found in repository"
    fi

    # Copy documentation for reference
    if [[ -d "$SCRIPT_DIR/claude-code/docs" ]]; then
        log_step "Copying Claude Code documentation..."
        mkdir -p "$HOME/.claude/docs"
        cp -r "$SCRIPT_DIR/claude-code/docs/"* "$HOME/.claude/docs/" 2>/dev/null || true
    fi

    echo ""
    log_info "Claude Code setup complete!"

    if command -v claude &> /dev/null; then
        log_info "You can now use 'claude' command in your terminal"
        log_info "Run 'claude --help' to get started"
    fi

    log_info "Documentation available at: ~/.claude/docs/"

    return 0
}
