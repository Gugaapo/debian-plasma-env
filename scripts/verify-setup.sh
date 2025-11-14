#!/bin/bash
#
# Verification script - Check if setup was successful
# Run this after logging back in to verify your environment
#

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Debian KDE Plasma Setup Verification            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Helper functions
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((CHECKS_PASSED++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((CHECKS_FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((CHECKS_WARNING++))
}

# Check KDE Plasma
echo -e "${BLUE}Checking KDE Plasma...${NC}"
if command -v plasmashell &> /dev/null; then
    PLASMA_VERSION=$(plasmashell --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
    check_pass "KDE Plasma installed (version: $PLASMA_VERSION)"

    # Check virtual desktops
    if [[ -f ~/.config/kwinrc ]]; then
        DESKTOP_COUNT=$(grep -A 10 "^\[Desktops\]" ~/.config/kwinrc | grep "^Number=" | cut -d'=' -f2)
        if [[ "$DESKTOP_COUNT" == "4" ]]; then
            check_pass "Virtual Desktops configured: $DESKTOP_COUNT workspaces"
        elif [[ -n "$DESKTOP_COUNT" ]]; then
            check_warn "Virtual Desktops: $DESKTOP_COUNT (expected 4)"
        else
            check_fail "Virtual Desktops not configured"
        fi
    else
        check_fail "kwinrc not found"
    fi

    # Check keyboard shortcuts
    if [[ -f ~/.config/kglobalshortcutsrc ]]; then
        SHORTCUT_COUNT=$(grep -c "^.*=.*,.*," ~/.config/kglobalshortcutsrc || echo "0")
        if [[ $SHORTCUT_COUNT -gt 50 ]]; then
            check_pass "Keyboard shortcuts configured ($SHORTCUT_COUNT shortcuts)"
        else
            check_warn "Keyboard shortcuts may not be fully configured ($SHORTCUT_COUNT found)"
        fi
    else
        check_fail "Keyboard shortcuts not configured"
    fi
else
    check_fail "KDE Plasma not installed"
fi
echo ""

# Check Bash configuration
echo -e "${BLUE}Checking Bash configuration...${NC}"
if [[ -f ~/.bashrc ]]; then
    check_pass "~/.bashrc exists"

    # Check oh-my-bash
    if [[ -d ~/.oh-my-bash ]]; then
        check_pass "oh-my-bash installed"

        if [[ -d ~/.oh-my-bash/custom ]]; then
            CUSTOM_FILES=$(find ~/.oh-my-bash/custom -type f 2>/dev/null | wc -l)
            if [[ $CUSTOM_FILES -gt 0 ]]; then
                check_pass "oh-my-bash custom files: $CUSTOM_FILES files"
            else
                check_warn "No oh-my-bash custom files found"
            fi
        fi
    else
        check_fail "oh-my-bash not installed"
    fi
else
    check_fail "~/.bashrc not found"
fi
echo ""

# Check Alacritty
echo -e "${BLUE}Checking Alacritty...${NC}"
if command -v alacritty &> /dev/null; then
    ALACRITTY_VERSION=$(alacritty --version 2>/dev/null | awk '{print $2}')
    check_pass "Alacritty installed (version: $ALACRITTY_VERSION)"

    if [[ -f ~/.config/alacritty/alacritty.toml ]] || [[ -f ~/.config/alacritty/alacritty.yml ]]; then
        check_pass "Alacritty configuration found"
    else
        check_warn "Alacritty configuration not found"
    fi
else
    check_warn "Alacritty not installed"
fi
echo ""

# Check Claude Code
echo -e "${BLUE}Checking Claude Code...${NC}"
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    check_pass "Claude Code installed (version: $CLAUDE_VERSION)"

    # Check agents
    if [[ -d ~/.claude/agents ]]; then
        AGENT_COUNT=$(find ~/.claude/agents -name "*.md" -type f 2>/dev/null | wc -l)
        if [[ $AGENT_COUNT -gt 0 ]]; then
            check_pass "Claude agents: $AGENT_COUNT agents installed"
        else
            check_warn "No Claude agents found"
        fi
    else
        check_warn "Claude agents directory not found"
    fi

    # Check configuration
    if [[ -f ~/.claude/settings.json ]]; then
        check_pass "Claude Code configuration found"
    else
        check_warn "Claude Code configuration not found"
    fi
else
    check_warn "Claude Code not installed"
fi
echo ""

# Check Docker
echo -e "${BLUE}Checking Docker...${NC}"
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
    check_pass "Docker installed (version: $DOCKER_VERSION)"

    # Check if user is in docker group
    if groups | grep -q docker; then
        check_pass "User in docker group"

        # Test docker
        if docker ps &> /dev/null; then
            check_pass "Docker daemon accessible"
        else
            check_warn "Docker daemon not accessible (may need logout/login or service start)"
        fi
    else
        check_warn "User NOT in docker group (run: sudo usermod -aG docker $USER)"
    fi
else
    check_warn "Docker not installed"
fi
echo ""

# Check Git
echo -e "${BLUE}Checking Git configuration...${NC}"
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
    check_pass "Git installed (version: $GIT_VERSION)"

    if [[ -f ~/.gitconfig ]]; then
        GIT_NAME=$(git config --global user.name 2>/dev/null)
        GIT_EMAIL=$(git config --global user.email 2>/dev/null)

        if [[ -n "$GIT_NAME" ]] && [[ -n "$GIT_EMAIL" ]]; then
            check_pass "Git configured (user: $GIT_NAME <$GIT_EMAIL>)"
        else
            check_warn "Git not fully configured (missing name/email)"
        fi
    else
        check_warn "~/.gitconfig not found"
    fi
else
    check_fail "Git not installed"
fi
echo ""

# Summary
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Verification Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Passed:${NC}  $CHECKS_PASSED"
echo -e "${YELLOW}Warnings:${NC} $CHECKS_WARNING"
echo -e "${RED}Failed:${NC}  $CHECKS_FAILED"
echo ""

if [[ $CHECKS_FAILED -eq 0 ]] && [[ $CHECKS_WARNING -eq 0 ]]; then
    echo -e "${GREEN}✓ All checks passed! Your environment is fully configured.${NC}"
elif [[ $CHECKS_FAILED -eq 0 ]]; then
    echo -e "${YELLOW}⚠ Setup mostly complete with some warnings.${NC}"
    echo -e "  Review warnings above and adjust as needed."
else
    echo -e "${RED}✗ Some critical components are missing.${NC}"
    echo -e "  Review failed checks and re-run setup if needed."
fi
echo ""

# Recommendations
if [[ $CHECKS_FAILED -gt 0 ]] || [[ $CHECKS_WARNING -gt 0 ]]; then
    echo -e "${BLUE}Recommendations:${NC}"
    echo ""

    if ! command -v plasmashell &> /dev/null; then
        echo "  • Install KDE Plasma: Run setup.sh to install packages"
    fi

    if groups | grep -q docker && ! docker ps &> /dev/null 2>&1; then
        echo "  • Log out and log back in for docker group membership to take effect"
    fi

    if [[ ! -f ~/.config/kglobalshortcutsrc ]] || [[ $(grep -c "^.*=.*,.*," ~/.config/kglobalshortcutsrc 2>/dev/null || echo 0) -lt 50 ]]; then
        echo "  • KDE settings may not have loaded: Log out and log back in"
        echo "  • If still not working, try running setup from TTY (Ctrl+Alt+F2)"
    fi

    if command -v claude &> /dev/null && [[ ! -f ~/.claude/settings.json ]]; then
        echo "  • Run 'claude' to complete initial Claude Code setup"
    fi

    echo ""
fi

echo -e "${BLUE}For detailed setup logs, check: ~/debian-plasma-env/setup.log${NC}"
echo ""
