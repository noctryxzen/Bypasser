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

## Find AntiCheats

```lua
-- Automatically finds all LocalScripts and ModuleScripts
local anticheats = Bynew.FindAC()

-- Searches in:
-- - ReplicatedFirst (and all descendants)
-- - Nil instances (parented to nil)

-- Warns each found script:
-- AntiCheat: ReplicatedFirst.AC.MainModule
-- AntiCheat: ReplicatedFirst.Security
-- AntiCheat: {Nil}.HiddenAC

-- Automatically copies to clipboard
-- Output format:
-- ReplicatedFirst.AC.MainModule
-- ReplicatedFirst.Security
-- {Nil}.HiddenAC
```

**Example usage:**
```lua
-- Find all anticheats
local acs = Bynew.FindAC()

-- Hook all found anticheats
for _, path in acs do
    Bynew.Hook({ScriptPath = path})
end
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
Bynew.Hook({ScriptPath = "Workspace.Scripts.AC"})
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

### Search by upvalues
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

### Custom callback
```lua
-- Instead of destroying, run custom code
Bynew.Hook("Anticheat", function(func)
    print("Found function:", debug.getinfo(func).name)
    -- Do whatever you want with the function
end)
```

## Replace Functions

```lua
-- Replace function behavior globally
Bynew.Replace("KickHandler", function()
    print("Kick blocked!")
end)
```

## Modify Functions

```lua
-- Wrap function with custom logic
Bynew.Modify("Anticheat", function(original)
    return function(...)
        print("Anticheat called")
        -- Don't call original to block it
        -- or: return original(...)
    end
end)
```

## Find Functions

```lua
-- Find without destroying
local funcs = Bynew.Find({ScriptName = "Anticheat"})
print("Found " .. #funcs .. " functions")

for _, func in funcs do
    local info = debug.getinfo(func)
    print(info.name, info.source)
end
```

## Restore

```lua
-- Restore all hooks
Bynew.Restore()

-- Restore specific script
Bynew.Restore("Anticheat")

-- Restore with options
Bynew.Restore({ScriptName = "Anticheat"})
```

## Clear Cache

```lua
-- Clear all hooks and cache
Bynew.Clear()
```

## Get Hooks

```lua
-- View all active hooks
local hooks = Bynew.GetHooks()

for func, entry in hooks do
    print("Active:", entry.Active)
    print("Script:", entry.Options.ScriptName)
end
```

## Full Example

```lua
local Bynew = loadstring(game:HttpGet("https://raw.githubusercontent.com/noctryxzen/Bypasser/refs/heads/main/BModule.luau"))()

-- Find all anticheats
local acs = Bynew.FindAC()

-- Hook all found anticheats
for _, path in acs do
    Bynew.Hook({ScriptPath = path})
end

-- Your code here
wait(5)

-- Restore if needed
Bynew.Restore()
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
    if player.Speed > 0 then  -- 16 → 0
        player:Kick("")  -- "Speed hacking" → ""
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

-- Find them automatically
Bynew.FindAC()

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

## API Reference

### Bynew.Hook(options, callback?)
Destroys or hooks functions matching criteria.

**Parameters:**
- `options` (string | HookOptions): Script name or search options
- `callback` (function, optional): Custom function to run instead of destroying

**Returns:** number - Count of hooked functions

**Examples:**
```lua
Bynew.Hook("Anticheat")
Bynew.Hook({ScriptName = "AC", Constants = {"kick"}})
Bynew.Hook("AC", function(func) print("Found:", func) end)
```

### Bynew.Replace(options, replacement)
Replaces function globally with new function.

**Parameters:**
- `options` (string | HookOptions): Script name or search options
- `replacement` (function): New function to use

**Returns:** number - Count of replaced functions

**Example:**
```lua
Bynew.Replace("KickHandler", function() print("blocked") end)
```

### Bynew.Modify(options, modifier)
Wraps function with custom logic.

**Parameters:**
- `options` (string | HookOptions): Script name or search options
- `modifier` (function): Function that receives original and returns new function

**Returns:** number - Count of modified functions

**Example:**
```lua
Bynew.Modify("AC", function(original)
    return function(...)
        print("AC called")
        -- return original(...)  -- call original
    end
end)
```

### Bynew.Find(options)
Finds functions without modifying them.

**Parameters:**
- `options` (string | HookOptions): Script name or search options

**Returns:** {function} - Array of found functions

**Example:**
```lua
local funcs = Bynew.Find({ScriptName = "AC"})
```

### Bynew.FindAC()
Finds all LocalScripts and ModuleScripts in ReplicatedFirst and nil.

**Returns:** {string} - Array of script paths

**Example:**
```lua
local acs = Bynew.FindAC()
for _, path in acs do
    print(path)
end
```

### Bynew.Restore(options?)
Restores hooked functions.

**Parameters:**
- `options` (string | HookOptions, optional): Script name or search options. If nil, restores all.

**Returns:** number - Count of restored functions

**Examples:**
```lua
Bynew.Restore()  -- restore all
Bynew.Restore("Anticheat")  -- restore specific
```

### Bynew.Clear()
Clears all hooks and cache.

**Example:**
```lua
Bynew.Clear()
```

### Bynew.GetHooks()
Gets all active hooks.

**Returns:** {[function]: HookEntry} - Dictionary of hooked functions

**Example:**
```lua
local hooks = Bynew.GetHooks()
```

## HookOptions Type

```lua
type HookOptions = {
    ScriptName: string?,      -- Script name to search
    ScriptPath: string?,      -- Full script path
    FunctionName: string?,    -- Function name
    Constants: {any}?,        -- Constants in function
    Upvalues: {string}?,      -- Upvalue names
    Hash: string?,            -- Function hash
    Callback: function?       -- Custom callback
}
```

## Executor Support

Bynew automatically detects and warns about missing executor features:

- `getgc` / `filtergc` - Required for Hook/Replace/Modify/Find
- `hookfunction` - Required for Replace/Modify
- `restorefunction` - Required for Restore
- `getnilinstances` - Optional for FindAC (nil scripts)
- `setclipboard` - Optional for FindAC (auto-copy)
- `clonefunction` - Optional (fallback available)

**Example warnings:**
```
[Solara] doesn't support: getgc or filtergc
[Wave] doesn't support: hookfunction
[Solara] doesn't support: getnilinstances
[Wave] doesn't support: setclipboard
```

## Notes

- Functions are cloned before modification for safety
- Cache system prevents duplicate processing
- All string comparisons are case-insensitive
- Supports nested function destruction
- Works with both LocalScript and ModuleScript
