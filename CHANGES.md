# Changes in v1.0.0 - Modular Architecture

## Overview

Version 1.0.0 represents a major refactoring of SpaceShipMod into three independent mods with proper separation of concerns and improved maintainability.

## Breaking Changes

⚠️ **This is a major version change with breaking changes:**

1. **Mod Structure**: SpaceShipMod is now split into three separate mods
2. **Dependencies**: SpaceShipMod now requires CircuitRequestController and TransferRequestSystem
3. **API Changes**: Direct require statements to internal modules no longer work
4. **File Structure**: All files have been reorganized into proper folders

**Migration Required:** See [MIGRATION.md](MIGRATION.md) for upgrade instructions.

## New Mod Structure

### Before (v0.2.2)
```
SpaceShipMod/
├── control.lua
├── data.lua
├── CircuitRequestController.lua
├── TransferRequest.lua
├── SpaceShip.lua
├── ... (all files in root)
```

### After (v1.0.0)
```
CircuitRequestController/         # Standalone mod
├── info.json
├── control.lua
├── data.lua
├── circuit-request-controller.lua
├── locale/
└── README.md

TransferRequestSystem/            # Standalone mod
├── info.json
├── control.lua
├── data.lua
├── transfer-request.lua
├── locale/
└── README.md

SpaceShipMod/                     # Main mod
├── info.json
├── control.lua
├── data.lua
├── data-final-fixes.lua
├── scripts/                      # Organized scripts
│   ├── gui.lua
│   ├── spaceship.lua
│   ├── stations.lua
│   ├── functions.lua
│   └── upgrade-bay.lua
├── graphics/                     # Organized graphics
│   └── control-hub.png
├── locale/
└── readme.md
```

## What's New

### CircuitRequestController (Standalone Mod)
- ✅ **No Space Age Required** - Works with base Factorio 2.0
- ✅ **Independent Operation** - Can be used without SpaceShipMod
- ✅ **Circuit Network Control** - Control logistics via circuit signals
- ✅ **Remote Interface** - Full API for other mods
- ✅ **Localization** - English and German support
- 🆕 **Standalone Technology** - Own research tree
- 🆕 **Optional Integration** - Works with or without TransferRequestSystem

**New Features:**
- Can create and manage logistics groups
- Circuit signals directly control logistics requests
- Groups can be locked by controllers
- Only one controller per group (global uniqueness)
- Proper cleanup and error handling

### TransferRequestSystem (Standalone Mod)
- ✅ **Space Age Compatible** - Works with Space Age platforms
- ✅ **Independent Operation** - Can be used without SpaceShipMod
- ✅ **Platform Transfers** - Automatic item transfers between platforms
- ✅ **Remote Interface** - Full API for other mods
- ✅ **Localization** - English and German support
- 🆕 **Standalone Transfer Logic** - No SpaceShip mod required for basic transfers
- 🆕 **Optional Circuit Control** - Integrates with CircuitRequestController

**New Features:**
- Transfer requests with configurable thresholds
- UPS-friendly batched processing
- Deadlock prevention
- Storage validation
- Ship-type restrictions (when SpaceShipMod is present)
- Cargo pod tracking

### SpaceShipMod (Main Mod)
- ✅ **Full Integration** - Complete GUI for all systems
- ✅ **Organized Structure** - Scripts in `scripts/`, graphics in `graphics/`
- ✅ **Remote Interfaces** - Provides GUI functions for standalone mods
- ✅ **Backward Compatible** - Old saves should work with migration
- 🆕 **Dependencies** - Now depends on CircuitRequestController and TransferRequestSystem
- 🆕 **Cleaner Code** - Better separation of concerns

**Improvements:**
- All require paths updated to use new structure
- GUI functions accessible via remote interface
- Station validation integrates with TransferRequestSystem
- Platform type management improved
- Better error handling

## Technical Changes

### Dependency Chain

**Old:**
```
SpaceShipMod (monolithic)
  └── Everything bundled together
```

**New:**
```
CircuitRequestController (standalone)
  └── No dependencies except base game

TransferRequestSystem (standalone)
  ├── Space Age required
  └── Optional: CircuitRequestController

SpaceShipMod
  ├── Space Age required
  ├── CircuitRequestController required
  ├── TransferRequestSystem required
  └── ship-gui required
```

### Remote Interfaces

All three mods now provide remote interfaces for inter-mod communication:

**CircuitRequestController:**
```lua
remote.call("CircuitRequestController", "create_logistics_group", platform, name)
remote.call("CircuitRequestController", "register_controller", entity, group_id, planet)
remote.call("CircuitRequestController", "get_module")
```

**TransferRequestSystem:**
```lua
remote.call("TransferRequestSystem", "register_request", platform, item_name, minimum_quantity, requested_quantity)
remote.call("TransferRequestSystem", "get_requests", platform)
remote.call("TransferRequestSystem", "get_module")
```

**SpaceShipMod:**
```lua
remote.call("SpaceShipMod", "create_transfer_request_gui", player, entity)
remote.call("SpaceShipMod", "create_circuit_controller_gui", player, entity)
remote.call("SpaceShipMod", "get_stations_module")
```

### File Organization

**Scripts Folder:**
- `scripts/gui.lua` - All GUI functions
- `scripts/spaceship.lua` - Core spaceship logic
- `scripts/stations.lua` - Station management
- `scripts/functions.lua` - Helper functions
- `scripts/upgrade-bay.lua` - Upgrade bay system

**Graphics Folder:**
- `graphics/control-hub.png` - Control hub sprite

**Better Require Paths:**
```lua
-- Old (v0.2.2)
local SpaceShip = require("SpaceShip")

-- New (v1.0.0)
local SpaceShip = require("scripts.spaceship")
```

### Data Definitions

**CircuitRequestController** now owns:
- `circuit-request-controller` entity
- `circuit-request-controller` item
- `circuit-request-controller` recipe
- `circuit-request-controller` technology

**TransferRequestSystem**:
- No new entities (uses existing cargo-landing-pad)
- All transfer logic and storage

**SpaceShipMod**:
- All spaceship entities and items
- Spaceship construction technology
- Upgrade bay system
- Docking ports

## Migration Path

See [MIGRATION.md](MIGRATION.md) for detailed upgrade instructions.

**Summary:**
1. Install all three new mods
2. Load your save
3. Data migration happens automatically
4. Verify everything works

## Testing

See [TESTING.md](TESTING.md) for comprehensive testing instructions.

**Test Coverage:**
- Each mod standalone
- Mods in combination
- Full integration
- Error handling
- Performance testing

## Documentation

**New Documents:**
- [README.md](README.md) - Repository overview
- [TESTING.md](TESTING.md) - Testing guide
- [MIGRATION.md](MIGRATION.md) - Upgrade guide
- [CHANGES.md](CHANGES.md) - This file
- [CircuitRequestController/README.md](CircuitRequestController/README.md)
- [TransferRequestSystem/README.md](TransferRequestSystem/README.md)
- [SpaceShipMod/readme.md](SpaceShipMod/readme.md)

## Benefits

### For Users
- ✅ More flexibility - use only what you need
- ✅ CircuitRequestController works without Space Age
- ✅ Better performance - modular code is easier to optimize
- ✅ Clearer documentation per mod

### For Developers
- ✅ Easier to maintain - each mod is independent
- ✅ Clearer code structure - organized folders
- ✅ Better testability - test each mod separately
- ✅ Easier to contribute - smaller, focused changes
- ✅ Reusable - other mods can use the standalone systems

### For Mod Authors
- ✅ Public APIs via remote interfaces
- ✅ Can depend on just CircuitRequestController or TransferRequestSystem
- ✅ Don't need full SpaceShipMod for circuit or transfer features
- ✅ Better compatibility with future versions

## Known Issues

### Compatibility
- ⚠️ Mods that directly required SpaceShipMod's internal modules will break
- ⚠️ Old saves might need manual verification after migration
- ℹ️ Downgrading from v1.0.0 to v0.2.2 is not supported

### Solutions
- Update dependent mods to use remote interfaces
- See [MIGRATION.md](MIGRATION.md) for save upgrade instructions
- Create backups before upgrading

## Future Plans

### v1.1.0 (Planned)
- Additional circuit signals
- More transfer options
- Performance optimizations
- More upgrade modules

### v2.0.0 (Future)
- Multi-mod GUI framework
- Enhanced automation
- Additional platform types
- More customization options

## Credits

- Original SpaceShipMod by Symgot
- Refactoring and modularization by Symgot
- Community feedback and testing

## License

GPL-3.0 - Same as original SpaceShipMod

---

**Version:** 1.0.0  
**Date:** October 2024  
**Factorio Version:** 2.0+  
**Space Age:** Required (for TransferRequestSystem and SpaceShipMod)
