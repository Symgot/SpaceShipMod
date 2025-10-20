# SpaceShip Mod for Factorio

A comprehensive spaceship construction and automation mod for Factorio's Space Age expansion. Build custom spaceships with multiblock structures, automate space travel, and manage complex logistics between planets and space stations.

## Features

### Platform Types & Mode Management
- **Two Platform Types**: Create either Space Stations (stationary platforms) or Ships (mobile platforms)
- **Mode Toggle**: Switch between Station Mode and Ship Mode at the space platform hub
  - **Station Mode**: Platform is paused, thrusters are ineffective, no movement possible
  - **Ship Mode**: Platform can move via schedules and docking operations
- **Transfer Rules**: Validation functions for cargo transfers within the same orbit:
  - ✅ Station ↔ Station transfers allowed
  - ✅ Station ↔ Ship transfers allowed
  - ❌ Ship ↔ Ship transfers forbidden
  - Note: Manual validation available via API; automatic enforcement requires additional implementation
- **Circuit Network Control**: Full monitoring and control via circuit network signals (built into Factorio)

### Custom Spaceship Construction
- **Spaceship Flooring**: Special tiles that define your ship's structure
- **Control Hub**: Central command center for ship operations
- **Docking Ports**: Enable automated docking at space stations
- **Thruster Placement**: Thrusters can only be placed on spaceship flooring for realism

### Advanced Space Travel
- **Ship Scanning**: Automatically detects and maps your ship's layout
- **Ship Cloning**: Transfer ships between surfaces and space platforms
- **Orbit Management**: Track which planet your ship is orbiting
- **Space Platform Integration**: Seamless integration with Factorio's space platforms

### Automation & Scheduling
- **Automatic Mode**: Ships can follow schedules autonomously
- **Circuit Conditions**: Use circuit network signals for complex automation
- **Station Management**: Automatic creation and management of planet stations
- **Docking Automation**: Ships can automatically dock at designated ports

### Drop Pod System
- **Player Drops**: Drop to planets with cargo pods (requires spaceship armor)
- **Cargo Drops**: Send items to planets via cargo pods
- **Resource Costs**: Drops require rocket fuel, processing units, and low-density structures
- **Safety Systems**: Blacklisted items cannot be dropped to prevent exploits

### Station & Logistics
- **Smart Station Creation**: Automatically creates one station per planet per force
- **Docking Port Limits**: Configure how many ships can dock at each port
- **Unique Naming**: Prevents duplicate station names on the same planet
- **Circuit Integration**: Full support for circuit network conditions

## Requirements

- **Factorio**: Version 2.0.0 or higher
- **Space Age DLC**: Required for space platform functionality
- **Ship GUI Mod**: External dependency for advanced GUI features

## Installation

1. Download the mod from the Factorio mod portal
2. Place in your Factorio mods folder
3. Ensure you have the Space Age DLC enabled
4. Install the required Ship GUI dependency mod

## Getting Started

### Creating Platforms
1. **Launch a Station**: Use the "Space Station (Platform)" starter pack to create a stationary platform
   - Automatically placed in Station Mode (paused)
   - One station allowed per planet per force
2. **Launch a Ship**: Use the "Ship" starter pack to create a mobile platform
   - Starts in Ship Mode (can move)
   - Multiple ships allowed

### Mode Toggle
1. **Open Space Platform Hub**: Click on the standard space platform hub entity
2. **Toggle Mode**: Use the mode toggle button to switch between Station and Ship modes
3. **Station Mode**: Platform cannot move, thrusters have no effect (useful for stationary bases)
4. **Ship Mode**: Platform can follow schedules and move between locations

### Basic Ship Construction
1. **Place Spaceship Flooring**: Define your ship's area with spaceship flooring tiles
2. **Build Control Hub**: Place the spaceship control hub on your flooring
3. **Add Components**: Build your ship structure (thrusters only work on spaceship flooring)
4. **Scan Ship**: The ship will automatically scan its structure when built

### Space Travel
1. **Enter Cockpit**: Get in the control hub car to pilot your ship
2. **Takeoff**: Use the ship GUI to select a destination and launch
3. **Automation**: Set up schedules for automatic travel between stations

### Drop Operations
1. **Equip Spaceship Armor**: Required for player drops and space travel
2. **Load Cargo**: Place items in the control hub inventory
3. **Prepare Resources**: Ensure you have drop costs (rocket fuel, processing units, low-density structures)
4. **Execute Drop**: Use GUI buttons to drop player or cargo to planets

## Advanced Features

### Circuit Network Integration
- Connect control hubs to circuit networks
- Use signals to control ship automation
- Set complex wait conditions for automatic mode

### Docking Port Configuration
- Set custom names for docking ports
- Configure ship limits per port
- Link ports to specific ship schedules

### Performance Optimizations
- Ships scan incrementally to prevent lag
- Large ship cloning is optimized for performance
- Automatic chunk generation prevents map edge issues

## Armor System

The mod replaces all power armor mk2 references with spaceship armor:
- **Required for space travel**: Players must wear spaceship armor to pilot ships
- **Drop pod protection**: Prevents players from using cargo pods without proper equipment
- **Global replacement**: Affects all mods that reference power armor mk2

## Storage Structure

Ships are stored with the following data:
```lua
storage.spaceships[id] = {
    name = "Ship Name",
    id = unique_id,
    player_owner = player_reference,
    hub = control_hub_entity,
    surface = current_surface,
    floor = {tile_positions},
    entities = {ship_entities},
    scanned = boolean,
    player_in_cockpit = player_or_nil,
    own_surface = boolean,
    planet_orbiting = "planet_name",
    schedule = {factorio_schedule},
    automatic = boolean,
    port_records = {docking_assignments},
    docking_port = entity_reference
}
```

## Troubleshooting

### Common Issues
- **Thrusters won't place**: Ensure you're placing them on spaceship flooring
- **Can't enter space**: Check that you're wearing spaceship armor

### Performance Tips
- Keep ship sizes reasonable for better performance

## Contributing

This mod is open source. Feel free to contribute improvements, bug fixes, or new features.

## License
https://opensource.org/license/gpl-3.0

*Built for Factorio Space Age - Explore the galaxy with style!*