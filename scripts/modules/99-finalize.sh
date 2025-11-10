#!/bin/bash
#
# Finalization module
# Post-installation tasks and summary
#

main_99_finalize() {
    log_section "Finalizing Setup"

    # Set default shell if needed
    check_default_shell

    # Provide wallpaper information
    provide_wallpaper_info

    # Show post-installation notes
    show_post_install_notes

    # Display summary
    show_setup_summary

    log_success "Setup finalization completed"
    return 0
}

# Check and optionally change default shell
check_default_shell() {
    log_info "Checking default shell..."

    local current_shell=$(basename "$SHELL")

    if [[ "$current_shell" != "bash" ]]; then
        log_info "  Current shell: $current_shell"

        if confirm "Change default shell to bash?"; then
            if chsh -s /bin/bash; then
                log_success "  ✓ Default shell changed to bash"
                log_info "    Log out and log back in for this to take effect"
            else
                log_warning "  ✗ Failed to change default shell"
            fi
        else
            log_info "  Keeping current shell: $current_shell"
        fi
    else
        log_success "  ✓ Default shell is already bash"
    fi
}

# Provide wallpaper information
provide_wallpaper_info() {
    local wallpaper_dir="$SCRIPT_DIR/assets/wallpapers"

    if [[ -d "$wallpaper_dir" ]]; then
        local wallpaper_count=$(find "$wallpaper_dir" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) 2>/dev/null | wc -l)

        if [[ $wallpaper_count -gt 0 ]]; then
            log_info "Wallpapers available: $wallpaper_count files"
            log_info "  Location: $wallpaper_dir"
            log_info "  To set wallpaper:"
            log_info "    1. Right-click desktop → Configure Desktop and Wallpaper"
            log_info "    2. Click 'Add Image...'"
            log_info "    3. Navigate to: $wallpaper_dir"
        fi
    fi
}

# Show post-installation notes
show_post_install_notes() {
    log_info "Post-installation notes:"

    echo ""
    echo "  Configuration Files:"
    echo "    • Bash: ~/.bashrc"
    echo "    • oh-my-bash: ~/.oh-my-bash/custom/"
    echo "    • KDE: ~/.config/kde* and ~/.config/plasma*"
    echo "    • Alacritty: ~/.config/alacritty/"
    echo ""

    if [[ "$SKIP_BACKUP" == false ]] && [[ -d "$BACKUP_DIR" ]]; then
        echo "  Backup Location:"
        echo "    • $BACKUP_DIR"
        echo ""
    fi

    echo "  Log File:"
    echo "    • $LOG_FILE"
    echo ""
}

# Display setup summary
show_setup_summary() {
    echo ""
    print_separator
    log_header "Setup Complete!"
    echo ""

    echo -e "${GREEN}Environment configuration has been applied successfully!${NC}"
    echo ""

    echo -e "${CYAN}Next Steps:${NC}"
    echo ""
    echo "  ${GREEN}1.${NC} Log out and log back in"
    echo "     This ensures all configurations take effect, especially:"
    echo "     • KDE Plasma settings"
    echo "     • Shell environment (.bashrc, oh-my-bash)"
    echo "     • Default shell (if changed)"
    echo ""

    echo "  ${GREEN}2.${NC} Open a new terminal"
    echo "     Your custom bash configuration and oh-my-bash will be active"
    echo ""

    echo "  ${GREEN}3.${NC} Verify KDE settings"
    echo "     Check:"
    echo "     • Keyboard shortcuts (System Settings → Shortcuts)"
    echo "     • Panel layout and widgets"
    echo "     • Theme and colors (System Settings → Appearance)"
    echo ""

    echo "  ${GREEN}4.${NC} Set wallpaper (optional)"
    echo "     Right-click desktop → Configure Desktop and Wallpaper"
    echo ""

    echo "  ${GREEN}5.${NC} Test applications"
    echo "     • Open Alacritty terminal"
    echo "     • Verify custom aliases (try: 'll', 'gs', etc.)"
    echo "     • Check application preferences (Dolphin, Gwenview, etc.)"
    echo ""

    if [[ "$SKIP_BACKUP" == false ]] && [[ -d "$BACKUP_DIR" ]]; then
        echo -e "${YELLOW}Backup Information:${NC}"
        echo "  Your previous configurations were backed up to:"
        echo "  → $BACKUP_DIR"
        echo ""
        echo "  If you need to restore anything:"
        echo "  → See $BACKUP_DIR/BACKUP_MANIFEST.txt"
        echo ""
    fi

    echo -e "${CYAN}Troubleshooting:${NC}"
    echo "  • If KDE changes don't appear: Try restarting Plasma"
    echo "    (Log out and log back in, or: kquitapp5 plasmashell && kstart5 plasmashell)"
    echo ""
    echo "  • If bash changes don't appear: Source the new config"
    echo "    (Open new terminal, or: source ~/.bashrc)"
    echo ""
    echo "  • For issues: Check the log file at:"
    echo "    → $LOG_FILE"
    echo ""

    print_separator
    echo ""

    echo -e "${GREEN}Thank you for using this setup script!${NC}"
    echo ""
    echo "Repository: $SCRIPT_DIR"
    echo "To update configurations in the future, run:"
    echo "  → $SCRIPT_DIR/scripts/update-repo.sh"
    echo ""
}

# Cleanup temporary files (if any)
cleanup_temp_files() {
    # Add cleanup logic here if needed
    return 0
}
