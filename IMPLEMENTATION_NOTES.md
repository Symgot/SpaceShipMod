# Transfer/Request Mod Implementation Summary

## Components Created

### 1. TransferRequest.lua Module
- **Purpose**: Standalone module for platform-to-platform item transfers
- **Key Features**:
  - Orbit detection (only transfers when platforms are in same orbit)
  - Request management system
  - Storage capacity validation
  - Deadlock prevention
  - UPS-friendly batched processing (max 10 transfers per tick)
  - Transfer cooldowns to prevent spam
  - Minimum quantity thresholds
  - Compatible with SpaceShip mod transfer restrictions
  - **NEW: Uses actual cargo pods with 3-second transit time instead of instant transfers**
  - **NEW: Visual effects for cargo pod arrivals**
  - **NEW: Proper in-transit item tracking**

### 2. GUI Integration (SpaceShipGuisScript.lua)
- **create_transfer_request_gui**: Main GUI for managing transfer requests
- **handle_transfer_request_buttons**: Event handler for GUI buttons
- Shows current orbit status
- Allows adding/removing transfer requests
- Displays all active requests

### 3. Control.lua Updates
- Initialized TransferRequest module
- Added periodic processing (every 60 ticks)
- Added periodic cleanup (every 5 minutes)
- Integrated GUI events for cargo landing pads
- Added button click handlers

### 4. Localization
- English locale strings for messages
- German locale strings for messages
- Messages for request registration, removal, and transfers

### 5. Documentation
- Updated readme.md with feature description
- Added usage instructions
- Added testing guide

## Technical Details

### Transfer Logic
1. Every 60 ticks, process_requests() is called
2. Iterates through all platforms with requests (max 10 transfers per tick)
3. For each request:
   - Check if platform is in orbit
   - Find other platforms in same orbit
   - Validate transfer is allowed (respects ship-to-ship restriction)
   - Check for deadlocks
   - Verify source has minimum quantity
   - Check destination has space
   - **Remove items from source platform**
   - **Create pending cargo pod with 3-second (180 tick) transit time**
   - Set cooldown
4. **Every tick, process_cargo_pod_arrivals() checks for pods that should arrive**
5. **When pod arrives: deliver items to destination, create visual effect**

### Deadlock Prevention
- Before transferring from A to B, checks if A has requests for items that B has
- If circular dependency detected, transfer is blocked
- This prevents infinite loops where platforms wait for each other

### UPS Optimization
- Batched processing (max 10 transfers per tick)
- Cooldown between transfers (5 seconds)
- Periodic cleanup of stale data
- Early exit conditions

### Storage Capacity Validation
- Calculates free space in cargo landing pads
- Accounts for partial stacks
- Tracks in-transit items (placeholder for future enhancement)
- Ensures transfers don't overflow destination

## Compatibility

### With SpaceShip Mod
- Uses Stations.validate_transfer() for transfer rules
- Respects ship-to-ship transfer restrictions
- Works with platform types (station/ship)

### Standalone
- Can work without SpaceShip mod features
- Falls back to allowing all transfers if no restrictions defined

## Known Limitations

### Current Implementation
- **RESOLVED: Now uses actual cargo pods with transit time**
- In-transit tracking properly implemented with cargo pods
- GUI only accessible via cargo landing pad
- No circuit network integration for requests yet
- No statistics/logging

### Recent Improvements (v0.2.2)
- ✅ Replaced instant transfers with actual cargo pod system
- ✅ Added multi-tick clone system for UPS optimization when player not on ship
- ✅ Added validation to prevent automatic mode without port selection
- ✅ Implemented docking port ship limit enforcement
- ✅ Added takeoff surface validation check
- ✅ Fixed spelling errors in comments

### Potential Improvements
- Use actual cargo pods for transfers
- Add circuit network signals for requests
- Add statistics tracking
- Add notification system for completed transfers
- Add priority system for requests
- Add request templates

## Testing Checklist

- [ ] Create two platforms in same orbit
- [ ] Add cargo landing pads to both
- [ ] Configure request on platform A
- [ ] Supply items on platform B
- [ ] Verify transfer occurs
- [ ] Test transfer restrictions (ship-to-ship)
- [ ] Test deadlock prevention
- [ ] Test minimum quantity thresholds
- [ ] Test storage capacity limits
- [ ] Test GUI element interactions
- [ ] Test with multiple platforms
- [ ] Test cleanup of deleted platforms

## Circuit Request Controller System (v0.2.3+)

### Overview
The Circuit Request Controller provides circuit network integration for logistics groups, allowing automated control of transfer requests through circuit signals.

### Components

#### CircuitRequestController.lua Module
- **Purpose**: Manages circuit-controlled logistics groups and request updates
- **Key Features**:
  - Logistics group creation and management
  - Circuit signal processing (reads red/green networks)
  - Group locking when controlled by circuit
  - One controller per group enforcement
  - Synchronization with TransferRequest system

#### Entity: circuit-request-controller
- **Type**: constant-combinator (1x1 entity)
- **Properties**:
  - Blue-tinted icon for easy identification
  - Circuit connectable (red/green wires)
  - Item slot count: 0 (no constant signals, only reads)
  - Unlocked with Spaceship Construction technology

### Data Flow

```
Circuit Network Signals
         ↓
Circuit Request Controller
         ↓
Logistics Group (locked)
         ↓
TransferRequest System
         ↓
Platform Transfer Requests
         ↓
Cargo Pod Transfers
```

### Architecture

#### Storage Structure
```lua
storage.circuit_controllers = {
    [unit_number] = {
        entity = LuaEntity,
        group_id = string,
        target_planet = string,
        last_update_tick = number
    }
}

storage.logistics_groups = {
    [group_id] = {
        id = string,
        name = string,
        platform_index = number,
        requests = {
            [item_name] = {
                minimum_quantity = number,
                requested_quantity = number
            }
        },
        locked = boolean,
        created_tick = number
    }
}

storage.group_controllers = {
    [group_id] = unit_number  -- Maps group to controlling entity
}
```

#### Processing Loop
1. Every 60 ticks (1 second):
   - For each registered controller:
     - Read red and green circuit networks
     - Merge signals from both networks
     - Update logistics group requests from signals
     - Sync group requests to TransferRequest system
2. Every 18000 ticks (5 minutes):
   - Clean up destroyed controllers
   - Clean up groups for deleted platforms

#### Signal Format
- Signal Type: item signals only
- Signal Value: requested quantity
- Minimum quantity: auto-calculated as 10% of requested (min 1)
- Example: Iron-plate signal with value 1000 = request 1000 iron plates (min 100)

### GUI Integration

#### Configuration GUI (SpaceShipGuisScript.lua)
- **create_circuit_controller_gui**: Main configuration interface
  - Shows controller status (registered/unregistered)
  - Allows group selection/creation
  - Planet selection dropdown
  - Active requests display
- **handle_circuit_controller_buttons**: Event handler for GUI actions
  - Register/unregister controller
  - Create new logistics groups
  - Refresh GUI on changes

#### GUI States
1. **Unregistered**: Show configuration options
   - Group dropdown (unlocked groups + create new)
   - New group name field
   - Planet selection
   - Register button
2. **Registered**: Show status and controls
   - Current group name
   - Target planet
   - Active requests list
   - Unregister button

### Event Handlers (control.lua)

- **on_gui_opened**: Opens circuit controller GUI when entity clicked
- **on_gui_closed**: Destroys circuit controller GUI
- **on_player_mined_entity**: Unregisters controller on mining
- **on_robot_mined_entity**: Unregisters controller on robot mining
- **on_space_platform_mined_entity**: Unregisters controller on platform mining
- **on_entity_died**: Unregisters controller on destruction
- **on_tick**: Processes controllers every 60 ticks

### Key Features

#### Group Locking
- When a controller registers a group, the group is marked as locked
- Locked groups cannot be manually edited through the cargo landing pad GUI
- Only the controlling circuit controller can update requests
- Unlocks automatically when controller is unregistered or destroyed

#### One Controller Per Group
- Global enforcement: only one controller can control a group at any time
- Prevents conflicts between multiple controllers
- If a controller tries to register an already-controlled group, registration fails
- Old/invalid controllers are cleaned up automatically

#### Synchronization
- Circuit signals update logistics group requests
- Logistics group requests sync to TransferRequest system
- TransferRequest system manages actual cargo pod transfers
- All changes take effect within 1 second (60 ticks)

### Localization

Supports English and German locales:
- circuit-request-controller (item/entity/recipe names)
- circuit-controller-registered (success message)
- circuit-controller-unregistered (success message)
- circuit-controller-group-locked (error message)

### Testing Checklist

- [ ] Place circuit request controller on space platform
- [ ] Configure controller with new logistics group
- [ ] Connect circuit wires with item signals
- [ ] Verify requests update automatically
- [ ] Test group locking (cannot manually edit)
- [ ] Test one controller per group enforcement
- [ ] Verify controller unregistration
- [ ] Test entity destruction/mining
- [ ] Test with multiple platforms
- [ ] Test circuit network merging (red + green)
- [ ] Verify synchronization with TransferRequest system
- [ ] Test cleanup of stale data
