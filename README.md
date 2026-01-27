## Installation

```lua
local Bynew = loadstring(game:HttpGet("https://raw.githubusercontent.com/noctryxzen/Bynew/refs/heads/main/ByModule.luau"))()
```

## API Reference

### Bynew.Get(args)

Retrieves various types of data from functions, scripts, or the garbage collector.

**Parameters:**
- `args` (table) - Options table

**Returns:** `table` - Result containing requested data

**Examples:**

```lua
local result = Bynew.Get({Upvalues = someFunction})
local result = Bynew.Get({Constants = someFunction})
local result = Bynew.Get({Info = someFunction})
local result = Bynew.Get({GC = false})
local result = Bynew.Get({GC = "tables"})
local result = Bynew.Get({Scripts = true})
local result = Bynew.Get({Nil = true})
local result = Bynew.Get({Name = "KickPlayer"})
local result = Bynew.Get({Source = "AntiCheat"})
local result = Bynew.Get({Constant = "Kicked"})
local result = Bynew.Get({Upvalue = "Player"})
local result = Bynew.Get({Search = "AntiCheat"})
local result = Bynew.Get({All = true})
```

---

### Bynew.Set(args)

Modifies upvalues or constants in functions.

**Parameters:**
- `args` (table) - Options table

**Examples:**

```lua
Bynew.Set({Upvalue = {Func = someFunction, Name = "Health", Value = 100}})
Bynew.Set({Constant = {Func = someFunction, Index = 1, Value = "NewValue"}})
```

---

### Bynew.Hook(options, callback?)

Hooks functions matching the criteria.

**Parameters:**
- `options` (string | HookOptions) - Script name or search options
- `callback` (function, optional) - Custom handler function

**Returns:** `number` - Count of hooked functions

**Examples:**

```lua
Bynew.Hook("AntiCheat")
Bynew.Hook("AntiCheat", function(fn) print("hooked:", fn) end)
Bynew.Hook({ScriptName = "AntiCheat", Constants = {"kick"}})
Bynew.Hook({FunctionName = "KickPlayer"}, function() print("ezzz") end)
```

---

### Bynew.Replace(options, callback)

Replaces matched functions using hookfunction.

**Parameters:**
- `options` (string | HookOptions) - Script name or search options
- `callback` (function) - Replacement function

**Returns:** `number` - Count of replaced functions

**Examples:**

```lua
Bynew.Replace("KickHandler", function() print("ezzz") end)
Bynew.Replace({FunctionName = "KickHandler"}, function() print("ezzz") end)
Bynew.Replace({ScriptName = "AntiCheat", FunctionName = "KickHandler"}, function() print("ezzz") end)
```

---

## HookOptions

```lua
type HookOptions = {
	ScriptName: string?,
	FunctionName: string?,
	FunctionAddress: string?,
	FunctionHash: string?,
	Constants: {any}?,
	Upvalues: {string}?
}
```

**Examples:**

```lua
Bynew.Hook({ScriptName = "AntiCheat"})
Bynew.Hook({FunctionName = "KickPlayer"})
Bynew.Hook({FunctionAddress = "0x9ee2e679783d026a"})
Bynew.Hook({FunctionHash = "df73abc9b265d4a457fc1859b4efc173..."})
Bynew.Hook({Constants = {"Kicked", "Banned", true}})
Bynew.Hook({Upvalues = {"Player", "RemoteEvent"}})
Bynew.Hook({ScriptName = "AntiCheat", FunctionName = "KickPlayer", Constants = {"Kicked"}})
Bynew.Hook({Upvalues = {"Player", "Character"}, Constants = {100, "Walkspeed"}})
```
