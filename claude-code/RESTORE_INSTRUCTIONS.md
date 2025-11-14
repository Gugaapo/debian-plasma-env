# Claude Code Restore Instructions

## Quick Restore

To restore your Claude Code configuration on a new system after Claude Code is installed:

```bash
# 1. Navigate to the repository
cd /path/to/debian-plasma-env

# 2. Ensure ~/.claude directory exists (created by Claude Code on first run)
# If not, run 'claude' once to initialize it

# 3. Copy agents
cp -r claude-code/agents/* ~/.claude/agents/

# 4. Copy configuration files
cp claude-code/config/settings.json ~/.claude/settings.json
cp claude-code/config/settings.local.json ~/.claude/settings.local.json

# 5. Copy documentation (optional)
cp claude-code/docs/* ~/.claude/
```

## Verification

After restoring, verify the agents are available:

```bash
# List agents directory
ls -l ~/.claude/agents/

# Check settings are in place
cat ~/.claude/settings.json
cat ~/.claude/settings.local.json

# Run Claude Code to test
claude
```

## Installing Claude Code

If Claude Code is not installed, install it first:

```bash
# Download and install Claude Code (check official docs for latest method)
# Typically installed to ~/.local/bin/claude

# Verify installation
which claude
claude --version
```

## What's Backed Up

- ✅ Custom agents (17 files)
- ✅ Settings and configuration
- ✅ Documentation files
- ❌ Binary files (too large, version-specific)
- ❌ Credentials (sensitive data)
- ❌ Session history
- ❌ Project data
- ❌ File history

## Security Considerations

**Files NOT included for security:**
- `.credentials.json` - Contains API keys and authentication tokens
- `history.jsonl` - May contain sensitive conversation data
- `projects/*` - May contain project-specific sensitive data
- `file-history/*` - Historical file contents

**You will need to:**
1. Re-authenticate Claude Code after restore
2. Reconfigure any API keys or credentials
3. Review and update permission settings in `settings.json` if needed

## Customization

### Adding New Agents

1. Create a new `.md` file in `~/.claude/agents/`
2. Follow the agent template structure (see existing agents)
3. Claude Code will automatically discover it on next run

### Modifying Permissions

Edit `~/.claude/settings.json` or `~/.claude/settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(command:*)",
      "WebSearch"
    ],
    "deny": [],
    "ask": []
  }
}
```

## Troubleshooting

**Agents not loading:**
- Verify file permissions: `chmod 644 ~/.claude/agents/*.md`
- Check file encoding is UTF-8
- Ensure no syntax errors in agent definitions

**Settings not applying:**
- Verify JSON syntax is valid: `jq . ~/.claude/settings.json`
- Check `settings.local.json` overrides (it takes precedence)
- Restart Claude Code after changes

**Permission errors:**
- Review `settings.json` permission allowlists
- Add specific commands to the `allow` array
- Check `settings.local.json` for conflicts

## Repository Structure

```
claude-code/
├── agents/                      # Custom agent definitions
│   ├── agent-manager.md
│   ├── api-architect.md
│   ├── data-pipeline-architect.md
│   ├── dev-env-manager.md
│   ├── documentation-expert.md
│   ├── git-operations-expert.md
│   ├── homelab-research-expert.md
│   ├── linux-sysadmin-expert.md
│   ├── pc-hardware-advisor-br.md
│   ├── performance-monitor.md
│   ├── prompt-architect.md
│   ├── requirements-analyst.md
│   ├── research-assistant.md
│   ├── security-auditor.md
│   ├── software-architect.md
│   ├── expert-software-developer.md.deprecated
│   └── senior-backend-engineer.md.deprecated
├── config/                      # Configuration files
│   ├── settings.json           # Main settings
│   └── settings.local.json     # Local overrides
├── docs/                        # Documentation
│   ├── AGENT_DISCOVERY_ALGORITHM.md
│   ├── AGENT_MANAGER_IMPLEMENTATION_GUIDE.md
│   ├── MIGRATION_GUIDE.md
│   ├── QUICK_REFERENCE.md
│   └── README.md
├── README.md                    # This directory overview
└── RESTORE_INSTRUCTIONS.md      # This file
```

## Version Information

- Claude Code version backed up: 2.0.41
- Backup date: 2025-11-14
- System: Debian GNU/Linux (testing)
- Installation path: `/home/gustavo/.local/bin/claude`

## Additional Resources

- Claude Code documentation: Check `docs/README.md`
- Agent development guide: See `docs/AGENT_MANAGER_IMPLEMENTATION_GUIDE.md`
- Migration guide: See `docs/MIGRATION_GUIDE.md`
