# fed2-tools Documentation Index

Quick navigation for Claude Code AI assistant.

## 📖 Critical Reading Order

When starting work on this project, read documentation in this order:

1. **[CLAUDE.md](CLAUDE.md)** - START HERE
   - Mandatory workflows (Git pre-flight checklist)
   - Critical warnings (function recreation from git history)
   - Lua coding conventions (project-specific)
   - Component structure patterns
   - Build system overview
   - GMCP reference (game data API)

2. **[src/shared/CLAUDE.md](src/shared/CLAUDE.md)** - Shared utilities API
   - Help system (registry + direct display)
   - Settings management system (registration, get/set/clear)
   - Table renderer (`f2t_render_table()` API)
   - Persistent settings pattern
   - Debug utilities

3. **Component CLAUDE.md** - When working on specific component
   - Component-specific usage and commands
   - Implementation patterns
   - Key files and their purposes

## 🎯 Quick Reference by Task

### Working with Git
- **Creating feature branch:** [CLAUDE.md → Git Workflow → Pre-Flight Checklist](CLAUDE.md#git-workflow-gitflow)
- **Commit message format:** [CLAUDE.md → Commit Messages](CLAUDE.md#commit-messages)
- **Completing feature:** [CLAUDE.md → Completing a Feature](CLAUDE.md#completing-a-feature)

### Adding Features
- **New component:** [CLAUDE.md → Creating Components](CLAUDE.md#creating-components)
- **New alias:** [CLAUDE.md → Consolidated Alias Pattern](CLAUDE.md#consolidated-alias-pattern)
- **Help system:** [shared/CLAUDE.md → Help System](src/shared/CLAUDE.md#help-system-f2t_help_registrylua-f2t_helplua)
- **Settings:** [shared/CLAUDE.md → Settings Management](src/shared/CLAUDE.md#settings-management-system-f2t_settings_managerlua)

### Using Shared Utilities
- **Table rendering:** [shared/CLAUDE.md → Table Renderer](src/shared/CLAUDE.md#table-renderer-f2t_table_rendererlua)
- **Debug logging:** [shared/CLAUDE.md → Debug Utilities](src/shared/CLAUDE.md#debug-utilities-f2t_debuglua)
- **Persistent settings:** [shared/CLAUDE.md → Settings Persistence](src/shared/CLAUDE.md#settings-persistence-f2t_settingslua)
- **Table utilities:** [shared/CLAUDE.md → Table Utilities](src/shared/CLAUDE.md#table-utilities-f2t_table_utilslua)

### Mudlet Integration
- **Capturing game output:** [CLAUDE.md → Capturing Game Output](CLAUDE.md#capturing-game-output)
- **GMCP data access:** [CLAUDE.md → GMCP Reference](CLAUDE.md#gmcp-reference)
- **Message formatting:** [CLAUDE.md → Message Formatting Convention](CLAUDE.md#message-formatting-convention)
- **Metadata headers:** [CLAUDE.md → Metadata Headers](CLAUDE.md#metadata-headers)

### Common Patterns
- **Quick patterns reference:** [CLAUDE_PATTERNS.md](CLAUDE_PATTERNS.md)
- **Component initialization:** [CLAUDE.md → Component Initialization Pattern](CLAUDE.md#component-initialization-pattern)

## 📂 Component Documentation

| Component | Lines | Description | Link |
|-----------|-------|-------------|------|
| **bulk-commands** | 53 | Bulk buy/sell commodities | [CLAUDE.md](src/bulk-commands/CLAUDE.md) |
| **commodities** | 228 | Price checking and analysis | [CLAUDE.md](src/commodities/CLAUDE.md) |
| **factory** | 71 | Factory status display | [CLAUDE.md](src/factory/CLAUDE.md) |
| **map** | 269 | Auto-mapper with navigation | [CLAUDE.md](src/map/CLAUDE.md) |
| **refuel** | 42 | Automatic ship refueling | [CLAUDE.md](src/refuel/CLAUDE.md) |
| **shared** | 460 | Shared utilities and APIs | [CLAUDE.md](src/shared/CLAUDE.md) |

## 🔍 Finding Specific Information

### By Component Feature

**bulk-commands:**
- Bulk buy/sell implementation
- State machine pattern
- GMCP cargo/hold integration

**commodities:**
- Price data capture
- Cartel broker integration
- "Price all" sequential processing
- Settings registration example

**factory:**
- Multi-query pattern
- Timer-based capture
- Buffer accumulation
- I/E ratio calculation

**map:**
- GMCP room handler
- Hash-based room IDs
- Navigation resolution (8 formats)
- Speedwalk controls
- Saved destinations
- Blacklist system
- Galaxy cache
- Jump integration

**refuel:**
- Prompt trigger pattern
- GMCP room flags
- Emergency refueling
- Enable/disable state

**shared:**
- Help registry API
- Settings manager API
- Table renderer API
- Debug logging
- Persistent settings

### By Programming Concept

**Triggers:**
- Pattern types: [CLAUDE.md → Metadata Headers](CLAUDE.md#metadata-headers)
- Prompt triggers: [refuel/CLAUDE.md](src/refuel/CLAUDE.md)
- Output capture: [CLAUDE.md → Capturing Game Output](CLAUDE.md#capturing-game-output)

**Aliases:**
- Consolidated pattern: [CLAUDE.md → Consolidated Alias Pattern](CLAUDE.md#consolidated-alias-pattern)
- Regex patterns: [CLAUDE.md → Metadata Headers](CLAUDE.md#metadata-headers)
- Help integration: [shared/CLAUDE.md → Help System](src/shared/CLAUDE.md#help-system-f2t_help_registrylua-f2t_helplua)

**Settings:**
- Registration: [shared/CLAUDE.md → Settings Management](src/shared/CLAUDE.md#settings-management-system-f2t_settings_managerlua)
- Complex data structures: [shared/CLAUDE.md → Complex Data Structures](src/shared/CLAUDE.md#complex-data-structures)
- Persistence: [shared/CLAUDE.md → Settings Persistence](src/shared/CLAUDE.md#settings-persistence-f2t_settingslua)

**State Management:**
- Global state flags: [bulk-commands/CLAUDE.md](src/bulk-commands/CLAUDE.md)
- Capture state: [commodities/CLAUDE.md](src/commodities/CLAUDE.md)
- Sequential processing: [factory/CLAUDE.md](src/factory/CLAUDE.md)

## 📝 Documentation Maintenance

**When to update:**
- **Main CLAUDE.md:** New project-wide patterns, GMCP discoveries, build changes
- **shared/CLAUDE.md:** New shared utilities, API changes
- **Component CLAUDE.md:** Component-specific features, usage changes

**See:** [CLAUDE.md → Maintaining Documentation](CLAUDE.md#maintaining-documentation)

## 🚀 Quick Start for AI Assistants

**First time working on fed2-tools?**

1. Read [CLAUDE.md](CLAUDE.md) sections:
   - ⚠️ MANDATORY WORKFLOW (Git pre-flight)
   - ⚠️ CRITICAL: Before Deleting Functions
   - Lua Coding Conventions → Essential Project Patterns
   - Consolidated Alias Pattern
   - Help System (brief overview)

2. Bookmark [CLAUDE_PATTERNS.md](CLAUDE_PATTERNS.md) for quick reference

3. When working on specific component, read that component's CLAUDE.md

4. When using shared utilities, reference [src/shared/CLAUDE.md](src/shared/CLAUDE.md)

**Working on existing feature?**
- Read relevant component CLAUDE.md
- Check git history if function is missing
- Follow Git pre-flight checklist

**Adding new feature?**
- Create feature branch FIRST (Git pre-flight)
- Review component CLAUDE.md for patterns
- Check [CLAUDE_PATTERNS.md](CLAUDE_PATTERNS.md) for common code patterns
- Reference [shared/CLAUDE.md](src/shared/CLAUDE.md) for help/settings APIs
- Update documentation in same commits as code
