# Bynew

Destroy anticheat functions without crashing the game.

## Installation

```lua
local Bynew = loadstring(game:HttpGet("https://raw.githubusercontent.com/noctryxzen/Bypasser/refs/heads/main/BModule.luau"))()
```

## Quick Start

```lua
-- Destroy all functions in a script
Bynew.Hook("Anticheat")
```

That's it. All functions in the Anticheat script are now broken.

## Examples

### Single script
```lua
Bynew.Hook("KickHandler")
```

### By script name (recommended)
```lua
Bynew.Hook({ScriptName = "Anticheat"})
```

### Multiple scripts
```lua
Bynew.Hook("Anticheat")
Bynew.Hook("KickHandler") 
Bynew.Hook("BanScript")
```

### Loop multiple
```lua
for _, name in {"Anticheat", "KickHandler", "BanScript"} do
    Bynew.Hook(name)
end
```

### Check destroyed count
```lua
local count = Bynew.Hook("Anticheat")
print(count .. " functions destroyed")
```

## Advanced

### Search by script name (explicit)
```lua
-- Same as simple hook but more specific
Bynew.Hook({ScriptName = "Anticheat"})
-- Finds any script with "Anticheat" in the name
```

### Search by path
```lua
Bynew.Hook({Path = "Workspace.Scripts.AC"})
```

### Search by function name
```lua
Bynew.Hook({FunctionName = "detectExploit"})
```

### Search by hash
```lua
Bynew.Hook({Hash = "193f276e993be040fa..."})
```

### Search by constants
```lua
Bynew.Hook({Constants = {"banned", "kicked"}})
```

### Search by variables
```lua
Bynew.Hook({Upvalues = {"player", "character"}})
```

### Combine filters
```lua
Bynew.Hook({
    ScriptName = "AC",
    Constants = {"speed", "fly"}
})
```

## Restore

```lua
Bynew.RestoreHooks()
```

## Full Example

```lua
local Bynew = loadstring(game:HttpGet("https://raw.githubusercontent.com/noctryxzen/Bypasser/refs/heads/main/BModule.luau"))()

-- Break anticheat
Bynew.Hook("Anticheat")

-- Your code here
wait(5)

-- Restore if needed
Bynew.RestoreHooks()
```

## How It Works

Finds functions in target scripts and destroys their internals.

**Example 1: Speed check becomes useless**
```lua
-- Before Bynew
function checkSpeed()
    if player.Speed > 16 then
        player:Kick("Speed hacking")
    end
end

-- After Bynew.Hook("Anticheat")
function checkSpeed()
    if player.Speed > 0 then  -- 16 → 0, always true now
        player:Kick("")  -- empty message, still kicks
    end
end
```

Wait, you'll still get kicked? Yes! That's why you need to hook the kick function too:

**Example 2: Hook the kick function**
```lua
-- Hook both anticheat AND kick handler
Bynew.Hook("Anticheat")  -- breaks detection
Bynew.Hook({FunctionName = "Kick"})  -- breaks kick itself
```

Or better, hook the entire kick script:
```lua
Bynew.Hook("KickHandler")  -- breaks all kick functions
```

**Example 3: Real scenario**
```lua
-- Game has these scripts:
-- - Anticheat (detects exploits)
-- - KickModule (handles kicks)
-- - BanHandler (handles bans)

-- Destroy all of them
Bynew.Hook("Anticheat")
Bynew.Hook("KickModule")
Bynew.Hook("BanHandler")

-- Now you're safe from detection, kicks, and bans
```

**What actually happens:**
- All numbers become 0
- All text becomes ""
- All true/false become false
- All variables become nil
- Nested functions get same treatment

The functions still run but with broken data, making them harmless.
