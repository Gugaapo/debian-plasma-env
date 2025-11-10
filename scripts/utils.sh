#!/bin/bash
#
# Utility functions for setup scripts
# Shared functions used across all modules
#

# Color codes for output (only define if not already set)
if [[ -z "${RED:-}" ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly CYAN='\033[0;36m'
    readonly NC='\033[0m' # No Color
fi

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"
}

log_section() {
    echo "" | tee -a "$LOG_FILE"
    echo -e "${CYAN}==== $* ====${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

log_header() {
    echo "" | tee -a "$LOG_FILE"
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}" | tee -a "$LOG_FILE"
    printf "${GREEN}║${NC} %-54s ${GREEN}║${NC}\n" "$*" | tee -a "$LOG_FILE"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

# User confirmation prompt
confirm() {
    if [[ "$INTERACTIVE" == false ]]; then
        return 0  # Always yes in non-interactive mode
    fi

    local prompt="$1"
    local default="${2:-n}"  # Default to 'n' if not specified
    local response

    if [[ "$default" == "y" ]]; then
        local choices="[Y/n]"
    else
        local choices="[y/N]"
    fi

    while true; do
        read -p "$prompt $choices: " response
        response="${response:-$default}"  # Use default if empty

        case "${response,,}" in  # Convert to lowercase
            y|yes)
                return 0
                ;;
            n|no)
                return 1
                ;;
            *)
                echo "Please answer yes or no."
                ;;
        esac
    done
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if package is installed (apt)
package_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

# Deploy a single file with backup
deploy_file() {
    local source="$1"
    local target="$2"
    local description="${3:-$(basename "$target")}"

    if [[ ! -f "$source" ]]; then
        log_warning "Source file not found: $source"
        return 1
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"

    # Backup existing file if it exists and differs
    if [[ -f "$target" ]]; then
        if ! diff -q "$source" "$target" &>/dev/null; then
            if [[ "$SKIP_BACKUP" == false ]]; then
                local backup_path="$BACKUP_DIR/$(basename "$target")"
                mkdir -p "$(dirname "$backup_path")"
                cp "$target" "$backup_path"
                log_info "  Backed up existing: $description"
            fi
        else
            log_info "  Unchanged: $description"
            return 0
        fi
    fi

    # Copy new file
    cp "$source" "$target"
    log_success "  Deployed: $description"
    return 0
}

# Deploy directory contents
deploy_directory() {
    local source="$1"
    local target="$2"
    local description="${3:-$(basename "$target")}"

    if [[ ! -d "$source" ]]; then
        log_warning "Source directory not found: $source"
        return 1
    fi

    # Create target directory
    mkdir -p "$target"

    # Copy contents
    cp -r "$source/"* "$target/" 2>/dev/null || true
    log_success "  Deployed: $description"
    return 0
}

# Detect distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$ID"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# Get distribution version
get_distro_version() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$VERSION_ID"
    else
        echo "unknown"
    fi
}

# Check if running Debian-based system
is_debian_based() {
    [[ -f /etc/debian_version ]] || grep -qi "debian\|ubuntu\|mint" /etc/os-release 2>/dev/null
}

# Print separator line
print_separator() {
    printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' '-'
}

# Pause with message
pause_with_message() {
    local message="${1:-Press any key to continue...}"
    read -n 1 -s -r -p "$message"
    echo ""
}

# Check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Check if running in KDE session
is_kde_session() {
    [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]] || pgrep -x "plasmashell" > /dev/null
}

# Restart Plasma shell
restart_plasma() {
    if is_kde_session; then
        log_info "Restarting Plasma shell..."
        kquitapp5 plasmashell &>/dev/null || killall plasmashell &>/dev/null
        sleep 2
        kstart5 plasmashell &>/dev/null &
        log_success "Plasma shell restarted"
    else
        log_info "Not in KDE session, skipping Plasma restart"
    fi
}

# Wait for process to finish
wait_for_process() {
    local process_name="$1"
    local timeout="${2:-30}"
    local elapsed=0

    while pgrep -x "$process_name" > /dev/null && [[ $elapsed -lt $timeout ]]; do
        sleep 1
        ((elapsed++))
    done

    if [[ $elapsed -ge $timeout ]]; then
        log_warning "Timeout waiting for $process_name to finish"
        return 1
    fi

    return 0
}

# Export functions for use in subshells
export -f log_info log_success log_warning log_error log_section log_header
export -f confirm command_exists package_installed
export -f deploy_file deploy_directory
export -f detect_distro get_distro_version is_debian_based
export -f print_separator pause_with_message
export -f is_root is_kde_session restart_plasma wait_for_process
