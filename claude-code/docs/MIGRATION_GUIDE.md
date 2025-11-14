# Agent-Manager Migration Guide

This guide provides step-by-step instructions for migrating from the old project-local agent-manager to the new dual-location system with global agent-manager.

## Migration Overview

### What's Changing

**Old System (v1.0):**
```
Project A:
  .claude/agents/
    ├── agent-manager.md  ❌ Only available in this project
    ├── project-engineer.md
    └── other-agents.md

Project B:
  (no agent-manager) ❌ Can't use intelligent routing
```

**New System (v2.0):**
```
Global:
  ~/.claude/agents/
    ├── agent-manager.md  ✅ Available in ALL projects
    ├── software-architect.md
    ├── data-pipeline-architect.md
    └── [other global agents]

Project A:
  .claude/agents/
    └── project-engineer.md  ✅ Project-specific only

Project B:
  .claude/agents/
    └── custom-tool.md  ✅ Also has access to global agents
```

### Benefits of Migration

✅ **Global Availability**: agent-manager works in all projects
✅ **Consistent Routing**: Same intelligent routing everywhere
✅ **Reduced Duplication**: One agent-manager, not per-project copies
✅ **Easier Maintenance**: Update once, applies everywhere
✅ **Dual Discovery**: Discovers both global and project-local agents
✅ **Smart Prioritization**: Project-local overrides global when needed

---

## Pre-Migration Checklist

Before starting, verify:

- [ ] You have the current agent-manager.md in a project's `.claude/agents/`
- [ ] You have backup of current agent setup
- [ ] You understand which agents are project-specific vs general-purpose
- [ ] You have write permissions to `~/.claude/` directory
- [ ] You're ready to update documentation references

---

## Migration Steps

### Step 1: Backup Current Setup

**Backup all projects with agent systems:**

```bash
# Backup Arandu API agents
cd /home/gustavo/TJAM/arandu-api/
tar -czf agent-backup-arandu-$(date +%Y%m%d-%H%M%S).tar.gz .claude/

# Verify backup
ls -lh agent-backup-*.tar.gz

# Backup other projects (repeat for each)
cd /path/to/other/project/
tar -czf agent-backup-$(basename $(pwd))-$(date +%Y%m%d-%H%M%S).tar.gz .claude/
```

**Store backups safely:**
```bash
# Move backups to safe location
mkdir -p ~/backups/agent-migration/
mv agent-backup-*.tar.gz ~/backups/agent-migration/

# Verify
ls -lh ~/backups/agent-migration/
```

---

### Step 2: Create Global Agents Directory

**Create the directory structure:**

```bash
# Create global directory
mkdir -p ~/.claude/agents/

# Set appropriate permissions
chmod 755 ~/.claude/
chmod 755 ~/.claude/agents/

# Verify
ls -lad ~/.claude/agents/
# Expected: drwxr-xr-x ... /home/gustavo/.claude/agents/
```

---

### Step 3: Move agent-manager to Global Location

**Copy agent-manager from project to global:**

```bash
# Source: Current location in Arandu API
SOURCE="/home/gustavo/TJAM/arandu-api/.claude/agents/agent-manager.md"

# Destination: Global location
DEST="$HOME/.claude/agents/agent-manager.md"

# Copy (not move yet - keep backup in project temporarily)
cp "$SOURCE" "$DEST"

# Verify the copy
ls -lh ~/.claude/agents/agent-manager.md

# Verify frontmatter
head -n 20 ~/.claude/agents/agent-manager.md
# Should see:
# ---
# name: agent-manager
# description: ...
# version: 2.0.0
# storage: global
# ---
```

**Verify it's the updated version (v2.0):**

```bash
# Check version in frontmatter
grep "version:" ~/.claude/agents/agent-manager.md
# Expected: version: 2.0.0

# Check for dual-location discovery mention
grep -i "dual-location" ~/.claude/agents/agent-manager.md
# Should find references to dual-location discovery
```

---

### Step 4: Classify Existing Agents

**Determine which agents should be global vs project-local:**

```bash
# List all current agents in Arandu API
ls -1 /home/gustavo/TJAM/arandu-api/.claude/agents/

# Expected output (example):
# agent-manager.md  ← Moving to global
# project-engineer.md  ← Keep project-local (Arandu-specific)
```

**Classification Guidelines:**

| Agent | Location | Reason |
|-------|----------|--------|
| agent-manager | Global | Meta-router, needed everywhere |
| project-engineer | Project-local | Arandu API-specific knowledge |
| software-architect | Global | General greenfield coordinator |
| data-pipeline-architect | Global | General SQL/data expertise |
| security-auditor | Global | General security (unless project-specific) |
| custom-linter | Project-local | Project-specific tool |

**For Arandu API:**
```bash
# Keep project-local:
- project-engineer.md (Arandu-specific)

# Remove from project (now in global):
- agent-manager.md
```

---

### Step 5: Move General-Purpose Agents to Global

**If you have existing global agents in ~/.claude/agents/:**

```bash
# List current global agents
ls -1 ~/.claude/agents/

# Example: Move general agents from any project to global
# (Only if they're general-purpose, not project-specific)

cd ~/.claude/agents/

# Verify these are general-purpose agents
for agent in software-architect.md data-pipeline-architect.md \
             linux-sysadmin-expert.md security-auditor.md \
             performance-monitor.md documentation-expert.md \
             requirements-analyst.md homelab-research-expert.md \
             pc-hardware-advisor-br.md git-operations-expert.md \
             dev-env-manager.md research-assistant.md; do
  if [ -f "$agent" ]; then
    echo "✓ Global agent exists: $agent"
  else
    echo "✗ Missing global agent: $agent"
  fi
done
```

---

### Step 6: Remove agent-manager from Project-Local

**Now that agent-manager is global, remove from project:**

```bash
# Remove from Arandu API
cd /home/gustavo/TJAM/arandu-api/

# Verify before removing
ls -lh .claude/agents/agent-manager.md

# Remove project-local copy
rm .claude/agents/agent-manager.md

# Verify removal
ls -la .claude/agents/ | grep agent-manager || echo "✓ Successfully removed"

# Verify project-engineer still exists (project-specific)
ls -lh .claude/agents/project-engineer.md
# Expected: Should still exist
```

**Repeat for other projects that have agent-manager:**

```bash
# For each project with agent-manager
for project in ~/projects/*; do
  AGENT_MGR="$project/.claude/agents/agent-manager.md"
  if [ -f "$AGENT_MGR" ]; then
    echo "Removing agent-manager from $(basename $project)"
    rm "$AGENT_MGR"
  fi
done

# Verify
find ~/projects -name "agent-manager.md" -path "*/.claude/agents/*"
# Expected: No results (all removed)
```

---

### Step 7: Update Documentation References

**Update references in project documentation:**

```bash
cd /home/gustavo/TJAM/arandu-api/

# Find all references to old location
grep -r "\.claude/agents/agent-manager" .claude/ --include="*.md"

# Example output:
# .claude/AGENT_SELECTION_GUIDE.md:| **Meta/Routing** | `agent-manager` (.claude/agents/) |
# .claude/AGENT_BEST_PRACTICES.md:The agent-manager (.claude/agents/agent-manager.md) ...
```

**Update each file:**

```bash
# Update AGENT_SELECTION_GUIDE.md
# OLD: | **Meta/Routing** | `agent-manager` (.claude/agents/) |
# NEW: | **Meta/Routing** | `agent-manager` (global: ~/.claude/agents/) |

# Update AGENT_BEST_PRACTICES.md
# OLD: The agent-manager (.claude/agents/agent-manager.md)
# NEW: The agent-manager (global: ~/.claude/agents/agent-manager.md)

# Update AGENT_INTERACTION_DIAGRAM.md
# OLD: [agent-manager] (.claude/agents/)
# NEW: [agent-manager] (global: ~/.claude/agents/)
```

**Automated update (use with caution):**

```bash
# Create a backup first
cp .claude/AGENT_SELECTION_GUIDE.md .claude/AGENT_SELECTION_GUIDE.md.bak

# Update references (example)
sed -i 's|\.claude/agents/agent-manager\.md|~/.claude/agents/agent-manager.md (global)|g' \
  .claude/AGENT_SELECTION_GUIDE.md

# Verify changes
diff .claude/AGENT_SELECTION_GUIDE.md.bak .claude/AGENT_SELECTION_GUIDE.md
```

---

### Step 8: Update Project README (If Applicable)

**Add agent location documentation:**

```bash
# Update project README
cat >> README.md << 'EOF'

## Agent System

This project uses the Claude Code agent system with dual-location discovery:

### Global Agents (~/.claude/agents/)
- **agent-manager**: Intelligent routing to specialist agents (system-wide)
- **software-architect**: Greenfield project coordinator
- **data-pipeline-architect**: SQL and data processing
- **security-auditor**: Security reviews
- **[other global agents]**: General-purpose tools

### Project-Local Agents (.claude/agents/)
- **project-engineer**: Arandu API specialist with deep codebase knowledge
- Project-specific tools and customizations

For more information, see `.claude/AGENT_SELECTION_GUIDE.md`.

EOF
```

---

### Step 9: Test Discovery

**Verify agent-manager can discover from both locations:**

```bash
# Test global discovery
find ~/.claude/agents -name "*.md" ! -name "*.deprecated" | sort

# Expected output:
# /home/gustavo/.claude/agents/agent-manager.md
# /home/gustavo/.claude/agents/data-pipeline-architect.md
# /home/gustavo/.claude/agents/software-architect.md
# [... other global agents ...]

# Test project-local discovery
cd /home/gustavo/TJAM/arandu-api/
find .claude/agents -name "*.md" ! -name "*.deprecated" | sort

# Expected output:
# .claude/agents/project-engineer.md
```

**Test with agent-manager (manual):**

```markdown
User: "@agent-manager show me all available agents"

Expected Response:
## Agent Discovery Report

**Total Agents:** 13

### Global Agents (~/.claude/agents/)
- agent-manager (meta-router)
- software-architect (greenfield coordinator)
- data-pipeline-architect (SQL & data)
- [... other global agents ...]

### Project-Local Agents (.claude/agents/)
- project-engineer (Arandu API specialist)

### Overrides
None (no name collisions)
```

---

### Step 10: Test Routing

**Test project-specific routing:**

```markdown
User: "Help me add a new endpoint to Arandu API"

Expected Response:
## Routing Decision

**Selected Agent:** project-engineer
**Location:** project-local
**Path:** .claude/agents/project-engineer.md

**Rationale:**
- This is Arandu API-specific work
- project-engineer has deep knowledge of the codebase
- Using project-local version for specialized Arandu expertise

→ Launching project-engineer agent...
```

**Test global routing:**

```markdown
User: "Help me design a new microservices architecture"

Expected Response:
## Routing Decision

**Selected Agent:** software-architect
**Location:** global
**Path:** ~/.claude/agents/software-architect.md

**Rationale:**
- This is greenfield architectural work
- Not project-specific (no Arandu knowledge needed)
- Using global software-architect for general expertise

→ Launching software-architect agent...
```

---

### Step 11: Migrate Other Projects (Optional)

**Apply same migration to other projects:**

```bash
# For each project with .claude/agents/
for project in ~/projects/*; do
  if [ -d "$project/.claude/agents" ]; then
    echo "Migrating: $(basename $project)"

    cd "$project"

    # Remove agent-manager if exists (now global)
    rm -f .claude/agents/agent-manager.md

    # Review remaining agents - are they project-specific?
    echo "Remaining agents:"
    ls -1 .claude/agents/*.md 2>/dev/null || echo "  (none)"

    # Decision: Keep project-specific, move general to global
  fi
done
```

---

### Step 12: Verify and Clean Up

**Final verification:**

```bash
# 1. Verify global agent-manager exists
test -f ~/.claude/agents/agent-manager.md && echo "✓ Global agent-manager exists" || echo "✗ Missing"

# 2. Verify project-local agent-manager removed
test ! -f /home/gustavo/TJAM/arandu-api/.claude/agents/agent-manager.md && \
  echo "✓ Project-local agent-manager removed" || echo "✗ Still exists"

# 3. Verify project-specific agents remain
test -f /home/gustavo/TJAM/arandu-api/.claude/agents/project-engineer.md && \
  echo "✓ Project-engineer still exists" || echo "✗ Missing"

# 4. Count agents
echo "Global agents: $(find ~/.claude/agents -name "*.md" ! -name "*.deprecated" | wc -l)"
echo "Project-local agents: $(find /home/gustavo/TJAM/arandu-api/.claude/agents -name "*.md" ! -name "*.deprecated" 2>/dev/null | wc -l)"
```

**Clean up backups (after confirming migration success):**

```bash
# Keep backups for 30 days, then remove
# Do NOT remove immediately - wait for confirmation everything works

# After 30 days:
# rm -rf ~/backups/agent-migration/
```

---

## Post-Migration Validation

### Validation Checklist

- [ ] agent-manager exists at `~/.claude/agents/agent-manager.md`
- [ ] Global agents exist in `~/.claude/agents/`
- [ ] Project-specific agents remain in `.claude/agents/`
- [ ] No duplicate agent-manager in project directories
- [ ] Documentation updated with new locations
- [ ] Discovery finds agents from both locations
- [ ] Routing works for project-specific requests
- [ ] Routing works for general requests
- [ ] No broken references in documentation

### Test Cases

**Test 1: Global Agent Discovery**
```bash
# Expected: Lists all global agents
ls ~/.claude/agents/*.md | wc -l
# Should be > 10 (agent-manager + other global agents)
```

**Test 2: Project-Local Agent Discovery**
```bash
# Expected: Lists only project-specific agents
cd /home/gustavo/TJAM/arandu-api/
ls .claude/agents/*.md 2>/dev/null | wc -l
# Should be ≥ 1 (project-engineer)
```

**Test 3: No Duplicate agent-manager**
```bash
# Expected: Only ONE result (global)
find ~ -name "agent-manager.md" -path "*/.claude/agents/*" 2>/dev/null

# Should return only:
# /home/gustavo/.claude/agents/agent-manager.md
```

**Test 4: Routing Decision**
```markdown
User: "@agent-manager I need help with Arandu API"

Expected:
- Discovers agents from BOTH locations
- Routes to project-engineer (project-local)
- Mentions location in response
```

---

## Rollback Instructions

If you need to rollback the migration:

### Rollback Step 1: Restore from Backup

```bash
# Navigate to project
cd /home/gustavo/TJAM/arandu-api/

# Remove current agents
rm -rf .claude/agents/

# Restore from backup
tar -xzf ~/backups/agent-migration/agent-backup-arandu-*.tar.gz

# Verify restoration
ls -la .claude/agents/
# Should include agent-manager.md and other agents
```

### Rollback Step 2: Remove Global agent-manager (Optional)

```bash
# If you want to fully rollback to old system
rm ~/.claude/agents/agent-manager.md

# Verify
ls ~/.claude/agents/agent-manager.md
# Should return: No such file or directory
```

### Rollback Step 3: Restore Documentation

```bash
# Restore documentation from backup
cd /home/gustavo/TJAM/arandu-api/
tar -xzf ~/backups/agent-migration/agent-backup-arandu-*.tar.gz .claude/*.md

# Or restore from git (if tracked)
git checkout .claude/AGENT_SELECTION_GUIDE.md
git checkout .claude/AGENT_MANAGER_IMPLEMENTATION_GUIDE.md
```

---

## Troubleshooting Migration Issues

### Issue 1: Permission Denied Creating ~/.claude/

**Error:**
```
mkdir: cannot create directory '/home/gustavo/.claude': Permission denied
```

**Solution:**
```bash
# Check current user
whoami

# Ensure you own your home directory
ls -ld ~/

# Create with proper permissions
mkdir -p ~/.claude/agents/
chmod 755 ~/.claude ~/.claude/agents/
```

### Issue 2: agent-manager Not Found After Migration

**Error:**
```
Agent 'agent-manager' not found
```

**Solution:**
```bash
# Verify file exists
ls -lh ~/.claude/agents/agent-manager.md

# Check file permissions
chmod 644 ~/.claude/agents/agent-manager.md

# Verify YAML frontmatter
head -n 10 ~/.claude/agents/agent-manager.md
# Should have 'name: agent-manager'
```

### Issue 3: Discovery Not Finding Global Agents

**Symptom:** Only project-local agents found

**Solution:**
```bash
# Check glob pattern support
cd ~/.claude/agents/
ls *.md

# Verify absolute path expansion
echo ~/.claude/agents/*.md

# Test with find
find ~/.claude/agents -name "*.md" ! -name "*.deprecated"
```

### Issue 4: Project-Local Agents Not Discovered

**Symptom:** Only global agents found

**Solution:**
```bash
# Verify directory exists
ls -ld .claude/agents/

# Check relative path
pwd
ls .claude/agents/*.md

# Verify working directory is project root
```

### Issue 5: Override Not Working

**Symptom:** Global agent used when project-local should override

**Solution:**
```bash
# Verify agent names match EXACTLY
grep "^name:" ~/.claude/agents/software-architect.md
grep "^name:" .claude/agents/software-architect.md

# Names must match for override
# If different, rename to match
```

---

## Migration Timeline

**Recommended timeline for safe migration:**

| Day | Activity | Duration |
|-----|----------|----------|
| Day 0 | Review migration guide | 1 hour |
| Day 0 | Backup current setup | 15 min |
| Day 0 | Create global directory | 5 min |
| Day 0 | Copy agent-manager to global | 5 min |
| Day 1 | Test global agent-manager | 30 min |
| Day 1 | Remove project-local agent-manager | 5 min |
| Day 1 | Test discovery and routing | 1 hour |
| Day 2 | Update documentation | 1 hour |
| Day 2 | Migrate other projects | 2 hours |
| Day 7 | Validate everything works | 30 min |
| Day 30 | Remove backups | 5 min |

**Total effort:** ~6-8 hours spread over 30 days for safe, validated migration

---

## Success Criteria

Migration is successful when:

✅ agent-manager exists at `~/.claude/agents/agent-manager.md`
✅ No duplicate agent-manager in project directories
✅ Discovery finds agents from both locations
✅ Project-specific agents remain in `.claude/agents/`
✅ General-purpose agents in `~/.claude/agents/`
✅ Routing correctly uses project-local for project work
✅ Routing correctly uses global for general work
✅ Documentation updated with new locations
✅ All test cases pass
✅ No broken agent references

---

## Post-Migration Benefits

After successful migration, you'll have:

1. **Global Agent Access**: agent-manager works in every project
2. **Consistent Routing**: Same intelligent routing everywhere
3. **Reduced Maintenance**: Update global agents once
4. **Project Customization**: Override global agents when needed
5. **Clear Separation**: Global vs project-local distinction
6. **Better Organization**: Agents in appropriate locations
7. **Scalability**: Easy to add new projects with agent support

---

## Support and Resources

**Documentation:**
- `~/.claude/agents/agent-manager.md` - Agent definition
- `~/.claude/AGENT_DISCOVERY_ALGORITHM.md` - Technical specification
- `~/.claude/AGENT_MANAGER_IMPLEMENTATION_GUIDE.md` - Implementation guide
- `.claude/AGENT_SELECTION_GUIDE.md` - Routing decision trees

**Community:**
- Claude Code documentation
- Agent development guides
- Community forums

**Troubleshooting:**
- See "Troubleshooting" section above
- Check agent frontmatter for errors
- Verify file permissions
- Review discovery logs

---

## Summary

**Migration Essence:**

1. **Backup** current setup
2. **Create** `~/.claude/agents/` directory
3. **Copy** agent-manager to global location
4. **Remove** agent-manager from project directories
5. **Classify** agents (global vs project-local)
6. **Update** documentation references
7. **Test** discovery and routing
8. **Validate** everything works

**Result:** A global agent-manager that discovers agents from both system-wide and project-local locations, providing intelligent routing everywhere.

**Next Steps:**
1. Complete migration using this guide
2. Test thoroughly in all projects
3. Update agent development practices
4. Train team on new location strategy
5. Enjoy consistent, global agent routing!

---

**Migration completed successfully? Welcome to the dual-location agent system! 🎉**
