--!strict

local FunctionButCloned: <T>(T) -> T = clonefunction or function<T>(f: T): T return f end

local GetService: (Instance, string) -> Instance = FunctionButCloned(game.GetService)
local Reference: (Instance) -> Instance = cloneref or function(X: Instance): Instance return X end
local SType: (any) -> string = FunctionButCloned(type)
local SPcall: ((...any) -> ...any, ...any) -> (boolean, ...any) = FunctionButCloned(pcall)
local SPairs: <K, V>({[K]: V}) -> ((any, any) -> (any, any), any, any) = FunctionButCloned(pairs)
local SNext: <K, V>({[K]: V}, K?) -> (K?, V?) = FunctionButCloned(next)
local SRawget: <K, V>({[K]: V}, K) -> V = FunctionButCloned(rawget)
local SRawset: <K, V>({[K]: V}, K, V) -> () = FunctionButCloned(rawset)
local SWarn: (...any) -> () = FunctionButCloned(warn)
local SToString: (any) -> string = FunctionButCloned(tostring)
local SLower: (string) -> string = FunctionButCloned(string.lower)
local SFind: (string, string, number?, boolean?) -> (number?, number?) = FunctionButCloned(string.find)
local SSub: (string, number, number?) -> string = FunctionButCloned(string.sub)
local SLen: (string) -> number = FunctionButCloned(string.len)

local Services: {[string]: Instance} = setmetatable({}, {
	__index = function(S: any, N: string): Instance
		S[N] = Reference(GetService(game, N))
		return S[N]
	end
})

local ExecutorName: string, ExecutorVersion: string = identifyexecutor()

type HookOptions = {
	ScriptName: string?,
	ScriptPath: string?,
	FunctionName: string?,
	Constants: {any}?,
	Upvalues: {string}?,
	Hash: string?,
	Callback: ((fn: (...any) -> any) -> ())?
}

type HookEntry = {
	Original: (...any) -> any,
	Hooked: (...any) -> any,
	Active: boolean,
	Options: HookOptions
}

local Bynew = {
	Hooks = {} :: {[(...any) -> any]: HookEntry},
	Cache = {} :: {[string]: {(...any) -> any}}
}

local function MatchesConstant(A: any, B: any): boolean
	if SType(A) == "string" and SType(B) == "string" then
		return SLower(A) == SLower(B)
	end
	return A == B
end

local function CheckConstants(Func: (...any) -> any, TargetConstants: {any}): boolean
	if not debug.getconstants then return false end
	
	local ok: boolean, Constants: any = SPcall(debug.getconstants, Func)
	if not ok or not Constants then return false end
	
	local Matches: number = 0
	for i: number = 1, #Constants do
		local Const: any = Constants[i]
		for j: number = 1, #TargetConstants do
			if MatchesConstant(Const, TargetConstants[j]) then
				Matches += 1
				break
			end
		end
	end
	
	return Matches == #TargetConstants
end

local function CheckUpvalues(Func: (...any) -> any, TargetUpvalues: {string}): boolean
	if not debug.getupvalues then return false end
	
	local ok: boolean, Upvalues: any = SPcall(debug.getupvalues, Func)
	if not ok or not Upvalues then return false end
	
	local Matches: number = 0
	for Name: any, Value: any in SPairs(Upvalues) do
		if SType(Name) == "string" then
			local LowerName: string = SLower(Name)
			for i: number = 1, #TargetUpvalues do
				if LowerName == SLower(TargetUpvalues[i]) then
					Matches += 1
					break
				end
			end
		end
	end
	
	return Matches == #TargetUpvalues
end

local function CheckScriptName(Info: any, SearchName: string): boolean
	if not Info.source then return false end
	
	local Source: string = SLower(SToString(Info.source))
	local Search: string = SLower(SearchName)
	
	if SFind(Source, Search, 1, true) then
		return true
	end
	
	return false
end

local function CheckScriptPath(Info: any, SearchPath: string): boolean
	if not Info.source then return false end
	
	local FullPath: string = SLower(SToString(Info.source))
	local Search: string = SLower(SearchPath)
	
	if SFind(FullPath, Search, 1, true) then
		return true
	end
	
	return false
end

local function CheckFunctionName(Info: any, SearchName: string): boolean
	if not Info.name then return false end
	return SLower(Info.name) == SLower(SearchName)
end

local function CheckHash(Func: (...any) -> any, TargetHash: string): boolean
	if not getfunctionhash then return false end
	
	local ok: boolean, Hash: any = SPcall(getfunctionhash, Func)
	return ok and Hash == TargetHash
end

local function ShouldHook(Func: (...any) -> any, Options: HookOptions): boolean
	if not islclosure or not islclosure(Func) then return false end
	
	local ok: boolean, Info: any = SPcall(debug.getinfo, Func)
	if not ok or not Info then return false end
	
	if Options.ScriptName and not CheckScriptName(Info, Options.ScriptName) then
		return false
	end
	
	if Options.ScriptPath and not CheckScriptPath(Info, Options.ScriptPath) then
		return false
	end
	
	if Options.FunctionName and not CheckFunctionName(Info, Options.FunctionName) then
		return false
	end
	
	if Options.Hash and not CheckHash(Func, Options.Hash) then
		return false
	end
	
	if Options.Constants and not CheckConstants(Func, Options.Constants) then
		return false
	end
	
	if Options.Upvalues and not CheckUpvalues(Func, Options.Upvalues) then
		return false
	end
	
	return true
end

local function DisableFunction(Func: (...any) -> any): ()
	if debug.getconstants and debug.setconstant then
		local ok: boolean, Constants: any = SPcall(debug.getconstants, Func)
		if ok and Constants then
			for i: number = 1, #Constants do
				local Const: any = Constants[i]
				local ConstType: string = SType(Const)
				
				if ConstType == "string" then
					SPcall(debug.setconstant, Func, i, "")
				elseif ConstType == "number" then
					SPcall(debug.setconstant, Func, i, 0)
				elseif ConstType == "boolean" then
					SPcall(debug.setconstant, Func, i, false)
				end
			end
		end
	end
	
	if debug.getupvalues and debug.setupvalue then
		local ok: boolean, Upvalues: any = SPcall(debug.getupvalues, Func)
		if ok and Upvalues then
			for Name: any, Value: any in SPairs(Upvalues) do
				SPcall(debug.setupvalue, Func, Name, nil)
			end
		end
	end
	
	if debug.getprotos then
		local ok: boolean, Protos: any = SPcall(debug.getprotos, Func)
		if ok and Protos then
			for i: number = 1, #Protos do
				local Proto: any = Protos[i]
				if SType(Proto) == "function" then
					DisableFunction(Proto)
				end
			end
		end
	end
end

local function GetAllFunctions(): {any}
	if filtergc then
		local ok: boolean, Result: any = SPcall(filtergc, "function")
		if ok and Result then
			return SType(Result) == "table" and Result or {Result}
		end
	end
	
	if getgc then
		return getgc(false)
	end
	
	return {}
end

function Bynew.FindAC(): {string}
	local Found: {string} = {}
	
	local ok: boolean, RepFirst: any = SPcall(function(): Instance
		return Services.ReplicatedFirst
	end)
	
	if ok and RepFirst then
		for idx: number, Child: Instance in RepFirst:GetDescendants() do
			if Child:IsA("LocalScript") or Child:IsA("ModuleScript") then
				Found[#Found + 1] = Child:GetFullName()
			end
		end
	end
	
	if getnilinstances then
		local ok2: boolean, NilInsts: any = SPcall(getnilinstances)
		if ok2 and NilInsts then
			for idx: number, Inst: any in NilInsts do
				if SType(Inst) == "userdata" and typeof(Inst) == "Instance" then
					if Inst:IsA("LocalScript") or Inst:IsA("ModuleScript") then
						Found[#Found + 1] = `{Nil}.{Inst.Name}`
					end
				end
			end
		end
	else
		SWarn(`[{ExecutorName}] doesn't support: getnilinstances`)
	end
	
	if #Found == 0 then
		SWarn("No AntiCheats found")
		return {}
	end
	
	local Output: string = ""
	for i: number = 1, #Found do
		SWarn(`AntiCheat: {Found[i]}`)
		Output ..= Found[i]
		if i < #Found then
			Output ..= "\n"
		end
	end
	
	if setclipboard then
		setclipboard(Output)
		SWarn("AntiCheats copied to clipboard")
	else
		SWarn(`[{ExecutorName}] doesn't support: setclipboard`)
	end
	
	return Found
end

function Bynew.Hook(Options: string | HookOptions, Callback: ((fn: (...any) -> any) -> ())?): number
	if not (getgc or filtergc) then
		SWarn(`[{ExecutorName}] doesn't support: getgc or filtergc`)
		return 0
	end
	
	local HookOpts: HookOptions = SType(Options) == "string" and {ScriptName = Options} or Options
	
	if Callback then
		HookOpts.Callback = Callback
	end
	
	local CacheKey: string = ""
	if HookOpts.ScriptName then CacheKey ..= HookOpts.ScriptName end
	if HookOpts.ScriptPath then CacheKey ..= HookOpts.ScriptPath end
	if HookOpts.FunctionName then CacheKey ..= HookOpts.FunctionName end
	if HookOpts.Hash then CacheKey ..= HookOpts.Hash end
	
	if CacheKey ~= "" and Bynew.Cache[CacheKey] then
		local Hooked: number = 0
		for i: number = 1, #Bynew.Cache[CacheKey] do
			local Func: (...any) -> any = Bynew.Cache[CacheKey][i]
			if not Bynew.Hooks[Func] or not Bynew.Hooks[Func].Active then
				if HookOpts.Callback then
					HookOpts.Callback(Func)
				else
					DisableFunction(Func)
				end
				Hooked += 1
			end
		end
		return Hooked
	end
	
	local Functions: {any} = GetAllFunctions()
	local Hooked: number = 0
	local CachedFunctions: {(...any) -> any} = {}
	
	for i: number = 1, #Functions do
		local Func: any = Functions[i]
		
		if SType(Func) == "function" and ShouldHook(Func, HookOpts) then
			if not Bynew.Hooks[Func] or not Bynew.Hooks[Func].Active then
				local Original: (...any) -> any = FunctionButCloned(Func)
				
				if HookOpts.Callback then
					HookOpts.Callback(Func)
					
					Bynew.Hooks[Func] = {
						Original = Original,
						Hooked = Func,
						Active = true,
						Options = HookOpts
					}
				else
					DisableFunction(Func)
					
					Bynew.Hooks[Func] = {
						Original = Original,
						Hooked = Func,
						Active = true,
						Options = HookOpts
					}
				end
				
				CachedFunctions[#CachedFunctions + 1] = Func
				Hooked += 1
			end
		end
	end
	
	if CacheKey ~= "" and #CachedFunctions > 0 then
		Bynew.Cache[CacheKey] = CachedFunctions
	end
	
	return Hooked
end

function Bynew.Replace(Options: string | HookOptions, Replacement: (...any) -> any): number
	if not hookfunction then
		SWarn(`[{ExecutorName}] doesn't support: hookfunction`)
		return 0
	end
	
	local HookOpts: HookOptions = SType(Options) == "string" and {ScriptName = Options} or Options
	local Functions: {any} = GetAllFunctions()
	local Replaced: number = 0
	
	for i: number = 1, #Functions do
		local Func: any = Functions[i]
		
		if SType(Func) == "function" and ShouldHook(Func, HookOpts) then
			if not Bynew.Hooks[Func] or not Bynew.Hooks[Func].Active then
				local Original: (...any) -> any = hookfunction(Func, Replacement)
				
				Bynew.Hooks[Func] = {
					Original = Original,
					Hooked = Replacement,
					Active = true,
					Options = HookOpts
				}
				
				Replaced += 1
			end
		end
	end
	
	return Replaced
end

function Bynew.Modify(Options: string | HookOptions, Modifier: (fn: (...any) -> any) -> (...any) -> any): number
	if not hookfunction then
		SWarn(`[{ExecutorName}] doesn't support: hookfunction`)
		return 0
	end
	
	local HookOpts: HookOptions = SType(Options) == "string" and {ScriptName = Options} or Options
	local Functions: {any} = GetAllFunctions()
	local Modified: number = 0
	
	for i: number = 1, #Functions do
		local Func: any = Functions[i]
		
		if SType(Func) == "function" and ShouldHook(Func, HookOpts) then
			if not Bynew.Hooks[Func] or not Bynew.Hooks[Func].Active then
				local Original: (...any) -> any = FunctionButCloned(Func)
				local NewFunction: (...any) -> any = Modifier(Original)
				
				hookfunction(Func, NewFunction)
				
				Bynew.Hooks[Func] = {
					Original = Original,
					Hooked = NewFunction,
					Active = true,
					Options = HookOpts
				}
				
				Modified += 1
			end
		end
	end
	
	return Modified
end

function Bynew.Find(Options: string | HookOptions): {(...any) -> any}
	local HookOpts: HookOptions = SType(Options) == "string" and {ScriptName = Options} or Options
	local Functions: {any} = GetAllFunctions()
	local Found: {(...any) -> any} = {}
	
	for i: number = 1, #Functions do
		local Func: any = Functions[i]
		
		if SType(Func) == "function" and ShouldHook(Func, HookOpts) then
			Found[#Found + 1] = Func
		end
	end
	
	return Found
end

function Bynew.Restore(Options: string | HookOptions?): number
	if not restorefunction then
		SWarn(`[{ExecutorName}] doesn't support: restorefunction`)
		return 0
	end
	
	if not Options then
		local Restored: number = 0
		for Func: any, Entry: any in SPairs(Bynew.Hooks) do
			if Entry.Active then
				local ok: boolean = SPcall(restorefunction, Func)
				if ok then
					Entry.Active = false
					Restored += 1
				end
			end
		end
		return Restored
	end
	
	local HookOpts: HookOptions = SType(Options) == "string" and {ScriptName = Options} or Options
	local Restored: number = 0
	
	for Func: any, Entry: any in SPairs(Bynew.Hooks) do
		if Entry.Active and ShouldHook(Func, HookOpts) then
			local ok: boolean = SPcall(restorefunction, Func)
			if ok then
				Entry.Active = false
				Restored += 1
			end
		end
	end
	
	return Restored
end

function Bynew.Clear(): ()
	Bynew.Hooks = {}
	Bynew.Cache = {}
end

function Bynew.GetHooks(): {[(...any) -> any]: HookEntry}
	return Bynew.Hooks
end

return Bynew
