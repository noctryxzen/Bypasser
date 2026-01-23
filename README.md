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

Finds functions in target scripts and:
- Sets strings to `""`
- Sets numbers to `0`
- Sets booleans to `false`
- Clears all variables
- Does same for nested functions

Before:
```lua
function kick()
    if speed > 16 then
        player:Kick("Speed hacking")
    end
end
```

After:
```lua
function kick()
    if speed > 0 then
        player:Kick("")
    end
end
```

Function exists but does nothing.
