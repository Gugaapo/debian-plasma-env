#!/bin/bash
#
# Debian KDE Plasma Environment Setup Script
# Recreates complete KDE Plasma environment from configuration files
#
# Usage: ./setup.sh [OPTIONS]
#

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script metadata
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
readonly LOG_FILE="$SCRIPT_DIR/setup.log"

# Configuration flags (set via command line args)
SKIP_PACKAGES=false
SKIP_BACKUP=false
DRY_RUN=false
INTERACTIVE=true

# Color codes for output (defined before sourcing utils)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Source utility functions
if [[ -f "$SCRIPT_DIR/scripts/utils.sh" ]]; then
    source "$SCRIPT_DIR/scripts/utils.sh"
else
    echo "ERROR: Required file scripts/utils.sh not found"
    exit 1
fi

# Main execution flow
main() {
    # Initialize log file
    echo "Setup started at: $(date)" > "$LOG_FILE"
    echo "Command: $0 $*" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"

    # Display header
    log_header "Debian KDE Plasma Environment Setup v${SCRIPT_VERSION}"

    # Parse command line arguments
    parse_arguments "$@"

    # Display setup information
    show_setup_info

    # Confirm start
    if [[ "$INTERACTIVE" == true ]] && [[ "$DRY_RUN" == false ]]; then
        echo ""
        if ! confirm "Start setup now?" "y"; then
            log_info "Setup cancelled by user"
            exit 0
        fi
        echo ""
    fi

    # Pre-flight checks
    run_module "00-prerequisites" || {
        log_error "Prerequisites check failed. Cannot continue."
        exit 1
    }

    # Create backup unless skipped
    if [[ "$SKIP_BACKUP" == false ]]; then
        source "$SCRIPT_DIR/scripts/backup.sh"
        main_backup || {
            log_error "Backup failed. Aborting for safety."
            exit 1
        }
    else
        log_warning "Backup skipped (--skip-backup flag)"
    fi

    # Installation modules (executed in order)
    run_module "10-packages"
    run_module "20-oh-my-bash"
    run_module "30-dotfiles"
    run_module "40-kde-config"
    run_module "50-alacritty"
    run_module "99-finalize"

    # All done!
    echo ""
    log_success "========================================="
    log_success "Setup completed successfully!"
    log_success "========================================="
    echo ""
    log_info "Log file saved to: $LOG_FILE"

    if [[ "$SKIP_BACKUP" == false ]]; then
        log_info "Backup saved to: $BACKUP_DIR"
    fi

    echo ""
}

# Run a module script
run_module() {
    local module="$1"
    local module_script="$SCRIPT_DIR/scripts/modules/${module}.sh"

    if [[ ! -f "$module_script" ]]; then
        log_warning "Module $module not found, skipping..."
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would execute module: $module"
        return 0
    fi

    # Source module
    source "$module_script"

    # Each module should define a main_<module>() function
    local func_name="main_${module//-/_}"

    if declare -f "$func_name" > /dev/null; then
        # Execute module function
        if "$func_name"; then
            log_success "Module $module completed successfully"
            return 0
        else
            log_error "Module $module failed"

            # Allow user to continue on non-critical failures
            if [[ "$module" != "00-prerequisites" ]] && [[ "$INTERACTIVE" == true ]]; then
                if confirm "Continue despite failure in $module?"; then
                    log_warning "Continuing despite failure..."
                    return 0
                fi
            fi
            return 1
        fi
    else
        log_error "Module $module missing main function: $func_name"
        return 1
    fi
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skip-packages)
                SKIP_PACKAGES=true
                shift
                ;;
            --skip-backup)
                SKIP_BACKUP=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --non-interactive)
                INTERACTIVE=false
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "Debian KDE Plasma Environment Setup v${SCRIPT_VERSION}"
                exit 0
                ;;
            *)
                echo -e "${RED}Error: Unknown option: $1${NC}"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done

    # Export flags for use in modules
    export SKIP_PACKAGES
    export SKIP_BACKUP
    export DRY_RUN
    export INTERACTIVE
    export SCRIPT_DIR
    export BACKUP_DIR
    export LOG_FILE
}

# Show setup information
show_setup_info() {
    log_info "Setup Configuration:"
    log_info "  • Version: $SCRIPT_VERSION"
    log_info "  • Repository: $SCRIPT_DIR"
    log_info "  • Mode: $([ "$DRY_RUN" == true ] && echo "DRY RUN" || echo "NORMAL")"
    log_info "  • Interactive: $INTERACTIVE"
    log_info "  • Skip Packages: $SKIP_PACKAGES"
    log_info "  • Skip Backup: $SKIP_BACKUP"
    log_info "  • Log File: $LOG_FILE"

    if [[ "$SKIP_BACKUP" == false ]]; then
        log_info "  • Backup Dir: $BACKUP_DIR"
    fi

    echo ""
    log_info "System Information:"
    log_info "  • User: $USER"
    log_info "  • Home: $HOME"
    log_info "  • Hostname: $(hostname)"

    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        log_info "  • OS: $PRETTY_NAME"
    fi

    log_info "  • Kernel: $(uname -r)"

    if command -v plasmashell &> /dev/null; then
        local plasma_version=$(plasmashell --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
        log_info "  • KDE Plasma: $plasma_version"
    fi
}

# Show help message
show_help() {
    cat << EOF
${GREEN}Debian KDE Plasma Environment Setup${NC}

${CYAN}DESCRIPTION:${NC}
    Recreates complete Debian KDE Plasma environment from repository configuration.
    Includes package installation, KDE settings, bash configuration, and more.

${CYAN}USAGE:${NC}
    ./setup.sh [OPTIONS]

${CYAN}OPTIONS:${NC}
    --skip-packages       Skip package installation (deploy configs only)
    --skip-backup         Skip backing up existing configuration
                          ${YELLOW}Warning: Not recommended!${NC}
    --dry-run             Show what would be done without executing
    --non-interactive     Don't prompt for confirmations (assume yes)
    -h, --help            Show this help message
    -v, --version         Show version information

${CYAN}EXAMPLES:${NC}
    ${GREEN}# Full setup with prompts${NC}
    ./setup.sh

    ${GREEN}# Preview what will be done${NC}
    ./setup.sh --dry-run

    ${GREEN}# Only configure (no package installation)${NC}
    ./setup.sh --skip-packages

    ${GREEN}# Automated setup (for scripts/CI)${NC}
    ./setup.sh --non-interactive

${CYAN}WHAT WILL BE INSTALLED:${NC}
    ✓ System packages (apt, flatpak, snap)
    ✓ KDE Plasma configuration (panels, shortcuts, themes)
    ✓ Bash configuration with oh-my-bash
    ✓ Alacritty terminal configuration
    ✓ Custom aliases and scripts
    ✓ GTK theme settings
    ✓ Git configuration

${CYAN}BACKUP:${NC}
    Your existing configurations will be automatically backed up to:
    ~/.config-backup-<timestamp>/

    To restore a backup:
    cp -r ~/.config-backup-<timestamp>/* ~/

${CYAN}POST-INSTALL:${NC}
    After setup completes:
    1. Log out and log back in
    2. Verify KDE settings and shortcuts
    3. Open new terminal for bash changes
    4. Set wallpaper if desired

${CYAN}TROUBLESHOOTING:${NC}
    • Check log file: $LOG_FILE
    • Review backup: ~/.config-backup-*/
    • KDE not updating? Log out completely
    • Bash not updating? Open new terminal

${CYAN}MORE INFO:${NC}
    Repository: $SCRIPT_DIR
    Documentation: $SCRIPT_DIR/docs/
    Update configs: $SCRIPT_DIR/scripts/update-repo.sh

EOF
}

# Handle script errors
handle_error() {
    local line_number=$1
    log_error "Script failed at line $line_number"
    log_error "Check log file for details: $LOG_FILE"

    if [[ "$SKIP_BACKUP" == false ]] && [[ -d "$BACKUP_DIR" ]]; then
        echo ""
        log_info "Your configurations were backed up to:"
        log_info "  $BACKUP_DIR"
    fi

    exit 1
}

# Set error trap
trap 'handle_error $LINENO' ERR

# Execute main function
main "$@"
