# Claude Code Agent System - Global Configuration

This directory contains the **global agent system** configuration for Claude Code, providing intelligent routing and specialized agents available across all projects.

## Overview

The agent system uses a **dual-location discovery architecture**:

```
Global Agents (~/.claude/agents/)     Project-Local Agents (.claude/agents/)
├─ agent-manager.md                   ├─ project-engineer.md (example)
├─ software-architect.md              ├─ custom-tools.md (example)
├─ data-pipeline-architect.md         └─ [project-specific agents]
├─ security-auditor.md
└─ [other global agents]

         ▼                                      ▼
         └──────────── Discovered by ──────────┘
                    agent-manager
                         │
                         ▼
                  Intelligent Routing
                  (Project-local > Global)
```

## Directory Structure

```
~/.claude/
├── agents/                           # Global agents (system-wide)
│   ├── agent-manager.md             # Meta-router (discovers & routes)
│   ├── software-architect.md        # Greenfield projects
│   ├── data-pipeline-architect.md   # SQL & data processing
│   ├── linux-sysadmin-expert.md     # Server administration
│   ├── security-auditor.md          # Security reviews
│   ├── performance-monitor.md       # Performance profiling
│   ├── documentation-expert.md      # Documentation writing
│   ├── requirements-analyst.md      # Requirements gathering
│   ├── homelab-research-expert.md   # Homelab guidance
│   ├── pc-hardware-advisor-br.md    # Brazilian PC hardware
│   ├── git-operations-expert.md     # Git operations
│   ├── dev-env-manager.md           # Development environments
│   ├── research-assistant.md        # Research & information
│   └── [other global agents]
│
├── AGENT_DISCOVERY_ALGORITHM.md     # Technical discovery specification
├── AGENT_MANAGER_IMPLEMENTATION_GUIDE.md  # Implementation guide
├── MIGRATION_GUIDE.md               # Migration from v1.0 to v2.0
└── README.md                        # This file
```

## Core Concepts

### 1. Dual-Location Discovery

The agent-manager discovers agents from TWO locations:

- **Global** (`~/.claude/agents/`): System-wide, available in all projects
- **Project-Local** (`.claude/agents/`): Project-specific, optional

### 2. Prioritization Strategy

**Rule**: When the same agent name exists in both locations, **project-local ALWAYS overrides global**.

**Example**:
```
Global: ~/.claude/agents/security-auditor.md (generic)
Project: .claude/agents/security-auditor.md (LGPD-specific)
→ Uses project-local version (more specific)
```

### 3. Agent Categories

**Meta-Router:**
- `agent-manager`: Discovers agents, analyzes requests, routes to specialists

**Architecture & Design:**
- `software-architect`: Greenfield project coordinator
- `api-architect`: API design specialist

**Development & Operations:**
- `linux-sysadmin-expert`: Server administration
- `dev-env-manager`: Development environment setup
- `git-operations-expert`: Git operations and workflows

**Data & Performance:**
- `data-pipeline-architect`: SQL optimization, ETL, data processing
- `performance-monitor`: Performance profiling and monitoring

**Security & Compliance:**
- `security-auditor`: Security reviews and audits

**Documentation & Requirements:**
- `documentation-expert`: Technical writing, API docs
- `requirements-analyst`: Requirements gathering and analysis

**Research & Hardware:**
- `research-assistant`: Information gathering
- `homelab-research-expert`: Homelab and NAS guidance
- `pc-hardware-advisor-br`: Brazilian PC hardware advice

**Specialized:**
- `prompt-architect`: Prompt engineering and AI control

## Quick Start

### Using agent-manager

The agent-manager is the intelligent router that discovers and delegates to specialist agents.

**Explicit invocation:**
```
@agent-manager I need help optimizing a database query
```

**Automatic routing:**
```
I'm not sure which agent to use for this task...
```

**Complex coordination:**
```
Build a new feature with security review and documentation
```

### Direct Agent Usage

You can also invoke agents directly when you know which one you need:

```
@software-architect Design a microservices architecture
@data-pipeline-architect Optimize this SQL query
@security-auditor Review this code for vulnerabilities
```

## Discovery Mechanism

### How It Works

1. **Global Discovery**: `~/.claude/agents/*.md` (always present)
2. **Project-Local Discovery**: `.claude/agents/*.md` (optional)
3. **Merge & Prioritize**: Project-local overrides global
4. **Build Routing Table**: Create searchable index
5. **Route Request**: Select optimal agent(s)

### Example Discovery

```markdown
## Agent Discovery Report

**Total Agents:** 14

### Global Agents (~/.claude/agents/)
- agent-manager (meta-router)
- software-architect (greenfield coordinator)
- data-pipeline-architect (SQL & data)
- security-auditor (security reviews)
- [... 10 more global agents ...]

### Project-Local Agents (.claude/agents/)
- project-engineer (Arandu API specialist)

### Overrides
None (no name collisions)
```

## Agent Development

### Creating a Global Agent

**When to create:**
- General-purpose tool useful across projects
- Reusable expertise (SQL, security, Linux, etc.)
- No project-specific knowledge required

**Location**: `~/.claude/agents/[agent-name].md`

**Template**:
```yaml
---
name: agent-name
description: Brief description of agent capabilities
version: 1.0.0
tags: [relevant, tags]
storage: global
delegates_to: [list-of-agents]
model: sonnet
---

You are [agent description]...

## Core Expertise
- [Expertise 1]
- [Expertise 2]

[... agent instructions ...]
```

### Creating a Project-Local Agent

**When to create:**
- Project-specific knowledge required
- Customization of global agent needed
- Experimental agent not ready for global use

**Location**: `[project]/.claude/agents/[agent-name].md`

**Template**:
```yaml
---
name: agent-name
description: Project-specific description
version: 1.0.0
tags: [project-specific, relevant]
storage: project-local
overrides: none  # Or: ~/.claude/agents/[agent].md
delegates_to: [list-of-agents]
model: sonnet
---

You are [agent description] specialized for the [Project Name] project...

## Project-Specific Context
- [Project detail 1]
- [Project detail 2]

[... agent instructions ...]
```

## Migration from v1.0

If you have project-local agent-manager (old system), follow the migration guide:

**See**: `~/.claude/MIGRATION_GUIDE.md`

**Quick migration:**
```bash
# 1. Backup
cd /path/to/project/
tar -czf agent-backup-$(date +%Y%m%d).tar.gz .claude/

# 2. Move agent-manager to global
cp .claude/agents/agent-manager.md ~/.claude/agents/

# 3. Remove from project
rm .claude/agents/agent-manager.md

# 4. Test discovery
ls ~/.claude/agents/agent-manager.md  # Should exist
ls .claude/agents/agent-manager.md    # Should NOT exist
```

## Key Features

### ✅ Global Availability
- agent-manager works in ALL projects
- No need to copy to each project

### ✅ Dual Discovery
- Finds agents from both global and project-local locations
- Automatic merging and prioritization

### ✅ Smart Prioritization
- Project-local overrides global (more specific wins)
- Transparent communication of location choice

### ✅ Future-Proof
- New agents discovered automatically
- No code changes when adding agents

### ✅ Flexible Architecture
- Global for general-purpose
- Project-local for specific needs
- Override mechanism for customization

## Documentation

### Core Documentation

- **AGENT_DISCOVERY_ALGORITHM.md**: Technical specification of discovery process
- **AGENT_MANAGER_IMPLEMENTATION_GUIDE.md**: Comprehensive implementation guide
- **MIGRATION_GUIDE.md**: Step-by-step migration from v1.0 to v2.0
- **README.md**: This file (overview and quick start)

### Project Documentation

Each project with `.claude/` may have:

- **AGENT_SELECTION_GUIDE.md**: Decision trees for agent selection
- **AGENT_BEST_PRACTICES.md**: Usage patterns and workflows
- **AGENT_INTERACTION_DIAGRAM.md**: Visual agent relationships

## Best Practices

### For Users

1. **Use agent-manager for routing decisions**
   - Let it discover and route to the right agent
   - Transparent explanations of routing choices

2. **Provide context in requests**
   - Mention project name (e.g., "in Arandu API")
   - Specify domain (SQL, security, Linux, etc.)
   - State your goal clearly

3. **Trust the location strategy**
   - Project-local for project-specific work
   - Global for general-purpose tasks

### For Developers

1. **Choose location carefully**
   - Global: Reusable, general-purpose
   - Project-local: Project-specific, customized

2. **Write clear frontmatter**
   - Accurate description
   - Relevant tags
   - Correct storage location

3. **Document limitations**
   - What agent does NOT handle
   - When to delegate to others

4. **Use semantic naming**
   - Clear, descriptive agent names
   - Consistent with ecosystem

## Troubleshooting

### Agent Not Found

```bash
# Verify agent exists
ls ~/.claude/agents/[agent-name].md

# Check frontmatter
head -n 15 ~/.claude/agents/[agent-name].md

# Verify 'name' field matches filename
grep "^name:" ~/.claude/agents/[agent-name].md
```

### Discovery Not Working

```bash
# Test global discovery
find ~/.claude/agents -name "*.md" ! -name "*.deprecated"

# Test project-local discovery
cd /path/to/project/
find .claude/agents -name "*.md" ! -name "*.deprecated"
```

### Override Not Applied

```bash
# Verify names match EXACTLY
grep "^name:" ~/.claude/agents/agent.md
grep "^name:" .claude/agents/agent.md

# Names must be identical for override
```

## Version History

### v2.0.0 (Current)
- Dual-location discovery (global + project-local)
- agent-manager moved to global location
- Smart prioritization (project-local > global)
- Transparent location communication
- Comprehensive migration guide

### v1.0.0 (Legacy)
- Project-local only
- agent-manager per-project
- No global discovery
- Deprecated as of v2.0.0

## Support

**Documentation:**
- See files in `~/.claude/` directory
- Check project-specific `.claude/` docs
- Review agent frontmatter for usage

**Community:**
- Claude Code documentation
- Agent development guides
- Community forums

## Summary

The Claude Code agent system provides:

🎯 **Intelligent Routing**: agent-manager discovers and routes to specialists
🌍 **Global Availability**: Core agents available in all projects
🎨 **Project Customization**: Override global agents when needed
🔍 **Dual Discovery**: Finds agents from both locations automatically
📚 **Transparent**: Clear communication of location choices
🚀 **Scalable**: Easy to add new agents and projects

**Start using**: `@agent-manager [your request]`

**Version**: 2.0.0
**Last Updated**: 2025-11-07
**Location**: `~/.claude/` (global)
