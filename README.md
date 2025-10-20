# SpaceShip Mod Collection

This repository contains three independent Factorio mods that work together to provide a comprehensive spaceship construction and logistics system for Space Age.

## Repository Structure

```
.
├── CircuitRequestController/    # Standalone circuit network logistics control
├── TransferRequestSystem/       # Standalone platform-to-platform transfer system
└── SpaceShipMod/               # Main spaceship construction mod
```

## Mods Overview

### 1. Circuit Request Controller
**Independent Mod** - Works with base Factorio 2.0 (no Space Age required)

- Circuit network control of logistics requests
- Create and manage logistics groups
- Control requests via circuit signals
- Works standalone or integrates with TransferRequestSystem
- See [CircuitRequestController/README.md](CircuitRequestController/README.md) for details

### 2. Transfer Request System
**Independent Mod** - Requires Space Age DLC

- Automatic item transfers between space platforms in the same orbit
- Configurable minimum and requested quantities
- UPS-friendly batched processing
- Deadlock prevention and storage validation
- Optional integration with CircuitRequestController for circuit control
- Optional integration with SpaceShipMod for ship-type restrictions
- See [TransferRequestSystem/README.md](TransferRequestSystem/README.md) for details

### 3. SpaceShip Mod
**Main Mod** - Requires Space Age DLC and both standalone mods

- Custom spaceship construction with multiblock structures
- Space platform hub mode toggle (Station vs Ship mode)
- Docking port system and automation
- Upgrade bay system with quality-based progression
- Full GUI support for TransferRequestSystem and CircuitRequestController
- Integration with ship-gui mod for advanced scheduling
- See [SpaceShipMod/readme.md](SpaceShipMod/readme.md) for details

## Dependency Chain

```
CircuitRequestController (standalone, no dependencies*)
    ↑
    │ (optional)
    │
TransferRequestSystem (requires Space Age, optional CircuitRequestController)
    ↑
    │ (required)
    │
SpaceShipMod (requires Space Age, CircuitRequestController, TransferRequestSystem, ship-gui)
```

*CircuitRequestController only requires base Factorio 2.0

## Installation

### For End Users

Download and install from the Factorio Mod Portal:
1. Install `CircuitRequestController` 
2. Install `TransferRequestSystem`
3. Install `SpaceShipMod`
4. Install `ship-gui` (dependency of SpaceShipMod)

### For Developers

This repository contains the source code for all three mods. To develop or test:

1. Clone this repository
2. Symlink or copy each mod folder to your Factorio mods directory:
   - `CircuitRequestController/` → `~/.factorio/mods/CircuitRequestController/`
   - `TransferRequestSystem/` → `~/.factorio/mods/TransferRequestSystem/`
   - `SpaceShipMod/` → `~/.factorio/mods/SpaceShipMod/`
3. See [TESTING.md](TESTING.md) for detailed testing instructions

### Migrating from v0.2.2

If you're upgrading from SpaceShipMod v0.2.2 or earlier, please read [MIGRATION.md](MIGRATION.md) for important upgrade instructions.

### Option 1: Install All Mods (Recommended)
For the full experience, install all three mods:
1. Install `CircuitRequestController` 
2. Install `TransferRequestSystem`
3. Install `SpaceShipMod`
4. Install `ship-gui` (dependency of SpaceShipMod)

### Option 2: Standalone Installations
You can install mods independently:

- **CircuitRequestController alone**: Basic circuit network logistics control (no GUI)
- **TransferRequestSystem alone**: Platform transfers with remote interface (no GUI)
- **TransferRequestSystem + CircuitRequestController**: Platform transfers with circuit control (no GUI)
- **All three mods**: Full experience with complete GUI support

## Key Features

### Platform Types & Transfer Rules
- **Station Mode**: Stationary platforms, can transfer items freely
- **Ship Mode**: Mobile platforms, cannot transfer items to other ships
- Transfer validation:
  - ✅ Station ↔ Station
  - ✅ Station ↔ Ship
  - ❌ Ship ↔ Ship (blocked)

### Circuit Network Integration
- Control logistics requests via circuit signals
- Each signal represents an item and quantity
- Automatic synchronization with transfer system
- Group-based request management

### Upgrade System
- Quality-based equipment grids (Common to Legendary)
- Building capacity modules
- Special enhancement modules (thrust, payload, docking, etc.)
- Planet-discovery-gated progression

## Development

Each mod is fully independent and can be developed separately:

- **CircuitRequestController**: No Space Age dependency, pure circuit logic
- **TransferRequestSystem**: Space Age features, independent transfer logic
- **SpaceShipMod**: Integrates everything with full GUI and spaceship features

All mods provide remote interfaces for inter-mod communication without direct code dependencies.

## License

GPL-3.0

## Documentation

- [TESTING.md](TESTING.md) - Comprehensive testing guide for all three mods
- [MIGRATION.md](MIGRATION.md) - Upgrade guide from v0.2.2 to v1.0.0
- Individual mod READMEs:
  - [CircuitRequestController/README.md](CircuitRequestController/README.md)
  - [TransferRequestSystem/README.md](TransferRequestSystem/README.md)
  - [SpaceShipMod/readme.md](SpaceShipMod/readme.md)

## Contributing

Contributions are welcome! Each mod can be improved independently while maintaining compatibility with the others.

Please read [TESTING.md](TESTING.md) for information on how to test your changes.

---

*Built for Factorio Space Age - Explore the galaxy with style!*
