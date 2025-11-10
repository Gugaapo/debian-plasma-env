#!/bin/bash
#
# Verification script
# Verifies that the setup was completed successfully
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}  Setup Verification${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

passed=0
failed=0
warnings=0

# Check function
check() {
    local test_name="$1"
    local result=$2

    if [[ $result -eq 0 ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((passed++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        ((failed++))
        return 1
    fi
}

check_warning() {
    local test_name="$1"
    local result=$2

    if [[ $result -eq 0 ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((passed++))
    else
        echo -e "${YELLOW}⚠${NC} $test_name"
        ((warnings++))
    fi
}

echo "Checking configuration files..."
echo ""

# Bash configuration
check "~/.bashrc exists" "[[ -f ~/.bashrc ]]"
check "oh-my-bash installed" "[[ -d ~/.oh-my-bash ]]"
check_warning "oh-my-bash custom aliases" "[[ -f ~/.oh-my-bash/custom/aliases/general.aliases.sh ]]"

echo ""
echo "Checking KDE configuration..."
echo ""

check "kdeglobals" "[[ -f ~/.config/kdeglobals ]]"
check "kglobalshortcutsrc (shortcuts)" "[[ -f ~/.config/kglobalshortcutsrc ]]"
check "plasmashellrc" "[[ -f ~/.config/plasmashellrc ]]"
check "kwinrc (window manager)" "[[ -f ~/.config/kwinrc ]]"
check_warning "plasma panel config" "[[ -f ~/.config/plasma-org.kde.plasma.desktop-appletsrc ]]"

echo ""
echo "Checking application configurations..."
echo ""

check_warning "Alacritty config" "[[ -f ~/.config/alacritty/alacritty.toml ]] || [[ -f ~/.config/alacritty/alacritty.yml ]]"
check_warning "Dolphin config" "[[ -f ~/.config/dolphinrc ]]"
check_warning "GTK 3.0 config" "[[ -f ~/.config/gtk-3.0/settings.ini ]]"

echo ""
echo "Checking applications..."
echo ""

check_warning "KDE Plasma installed" "command -v plasmashell &>/dev/null"
check_warning "Alacritty installed" "command -v alacritty &>/dev/null"
check_warning "Git installed" "command -v git &>/dev/null"

echo ""
echo "═══════════════════════════════════════════"
echo ""

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}Setup verification completed!${NC}"
    echo -e "  ${GREEN}✓${NC} Passed: $passed"
    if [[ $warnings -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠${NC} Warnings: $warnings (optional items)"
    fi
    echo ""
    echo "Your environment is ready!"
    echo ""
    echo "Remember to:"
    echo "  • Log out and log back in for full KDE configuration"
    echo "  • Open a new terminal for bash/oh-my-bash changes"
    exit 0
else
    echo -e "${RED}Some checks failed!${NC}"
    echo -e "  ${GREEN}✓${NC} Passed: $passed"
    echo -e "  ${RED}✗${NC} Failed: $failed"
    if [[ $warnings -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠${NC} Warnings: $warnings"
    fi
    echo ""
    echo "Check the setup log for details:"
    echo "  → $SCRIPT_DIR/setup.log"
    exit 1
fi
