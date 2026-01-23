## Installation

```lua
local Bynew = loadstring(game:HttpGet("https://raw.githubusercontent.com/noctryxzen/Bynew/refs/heads/main/ByModule.luau"))()
```

## API Reference

### Bynew.Find(options?)

Finds and analyzes functions in the garbage collector. Without parameters, returns all functions. With a string parameter, searches for functions containing that string in their constants. With HookOptions, performs advanced filtering.

**Parameters:**
- `options` (string | HookOptions | nil, optional) - Search criteria

**Returns:** Array of objects with Function, Info, Script, Constants, and Upvalues

```lua
Bynew.Find()
Bynew.Find("string.rep")
Bynew.Find({Constants = {"GuiService", "InspectPlayer"}})
```

---

### Bynew.Hook(options, callback?)

Hooks functions matching the criteria. Without a callback, it destroys the function by clearing all constants and upvalues. With a callback, you can execute custom logic on each matched function.

**Parameters:**
- `options` (string | HookOptions) - Script name or search options
- `callback` (function, optional) - Custom handler function

**Returns:** `number` - Count of hooked functions

```lua
Bynew.Hook("AntiCheat")
Bynew.Hook("AC", function(fn) print("Hooked:", fn) end)
Bynew.Hook({ScriptName = "Security", Constants = {"kick"}})
```

---

### Bynew.Replace(options, replacement)

Replaces matched functions globally using hookfunction. The original function is completely replaced with your provided function.

**Parameters:**
- `options` (string | HookOptions) - Script name or search options
- `replacement` (function) - New function to replace with

**Returns:** `number` - Count of replaced functions

```lua
Bynew.Replace("KickHandler", function() print("Blocked") end)
```

---

### Bynew.Restore(options?)

Restores hooked or replaced functions to their original state. Without parameters, restores all hooks. With parameters, restores only matching hooks.

**Parameters:**
- `options` (string | HookOptions, optional) - Script name or search options

**Returns:** `number` - Count of restored functions

```lua
Bynew.Restore()
Bynew.Restore("AntiCheat")
```

---

## HookOptions

```lua
type HookOptions = {
	ScriptName: string?,
	FunctionName: string?,
	FunctionAddress: string?,
	FunctionHash: string?,
	ScriptHash: string?,
	Constants: {any}?,
	Upvalues: {string}?
}
```

---

### ScriptName

Searches the function's source path for this string. Case-insensitive, partial matching.

```lua
Bynew.Hook({ScriptName = "AntiCheat"})
```

---

### FunctionName

Matches the function's name from debug.getinfo. Case-insensitive, partial matching.

```lua
Bynew.Hook({FunctionName = "DetectExploit"})
```

---

### FunctionAddress

Matches the function's memory address from tostring(function).

```lua
Bynew.Hook({FunctionAddress = "0x123abc"})
```

---

### FunctionHash

Matches the function's bytecode hash using getfunctionhash.

```lua
Bynew.Hook({FunctionHash = "abc123def456"})
```

---

### ScriptHash

Matches the script's bytecode hash using getscripthash.

```lua
Bynew.Hook({ScriptHash = "def456abc123"})
```

---

### Constants

Function must contain all specified constants in its bytecode. Strings use partial matching and are case-insensitive.

```lua
Bynew.Hook({Constants = {"Kicked", "Banned", true}})
```

---

### Upvalues

Function must have all specified upvalue names. Partial matching, case-insensitive.

```lua
Bynew.Hook({Upvalues = {"Player", "RemoteEvent"}})
```

---

### Multiple Filters

Combine filters to target specific functions precisely.

```lua
Bynew.Hook({
	ScriptName = "AC",
	FunctionName = "Check",
	Constants = {"exploit", "detected"}
})

Bynew.Hook({
	Upvalues = {"Player", "Character"},
	Constants = {100, "Health"}
})
```
