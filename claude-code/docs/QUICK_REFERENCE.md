# Agent-Manager Quick Reference Card

## TL;DR

```bash
# agent-manager is now GLOBAL
~/.claude/agents/agent-manager.md  ✅ Works everywhere

# Project-specific agents stay LOCAL
.claude/agents/project-engineer.md  ✅ Arandu-specific

# Rule: Project-local > Global when same name
```

---

## Discovery at a Glance

```
Discovery Flow:
1. Glob ~/.claude/agents/*.md     → 16+ global agents
2. Glob .claude/agents/*.md       → 0-N project agents
3. Merge (project > global)       → Combined pool
4. Route to optimal agent         → User gets result
```

---

## File Locations

| File | Location | Description |
|------|----------|-------------|
| **agent-manager** | `~/.claude/agents/` | Meta-router (global) |
| **Global agents** | `~/.claude/agents/` | General-purpose agents |
| **Project agents** | `.claude/agents/` | Project-specific agents |
| **Discovery algo** | `~/.claude/AGENT_DISCOVERY_ALGORITHM.md` | Technical spec |
| **Implementation** | `~/.claude/AGENT_MANAGER_IMPLEMENTATION_GUIDE.md` | How-to guide |
| **Migration** | `~/.claude/MIGRATION_GUIDE.md` | v1.0 → v2.0 steps |

---

## Usage Patterns

### Invoke agent-manager

```markdown
@agent-manager I need help optimizing a database query
@agent-manager Show me available agents
@agent-manager Route this to the right specialist
```

### Direct agent usage

```markdown
@software-architect Design a microservices architecture
@project-engineer Add an endpoint to Arandu API
@security-auditor Review this code for vulnerabilities
```

---

## Prioritization Rules

| Scenario | Result |
|----------|--------|
| Global only | ✅ Use global |
| Project only | ✅ Use project-local |
| Both exist | ✅ **Use project-local** |
| Neither exists | ❌ Error |

---

## Migration Quick Steps

```bash
# 1. Backup
tar -czf agent-backup-$(date +%Y%m%d).tar.gz .claude/

# 2. Copy to global
cp .claude/agents/agent-manager.md ~/.claude/agents/

# 3. Remove from project
rm .claude/agents/agent-manager.md

# 4. Verify
ls ~/.claude/agents/agent-manager.md  # ✅ Should exist
ls .claude/agents/agent-manager.md    # ❌ Should NOT exist
```

---

## Discovery Test

```bash
# Global agents
find ~/.claude/agents -name "*.md" | wc -l

# Project agents
find .claude/agents -name "*.md" | wc -l

# No duplicate agent-manager
find ~ -name "agent-manager.md" -path "*/.claude/agents/*" | wc -l
# Expected: 1 (only global)
```

---

## Agent Development

### Global Agent Template

```yaml
---
name: agent-name
description: General-purpose description
version: 1.0.0
tags: [relevant, tags]
storage: global
---

You are [general-purpose agent]...
```

**Location**: `~/.claude/agents/[name].md`

### Project-Local Agent Template

```yaml
---
name: agent-name
description: Project-specific description
version: 1.0.0
tags: [project-specific, tags]
storage: project-local
overrides: none  # or ~/.claude/agents/[name].md
---

You are [project-specific agent] for [Project Name]...
```

**Location**: `.claude/agents/[name].md`

---

## Common Commands

```bash
# List global agents
ls -1 ~/.claude/agents/*.md

# List project agents
ls -1 .claude/agents/*.md

# Check agent version
grep "version:" ~/.claude/agents/agent-manager.md

# Find all agent references
grep -r "agent-manager" .claude/ --include="*.md"

# Verify frontmatter
head -n 15 ~/.claude/agents/agent-manager.md
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Agent not found | `ls ~/.claude/agents/[name].md` |
| Override not working | Verify names match EXACTLY |
| Discovery slow | Skip `.deprecated` files |
| Permission denied | `chmod 755 ~/.claude/agents/` |

---

## Key Concepts

**Global**: System-wide, shared across all projects
**Project-Local**: Project-specific, can override global
**Dual-Discovery**: Searches both locations
**Prioritization**: Project-local > Global (more specific wins)
**Transparent**: Location communicated to user

---

## Documentation Hierarchy

```
~/.claude/
├── README.md                              ← Start here
├── QUICK_REFERENCE.md                     ← This file
├── AGENT_DISCOVERY_ALGORITHM.md           ← Technical details
├── AGENT_MANAGER_IMPLEMENTATION_GUIDE.md  ← How to implement
└── MIGRATION_GUIDE.md                     ← v1.0 → v2.0 steps
```

---

## Version Info

| Version | Storage | Discovery |
|---------|---------|-----------|
| v1.0 (old) | Project-local | Single location |
| v2.0 (new) | Global | Dual-location |

**Current**: v2.0
**Date**: 2025-11-07

---

## Example Routing

```markdown
Request: "Add endpoint to Arandu API"
Discovery: 16 global + 1 project-local
Route: project-engineer (project-local)
Reason: Arandu-specific work

Request: "Design new microservices"
Discovery: 16 global + 1 project-local
Route: software-architect (global)
Reason: General architectural work
```

---

## Quick Tests

✅ **agent-manager exists globally**
```bash
test -f ~/.claude/agents/agent-manager.md && echo "OK" || echo "FAIL"
```

✅ **No project-local agent-manager**
```bash
test ! -f .claude/agents/agent-manager.md && echo "OK" || echo "FAIL"
```

✅ **Discovery finds both**
```bash
find ~/.claude/agents -name "*.md" | wc -l  # Should be > 10
find .claude/agents -name "*.md" | wc -l    # Should be ≥ 1
```

---

## Support

- **Overview**: `~/.claude/README.md`
- **Technical**: `~/.claude/AGENT_DISCOVERY_ALGORITHM.md`
- **How-to**: `~/.claude/AGENT_MANAGER_IMPLEMENTATION_GUIDE.md`
- **Migration**: `~/.claude/MIGRATION_GUIDE.md`
- **This card**: `~/.claude/QUICK_REFERENCE.md`

---

**Remember**: Project-local ALWAYS overrides global for same agent name.

**Status**: ✅ Ready to use
**Version**: 2.0.0
