# Agent Manager Implementation Guide v2.0

This guide provides comprehensive instructions for implementing and using the **dual-location agent-manager system** in Claude Code.

## Table of Contents
1. [System Architecture](#system-architecture)
2. [Installation & Migration](#installation--migration)
3. [Discovery Mechanism](#discovery-mechanism)
4. [How It Works](#how-it-works)
5. [Usage Examples](#usage-examples)
6. [Advanced Patterns](#advanced-patterns)
7. [Troubleshooting](#troubleshooting)
8. [Integration with Existing Agents](#integration-with-existing-agents)

---

## System Architecture

### Overview - Dual-Location System

The agent-manager operates as a **global meta-layer** that discovers agents from TWO locations:

```
┌─────────────────────────────────────────────────────────────┐
│                         User Request                         │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
                ┌──────────────────────┐
                │   agent-manager      │ ◄── Global Meta-Router
                │  (Intelligent Router)│     (~/.claude/agents/)
                │                      │
                │  Discovers from:     │
                │  • Global agents     │
                │  • Project agents    │
                └──────────┬───────────┘
                           │
        ┌──────────────────┴──────────────────┐
        │                                     │
        ▼                                     ▼
┌─────────────────┐                  ┌──────────────────┐
│ GLOBAL AGENTS   │                  │ PROJECT AGENTS   │
│ ~/.claude/      │                  │ .claude/agents/  │
│  agents/        │                  │                  │
│                 │                  │ (Project-local)  │
│ (System-wide)   │                  │ (Optional)       │
│                 │                  │                  │
│ • architect     │                  │ • project-eng    │
│ • data-arch     │                  │ • custom-tool    │
│ • security      │                  │ [overrides]      │
│ • [etc...]      │                  │                  │
└─────────────────┘                  └──────────────────┘
```

### Key Components

1. **agent-manager.md**: Global agent definition at `~/.claude/agents/agent-manager.md`
2. **AGENT_DISCOVERY_ALGORITHM.md**: Technical specification for discovery (new)
3. **AGENT_SELECTION_GUIDE.md**: Reference for routing decisions
4. **Agent Frontmatter**: YAML metadata that agent-manager reads dynamically
5. **Dual-Location Discovery**: Glob from both `~/.claude/agents/` AND `.claude/agents/`

### Dual-Location Discovery Mechanism

The agent-manager discovers agents at runtime by:

1. **Globbing global agents**: `~/.claude/agents/*.md` (always present, system-wide)
2. **Globbing project-local agents**: `.claude/agents/*.md` (optional, project-specific)
3. **Parsing YAML frontmatter**: Extract name, description, tags, delegates_to
4. **Applying prioritization**: Project-local OVERRIDES global when same name exists
5. **Building routing table**: In-memory mapping of capabilities to agents

This means **no code changes required when adding new agents** - the agent-manager automatically discovers them from BOTH locations.

### Prioritization Strategy

**Rule**: When the same agent name exists in BOTH locations, **project-local ALWAYS takes priority**.

**Example Collision**:
```
Global: ~/.claude/agents/software-architect.md (generic)
Project: .claude/agents/software-architect.md (Arandu-specific)

Result: Use .claude/agents/software-architect.md
Reason: Project-local version has specific project knowledge
```

**Communication to User**:
```markdown
**Selected Agent:** software-architect (project-local)

Note: Using the project-specific version which has deep Arandu knowledge.
A global version also exists but is less specialized for this project.
```

---

## Installation & Migration

### New Installation (Fresh Setup)

#### Step 1: Create Global Agents Directory

```bash
# Create global directory
mkdir -p ~/.claude/agents/

# Verify
ls -la ~/.claude/agents/
```

#### Step 2: Install agent-manager Globally

```bash
# Copy agent-manager to global location
cp /home/gustavo/TJAM/arandu-api/.claude/agents/agent-manager.md ~/.claude/agents/

# Verify
ls -la ~/.claude/agents/agent-manager.md
```

#### Step 3: Move Global Agents to ~/.claude/agents/

```bash
# Move general-purpose agents to global location
mv ~/.claude/agents/*.md ~/.claude/agents/ 2>/dev/null || echo "Already in place"

# Recommended global agents to have:
# - software-architect.md
# - data-pipeline-architect.md
# - linux-sysadmin-expert.md
# - security-auditor.md
# - performance-monitor.md
# - documentation-expert.md
# - requirements-analyst.md
# - homelab-research-expert.md
# - pc-hardware-advisor-br.md
# - git-operations-expert.md
# - dev-env-manager.md
# - research-assistant.md
```

#### Step 4: Keep Project-Specific Agents Local

```bash
# In each project, keep only project-specific agents in .claude/agents/
# Example for Arandu API:
cd /home/gustavo/TJAM/arandu-api/

# Keep project-specific agents
ls .claude/agents/
# Expected: project-engineer.md (Arandu-specific)
```

#### Step 5: Update Agent Selection Guide

Add agent-manager to `AGENT_SELECTION_GUIDE.md`:

```markdown
| Task Category | Agent to Use | Location |
|---------------|-------------|----------|
| **Meta/Routing** | `agent-manager` | Global |
| Arandu API work | `project-engineer` | Project-local |
| New project | `software-architect` | Global |
...
```

### Migration from Project-Local Agent-Manager

If you already have agent-manager in a project's `.claude/agents/`, follow these steps:

#### Migration Step 1: Backup Current Setup

```bash
# Backup current project agents
cd /home/gustavo/TJAM/arandu-api/
tar -czf agent-backup-$(date +%Y%m%d).tar.gz .claude/agents/

# Verify backup
ls -lh agent-backup-*.tar.gz
```

#### Migration Step 2: Move agent-manager to Global

```bash
# Create global directory if it doesn't exist
mkdir -p ~/.claude/agents/

# Copy agent-manager to global location
cp .claude/agents/agent-manager.md ~/.claude/agents/

# Verify
ls -la ~/.claude/agents/agent-manager.md
```

#### Migration Step 3: Remove Project-Local agent-manager

```bash
# Remove from project (now that it's global)
rm .claude/agents/agent-manager.md

# Verify removal
ls -la .claude/agents/ | grep agent-manager || echo "Successfully removed"
```

#### Migration Step 4: Update Documentation References

Search and replace in project documentation:

```bash
# Find references to old location
cd /home/gustavo/TJAM/arandu-api/
grep -r "\.claude/agents/agent-manager" .claude/

# Update references to:
# OLD: .claude/agents/agent-manager.md
# NEW: ~/.claude/agents/agent-manager.md
```

#### Migration Step 5: Test Discovery

Verify agent-manager can discover from both locations:

```bash
# Test glob patterns
find ~/.claude/agents -name "*.md" ! -name "*.deprecated" | sort
find .claude/agents -name "*.md" ! -name "*.deprecated" | sort

# Expected: agent-manager in global, project-engineer in local
```

#### Migration Step 6: Update Other Projects

Repeat for each project:

```bash
# For each project with .claude/agents/agent-manager.md
for project in ~/projects/*; do
  if [ -f "$project/.claude/agents/agent-manager.md" ]; then
    echo "Removing agent-manager from $project"
    rm "$project/.claude/agents/agent-manager.md"
  fi
done
```

---

## Discovery Mechanism

### How Discovery Works

The agent-manager uses a **two-phase discovery process**:

#### Phase 1: Global Discovery

```python
# Pseudo-code representation
global_agents = {}

# Use Glob tool: pattern "~/.claude/agents/*.md"
for agent_file in glob("~/.claude/agents/*.md"):
    if '.deprecated' in agent_file:
        continue  # Skip deprecated

    metadata = parse_yaml_frontmatter(agent_file)
    agent_name = metadata['name']

    global_agents[agent_name] = {
        'location': 'global',
        'path': agent_file,
        'metadata': metadata
    }
```

#### Phase 2: Project-Local Discovery

```python
project_agents = {}

# Use Glob tool: pattern ".claude/agents/*.md"
# Handle gracefully if directory doesn't exist
if directory_exists(".claude/agents/"):
    for agent_file in glob(".claude/agents/*.md"):
        if '.deprecated' in agent_file:
            continue

        metadata = parse_yaml_frontmatter(agent_file)
        agent_name = metadata['name']

        project_agents[agent_name] = {
            'location': 'project-local',
            'path': agent_file,
            'metadata': metadata
        }
```

#### Phase 3: Merge and Prioritize

```python
merged_agents = {}

# Add all global agents
for name, data in global_agents.items():
    merged_agents[name] = data

# Add project-local agents (overriding global if collision)
for name, data in project_agents.items():
    if name in merged_agents:
        # COLLISION: Project-local overrides global
        print(f"Override: {name} (project-local > global)")
        merged_agents[name] = {
            **data,
            'overrides': merged_agents[name]['path']
        }
    else:
        merged_agents[name] = data

return merged_agents
```

### Discovery Output Example

```markdown
## Agent Discovery Report

**Total Agents:** 13

### Global Agents (~/.claude/agents/)
- agent-manager (meta-router)
- software-architect (greenfield coordinator)
- data-pipeline-architect (SQL & data)
- linux-sysadmin-expert (server admin)
- security-auditor (security reviews)
- performance-monitor (profiling)
- documentation-expert (docs)
- requirements-analyst (requirements)
- homelab-research-expert (homelab)
- pc-hardware-advisor-br (hardware)
- git-operations-expert (git)
- dev-env-manager (environments)
- research-assistant (research)

### Project-Local Agents (.claude/agents/)
- project-engineer (Arandu API specialist)

### Overrides
None (no name collisions)
```

---

## How It Works

### Invocation Methods

Users can invoke agent-manager in three ways:

#### Method 1: Explicit Invocation
```
User: "@agent-manager I need help optimizing a database query"
```

#### Method 2: Automatic Routing (Claude Code auto-detects)
```
User: "I'm not sure which agent to use for this task..."
```
Claude Code sees "not sure which agent" and invokes agent-manager.

#### Method 3: Complex Request Detection
```
User: "Build a new feature with security review and documentation"
```
Claude Code detects multi-domain request and invokes agent-manager for coordination.

### Agent-Manager Decision Process

```
┌─────────────────────────────────────────────────────────┐
│ 1. ANALYZE REQUEST                                       │
│    - Extract domain keywords                             │
│    - Identify goal and constraints                       │
│    - Assess complexity                                   │
│    - Determine if project-specific or general            │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ 2. DISCOVER AGENTS (Dual-Location)                      │
│    - Glob: ~/.claude/agents/*.md (global)               │
│    - Glob: .claude/agents/*.md (project-local)          │
│    - Parse YAML frontmatter from both                    │
│    - Apply prioritization (project > global)             │
│    - Consult AGENT_SELECTION_GUIDE.md                   │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ 3. SELECT ROUTING STRATEGY                               │
│    - Single agent (80% of cases)                         │
│    - Sequential chain (15% of cases)                     │
│    - Parallel consultation (5% of cases)                 │
│    - Prefer project-local for project work               │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ 4. CRAFT DELEGATION PROMPT                               │
│    - Restate goal                                        │
│    - Include complete context                            │
│    - Add constraints and preferences                     │
│    - Specify success criteria                            │
│    - Note agent location (global or project-local)       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ 5. EXECUTE & MONITOR                                     │
│    - Launch agent(s) via Task tool                       │
│    - Monitor progress                                    │
│    - Synthesize results (if multi-agent)                 │
│    - Return to user with location transparency           │
└─────────────────────────────────────────────────────────┘
```

---

## Usage Examples

### Example 1: Project-Specific Routing (Arandu API)

**User Request:**
```
I need to add a new endpoint to Arandu API that returns user statistics.
```

**Agent-Manager Process:**

1. **Analysis**:
   - Domain: Arandu API (project-specific)
   - Complexity: Moderate (single agent)
   - Context: Sufficient

2. **Discovery**:
   - Global: 12 agents discovered
   - Project-local: 1 agent (project-engineer)
   - No collisions

3. **Selection**:
   - **Chosen**: project-engineer (project-local)
   - **Reason**: Arandu-specific, deep codebase knowledge
   - **Location**: .claude/agents/project-engineer.md

4. **Delegation**:
```markdown
→ Launch project-engineer agent (project-local)

"The user wants to add a user statistics endpoint to Arandu API.

Context:
- Arandu API uses FastAPI with /api/v1/ prefix
- Authentication via JWT (@auth_required)
- Database: PostgreSQL (cnjbrasil.*, ia.*)
- Router structure: arandu_api/routers/

Using project-local project-engineer because it has deep knowledge
of the Arandu API codebase, patterns, and architecture.

Please provide Arandu-specific implementation guidance."
```

---

### Example 2: Global Agent Routing (New Project)

**User Request:**
```
Help me design a new microservices architecture for a SaaS application.
```

**Agent-Manager Process:**

1. **Analysis**:
   - Domain: New project (not Arandu-specific)
   - Complexity: High (architectural design)
   - Context: Sufficient

2. **Discovery**:
   - Global: 12 agents discovered
   - Project-local: 1 agent (project-engineer - not relevant)
   - No relevant project-local agent

3. **Selection**:
   - **Chosen**: software-architect (global)
   - **Reason**: Greenfield project coordinator, not project-specific
   - **Location**: ~/.claude/agents/software-architect.md

4. **Delegation**:
```markdown
→ Launch software-architect agent (global)

"The user wants to design a new microservices architecture for a SaaS application.

Context:
- New project (not existing codebase)
- Needs architectural guidance
- Microservices pattern
- SaaS delivery model

Using global software-architect because this is greenfield work
that doesn't require project-specific knowledge.

Please provide architectural guidance and coordinate with specialists as needed."
```

---

### Example 3: Override Scenario (Project-Local Overrides Global)

**Setup:**
```
Global: ~/.claude/agents/security-auditor.md (generic security)
Project: .claude/agents/security-auditor.md (Arandu-specific, LGPD compliance)
```

**User Request:**
```
Review this Arandu API endpoint for security vulnerabilities.
```

**Agent-Manager Process:**

1. **Discovery**:
   - Global: security-auditor found
   - Project-local: security-auditor found
   - **COLLISION DETECTED**

2. **Prioritization**:
   - Applying rule: Project-local > Global
   - **Selected**: .claude/agents/security-auditor.md

3. **Communication**:
```markdown
→ Launch security-auditor agent (project-local)

**Note:** Using the project-specific version of security-auditor,
which has specialized knowledge of Arandu API's security patterns,
LGPD compliance requirements, and legal data sensitivity.

A global security-auditor also exists at ~/.claude/agents/security-auditor.md,
but the project-local version at .claude/agents/security-auditor.md takes
priority due to its Arandu-specific security expertise.
```

---

### Example 4: Multi-Location Coordination

**User Request:**
```
Build a new feature for Arandu API, review security, and document it.
```

**Agent-Manager Process:**

1. **Coordination Plan**:
```markdown
## Multi-Agent Coordination Plan

**Workflow Type:** Sequential (3 agents)

**Agents Involved:**
1. project-engineer (project-local: .claude/agents/)
   - Reason: Arandu-specific implementation
   - Task: Design and implement the feature

2. security-auditor (global: ~/.claude/agents/)
   - Reason: General security review (no project-specific auditor)
   - Task: Review for vulnerabilities

3. documentation-expert (global: ~/.claude/agents/)
   - Reason: Documentation writing (general skill)
   - Task: Create API documentation

**Location Strategy:**
- Using project-local for implementation (project knowledge)
- Using global for review/docs (general skills)
```

2. **Execution**:
```
Step 1: project-engineer (project-local) → Feature design + implementation ✓
Step 2: security-auditor (global) → Security review ✓
Step 3: documentation-expert (global) → API docs ✓
Step 4: Synthesis → Unified recommendations
```

---

### Example 5: No Project-Local Agents

**Project Structure:**
```
new-project/
├── src/
└── (no .claude/ directory)
```

**User Request:**
```
Help me optimize this PostgreSQL query.
```

**Agent-Manager Process:**

1. **Discovery**:
   - Global: 12 agents discovered
   - Project-local: Directory not found
   - **Result**: Use global-only

2. **Selection**:
   - **Chosen**: data-pipeline-architect (global)
   - **Location**: ~/.claude/agents/data-pipeline-architect.md

3. **Communication**:
```markdown
→ Launch data-pipeline-architect agent (global)

Using system-wide agents (no project-specific agents found).
This is normal for projects without a .claude/ directory.

The data-pipeline-architect will provide SQL optimization guidance.
```

---

## Advanced Patterns

### Pattern 1: Iterative Multi-Location Routing

```
User: "Design caching for Arandu API"
  ↓
agent-manager discovers agents:
  - Global: performance-monitor, data-pipeline-architect, security-auditor
  - Project-local: project-engineer
  ↓
Step 1: project-engineer (project-local) → Arandu-specific cache design
  ↓
User: "What about security?"
  ↓
Step 2: security-auditor (global) → Security review
  ↓
User: "Will this scale?"
  ↓
Step 3: performance-monitor (global) → Scalability analysis
  ↓
Final: agent-manager synthesis → Unified caching strategy
```

### Pattern 2: Hybrid Coordination (Mix Global + Project-Local)

```
Task: "Add real-time notifications to Arandu API with security review"

Coordination:
  ├─ requirements-analyst (global) → Clarify requirements
  ├─ project-engineer (project-local) → Arandu implementation
  ├─ security-auditor (global) → Security review
  └─ documentation-expert (global) → API docs

Result: Mix of global (general skills) and project-local (Arandu expertise)
```

### Pattern 3: Override Strategy for Specialized Agents

**When to Create Project-Local Override:**

1. **Specialized Domain Knowledge**: Project has unique patterns
2. **Custom Workflows**: Project-specific processes
3. **Compliance Requirements**: Project-specific regulations (LGPD, HIPAA)
4. **Technology Stack**: Project uses specific tech not in global agents

**Example - Creating Arandu-Specific Security Auditor:**

```yaml
---
name: security-auditor
description: Security auditor specialized for Arandu API with LGPD compliance expertise
version: 1.0.0-arandu
tags: [security, lgpd, legal-data, arandu]
overrides: ~/.claude/agents/security-auditor.md
---

You are a security auditor specialized in the Arandu API project...

**Arandu-Specific Security Concerns:**
- Legal data sensitivity (processo data, partes, documentos)
- LGPD compliance (Brazilian data protection law)
- JWT authentication via Keycloak
- MongoDB conversas collection (AI conversation history)
- PostgreSQL schemas (cnjbrasil.*, ia.*)

[... Arandu-specific security guidance ...]
```

---

## Troubleshooting

### Issue 1: Agent-Manager Not Found

**Symptom:** "Agent agent-manager not found"

**Cause:** agent-manager not in global location

**Solution:**
```bash
# Check if agent-manager is global
ls -la ~/.claude/agents/agent-manager.md

# If not found, install it
mkdir -p ~/.claude/agents/
cp /path/to/agent-manager.md ~/.claude/agents/

# Verify
ls -la ~/.claude/agents/agent-manager.md
```

### Issue 2: Project-Local Agents Not Discovered

**Symptom:** "Only global agents found, expected project-local agents"

**Cause:** Incorrect directory structure or glob pattern

**Solution:**
```bash
# Verify directory exists
ls -la .claude/agents/

# Check agent files
find .claude/agents/ -name "*.md" ! -name "*.deprecated"

# Ensure YAML frontmatter has 'name' field
head -n 10 .claude/agents/project-engineer.md
```

### Issue 3: Wrong Agent Version Used (Override Not Working)

**Symptom:** Global agent used when project-local should override

**Cause:** Name mismatch or discovery failure

**Solution:**
```bash
# Check agent names match exactly
# Global agent:
grep "^name:" ~/.claude/agents/software-architect.md

# Project-local agent:
grep "^name:" .claude/agents/software-architect.md

# Names must match EXACTLY for override to work
# If different, rename to match
```

### Issue 4: Discovery Performance Slow

**Symptom:** Agent-manager takes long time to discover agents

**Cause:** Too many agents or large files

**Solution:**
```markdown
**Optimization Strategies:**

1. **Lazy Loading**: Only load frontmatter during discovery
2. **Caching**: Cache discovery results (5-minute TTL)
3. **Exclude Deprecated**: Use `.deprecated` suffix to skip old agents
4. **Reduce Agent Count**: Archive unused agents

**Implementation:**
- Move deprecated agents to `~/.claude/agents/archive/`
- Use frontmatter-only parsing during discovery
- Full content loaded only when routing to that agent
```

### Issue 5: Glob Pattern Not Working

**Symptom:** No agents found despite files existing

**Cause:** Incorrect glob pattern or tool usage

**Solution:**
```python
# Correct glob patterns:
# Global: Use absolute path or tilde expansion
glob("~/.claude/agents/*.md")  # ✅ Correct
glob(os.path.expanduser("~/.claude/agents/*.md"))  # ✅ Also correct

# Project-local: Use relative path
glob(".claude/agents/*.md")  # ✅ Correct

# Incorrect patterns:
glob("~/.claude/agents/.md")  # ❌ Missing *
glob("./.claude/agents/*.md")  # ⚠️ Works but redundant
glob("$HOME/.claude/agents/*.md")  # ❌ Shell variable not expanded
```

---

## Integration with Existing Agents

### Updating Existing Global Agents

Existing agents should be aware they're in the global pool:

**Add to frontmatter:**
```yaml
---
name: software-architect
description: Greenfield project coordinator
version: 1.0.0
tags: [architecture, coordinator, greenfield]
storage: global
---
```

**No other changes required** - agent-manager uses dynamic discovery.

### Updating Existing Project-Local Agents

Project-specific agents should note they're local:

**Add to frontmatter:**
```yaml
---
name: project-engineer
description: Arandu API specialist with deep codebase knowledge
version: 1.0.0
tags: [arandu, fastapi, legal-tech, project-specific]
storage: project-local
overrides: none  # Or specify if overriding a global agent
---
```

### Creating New Project-Local Agent

**When to Create:**
- Project has unique patterns not covered by global agents
- Need to override global agent with project-specific version
- Experimental agent not ready for global use

**Template:**
```yaml
---
name: custom-agent-name
description: Project-specific agent for [purpose]
version: 1.0.0
tags: [project-specific, custom]
storage: project-local
overrides: none  # Or: ~/.claude/agents/agent-name.md
delegates_to: [list-of-agents]
---

You are [agent description] specialized for the [Project Name] project...

**Project-Specific Context:**
- [Project detail 1]
- [Project detail 2]
- [Project detail 3]

[... agent instructions ...]
```

### Bidirectional Delegation

Agents can delegate TO agent-manager when they need routing help:

**Example in project-engineer:**
```markdown
## Limitations & Escalation

**When to escalate:**
- Task outside Arandu API scope → Delegate to agent-manager for routing
- Need specialist not in project agents → agent-manager will find global agent
- Unclear which specialist to use → agent-manager decision
```

This creates a bidirectional flow:
```
User → agent-manager → specialist agent
                ↑              │
                └──────────────┘
            (agent delegates back if needed)
```

---

## Best Practices

### For Users

1. **Provide context upfront** - Mention project name, domain, goal
2. **Trust the routing** - agent-manager has full ecosystem knowledge
3. **Understand location strategy**:
   - Project-local: Project-specific work
   - Global: General-purpose tasks
4. **Ask for discovery report** - "@agent-manager show me available agents"
5. **Provide feedback** - "Actually, I wanted the global version, not project-local"

### For Agent Developers

1. **Decide location carefully**:
   - **Global**: General-purpose, reusable across projects
   - **Project-local**: Project-specific customizations

2. **Write clear descriptions** - agent-manager reads these for routing decisions

3. **Use semantic tags**:
   ```yaml
   tags: [architecture, fastapi, arandu, project-specific]
   ```

4. **Document limitations** - So agent-manager knows when NOT to route

5. **Specify overrides** (if applicable):
   ```yaml
   overrides: ~/.claude/agents/software-architect.md
   ```

6. **Keep frontmatter updated** - Version, tags, storage location

### For Project Maintainers

1. **Establish global agent baseline**:
   ```bash
   # Essential global agents:
   - agent-manager (meta-router)
   - software-architect (greenfield)
   - data-pipeline-architect (SQL/data)
   - security-auditor (security)
   - performance-monitor (profiling)
   - documentation-expert (docs)
   ```

2. **Create project-local only when needed**:
   - Deep project knowledge required
   - Project-specific patterns/conventions
   - Override global agent for specialization

3. **Document location strategy** in project README:
   ```markdown
   ## Agent Ecosystem

   **Global Agents** (~/.claude/agents/):
   - General-purpose agents shared across all projects

   **Project-Local Agents** (.claude/agents/):
   - project-engineer: Arandu API specialist
   - [list project-specific agents]
   ```

---

## Metrics & Monitoring

Track agent-manager effectiveness:

### Success Metrics

- **First-try routing accuracy**: Right agent on first attempt?
- **Location correctness**: Project-local used for project work, global for general?
- **Override effectiveness**: Are overrides working as expected?
- **Multi-agent coordination**: Complex workflows complete smoothly?
- **Discovery performance**: Discovery time < 2 seconds?

### Warning Signs

- Frequent re-routing (user not satisfied with initial agent)
- Global agent used when project-local should be preferred
- Discovery failures (agents not found)
- Override conflicts (wrong version used)
- Circular delegation loops

---

## Future Enhancements

Potential improvements to the dual-location system:

1. **Remote Discovery**: Discover agents from Git repositories
   ```yaml
   discovery_sources:
     - ~/.claude/agents/ (local global)
     - .claude/agents/ (local project)
     - https://github.com/org/agents-repo (remote)
   ```

2. **Agent Versioning**: Handle version conflicts intelligently
   ```yaml
   # Prefer newer version
   global: v2.0.0
   project-local: v1.5.0
   → Use global (newer) despite project-local priority
   ```

3. **Dependency Resolution**: Agent dependencies and compatibility
   ```yaml
   dependencies:
     requires: [software-architect >= 2.0]
     conflicts_with: [legacy-tool < 1.0]
   ```

4. **Discovery Caching**: Cache discovery results for performance
   ```python
   cache_discovery(ttl=300)  # 5-minute cache
   ```

5. **Agent Marketplace**: Shared agent repository
   ```bash
   claude agents search "security"
   claude agents install security-auditor --global
   ```

---

## Reference

**Key Files:**

- **Global agent definition**: `~/.claude/agents/agent-manager.md` (NEW LOCATION)
- **Discovery algorithm**: `~/.claude/AGENT_DISCOVERY_ALGORITHM.md` (NEW)
- **Selection guide**: `.claude/AGENT_SELECTION_GUIDE.md` (project)
- **Best practices**: `.claude/AGENT_BEST_PRACTICES.md` (project)
- **This guide**: `~/.claude/AGENT_MANAGER_IMPLEMENTATION_GUIDE.md` (NEW)

**Quick Reference Card:**

| Scenario | Location | Rationale |
|----------|----------|-----------|
| agent-manager | Global (~/.claude/agents/) | Available in ALL projects |
| General-purpose agents | Global | Reusable across projects |
| Project-specific agents | Project-local (.claude/agents/) | Deep project knowledge |
| Override global agent | Project-local with same name | Customization for project |
| Experimental agent | Project-local | Test before globalizing |

**Discovery Patterns:**

```python
# Global-only (no .claude/ in project)
discovered = discover_from("~/.claude/agents/")

# Global + Project-local (both exist)
discovered = merge(
    discover_from("~/.claude/agents/"),
    discover_from(".claude/agents/")
)

# With override (project-local priority)
if collision:
    use project_local_version
    mark as 'overrides': global_path
```

---

## Summary

**The v2.0 dual-location agent-manager system provides:**

✅ **Global Availability**: agent-manager works in all projects
✅ **Dual Discovery**: Finds agents from both global and project-local locations
✅ **Smart Prioritization**: Project-local overrides global when same name
✅ **Transparent Routing**: Users know which location and why
✅ **Flexible Architecture**: Global for general, local for specific
✅ **Future-Proof**: New agents discovered automatically
✅ **Performance**: Lazy loading and caching strategies
✅ **Maintainability**: Clear separation of global vs project agents

**Migration Summary:**

1. Move agent-manager to `~/.claude/agents/` (global)
2. Keep general agents in `~/.claude/agents/` (global)
3. Keep project-specific agents in `.claude/agents/` (project-local)
4. Update documentation to reference new locations
5. Test discovery from both locations

**The agent-manager is now a truly global, project-aware intelligent router that discovers and coordinates agents from both system-wide and project-local locations, ensuring optimal routing with transparent location handling.**
