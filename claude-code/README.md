# Claude Code Configuration

This directory contains Claude Code (CLI) configuration files, custom agents, and documentation.

## Directory Structure

```
claude-code/
├── agents/          # Custom Claude agents (17 agents)
├── config/          # Claude Code configuration files
├── docs/            # Claude Code documentation
└── README.md        # This file
```

## Agents (17 total)

### Active Agents
- **agent-manager.md** - Meta-agent for managing other agents
- **api-architect.md** - REST/GraphQL API design and architecture
- **data-pipeline-architect.md** - Data pipeline and ETL architecture
- **dev-env-manager.md** - Development environment setup and configuration
- **documentation-expert.md** - Technical documentation and writing
- **git-operations-expert.md** - Git workflows, branching, and version control
- **homelab-research-expert.md** - Homelab and self-hosting research
- **linux-sysadmin-expert.md** - Linux system administration and operations
- **pc-hardware-advisor-br.md** - PC hardware advice (Brazil-focused)
- **performance-monitor.md** - Application performance analysis and monitoring
- **prompt-architect.md** - AI prompt engineering and optimization
- **requirements-analyst.md** - Requirements gathering and analysis
- **research-assistant.md** - General research and information gathering
- **security-auditor.md** - Security auditing and vulnerability assessment
- **software-architect.md** - Software architecture and system design

### Deprecated Agents
- **expert-software-developer.md.deprecated** - Superseded by specialized agents
- **senior-backend-engineer.md.deprecated** - Superseded by specialized agents

## Configuration Files

### config/settings.json
Main Claude Code settings including:
- Permission policies for allowed Bash commands
- Feature flags (e.g., alwaysThinkingEnabled)
- Command whitelists for safe operations

### config/settings.local.json
Local overrides for settings.json:
- Additional permission configurations
- User-specific preferences
- WebSearch enablement

## Documentation

The `docs/` directory contains:
- **AGENT_DISCOVERY_ALGORITHM.md** - How Claude discovers and loads agents
- **AGENT_MANAGER_IMPLEMENTATION_GUIDE.md** - Guide for implementing agent management
- **MIGRATION_GUIDE.md** - Migration guide for Claude Code updates
- **QUICK_REFERENCE.md** - Quick reference for common operations
- **README.md** - General Claude Code documentation

## Installation Location

Claude Code is installed at:
- Binary: `/home/gustavo/.local/bin/claude` (symlink)
- Versions: `/home/gustavo/.local/share/claude/versions/`
- Current version: 2.0.41
- Config directory: `/home/gustavo/.claude/`

## Usage

Agents are automatically discovered by Claude Code when placed in `~/.claude/agents/`.

To restore these agents to a new system:
```bash
# Copy agents to Claude directory
cp -r agents/* ~/.claude/agents/

# Copy configuration files
cp config/settings.json ~/.claude/settings.json
cp config/settings.local.json ~/.claude/settings.local.json
```

## Security Notes

- The `.credentials.json` file from `~/.claude/` is NOT included (contains sensitive data)
- User-specific session data, history, and projects are NOT included
- Only configuration templates and custom agents are tracked

## Backup Information

- Last backed up: 2025-11-14
- Total size: ~360KB
- Source directory: `/home/gustavo/.claude/`
- Number of agents: 17 (15 active, 2 deprecated)

## Additional Notes

- These agents are custom-created for specific development workflows
- The agent system is extensible - new agents can be added as .md files
- Settings can be overridden locally without affecting the base configuration
- Claude Code binary updates are managed separately (not included in this backup)
