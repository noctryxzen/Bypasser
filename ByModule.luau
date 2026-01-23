lcal FunctionButCloned: <T>(T) -> T = clonefunction or function<T>(f: T): T return f end

local GetService: (Instance, string) -> Instance = FunctionButCloned(game.GetService)
local Reference: (Instance) -> Instance = cloneref or function(X: Instance): Instance return X end
local SType: (any) -> string = FunctionButCloned(type)
local SPcall: ((...any) -> ...any, ...any) -> (boolean, ...any) = FunctionButCloned(pcall)
local SPairs: <K, V>({[K]: V}) -> ((any, any) -> (any, any), any, any) = FunctionButCloned(pairs)
local SWarn: (...any) -> () = FunctionButCloned(warn)
local SToString: (any) -> string = FunctionButCloned(tostring)
local SLower: (string) -> string = FunctionButCloned(string.lower)

local Services: {[string]: Instance} = setmetatable({}, {
	__index = function(S: any, N: string): Instance
		S[N] = Reference(GetService(game, N))
		return S[N]
	end
})

type HookOptions = {
	ScriptName: string?,
	FunctionName: string?,
	FunctionAddress: string?,
	FunctionHash: string?,
	ScriptHash: string?,
	Constants: {any}?,
	Upvalues: {string}?,
	Service: string?
}

type HookEntry = {
	Original: (...any) -> any,
	Active: boolean
}

type FindResult = {
	Function: (...any) -> any,
	Info: {[string]: any},
	Script: string?,
	ScriptPath: string?,
	Constants: {any}?,
	Upvalues: {[string]: any}?
}

local Bynew = {
	Hooks = {} :: {[(...any) -> any]: HookEntry}
}

local function GetExecutorName(): string
	local ok: boolean, Name: any = SPcall(identifyexecutor)
	return ok and Name or "idk this executor"
end

local function GetScriptFromFunction(Func: (...any) -> any): LuaSourceContainer?
	if not getscripts then return nil end
	
	local ok: boolean, Info: any = SPcall(debug.getinfo, Func)
	if not ok or not Info or not Info.source then return nil end
	
	local Source: string = Info.source
	if Source:sub(1, 1) == "@" then
		Source = Source:sub(2)
	end
	
	local AllScripts: {LuaSourceContainer} = getscripts()
	for i: number = 1, #AllScripts do
		local Scr: LuaSourceContainer = AllScripts[i]
		if Scr:GetFullName() == Source or Scr.Name == Source then
			return Scr
		end
	end
	
	return nil
end

local function GetFunctionAddress(Func: (...any) -> any): string?
	local Addr: string = SToString(Func)
	local Start: number?, End: number? = Addr:find("0x", 1, true)
	if Start then
		return Addr:sub(Start)
	end
	return nil
end

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
	
	for j: number = 1, #TargetConstants do
		local Found: boolean = false
		for i: number = 1, #Constants do
			if MatchesConstant(Constants[i], TargetConstants[j]) then
				Found = true
				break
			end
		end
		if not Found then
			return false
		end
	end
	
	return true
end

local function CheckUpvalues(Func: (...any) -> any, TargetUpvalues: {string}): boolean
	if not debug.getupvalues then return false end
	
	local ok: boolean, Upvalues: any = SPcall(debug.getupvalues, Func)
	if not ok or not Upvalues then return false end
	
	for i: number = 1, #TargetUpvalues do
		local Found: boolean = false
		local SearchLower: string = SLower(TargetUpvalues[i])
		
		for Name: any, Value: any in SPairs(Upvalues) do
			if SType(Name) == "string" and SLower(Name):find(SearchLower, 1, true) then
				Found = true
				break
			end
		end
		
		if not Found then
			return false
		end
	end
	
	return true
end

local function CheckScriptName(Info: any, SearchName: string): boolean
	if not Info.source then return false end
	local Source: string = SLower(SToString(Info.source))
	local Search: string = SLower(SearchName)
	return Source:find(Search, 1, true) ~= nil
end

local function CheckFunctionName(Info: any, SearchName: string): boolean
	if not Info.name then return false end
	return SLower(Info.name) == SLower(SearchName)
end

local function CheckFunctionAddress(Func: (...any) -> any, TargetAddress: string): boolean
	local Addr: string? = GetFunctionAddress(Func)
	return Addr ~= nil and SLower(Addr) == SLower(TargetAddress)
end

local function CheckFunctionHash(Func: (...any) -> any, TargetHash: string): boolean
	if not getfunctionhash then return false end
	
	local ok: boolean, Hash: any = SPcall(getfunctionhash, Func)
	return ok and Hash == TargetHash
end

local function CheckScriptHash(Func: (...any) -> any, TargetHash: string): boolean
	if not getscripthash then return false end
	
	local Scr: LuaSourceContainer? = GetScriptFromFunction(Func)
	if not Scr then return false end
	
	local ok: boolean, Hash: any = SPcall(getscripthash, Scr)
	return ok and Hash == TargetHash
end

local function CheckService(Func: (...any) -> any, ServiceName: string): boolean
	local Scr: LuaSourceContainer? = GetScriptFromFunction(Func)
	if not Scr then return false end
	
	if SLower(ServiceName) == "nil" then
		if not getnilinstances then return false end
		
		local NilInsts: {Instance} = getnilinstances()
		for i: number = 1, #NilInsts do
			if NilInsts[i] == Scr then
				return true
			end
		end
		return false
	end
	
	local Current: Instance? = Scr.Parent
	while Current do
		if Current.Name == ServiceName or Current.ClassName == ServiceName then
			return true
		end
		Current = Current.Parent
	end
	
	return false
end

local function ShouldHook(Func: (...any) -> any, Options: HookOptions): boolean
	if not islclosure or not islclosure(Func) then return false end
	
	local ok: boolean, Info: any = SPcall(debug.getinfo, Func)
	if not ok or not Info then return false end
	
	if Options.Service and not CheckService(Func, Options.Service) then
		return false
	end
	
	if Options.ScriptName and not CheckScriptName(Info, Options.ScriptName) then
		return false
	end
	
	if Options.FunctionName and not CheckFunctionName(Info, Options.FunctionName) then
		return false
	end
	
	if Options.FunctionAddress and not CheckFunctionAddress(Func, Options.FunctionAddress) then
		return false
	end
	
	if Options.FunctionHash and not CheckFunctionHash(Func, Options.FunctionHash) then
		return false
	end
	
	if Options.ScriptHash and not CheckScriptHash(Func, Options.ScriptHash) then
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

local function GetScriptsFromService(ServiceName: string): {LuaSourceContainer}
	if not getscripts then return {} end
	
	local AllScripts: {LuaSourceContainer} = getscripts()
	local Results: {LuaSourceContainer} = {}
	
	for i: number = 1, #AllScripts do
		local Scr: LuaSourceContainer = AllScripts[i]
		local Current: Instance? = Scr.Parent
		
		while Current do
			if Current.Name == ServiceName or Current.ClassName == ServiceName then
				Results[#Results + 1] = Scr
				break
			end
			Current = Current.Parent
		end
	end
	
	return Results
end

local function GetNilScripts(): {LuaSourceContainer}
	if not getnilinstances then return {} end
	
	local NilInsts: {Instance} = getnilinstances()
	local Results: {LuaSourceContainer} = {}
	
	for i: number = 1, #NilInsts do
		local Inst: Instance = NilInsts[i]
		if Inst:IsA("LocalScript") or Inst:IsA("ModuleScript") then
			Results[#Results + 1] = Inst
		end
	end
	
	return Results
end

function Bynew.Find(Options: string | HookOptions?): {FindResult}
	local Results: {FindResult} = {}
	
	local HookOpts: HookOptions
	if Options == nil then
		HookOpts = {}
	elseif SType(Options) == "string" then
		HookOpts = {FunctionName = Options}
	else
		HookOpts = Options
	end
	
	local Functions: {any} = GetAllFunctions()
	
	for i: number = 1, #Functions do
		local Func: any = Functions[i]
		
		if SType(Func) == "function" then
			local Matches: boolean = false
			
			if next(HookOpts) == nil then
				Matches = true
			else
				Matches = ShouldHook(Func, HookOpts)
			end
			
			if Matches then
				local ok: boolean, Info: any = SPcall(debug.getinfo, Func)
				if ok and Info then
					local Scr: LuaSourceContainer? = GetScriptFromFunction(Func)
					
					local Entry: FindResult = {
						Function = Func,
						Info = Info,
						Script = nil,
						ScriptPath = nil,
						Constants = nil,
						Upvalues = nil
					}
					
					if Scr then
						Entry.Script = Scr.Name
						Entry.ScriptPath = Scr:GetFullName()
					elseif Info.source then
						Entry.Script = Info.source
					end
					
					if debug.getconstants then
						local ok2: boolean, Consts: any = SPcall(debug.getconstants, Func)
						if ok2 and Consts then
							Entry.Constants = Consts
						end
					end
					
					if debug.getupvalues then
						local ok3: boolean, Ups: any = SPcall(debug.getupvalues, Func)
						if ok3 and Ups then
							Entry.Upvalues = Ups
						end
					end
					
					Results[#Results + 1] = Entry
					
					if Entry.ScriptPath then
						SWarn(`Found: {Entry.ScriptPath}`)
					elseif Entry.Script then
						SWarn(`Found: {Entry.Script}`)
					else
						SWarn(`Found: {SToString(Func)}`)
					end
					
					if Entry.Constants and #Entry.Constants > 0 then
						local ConstPreview: {string} = {}
						for idx: number = 1, math.min(5, #Entry.Constants) do
							ConstPreview[#ConstPreview + 1] = SToString(Entry.Constants[idx])
						end
						SWarn(`  Constants: {table.concat(ConstPreview, ", ")}`)
					end
					
					if Entry.Upvalues and next(Entry.Upvalues) then
						local UpPreview: {string} = {}
						local Count: number = 0
						for Name: any, Val: any in SPairs(Entry.Upvalues) do
							if Count >= 5 then break end
							UpPreview[#UpPreview + 1] = SToString(Name)
							Count += 1
						end
						SWarn(`  Upvalues: {table.concat(UpPreview, ", ")}`)
					end
				end
			end
		end
	end
	
	local Output: {string} = {}
	for i: number = 1, #Results do
		local R: FindResult = Results[i]
		if R.ScriptPath then
			Output[#Output + 1] = R.ScriptPath
		elseif R.Script then
			Output[#Output + 1] = R.Script
		else
			Output[#Output + 1] = SToString(R.Function)
		end
	end
	
	if setclipboard then
		setclipboard(table.concat(Output, "\n"))
	elseif toclipboard then
		toclipboard(table.concat(Output, "\n"))
	end
	
	return Results
end

function Bynew.Hook(Options: string | HookOptions, Callback: ((fn: (...any) -> any) -> ())?): number
	if not (getgc or filtergc) then
		SWarn(`[{GetExecutorName()}] doesn't support: getgc or filtergc`)
		return 0
	end
	
	local HookOpts: HookOptions = SType(Options) == "string" and {ScriptName = Options} or Options
	local Functions: {any} = GetAllFunctions()
	local Hooked: number = 0
	
	for i: number = 1, #Functions do
		local Func: any = Functions[i]
		
		if SType(Func) == "function" and ShouldHook(Func, HookOpts) then
			if not Bynew.Hooks[Func] or not Bynew.Hooks[Func].Active then
				local Original: (...any) -> any = FunctionButCloned(Func)
				
				if Callback then
					Callback(Func)
				else
					DisableFunction(Func)
				end
				
				Bynew.Hooks[Func] = {
					Original = Original,
					Active = true
				}
				
				Hooked += 1
			end
		end
	end
	
	return Hooked
end

function Bynew.Replace(Options: string | HookOptions, Replacement: (...any) -> any): number
	if not hookfunction then
		SWarn(`[{GetExecutorName()}] doesn't support: hookfunction`)
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
					Active = true
				}
				
				Replaced += 1
			end
		end
	end
	
	return Replaced
end

function Bynew.Restore(Options: string | HookOptions?): number
	if not restorefunction then
		SWarn(`[{GetExecutorName()}] doesn't support: restorefunction`)
		return 0
	end
	
	if not Options then
		local Restored: number = 0
		for Func: any, Entry: any in SPairs(Bynew.Hooks) do
			if Entry.Active then
				SPcall(restorefunction, Func)
				Entry.Active = false
				Restored += 1
			end
		end
		return Restored
	end
	
	local HookOpts: HookOptions = SType(Options) == "string" and {ScriptName = Options} or Options
	local Restored: number = 0
	
	for Func: any, Entry: any in SPairs(Bynew.Hooks) do
		if Entry.Active and ShouldHook(Func, HookOpts) then
			SPcall(restorefunction, Func)
			Entry.Active = false
			Restored += 1
		end
	end
	
	return Restored
end

return Bynew
