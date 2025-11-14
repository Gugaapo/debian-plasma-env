#!/bin/bash
#
# Update repository with current system configuration
# This script captures your current configuration and updates the repository
#

set -euo pipefail

# Determine repository root
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Updating Repository with Current Configuration       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to log messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_section() {
    echo ""
    echo -e "${BLUE}==== $* ====${NC}"
    echo ""
}

# Check if file/directory exists before copying
copy_if_exists() {
    local source="$1"
    local dest="$2"
    local description="${3:-$(basename "$source")}"

    if [[ -e "$source" ]]; then
        mkdir -p "$(dirname "$dest")"
        cp -r "$source" "$dest"
        log_success "Captured: $description"
        return 0
    else
        log_warning "Not found: $description"
        return 1
    fi
}

# ============================================================================
# 1. Package Lists
# ============================================================================
log_section "Collecting Package Lists"

log_info "Generating apt package lists..."
apt-mark showmanual > "$REPO_DIR/packages/apt-manual-packages.txt"
log_success "Created: apt-manual-packages.txt ($(wc -l < "$REPO_DIR/packages/apt-manual-packages.txt") packages)"

dpkg --get-selections | grep -v deinstall | awk '{print $1}' > "$REPO_DIR/packages/apt-packages.txt"
log_success "Created: apt-packages.txt ($(wc -l < "$REPO_DIR/packages/apt-packages.txt") packages)"

# Flatpak packages
if command -v flatpak &> /dev/null; then
    flatpak list --app --columns=application > "$REPO_DIR/packages/flatpak-packages.txt" 2>/dev/null || touch "$REPO_DIR/packages/flatpak-packages.txt"
    if [[ -s "$REPO_DIR/packages/flatpak-packages.txt" ]]; then
        log_success "Created: flatpak-packages.txt ($(wc -l < "$REPO_DIR/packages/flatpak-packages.txt") packages)"
    else
        log_info "No Flatpak packages installed"
    fi
else
    touch "$REPO_DIR/packages/flatpak-packages.txt"
    log_info "Flatpak not installed"
fi

# Snap packages
if command -v snap &> /dev/null; then
    snap list | tail -n +2 | awk '{print $1}' > "$REPO_DIR/packages/snap-packages.txt" 2>/dev/null || touch "$REPO_DIR/packages/snap-packages.txt"
    if [[ -s "$REPO_DIR/packages/snap-packages.txt" ]]; then
        log_success "Created: snap-packages.txt ($(wc -l < "$REPO_DIR/packages/snap-packages.txt") packages)"
    else
        log_info "No Snap packages installed"
    fi
else
    touch "$REPO_DIR/packages/snap-packages.txt"
    log_info "Snap not installed"
fi

# ============================================================================
# 2. Bash Configuration
# ============================================================================
log_section "Collecting Bash Configuration"

copy_if_exists "$HOME/.bashrc" "$REPO_DIR/config/bash/.bashrc" ".bashrc"

# oh-my-bash custom files
if [[ -d "$HOME/.oh-my-bash/custom" ]]; then
    log_info "Collecting oh-my-bash custom files..."

    # Aliases
    if [[ -d "$HOME/.oh-my-bash/custom/aliases" ]]; then
        mkdir -p "$REPO_DIR/config/bash/oh-my-bash/custom/aliases"
        cp -r "$HOME/.oh-my-bash/custom/aliases/"* "$REPO_DIR/config/bash/oh-my-bash/custom/aliases/" 2>/dev/null || true
        alias_count=$(find "$REPO_DIR/config/bash/oh-my-bash/custom/aliases" -type f | wc -l)
        if [[ $alias_count -gt 0 ]]; then
            log_success "Captured: oh-my-bash aliases ($alias_count files)"
        fi
    fi

    # Scripts
    if [[ -d "$HOME/.oh-my-bash/custom/scripts" ]]; then
        mkdir -p "$REPO_DIR/config/bash/oh-my-bash/custom/scripts"
        cp -r "$HOME/.oh-my-bash/custom/scripts/"* "$REPO_DIR/config/bash/oh-my-bash/custom/scripts/" 2>/dev/null || true
        script_count=$(find "$REPO_DIR/config/bash/oh-my-bash/custom/scripts" -type f | wc -l)
        if [[ $script_count -gt 0 ]]; then
            log_success "Captured: oh-my-bash scripts ($script_count files)"
        fi
    fi

    # Themes
    if [[ -d "$HOME/.oh-my-bash/custom/themes" ]]; then
        mkdir -p "$REPO_DIR/config/bash/oh-my-bash/custom/themes"
        cp -r "$HOME/.oh-my-bash/custom/themes/"* "$REPO_DIR/config/bash/oh-my-bash/custom/themes/" 2>/dev/null || true
        theme_count=$(find "$REPO_DIR/config/bash/oh-my-bash/custom/themes" -type f | wc -l)
        if [[ $theme_count -gt 0 ]]; then
            log_success "Captured: oh-my-bash themes ($theme_count files)"
        fi
    fi
else
    log_warning "oh-my-bash custom directory not found"
fi

# ============================================================================
# 3. Alacritty Configuration
# ============================================================================
log_section "Collecting Alacritty Configuration"

if [[ -d "$HOME/.config/alacritty" ]]; then
    mkdir -p "$REPO_DIR/config/alacritty"
    cp -r "$HOME/.config/alacritty/"* "$REPO_DIR/config/alacritty/" 2>/dev/null || true
    file_count=$(find "$REPO_DIR/config/alacritty" -type f | wc -l)
    if [[ $file_count -gt 0 ]]; then
        log_success "Captured: Alacritty configuration ($file_count files)"
    fi
else
    log_warning "Alacritty configuration not found"
fi

# ============================================================================
# 4. KDE Plasma Configuration
# ============================================================================
log_section "Collecting KDE Plasma Configuration"

# Critical KDE config files
kde_configs=(
    "kdeglobals"
    "kglobalshortcutsrc"
    "plasma-org.kde.plasma.desktop-appletsrc"
    "plasmashellrc"
    "kwinrc"
    "kded5rc"
    "plasma-localerc"
    "plasmanotifyrc"
    "breezerc"
    "bluedevilglobalrc"
    "xdg-desktop-portal-kderc"
    "dolphinrc"
    "gwenviewrc"
    "arkrc"
    "katerc"
    "konsolerc"
    "spectaclerc"
)

kde_captured=0
mkdir -p "$REPO_DIR/config/kde/config"

for config in "${kde_configs[@]}"; do
    if [[ -f "$HOME/.config/$config" ]]; then
        cp "$HOME/.config/$config" "$REPO_DIR/config/kde/config/"
        ((kde_captured++))
        log_info "  ✓ $config"
    fi
done

log_success "Captured: $kde_captured KDE configuration files"

# KDE Plasma data (custom plasmoids, themes)
if [[ -d "$HOME/.local/share/plasma/plasmoids" ]]; then
    mkdir -p "$REPO_DIR/config/kde/local/plasma"
    cp -r "$HOME/.local/share/plasma/plasmoids" "$REPO_DIR/config/kde/local/plasma/" 2>/dev/null || true
    plasmoid_count=$(find "$REPO_DIR/config/kde/local/plasma/plasmoids" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    if [[ $plasmoid_count -gt 0 ]]; then
        log_success "Captured: Custom plasmoids ($plasmoid_count widgets)"
    fi
fi

# ============================================================================
# 5. GTK Configuration
# ============================================================================
log_section "Collecting GTK Configuration"

copy_if_exists "$HOME/.gtkrc" "$REPO_DIR/config/gtk/gtkrc" ".gtkrc"
copy_if_exists "$HOME/.gtkrc-2.0" "$REPO_DIR/config/gtk/gtkrc-2.0" ".gtkrc-2.0"

if [[ -d "$HOME/.config/gtk-3.0" ]]; then
    mkdir -p "$REPO_DIR/config/gtk/gtk-3.0"
    cp -r "$HOME/.config/gtk-3.0/"* "$REPO_DIR/config/gtk/gtk-3.0/" 2>/dev/null || true
    log_success "Captured: GTK 3.0 configuration"
fi

if [[ -d "$HOME/.config/gtk-4.0" ]]; then
    mkdir -p "$REPO_DIR/config/gtk/gtk-4.0"
    cp -r "$HOME/.config/gtk-4.0/"* "$REPO_DIR/config/gtk/gtk-4.0/" 2>/dev/null || true
    log_success "Captured: GTK 4.0 configuration"
fi

# ============================================================================
# 6. Git Configuration
# ============================================================================
log_section "Collecting Git Configuration"

if [[ -f "$HOME/.gitconfig" ]]; then
    log_info "Copying .gitconfig (you may want to sanitize personal info)..."
    cp "$HOME/.gitconfig" "$REPO_DIR/config/git/.gitconfig"
    log_success "Captured: .gitconfig"
    log_warning "Remember to review config/git/.gitconfig for sensitive data!"
fi

# ============================================================================
# 7. Claude Code Configuration
# ============================================================================
log_section "Collecting Claude Code Configuration"

if command -v claude &> /dev/null; then
    claude_version=$(claude --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    log_info "Claude Code detected (version: $claude_version)"

    # Capture agents
    if [[ -d "$HOME/.claude/agents" ]]; then
        mkdir -p "$REPO_DIR/claude-code/agents"
        # Copy all agent files
        cp -r "$HOME/.claude/agents/"* "$REPO_DIR/claude-code/agents/" 2>/dev/null || true
        agent_count=$(find "$HOME/.claude/agents" -name "*.md" -type f 2>/dev/null | wc -l)
        if [[ $agent_count -gt 0 ]]; then
            log_success "Captured: Claude agents ($agent_count agents)"
        fi
    else
        log_warning "No Claude agents found"
    fi

    # Capture configuration files
    mkdir -p "$REPO_DIR/claude-code/config"

    if [[ -f "$HOME/.claude/settings.json" ]]; then
        cp "$HOME/.claude/settings.json" "$REPO_DIR/claude-code/config/"
        log_success "Captured: settings.json"
    fi

    if [[ -f "$HOME/.claude/settings.local.json" ]]; then
        cp "$HOME/.claude/settings.local.json" "$REPO_DIR/claude-code/config/"
        log_success "Captured: settings.local.json"
    fi

    # Capture documentation
    if [[ -d "$HOME/.claude" ]]; then
        mkdir -p "$REPO_DIR/claude-code/docs"
        for doc in README.md QUICK_REFERENCE.md AGENT_DISCOVERY_ALGORITHM.md AGENT_MANAGER_IMPLEMENTATION_GUIDE.md MIGRATION_GUIDE.md; do
            if [[ -f "$HOME/.claude/$doc" ]]; then
                cp "$HOME/.claude/$doc" "$REPO_DIR/claude-code/docs/"
                log_info "  ✓ $doc"
            fi
        done
        log_success "Captured: Claude documentation"
    fi

    log_warning "Note: Credentials and history are NOT backed up for security"
else
    log_info "Claude Code not installed, skipping"
fi

# ============================================================================
# 8. Wallpapers
# ============================================================================
log_section "Collecting Wallpapers"

# Try to find current wallpaper from KDE config
if command -v kreadconfig5 &> /dev/null && [[ -f "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" ]]; then
    log_info "Attempting to find current wallpaper..."

    # Find wallpaper path from plasma config
    wallpaper_path=$(grep -A 5 "org.kde.image" "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" | grep "Image=" | head -1 | cut -d'=' -f2 || echo "")

    if [[ -n "$wallpaper_path" ]] && [[ -f "$wallpaper_path" ]]; then
        mkdir -p "$REPO_DIR/assets/wallpapers"
        cp "$wallpaper_path" "$REPO_DIR/assets/wallpapers/"
        log_success "Captured: Current wallpaper ($(basename "$wallpaper_path"))"
    else
        log_info "Could not automatically detect wallpaper"
        log_info "You can manually copy wallpapers to: $REPO_DIR/assets/wallpapers/"
    fi
else
    log_info "Manual wallpaper collection required"
    log_info "Copy wallpapers to: $REPO_DIR/assets/wallpapers/"
fi

# ============================================================================
# 9. System Information
# ============================================================================
log_section "Recording System Information"

cat > "$REPO_DIR/SYSTEM_INFO.txt" << EOF
System Configuration Snapshot
Generated: $(date)

OS Information:
$(cat /etc/os-release 2>/dev/null || echo "Not available")

Kernel: $(uname -r)

KDE Plasma Version:
$(plasmashell --version 2>/dev/null || echo "Not detected")

Desktop Environment:
$XDG_CURRENT_DESKTOP

Shell: $SHELL

Installed Package Managers:
- apt: $(dpkg --version | head -1)
$(command -v flatpak &> /dev/null && echo "- flatpak: $(flatpak --version)" || echo "- flatpak: not installed")
$(command -v snap &> /dev/null && echo "- snap: $(snap version | head -1)" || echo "- snap: not installed")

Claude Code:
$(command -v claude &> /dev/null && echo "- claude: $(claude --version 2>/dev/null || echo 'installed')" || echo "- claude: not installed")
EOF

log_success "Created: SYSTEM_INFO.txt"

# ============================================================================
# Summary
# ============================================================================
log_section "Summary"

echo -e "${GREEN}Configuration capture complete!${NC}"
echo ""
echo "Captured configuration files in: $REPO_DIR"
echo ""
echo "What was captured:"
echo "  • Package lists (apt, flatpak, snap)"
echo "  • Bash configuration (.bashrc)"
echo "  • oh-my-bash custom files"
echo "  • Alacritty configuration"
echo "  • KDE Plasma configuration ($kde_captured files)"
echo "  • GTK theme settings"
echo "  • Git configuration"
echo "  • Claude Code (agents & configuration)"
echo "  • System information"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  • Review config/git/.gitconfig for sensitive information"
echo "  • Add wallpapers manually to assets/wallpapers/ if needed"
echo "  • Verify captured files before committing to Git"
echo ""
echo "Next steps:"
echo "  1. Review captured configurations"
echo "  2. Initialize git: git init && git add -A && git commit -m 'Initial configuration'"
echo "  3. Create setup scripts or use existing ones"
echo ""
