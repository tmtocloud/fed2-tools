# fed2-tools

A Mudlet package for [Federation 2 Community Edition](https://federation2.com) that provides mapping, navigation, automated trading, factory management, and quality-of-life improvements.

## Features

| Component | Commands | Description |
|-----------|----------|-------------|
| Map | `nav`, `map` | Auto-mapping builds the map as you explore. Speedwalk navigation gets you anywhere fast. Exploration mode automatically visits unmapped rooms. |
| Hauling | `haul` | Automated trading that adapts to your rank. Commanders/Captains run Armstrong Cuthbert jobs, Adventurers do Akaturi deliveries, Merchants+ trade between exchanges. |
| Factory | `factory` | View status of all your factories in one table. Flush all production to market with a single command. |
| Planet Owner | `po` | View your planet's economy at a glance — commodity values, production, consumption, stock levels, and efficiency. Filter by commodity group. |
| Commodities | `price`, `bb`, `bs` | Check commodity prices across all cartel exchanges. Find the best places to buy and sell, with profit calculations. Buy or sell commodities in bulk at exchanges. |
| Auto-Refuel | `f2t settings` | Automatically refuels your ship when landing at shuttlepads. Triggers when fuel drops below your configured threshold. |
| Stamina Monitor | `f2t settings` | Detects low stamina and navigates to buy food. Pauses active automation, refills stamina, then returns you to where you were. |
| Death Monitor | `f2t settings` | Handles death automatically by stopping all automation and running `insure`. Permanently locks the death room so navigation avoids it. |

## Installation

### Prerequisites

- [Mudlet](https://www.mudlet.org/) 4.0 or higher
- A Federation 2 account

### Before Installing

**Important:** Uninstall any existing mapper packages before installing fed2-tools. This includes:
- Mudlet's `generic-mapper`
- Any other mapping scripts or packages

Having multiple mappers active will cause conflicts.

To uninstall in Mudlet: Go to **Package Manager** → select the package → **Uninstall**

### Install fed2-tools

1. Download the latest `fed2-tools.mpackage` from the [Releases](https://github.com/ping65510/fed2-tools/releases) page
2. In Mudlet, go to **Package Manager** → **Install**
3. Select the downloaded `.mpackage` file
4. Connect to Federation 2

## Initial Setup

After installing, follow these steps to get the most out of fed2-tools.

### 1. Import a Base Map

The package comes with bundled with two starter maps to help you get started. Additionally, a third map including shuttlepads and exchanges for all planets in the galaxy is available in this repository.

|Map|Description|
|--|--|
|starter_map.json|Matches the maps available in the [Federation 2 Guide](https://federation2.com/guide/#sec-20).|
|starter_map_with_exchanges.json|Adds exchanges for planets where they were not included in the starter map.|
|galaxy_brief.json|Available in the maps folder of this repository, includes all systems, planets, and their shuttlepads and exchanges as of the commit date.|

To import:

```
map import
```

Select the map JSON file you wish to import, then confirm with:

```
map confirm
```

The bundled maps are included as resources in the package (and are also in the maps folder in this repo). You can find them at:

- **Windows**: `%APPDATA%\Mudlet\profiles\<profile>\fed2-tools\shared\resources`
- **macOS**: `~/.config/mudlet/profiles/<profile>/fed2-tools/shared/resources`
- **Linux**: `~/.config/mudlet/profiles/<profile>/fed2-tools/shared/resources`

Alternatively, skip this step and explore on your own - the mapper auto-creates rooms as you move with `map on` enabled.

### 2. Enable Automatic Refueling

Never run out of fuel again. When enabled, your ship automatically refuels at shuttlepads when fuel drops below the threshold.

```
f2t settings set refuel_threshold 50
```

This sets the threshold to 50% - your ship will refuel whenever fuel is at or below 50%. Adjust the number to your preference (1-100). Set to 0 to disable.

To check current settings: `f2t settings`

### 3. Enable Stamina Monitoring

Automatically handles low stamina by navigating to buy food, then returning you to what you were doing.

```
f2t settings set stamina_threshold 25
f2t settings set food_source Sol.Earth.454
```

This triggers a food run when stamina drops to 25%. Change `food_source` to your preferred food location.

### 4. Enable Death Monitoring

When enabled, the system automatically handles death by:
- Stopping all automation (hauling, exploration, navigation)
- Running `insure` after respawn
- Locking the room where death occurred so navigation avoids it in the future

To enable:

```
f2t settings set death_monitor_enabled true
```

## Quick Reference

### Navigation

Get anywhere fast with the `nav` command (aliases: `go`, `goto`):

```
nav Earth              # Go to Earth (shuttlepad by default)
nav Earth orbit        # Go to Earth orbit
nav Sol                # Go to Sol system link room
nav exchange           # Go to exchange in current area
nav Earth exchange     # Go to Earth's exchange
nav mybase             # Go to saved destination "mybase"
```

**Room identifiers:** Fed2 uses hashes like `Sol.Earth.454` (system.area.room_number) to identify rooms. Mudlet uses numeric room IDs internally. You can use either format with `nav`, and Fed2 hashes work in settings like `food_source` and `safe_room`.

Save your favorite locations:

```
map dest add mybase    # Save current location as "mybase"
map dest               # List all saved destinations
map dest remove mybase # Remove saved destination
```

Control speedwalk:

```
nav stop               # Stop navigation
nav pause              # Pause navigation
nav resume             # Resume navigation
```

### Mapping

Auto-mapping is enabled by default. As you move, rooms and exits are created automatically.

```
map on                 # Enable auto-mapping
map off                # Disable auto-mapping
```

Explore new areas automatically:

```
map explore            # Auto-explore current area
map explore Earth      # Auto-explore Earth
map explore Sol        # Auto-explore Sol system
map explore galaxy     # Auto-explore everything (takes a while!)
map explore stop       # Stop exploration
```

Search the map:

```
map search casino      # Search current area
map search Earth casino # Search specific planet
map search all casino  # Search entire map
```

### Trading

Check commodity prices:

```
price alloys           # Show best buy/sell locations for alloys
price all              # Analyze all commodities (30-40 seconds)
```

**Note:** Price checking requires the Remote Price Check Service. See the [Fed2 guide](https://federation2.com/guide/#sec-230.20) for details on acquiring it.

Bulk buy and sell at exchanges:

```
bb alloys              # Buy alloys until hold is full
bb alloys 5            # Buy 5 lots of alloys
bs                     # Sell all cargo
bs alloys              # Sell all alloys
bs alloys 3            # Sell 3 lots of alloys
```

### Automated Hauling

Start automated trading appropriate for your rank:

```
haul start             # Begin hauling
haul stop              # Stop gracefully
haul status            # Check current status
haul pause             # Pause operation
haul resume            # Resume operation
```

The system automatically adapts:
- **Commander/Captain**: Armstrong Cuthbert courier jobs
- **Adventurer**: Akaturi delivery contracts
- **Merchant+**: Exchange-to-exchange commodity trading

### Factory Status (Industrialist/Manufacturer)

View all your factories in one table:

```
factory status         # or: fac status
```

Send all production to market:

```
factory flush          # or: fac flush
```

### Planet Owner (Founder+)

View your planet's economy:

```
po economy             # Economy for current planet
po economy Earth       # Economy for specific planet
po economy agri        # Filter by commodity group
po econ Earth tech     # Planet + group filter
```

**Groups:** agricultural (agri), resource, industrial (ind), technological (tech), biological, leisure

### System Commands

```
f2t status             # Show all component states
f2t settings           # View all settings
f2t debug on           # Enable debug logging
f2t debug off          # Disable debug logging
f2t version            # Show package version
```

## Settings

All components use a consistent settings interface:

```
<component> settings                    # List all settings
<component> settings get <name>         # Get specific setting
<component> settings set <name> <value> # Set a setting
<component> settings clear <name>       # Reset to default
```

### Common Settings

Settings are organized by component. Use `<component> settings` to see all settings for a component.

**System settings** (`f2t settings`):

| Setting | Default | Description |
|---------|---------|-------------|
| refuel_threshold | 50 | Auto-refuel threshold (0=disabled, 1-99=refuel at/below %) |
| stamina_threshold | 25 | Stamina % to trigger food run (0=disabled, 1-99=buy food at below %)|
| food_source | Sol.Earth.454 | Where to buy food |
| death_monitor_enabled | true | Auto-lock death rooms |
| safe_room | (empty) | Safe destination for hauling (e.g., "earth") |

**Map settings** (`map settings`):

| Setting | Default | Description |
|---------|---------|-------------|
| enabled | true | Enable auto-mapping |
| planet_nav_default | shuttlepad | Where `nav <planet>` goes |

**Hauling settings** (`haul settings`):

| Setting | Default | Description |
|---------|---------|-------------|
| margin_threshold | 40 | Minimum profit margin % |
| cycle_pause | 60 | Seconds to pause after 5 trades |
| use_safe_room | false | Return to safe_room when stopping |

**Price settings** (`price settings`):

| Setting | Default | Description |
|---------|---------|-------------|
| results_count | 5 | Number of results shown |

## Getting Help

### In-Game Help

Every command supports help by adding `help` after the command:

```
nav help
map help
haul help
price help
factory help
po help
bb help
bs help
f2t help
```

### Reporting Issues

If you encounter a bug or have a feature request:

1. Enable debug logging: `f2t debug on`
2. Reproduce the issue
3. Copy the relevant output from Mudlet
4. Open an issue at [GitHub Issues](https://github.com/ping65510/fed2-tools/issues) with:
   - What you were trying to do
   - What happened instead
   - The debug output
   - Your character rank (if relevant)

## Contributing

Contributions are welcome! Here's how to get started:

### Workflow

1. Fork the repository on GitHub.

2. Clone your fork and create a branch:
   ```bash
   git clone https://github.com/YOUR-USERNAME/fed2-tools.git
   cd fed2-tools
   git checkout -b feature/my-feature
   ```

3. Build the package:
   ```bash
   pwsh ./build.ps1
   ```
   This creates `build/fed2-tools.mpackage`.

4. Install in Mudlet via **Package Manager** → **Install** and test your changes.

5. Commit and push to your fork:
   ```bash
   git add .
   git commit -m "feat: description of your change"
   git push origin feature/my-feature
   ```

6. Open a pull request from your fork to the main repository on GitHub.

### Project Structure

- `src/` - Source files organized by component
- `build.ps1` - Build script (PowerShell 7)
- `CLAUDE.md` - Technical documentation for AI assistants and developers

Each component in `src/` has its own folder with `aliases/`, `triggers/`, `scripts/`, and optionally `resources/` subdirectories.

## License

This project is licensed under the MIT License.

## Resources

- [Federation 2 Community Edition](https://federation2.com)
- [Mudlet](https://www.mudlet.org/)
