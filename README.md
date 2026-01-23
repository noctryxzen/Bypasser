## Installation

```lua
local Bynew = loadstring(game:HttpGet("https://raw.githubusercontent.com/noctryxzen/Bynew/refs/heads/main/ByModule.luau"))()
```

## API Reference

### Bynew.Find(scriptName?)

Finds and lists anti-cheat scripts. Without parameters, it scans ReplicatedFirst and nil-parented instances for all LocalScripts and ModuleScripts. With a parameter, it searches the garbage collector for functions whose source contains the specified string.

**Parameters:**
- `scriptName` (string, optional) - Script name to filter by

**Returns:** `{string}` - Array of script paths

```lua
Bynew.Find()
Bynew.Find("AntiCheat")
```

---

### Bynew.Hook(options, callback?)

Hooks functions matching the criteria. Without a callback, it destroys the function by clearing all constants, upvalues, and nested functions. With a callback, you can execute custom logic on each matched function.

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

Searches the function's source path for this string. Case-insensitive.

```lua
Bynew.Hook({ScriptName = "AntiCheat"})
```

---

### FunctionName

Matches the function's name from debug.getinfo.

```lua
Bynew.Hook({FunctionName = "DetectExploit"})
```

---

### FunctionAddress

Matches the function's memory address from tostring(function).

```lua
Bynew.Hook({FunctionAddress = "0x9ee2e679783d026a"})
```

---

### FunctionHash

Matches the function's bytecode hash using getfunctionhash.

```lua
Bynew.Hook({FunctionHash = "df73abc9b265d4a457fc1859b4efc1734945a957ea45e5c943f3948c0b2fc933923a5eeb829fa6c87b3002ccba837496"})
```

---

### ScriptHash

Matches the script's bytecode hash using getscripthash.

```lua
Bynew.Hook({ScriptHash = "def456abc123"})
```

---

### Constants

Function must contain all specified constants in its bytecode. Strings are case-insensitive.

```lua
Bynew.Hook({Constants = {"Kicked", "Banned", true}})
```

---

### Upvalues

Function must have all specified upvalue names. Case-insensitive.

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
