# Testing Guide for SpaceShip Mod Collection

This guide provides instructions for testing each mod independently and together.

## Prerequisites

- Factorio 2.0+
- Space Age DLC (for TransferRequestSystem and SpaceShipMod)
- ship-gui mod (for SpaceShipMod)

## Repository Structure

The repository contains three independent mods:
- `CircuitRequestController/` - Standalone circuit logistics control
- `TransferRequestSystem/` - Standalone platform transfer system
- `SpaceShipMod/` - Main spaceship construction mod

## Installation for Testing

### Option 1: Symlink to Factorio Mods Folder (Development)

```bash
# Linux/Mac
ln -s /path/to/repo/CircuitRequestController ~/.factorio/mods/CircuitRequestController
ln -s /path/to/repo/TransferRequestSystem ~/.factorio/mods/TransferRequestSystem
ln -s /path/to/repo/SpaceShipMod ~/.factorio/mods/SpaceShipMod

# Windows (run as Administrator)
mklink /D "%APPDATA%\Factorio\mods\CircuitRequestController" "C:\path\to\repo\CircuitRequestController"
mklink /D "%APPDATA%\Factorio\mods\TransferRequestSystem" "C:\path\to\repo\TransferRequestSystem"
mklink /D "%APPDATA%\Factorio\mods\SpaceShipMod" "C:\path\to\repo\SpaceShipMod"
```

### Option 2: Copy to Factorio Mods Folder

Copy each mod folder to your Factorio mods directory.

## Test Plan

### Test 1: CircuitRequestController Standalone

**Setup:**
1. Enable only `CircuitRequestController` mod
2. Start a new game

**Tests:**
- [ ] Technology "Circuit Request Controller" appears and is researchable
- [ ] After research, circuit-request-controller item/recipe is available
- [ ] Can place circuit-request-controller entity
- [ ] Can connect red/green wires to the entity
- [ ] Entity has no constant slots (item_slot_count = 0)
- [ ] Opening the entity shows fallback message (no GUI without SpaceShipMod)
- [ ] Remote interface "CircuitRequestController" is available in `/c game.print(serpent.block(remote.interfaces))`
- [ ] Can create logistics groups via remote interface
- [ ] Mining the entity doesn't cause errors

**Expected Result:** Mod loads without errors, entity works, but no GUI available.

### Test 2: TransferRequestSystem Standalone

**Setup:**
1. Enable only `TransferRequestSystem` mod
2. Start a new game with Space Age

**Tests:**
- [ ] Mod loads without errors
- [ ] Launch two space platforms to the same orbit (e.g., Nauvis)
- [ ] Both platforms have cargo landing pads
- [ ] Opening cargo landing pad shows fallback message (no GUI without SpaceShipMod)
- [ ] Remote interface "TransferRequestSystem" is available
- [ ] Can register transfer requests via remote interface:
  ```lua
  /c local platform = game.forces.player.platforms[1]
  /c remote.call("TransferRequestSystem", "register_request", platform, "iron-plate", 100, 1000)
  ```
- [ ] Items transfer between platforms automatically (check every 60 ticks)
- [ ] Ship-to-ship transfers are blocked (if using platform names with "-ship")
- [ ] Station-to-station transfers work

**Expected Result:** Mod loads without errors, transfers work via remote interface, but no GUI available.

### Test 3: CircuitRequestController + TransferRequestSystem

**Setup:**
1. Enable both `CircuitRequestController` and `TransferRequestSystem`
2. Start a new game with Space Age

**Tests:**
- [ ] Both mods load without errors
- [ ] Can place circuit-request-controller on a space platform
- [ ] Can create logistics groups and register controller via remote interface
- [ ] Circuit signals are read and synced to transfer requests:
  ```lua
  /c local platform = game.forces.player.platforms[1]
  /c local group_id = remote.call("CircuitRequestController", "create_logistics_group", platform, "Test Group")
  /c local controller = game.player.surface.find_entities_filtered({name="circuit-request-controller"})[1]
  /c remote.call("CircuitRequestController", "register_controller", controller, group_id, "nauvis")
  ```
- [ ] Connect circuit wires with item signals
- [ ] Verify signals are processed and synced to transfer system
- [ ] Verify transfers happen based on circuit signals

**Expected Result:** Both mods work together, circuit signals control transfers.

### Test 4: All Three Mods Together (Full Integration)

**Setup:**
1. Enable all mods: `CircuitRequestController`, `TransferRequestSystem`, `SpaceShipMod`, `ship-gui`
2. Start a new game with Space Age

**Tests:**

#### Basic SpaceShipMod Features
- [ ] Technology "Spaceship Construction" appears and is researchable
- [ ] After research, spaceship items/recipes are available
- [ ] Can place spaceship flooring
- [ ] Can place spaceship control hub
- [ ] Can place docking ports
- [ ] Opening control hub shows spaceship GUI
- [ ] Ship scanning works
- [ ] Can build and launch spaceships

#### Platform Types
- [ ] Can create stations (space-platform-hub)
- [ ] Can create ships (spaceship-control-hub)
- [ ] Platform names indicate type ("-station" or "-ship")
- [ ] Platform tags store ship_type correctly
- [ ] Mode toggle button appears on space-platform-hub
- [ ] Can toggle between Station and Ship modes

#### Transfer Request GUI
- [ ] Launch two platforms to same orbit
- [ ] Open cargo landing pad on a platform
- [ ] Transfer Request GUI appears
- [ ] Shows current orbit
- [ ] Can add transfer requests via GUI
- [ ] Can set minimum and requested quantities
- [ ] Can remove requests via GUI
- [ ] Requests are displayed in the GUI
- [ ] Items transfer automatically between platforms
- [ ] Ship-to-ship transfers are blocked with proper message

#### Circuit Controller GUI
- [ ] Can place circuit-request-controller on platform
- [ ] Opening circuit-request-controller shows GUI
- [ ] Can create new logistics groups via GUI
- [ ] Can select existing logistics groups
- [ ] Can select target planet
- [ ] Can register controller via GUI
- [ ] Controller status is displayed
- [ ] Can unregister controller via GUI
- [ ] Connect circuit wires to controller
- [ ] Send item signals (e.g., iron-plate = 1000)
- [ ] Verify signals appear in GUI
- [ ] Verify transfer requests are created automatically
- [ ] Verify items transfer based on circuit signals

#### Upgrade Bay System
- [ ] Control hub has upgrade bay (hidden car entity)
- [ ] Can open upgrade bay by clicking hub button or via GUI
- [ ] Equipment grid size matches hub quality
- [ ] Can place capacity modules in equipment grid
- [ ] Modules affect ship building limits
- [ ] Special modules work (thrust, payload, etc.)

#### Integration Tests
- [ ] All GUIs work together without conflicts
- [ ] Multiple controllers can exist but only one per group
- [ ] Destroying controller releases group lock
- [ ] Transfer validation respects ship types
- [ ] Circuit signals sync to transfer system correctly
- [ ] Platform state changes are handled properly
- [ ] No errors in log during normal operation

**Expected Result:** Full functionality with complete GUI support.

### Test 5: Error Handling

**Tests:**
- [ ] Removing TransferRequestSystem while SpaceShipMod is active shows proper errors
- [ ] Removing CircuitRequestController while SpaceShipMod is active shows proper errors
- [ ] Invalid circuit signals don't crash
- [ ] Invalid transfer requests don't crash
- [ ] Destroying entities during operation doesn't crash
- [ ] Loading saves with mods enabled/disabled works correctly

## Common Issues and Solutions

### Issue: "TransferRequestSystem mod not found!"
**Solution:** Ensure TransferRequestSystem mod is enabled and loaded.

### Issue: "CircuitRequestController mod not found!"
**Solution:** Ensure CircuitRequestController mod is enabled and loaded.

### Issue: GUI not appearing
**Solution:** Ensure SpaceShipMod is enabled. Standalone mods don't provide GUIs.

### Issue: Transfers not working
**Solution:** 
1. Verify platforms are in same orbit
2. Check that platforms have cargo landing pads
3. Verify items are available in source platform
4. Check ship-to-ship restriction isn't blocking transfer

### Issue: Circuit signals not working
**Solution:**
1. Verify controller is registered to a group
2. Check that wires are connected
3. Verify signals are being sent
4. Check that controller is on a platform (not ground)

## Debug Commands

Useful console commands for debugging:

```lua
-- List all platforms
/c for _, p in pairs(game.forces.player.platforms) do
    game.print(p.name .. " at " .. (p.space_location and p.space_location.name or "traveling"))
end

-- Check remote interfaces
/c game.print(serpent.block(remote.interfaces))

-- Get all transfer requests for first platform
/c if remote.interfaces["TransferRequestSystem"] then
    local platform = game.forces.player.platforms[1]
    local requests = remote.call("TransferRequestSystem", "get_requests", platform)
    game.print(serpent.block(requests))
end

-- Get all logistics groups for first platform
/c if remote.interfaces["CircuitRequestController"] then
    local platform = game.forces.player.platforms[1]
    local groups = remote.call("CircuitRequestController", "get_platform_groups", platform)
    game.print(serpent.block(groups))
end

-- Check platform type
/c local platform = game.forces.player.platforms[1]
/c game.print("Type: " .. (platform.tags.ship_type or "unknown"))
/c game.print("Station mode: " .. tostring(platform.tags.station_mode))
```

## Performance Testing

For UPS testing with many platforms and transfers:

1. Create 10+ platforms in same orbit
2. Add transfer requests on all platforms
3. Use `/measured-command` to check UPS impact
4. Monitor via F5 debug view

Expected: Minimal UPS impact due to batched processing (60 tick interval, max 10 transfers per tick).

## Reporting Issues

When reporting issues, please include:
- Which mods are enabled
- Steps to reproduce
- Expected vs actual behavior
- Console errors from log
- Save file (if applicable)
- Screenshots of GUI issues
