# Migration Guide from v0.2.2 to v1.0.0

This guide helps existing SpaceShipMod users migrate to the new modular structure introduced in v1.0.0.

## What Changed?

**v0.2.2 and earlier:**
- Single monolithic mod "SpaceShipMod"
- All features bundled together
- CircuitRequestController and TransferRequest were internal modules

**v1.0.0 and later:**
- Three independent mods:
  - `CircuitRequestController` - Standalone circuit logistics control
  - `TransferRequestSystem` - Standalone platform transfer system  
  - `SpaceShipMod` - Main spaceship construction mod (depends on the other two)

## Why the Change?

1. **Modularity**: Each system can now be used independently
2. **Reduced Dependencies**: CircuitRequestController doesn't require Space Age
3. **Better Structure**: Clean separation of concerns with proper folder organization
4. **Easier Maintenance**: Each mod can be updated independently
5. **Flexibility**: Use only the features you need

## Migration Steps

### For New Installations

Simply install all three mods:
1. CircuitRequestController
2. TransferRequestSystem  
3. SpaceShipMod
4. ship-gui (dependency)

All mods will work together seamlessly.

### For Existing Saves (Upgrading from v0.2.2)

⚠️ **Important:** Create a backup of your save before upgrading!

#### Option 1: Clean Upgrade (Recommended)

1. **Before upgrading:**
   - Note down your ship configurations
   - Take screenshots of important GUIs
   - Document your circuit controller setups
   - Document your transfer requests

2. **Upgrade process:**
   - Remove SpaceShipMod v0.2.2 from your mods folder
   - Install all three new mods (CircuitRequestController, TransferRequestSystem, SpaceShipMod v1.0.0)
   - Load your save

3. **After loading:**
   - Factorio will detect the mod changes
   - Data migration should happen automatically
   - Verify your ships, stations, and platforms are intact
   - Re-check circuit controllers (they should still work)
   - Re-check transfer requests (they should still work)

#### Option 2: Parallel Testing

1. Create a copy of your save file
2. Test the upgrade on the copy first
3. If everything works, upgrade your main save
4. If issues occur, report them and stick with v0.2.2 until fixed

### Expected Behavior After Migration

✅ **Should work automatically:**
- All ships and their configurations
- Space platforms (stations and ships)
- Platform mode settings (Station vs Ship)
- Spaceship flooring and structures
- Control hubs and their inventories
- Docking ports and their settings
- Upgrade bay configurations
- Equipment modules in upgrade bays

✅ **Should be preserved:**
- Transfer requests (now managed by TransferRequestSystem)
- Circuit controllers (now managed by CircuitRequestController)
- Logistics groups
- Controller registrations

⚠️ **May need reconfiguration:**
- Some GUI states might be reset
- Circuit controller GUI positions
- Transfer request GUI states

❌ **Known limitations:**
- Old save data structure is incompatible if saved with v0.2.2, but migration code should handle most cases
- Very old saves (before v0.2.0) may need manual intervention

## Data Migration Details

The migration process handles:

1. **Storage structures:**
   - `storage.circuit_controllers` → Managed by CircuitRequestController mod
   - `storage.logistics_groups` → Managed by CircuitRequestController mod  
   - `storage.transfer_requests` → Managed by TransferRequestSystem mod
   - `storage.platform_requests` → Managed by TransferRequestSystem mod
   - `storage.spaceships` → Remains in SpaceShipMod

2. **Entity preservation:**
   - `circuit-request-controller` entities remain functional
   - `cargo-landing-pad` entities with transfer requests remain functional
   - `spaceship-control-hub` entities remain functional
   - All ships and platforms remain intact

3. **Remote interface changes:**
   - Old code that directly required modules needs updating
   - New code should use remote interfaces
   - See [TESTING.md](TESTING.md) for remote interface examples

## Troubleshooting

### Issue: "CircuitRequestController not found"

**Symptom:** Error message when loading save  
**Cause:** CircuitRequestController mod not installed  
**Solution:** Install CircuitRequestController v1.0.0 or later

### Issue: "TransferRequestSystem not found"

**Symptom:** Error message when loading save  
**Cause:** TransferRequestSystem mod not installed  
**Solution:** Install TransferRequestSystem v1.0.0 or later

### Issue: Transfer requests disappeared

**Symptom:** Previously configured transfer requests are gone  
**Cause:** TransferRequestSystem mod not properly initialized  
**Solution:**
1. Check that TransferRequestSystem mod is enabled
2. Save and reload the game
3. If still missing, reconfigure requests via GUI or remote interface

### Issue: Circuit controllers not working

**Symptom:** Circuit signals don't control logistics  
**Cause:** CircuitRequestController mod not properly initialized  
**Solution:**
1. Check that CircuitRequestController mod is enabled
2. Verify controller is registered to a group
3. Save and reload the game
4. If still not working, re-register controllers via GUI

### Issue: Mods won't load together

**Symptom:** Error about circular dependencies or missing dependencies  
**Cause:** Incorrect mod versions or installation  
**Solution:**
1. Ensure all three mods are v1.0.0 or later
2. Check that dependencies are correct in info.json
3. Reinstall all three mods from scratch
4. Check Factorio logs for specific error messages

### Issue: Save file corrupted

**Symptom:** Can't load save, crashes on load  
**Cause:** Migration failed due to data incompatibility  
**Solution:**
1. Restore your backup save
2. Report the issue with log files
3. Wait for a patch or use v0.2.2 until fixed

## Reverting to v0.2.2

If you need to revert:

1. Remove all three new mods
2. Reinstall SpaceShipMod v0.2.2
3. Load your backup save from before the upgrade
4. **Do not** load a save that was already migrated to v1.0.0

⚠️ **Warning:** Once a save is migrated to v1.0.0, it cannot be downgraded to v0.2.2!

## Updating Existing Mods That Depend on SpaceShipMod

If you maintain a mod that depends on SpaceShipMod:

### Old way (v0.2.2):
```lua
local TransferRequest = require("__SpaceShipMod__.TransferRequest")
TransferRequest.register_request(platform, item, min, max)
```

### New way (v1.0.0+):
```lua
-- Use remote interface
if remote.interfaces["TransferRequestSystem"] then
    remote.call("TransferRequestSystem", "register_request", platform, item, min, max)
end
```

### Compatibility with both versions:
```lua
-- Try v1.0.0+ first
if remote.interfaces["TransferRequestSystem"] then
    remote.call("TransferRequestSystem", "register_request", platform, item, min, max)
else
    -- Fall back to v0.2.2
    local success, TransferRequest = pcall(require, "__SpaceShipMod__.TransferRequest")
    if success then
        TransferRequest.register_request(platform, item, min, max)
    end
end
```

## Getting Help

If you encounter issues during migration:

1. Check the [TESTING.md](TESTING.md) guide for common solutions
2. Review Factorio logs for specific error messages
3. Report issues on the mod portal or GitHub with:
   - Your save file (if shareable)
   - Log file (factorio-current.log)
   - Description of the issue
   - Steps to reproduce
   - Which mods are installed and their versions

## Feedback

We want to make this migration as smooth as possible. If you encounter any issues or have suggestions for improving this guide, please let us know!

## Version History

- **v1.0.0** (2024): Modular structure with three independent mods
- **v0.2.2** (2024): Last version of monolithic SpaceShipMod
- Earlier versions: Single mod structure
