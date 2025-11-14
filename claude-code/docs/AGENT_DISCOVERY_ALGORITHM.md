# Agent Discovery Algorithm

This document provides the technical specification for the agent-manager's dual-location discovery mechanism.

## Overview

The agent-manager discovers agents from TWO locations and applies a prioritization strategy when conflicts occur:

1. **Global Location**: `~/.claude/agents/*.md` (system-wide, always present)
2. **Project-Local Location**: `.claude/agents/*.md` (project-specific, optional)

**Core Principle**: Project-local agents override global agents when the same name exists.

---

## Discovery Algorithm Specification

### Phase 1: Global Agent Discovery

```python
def discover_global_agents():
    """
    Discover all agents from the global location.
    This location MUST always be checked and should always exist.

    Returns:
        dict: Mapping of agent_name -> agent_metadata
    """
    global_agents = {}
    global_path = os.path.expanduser("~/.claude/agents/")

    # Use Glob tool: pattern "~/.claude/agents/*.md"
    agent_files = glob(f"{global_path}*.md")

    for agent_file in agent_files:
        # Skip deprecated agents
        if '.deprecated' in agent_file:
            continue

        # Read and parse YAML frontmatter
        metadata = parse_yaml_frontmatter(agent_file)
        agent_name = metadata.get('name')

        if not agent_name:
            log_warning(f"Agent file {agent_file} missing 'name' in frontmatter")
            continue

        global_agents[agent_name] = {
            'name': agent_name,
            'location': 'global',
            'path': agent_file,
            'description': metadata.get('description', ''),
            'tags': metadata.get('tags', []),
            'delegates_to': metadata.get('delegates_to', []),
            'version': metadata.get('version', '1.0.0'),
            'full_metadata': metadata
        }

    return global_agents
```

### Phase 2: Project-Local Agent Discovery

```python
def discover_project_local_agents(working_directory):
    """
    Discover all agents from the project-local location.
    This location may not exist - handle gracefully.

    Args:
        working_directory: The current project's root directory

    Returns:
        dict: Mapping of agent_name -> agent_metadata
        None: If .claude/agents/ doesn't exist
    """
    project_agents = {}
    project_path = os.path.join(working_directory, ".claude/agents/")

    # Check if directory exists
    if not os.path.exists(project_path):
        return None  # Graceful handling - not all projects have local agents

    # Use Glob tool: pattern ".claude/agents/*.md"
    agent_files = glob(f"{project_path}*.md")

    if not agent_files:
        return None  # Directory exists but no agents

    for agent_file in agent_files:
        # Skip deprecated agents
        if '.deprecated' in agent_file:
            continue

        # Read and parse YAML frontmatter
        metadata = parse_yaml_frontmatter(agent_file)
        agent_name = metadata.get('name')

        if not agent_name:
            log_warning(f"Agent file {agent_file} missing 'name' in frontmatter")
            continue

        project_agents[agent_name] = {
            'name': agent_name,
            'location': 'project-local',
            'path': agent_file,
            'description': metadata.get('description', ''),
            'tags': metadata.get('tags', []),
            'delegates_to': metadata.get('delegates_to', []),
            'version': metadata.get('version', '1.0.0'),
            'full_metadata': metadata
        }

    return project_agents
```

### Phase 3: Merge and Prioritize

```python
def merge_and_prioritize_agents(global_agents, project_agents):
    """
    Merge agents from both locations, applying prioritization rules.

    Rule: Project-local ALWAYS overrides global for same agent name.

    Args:
        global_agents: dict of global agents
        project_agents: dict of project-local agents (or None)

    Returns:
        dict: Combined agent pool with metadata about overrides
    """
    merged = {}

    # Step 1: Add all global agents
    for agent_name, agent_data in global_agents.items():
        merged[agent_name] = {
            **agent_data,
            'source': 'global-only',
            'overridden': False
        }

    # Step 2: Add project-local agents (overriding global if collision)
    if project_agents:
        for agent_name, agent_data in project_agents.items():
            if agent_name in merged:
                # COLLISION: Project-local overrides global
                global_path = merged[agent_name]['path']
                merged[agent_name] = {
                    **agent_data,
                    'source': 'project-local-override',
                    'overridden': True,
                    'overridden_global_path': global_path
                }
            else:
                # No collision: Project-local only
                merged[agent_name] = {
                    **agent_data,
                    'source': 'project-local-only',
                    'overridden': False
                }

    return merged
```

### Phase 4: Build Routing Table

```python
def build_routing_table(merged_agents):
    """
    Build a routing table from discovered agents for quick lookups.

    Args:
        merged_agents: Combined agent pool from merge_and_prioritize_agents

    Returns:
        dict: Routing table with multiple indexes
    """
    routing_table = {
        'by_name': {},           # agent_name -> agent_data
        'by_tags': {},           # tag -> [agent_names]
        'by_location': {         # location -> [agent_names]
            'global-only': [],
            'project-local-only': [],
            'project-local-override': []
        },
        'overrides': [],         # List of agents with overrides
        'total_count': 0,
        'global_count': 0,
        'project_local_count': 0
    }

    for agent_name, agent_data in merged_agents.items():
        # Index by name
        routing_table['by_name'][agent_name] = agent_data

        # Index by tags
        for tag in agent_data.get('tags', []):
            if tag not in routing_table['by_tags']:
                routing_table['by_tags'][tag] = []
            routing_table['by_tags'][tag].append(agent_name)

        # Index by location source
        source = agent_data['source']
        routing_table['by_location'][source].append(agent_name)

        # Track overrides
        if agent_data.get('overridden'):
            routing_table['overrides'].append({
                'name': agent_name,
                'project_path': agent_data['path'],
                'global_path': agent_data['overridden_global_path']
            })

        # Update counts
        routing_table['total_count'] += 1
        if 'global' in source:
            routing_table['global_count'] += 1
        if 'project-local' in source:
            routing_table['project_local_count'] += 1

    return routing_table
```

### Complete Discovery Flow

```python
def discover_all_agents(working_directory):
    """
    Main discovery function that orchestrates all phases.

    Args:
        working_directory: Current project root directory

    Returns:
        dict: Complete routing table ready for agent selection
    """
    # Phase 1: Discover global agents (always present)
    global_agents = discover_global_agents()

    # Phase 2: Discover project-local agents (optional)
    project_agents = discover_project_local_agents(working_directory)

    # Phase 3: Merge with prioritization
    merged_agents = merge_and_prioritize_agents(global_agents, project_agents)

    # Phase 4: Build routing table
    routing_table = build_routing_table(merged_agents)

    return routing_table
```

---

## Prioritization Strategy

### Rule: Project-Local ALWAYS Overrides Global

When the same agent name exists in both locations:

**Scenario**: `software-architect` exists in both `~/.claude/agents/` and `.claude/agents/`

**Resolution**:
```python
# The project-local version is used
selected_agent = routing_table['by_name']['software-architect']
assert selected_agent['location'] == 'project-local'
assert selected_agent['source'] == 'project-local-override'
assert selected_agent['overridden'] == True
```

**Rationale**:
1. **Specificity wins**: Project-local agents are customized for specific projects
2. **Intentional customization**: Users explicitly created project-local version
3. **Context awareness**: Project-local agents have deeper project knowledge
4. **Principle of least surprise**: Users expect local overrides to take precedence

**Communication to User**:
```markdown
**Selected Agent:** software-architect (project-local)

**Note:** Using the project-specific version of software-architect.
A global version also exists at ~/.claude/agents/software-architect.md,
but the project-local version at .claude/agents/software-architect.md
takes priority due to its project-specific customizations.
```

---

## Edge Case Handling

### Case 1: Project Has No `.claude/` Directory

**Detection**:
```python
if not os.path.exists(".claude/"):
    # No project-local agents
    pass
```

**Behavior**:
- Use only global agents
- No error or warning (this is normal)
- Discovery succeeds with global-only agents

**User Communication** (only if relevant to context):
```
Using system-wide agents from ~/.claude/agents/ (no project-specific agents found).
```

### Case 2: `.claude/` Exists but No `agents/` Subdirectory

**Detection**:
```python
if os.path.exists(".claude/") and not os.path.exists(".claude/agents/"):
    # .claude/ exists but no agents subdirectory
    pass
```

**Behavior**:
- Use only global agents
- No error or warning
- Discovery succeeds with global-only agents

**User Communication**:
- Don't mention unless user asks
- Normal operation

### Case 3: Both Locations Have Agents, No Collisions

**Example**:
```
Global: software-architect, data-pipeline-architect, security-auditor
Project: project-engineer, custom-linter
```

**Behavior**:
- All agents available
- Combined pool: 5 agents total
- No overrides

**User Communication**:
```
Discovered 5 agents:
- 3 global agents
- 2 project-local agents
- No conflicts
```

### Case 4: Agent Exists Only in Project-Local

**Example**:
```
Global: [standard agents]
Project: project-engineer (Arandu-specific, no global equivalent)
```

**Behavior**:
- Agent available from project-local only
- Routing works normally

**User Communication**:
```
**Selected Agent:** project-engineer (project-local)

This is a project-specific agent with deep knowledge of the Arandu API codebase.
```

### Case 5: No Agents Found Anywhere

**Detection**:
```python
if not global_agents and not project_agents:
    # ERROR: No agents discovered
    raise NoAgentsFoundError()
```

**Behavior**:
- Fail discovery gracefully
- Inform user of the issue
- Provide remediation steps

**User Communication**:
```
**Discovery Error:** No agents found in either location:

Checked:
- Global: ~/.claude/agents/ → [not found or empty]
- Project: .claude/agents/ → [not found or empty]

Please ensure:
1. ~/.claude/agents/ directory exists with agent definitions
2. Agent files are *.md format with YAML frontmatter
3. At least one valid agent file exists

Would you like help setting up the agent system?
```

### Case 6: Global Location Missing (Critical)

**Detection**:
```python
if not os.path.exists(os.path.expanduser("~/.claude/agents/")):
    # CRITICAL: Global agents directory missing
    raise GlobalAgentsDirectoryMissing()
```

**Behavior**:
- Fail discovery
- Inform user this is a critical issue
- Global agents are the fallback - they must exist

**User Communication**:
```
**Critical Error:** Global agents directory not found at ~/.claude/agents/

This directory is required as the fallback location for system-wide agents.

To fix:
1. Create directory: mkdir -p ~/.claude/agents/
2. Add agent definitions (*.md files with YAML frontmatter)
3. At minimum, add agent-manager.md to this location

The agent-manager itself should be at ~/.claude/agents/agent-manager.md
for global availability across all projects.
```

---

## Implementation Checklist

When implementing the discovery algorithm, ensure:

- [ ] **Glob global agents** using pattern: `~/.claude/agents/*.md`
- [ ] **Glob project-local agents** using pattern: `.claude/agents/*.md`
- [ ] **Handle missing directories gracefully** (don't fail if .claude/ doesn't exist)
- [ ] **Skip `.deprecated` files** in both locations
- [ ] **Parse YAML frontmatter** from each agent file
- [ ] **Validate `name` field exists** in frontmatter
- [ ] **Apply prioritization rule**: Project-local overrides global
- [ ] **Build routing table** with indexes (by_name, by_tags, by_location)
- [ ] **Track overrides** for transparent communication
- [ ] **Count agents** by location for reporting
- [ ] **Communicate location transparently** when routing to agents
- [ ] **Handle all edge cases** documented above

---

## Testing Discovery Algorithm

### Test Case 1: Global Only

**Setup**:
```
~/.claude/agents/
├── software-architect.md
├── data-pipeline-architect.md
└── security-auditor.md

.claude/ (does not exist)
```

**Expected Result**:
```python
routing_table = {
    'total_count': 3,
    'global_count': 3,
    'project_local_count': 0,
    'overrides': []
}
```

### Test Case 2: Global + Project-Local (No Collisions)

**Setup**:
```
~/.claude/agents/
├── software-architect.md
├── data-pipeline-architect.md
└── security-auditor.md

.claude/agents/
├── project-engineer.md
└── custom-tool.md
```

**Expected Result**:
```python
routing_table = {
    'total_count': 5,
    'global_count': 3,
    'project_local_count': 2,
    'overrides': []
}
```

### Test Case 3: Collision (Project-Local Overrides)

**Setup**:
```
~/.claude/agents/
├── software-architect.md (generic)
├── data-pipeline-architect.md
└── security-auditor.md

.claude/agents/
├── software-architect.md (Arandu-specific)
└── project-engineer.md
```

**Expected Result**:
```python
routing_table = {
    'total_count': 4,
    'global_count': 2,  # security-auditor, data-pipeline (architect overridden)
    'project_local_count': 2,
    'overrides': [
        {
            'name': 'software-architect',
            'project_path': '.claude/agents/software-architect.md',
            'global_path': '~/.claude/agents/software-architect.md'
        }
    ]
}

# Verify software-architect uses project-local version
assert routing_table['by_name']['software-architect']['location'] == 'project-local'
assert routing_table['by_name']['software-architect']['source'] == 'project-local-override'
```

### Test Case 4: Empty Project Directory

**Setup**:
```
~/.claude/agents/
├── software-architect.md
└── data-pipeline-architect.md

.claude/agents/ (empty directory)
```

**Expected Result**:
```python
routing_table = {
    'total_count': 2,
    'global_count': 2,
    'project_local_count': 0,
    'overrides': []
}
```

### Test Case 5: Deprecated Agents (Should Skip)

**Setup**:
```
~/.claude/agents/
├── software-architect.md
├── old-tool.md.deprecated (should skip)
└── data-pipeline-architect.md

.claude/agents/
├── project-engineer.md
└── legacy-agent.md.deprecated (should skip)
```

**Expected Result**:
```python
routing_table = {
    'total_count': 3,  # Only non-deprecated
    'global_count': 2,
    'project_local_count': 1,
    'overrides': []
}

# Verify deprecated agents not in routing table
assert 'old-tool' not in routing_table['by_name']
assert 'legacy-agent' not in routing_table['by_name']
```

---

## Performance Considerations

### Caching Strategy

Discovery can be expensive (file I/O, parsing). Consider caching:

```python
class AgentDiscoveryCache:
    def __init__(self, ttl_seconds=300):  # 5 minute TTL
        self._cache = {}
        self._ttl = ttl_seconds

    def get_or_discover(self, working_directory):
        cache_key = working_directory

        if cache_key in self._cache:
            cached_result, timestamp = self._cache[cache_key]
            if time.time() - timestamp < self._ttl:
                return cached_result

        # Cache miss or expired - perform discovery
        result = discover_all_agents(working_directory)
        self._cache[cache_key] = (result, time.time())
        return result
```

**Trade-offs**:
- **Pro**: Faster subsequent routing decisions
- **Con**: Stale data if agents added/modified during cache TTL
- **Recommendation**: Use for batch operations, skip for one-off routing

### Lazy Loading Agent Content

Don't read full agent content until needed:

```python
def lazy_load_agent_content(agent_path):
    """
    Only load full agent content when routing to that agent.
    During discovery, only parse frontmatter.
    """
    with open(agent_path, 'r') as f:
        # Read until end of frontmatter
        in_frontmatter = False
        frontmatter_lines = []

        for line in f:
            if line.strip() == '---':
                if in_frontmatter:
                    # End of frontmatter
                    break
                else:
                    in_frontmatter = True
                    continue

            if in_frontmatter:
                frontmatter_lines.append(line)

        return yaml.safe_load(''.join(frontmatter_lines))
```

**Performance Gain**:
- Discovery: Parse only frontmatter (~50 lines) × N agents
- Routing: Load full content (~500-1000 lines) × 1 agent
- **Result**: ~10-20x faster discovery

---

## Security Considerations

### Path Traversal Prevention

Prevent malicious agent paths:

```python
def validate_agent_path(path, base_directory):
    """
    Ensure agent path is within allowed directory.
    Prevent path traversal attacks.
    """
    real_path = os.path.realpath(path)
    real_base = os.path.realpath(base_directory)

    if not real_path.startswith(real_base):
        raise SecurityError(f"Agent path {path} outside allowed directory {base_directory}")

    return real_path
```

### Agent Name Validation

Prevent malicious agent names:

```python
def validate_agent_name(name):
    """
    Ensure agent name is safe (no path traversal, injection).
    """
    if not re.match(r'^[a-zA-Z0-9_-]+$', name):
        raise ValidationError(f"Invalid agent name: {name}")

    if len(name) > 64:
        raise ValidationError(f"Agent name too long: {name}")

    return name
```

---

## Debugging Discovery

### Discovery Trace Log

Enable detailed logging for troubleshooting:

```python
def discover_with_trace(working_directory):
    """
    Perform discovery with detailed trace logging.
    """
    trace = []

    # Global discovery
    trace.append("Starting global agent discovery...")
    global_agents = discover_global_agents()
    trace.append(f"Found {len(global_agents)} global agents")

    # Project-local discovery
    trace.append("Starting project-local agent discovery...")
    project_agents = discover_project_local_agents(working_directory)
    if project_agents:
        trace.append(f"Found {len(project_agents)} project-local agents")
    else:
        trace.append("No project-local agents found (or directory doesn't exist)")

    # Merge
    trace.append("Merging and prioritizing agents...")
    merged = merge_and_prioritize_agents(global_agents, project_agents)
    trace.append(f"Total agents after merge: {len(merged)}")

    # Detect overrides
    overrides = [name for name, data in merged.items() if data.get('overridden')]
    if overrides:
        trace.append(f"Overrides detected: {', '.join(overrides)}")
    else:
        trace.append("No overrides detected")

    # Build routing table
    trace.append("Building routing table...")
    routing_table = build_routing_table(merged)
    trace.append("Discovery complete")

    return routing_table, trace
```

### Discovery Report

Generate user-friendly discovery report:

```python
def generate_discovery_report(routing_table):
    """
    Generate markdown report of discovery results.
    """
    report = f"""
## Agent Discovery Report

**Total Agents Discovered:** {routing_table['total_count']}

### Global Agents (~/.claude/agents/)
{len(routing_table['by_location']['global-only'])} agents

{', '.join(routing_table['by_location']['global-only'])}

### Project-Local Agents (.claude/agents/)
{len(routing_table['by_location']['project-local-only'])} agents

{', '.join(routing_table['by_location']['project-local-only']) or 'None'}

### Overrides (Project-Local Overriding Global)
{len(routing_table['overrides'])} overrides

"""

    for override in routing_table['overrides']:
        report += f"- **{override['name']}**\n"
        report += f"  - Project: `{override['project_path']}`\n"
        report += f"  - Global: `{override['global_path']}`\n"

    if not routing_table['overrides']:
        report += "None\n"

    return report
```

---

## Migration from Old System

### Old System (Project-Local Only)

```
.claude/agents/
├── agent-manager.md (only available in this project)
├── project-engineer.md
└── [other agents]
```

**Problem**: `agent-manager` not available in other projects

### New System (Global + Project-Local)

```
~/.claude/agents/
├── agent-manager.md (available everywhere)
├── software-architect.md
├── data-pipeline-architect.md
└── [other global agents]

.claude/agents/
├── project-engineer.md (project-specific)
└── [other project agents]
```

**Solution**: Move agent-manager to global, keep project agents local

### Migration Steps

See `MIGRATION_GUIDE.md` for detailed instructions.

---

## Future Enhancements

### Potential Improvements

1. **Agent Versioning**: Handle version conflicts between global and project-local
2. **Remote Discovery**: Discover agents from remote repositories
3. **Agent Dependencies**: Declare and resolve agent dependencies
4. **Discovery Plugins**: Custom discovery sources beyond file system
5. **Agent Registry**: Central registry for agent metadata and search

---

## Summary

The dual-location discovery algorithm ensures:

✅ **Global agents** available in all projects (fallback)
✅ **Project-local agents** for project-specific needs (override)
✅ **Graceful handling** of missing directories
✅ **Transparent communication** of agent locations
✅ **Prioritization strategy** (project-local > global)
✅ **Edge case handling** (deprecated, collisions, empty dirs)
✅ **Performance optimization** (lazy loading, caching)
✅ **Security validation** (path traversal, name validation)

**Result**: A robust, flexible, and transparent agent discovery system that works across all projects while supporting project-specific customization.
