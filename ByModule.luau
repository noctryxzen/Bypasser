--!strict

local FunctionButCloned: <T>(T) -> T = clonefunction or function<T>(f: T): T return f end

local GetService: (Instance, string) -> Instance = FunctionButCloned(game.GetService)
local Reference: (Instance) -> Instance = cloneref or function(X: Instance): Instance return X end
local SType: (any) -> string = FunctionButCloned(type)
local SPcall: ((...any) -> ...any, ...any) -> (boolean, ...any) = FunctionButCloned(pcall)
local SPairs: <K, V>({[K]: V}) -> ((any, any) -> (any, any), any, any) = FunctionButCloned(pairs)
local SWarn: (...any) -> () = FunctionButCloned(warn)
local SToString: (any) -> string = FunctionButCloned(tostring)
local SLower: (string) -> string = FunctionButCloned(string.lower)
local SFind: (string, string, number?, boolean?) -> (number?, number?) = FunctionButCloned(string.find)

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
	Upvalues: {string}?
}

type HookEntry = {
	Original: (...any) -> any,
	Active: boolean
}

local Bynew = {
	Hooks = {} :: {[(...any) -> any]: HookEntry}
}

local RobloxDefaultHashes: {[string]: boolean} = {
	["81328984bba601574d63022d2347a455da79960822ebb59790bf6c38c59e170978fd5103854c6acd255704ac0df347d2"] = true,
	["c4f4d244db0b53cf494481ebf60bddffbdd80db139e35db3a774ba5a42fa9f3712b0c102c4bb9fcf513d2c081faab8c3"] = true,
	["1d1c8d41ee0aa615f84e607ba63b43809c07cef225cb7087545e66cfc362d2590576870716767b5e784aaea098b9ab5c"] = true,
	["77a977fb946ee5368b96508f59d025c4f884422b6017f54896eee35a0bd9b3767a82568bb977f47c76fca4643600e854"] = true,
	["bcad9dbf421b74735c1505c93cbc6c085455111b86edb8570c1301b6b1ee43d7b253b7bd644fb54cbc9ee96ef539a9e1"] = true,
	["0f8b98ea57e2b140781f32a28c3b01e339e773be8a1f77441afb2de77cbab061889495e56b0bf8650b028637c91ebefd"] = true,
	["4825b9e3f5a6140abb5433b5075b2a8f7c644458ed48235cb31e8dc46e136544706db07563e4aa1d81a2b4f707fd6ef3"] = true,
	["d6cd02b52532a140ea6ac1434f9b353d4a961a3a05a0b6fbc2319c5febcc5a243c7211e21c0b7d4900f69bbe383588df"] = true,
	["ab3796c569247e2af63fa7b4cd741e78aaaaec5a5dd596d3b77362a440df4aa3667aed0a35b075a312dcb240a7c9f544"] = true,
	["f3ae01075f345ff5da078d9d4ea5d75e030c66d40cb131d4a55f8d758a2bae7da62dbd62e3879bf4ec4c1304317f5066"] = true,
	["1adab85dc81a41533edd955cc74b9306b045669d4e612e37401e7148e8dd679b87043fc3e5c9421822cfc53631dd6cad"] = true,
	["c3f47825b0092cfd6d3cd89cce5b2adb5ec8b422c0ee6aa7d74930039f234d73530069c50c3d8c61e467dfd84a629f84"] = true,
	["ea8c2e9e550e115a23af2b2fa67591ef99124b245e97943a31a5751b2f75ad38b5bc77af59389721b8a29e33c533003e"] = true,
	["40e3c730906b363c248fbdbce32ef9ed05e38aaade87a788f6365c829ea567cb9999966a58c5c8fb623bb8816a76e2bc"] = true,
	["fb5e8e110360e1b25d4cdb287faf91ef37c83f0a78b7285ea974da8537cbbd3ffbfcdd644aec2c63f39dec4b24591716"] = true,
	["e686d1c6aa65307fbd8c8dcbeff3e2016aef4445f8385d385fcfab038b94e0816a3628f52a111bc6a100de7b28ef7b33"] = true,
	["830607ce8f3966dbcea2b3f82d819f6c588f1ab5525223672fee3dbce8c8d1a3d004d3f6c8667d84916ef6fd82d9eba8"] = true,
	["f7f83168e400dc2d13b9e58eba092a8e2673d40307ba744ba2ef13fe597403996cf721f58ee4a73deccf08d4b8dd5a9d"] = true,
	["b2c2596193dd5fe73fe320e791e0b77cd86662f893f41563092a72a1bf43ed4ebccf0c75592ccaacb4b6a1162c2f6585"] = true,
	["8c86b26bfbffbf95d73e76ab55e66eba657d57134794a3913cbe59062ed1c79c46d7ecf2dc4668a88faba7f5a8d507af"] = true,
	["10fe0fe5bb5230192306e4c223ed9ccb9f5d3736d2ca48c4f3d0cead78ee63919cb4109ccb3e46b8e474de9b87f8821f"] = true,
	["63eee5614da92292210ed57c4fe5e8ef2ba8f0f9c86e30b6b22eda4457dd45c65d0e55abe01ce9b3535853af6780ed7d"] = true,
	["d7c251c4210c0eec86eb27bad72ed712f6947bcdf4fd7891bb4d85a69ed494921d0d57dbad9b525614417a0af63ecc90"] = true,
	["1cbdf3fd9b19a972ea8fe289dbdcb9d665a2cc67c15ef20367b4610f3611b2fe456a5982090e0e12b5096e8774398862"] = true,
	["49f79baa36e3906ae4f6cb796ebc6497b8f878e7ba60551601297300cb3f6cf034e9cd0311905a484fb61f23f6a8a89e"] = true,
	["588e9259ca6cc3026cdac738618420b8d382af0bb1c7d8bd1deacdfd89aeb501bcf820eedf047d9e6287c6c3f250928b"] = true,
	["840df5f72c7913c4216550c081bbc5716dd85644f70fc2c54f07c65f163ec32e95d0061ea2f81fcebc4cae5c87c8f017"] = true,
	["1d9f447832f225a974f5386130821dd7f41350a72499e06abfb0b2130748b7ad5d77eef1fc759b6dcfc465257101f50f"] = true,
	["85e9be224c20ff1828f70cbd73bd07459d243e062ba7ef9fcbe688e65fe80880f138047e6ada28fe145d86fbd83f7aa0"] = true,
	["9c2f3816d1dcbe4e380868a5064ab0c67ab6d00cbc97260543c1f7b30be114b4c67088182ac1b1f2a4838402f89f1d0a"] = true,
	["a79b55ac9bacba20b5e33eecc82cf7fb1db2f46b64a29b9590f49b63e93ead985ca6b04a1b6a1c0226e8fed66c0bb770"] = true,
	["27ffe51af8d63fc74da1fdec9b5bc3d4fb4893ba9a2a66d5d60ebd3b15b9cfdd3b9c41453754511b62b566b47b4722c3"] = true,
	["e30c8f9ffe258b799e4609ed8a72df8da6c58d00645df4092b711d5f214d5ee80f8167ebed14f38d71b1b814864e622e"] = true,
	["6509f53bdc27132e104b5b22e7e55ecc5fa604bbfa67addd80461d2b98efe892f8497957aace24645d1cae3cc8c2a273"] = true,
	["e80469f00730d1738267353826847f7dd3f780f18f0233baf44ef4f1d184f2544ac73d45671a7685540650bac581ca1d"] = true,
	["51766b32db8f0fa9f02131763c4428ac1745a45888b18bca88755c874ffe3922677752f93f72d53c76e8b4d8b0cea62b"] = true,
	["16ea1f99d58bd1a9a12167c3c69ef2dc8495778d64e82abc44a9e1b25f8d52a1aeee146ad9f572a71b0b9d2073d7853a"] = true,
	["6bc3e2de13b03277fceaab87a9b38e81864579ae3ee4fe8d333e96f48cb2a4402100878defeb531e9d4f5e7f553bcc02"] = true,
	["fc5a11cc0ef6b01fd7fce7436ef65aa5778d0035ece0c51e74af1d00e4fe54259f10caaac12872b9b5fa57110fe65c5c"] = true,
	["f28a24239fc50c6db94c97a763b2165ed41e361d04928973c7f8040f90ad343a1349dc94010b7f8ebbea0e571f53bfd4"] = true,
	["6630106c823568a7821dc345842e52f4b0bd1d417ee82d0949ad2fc9d8433c5f391daa5200933bb61f95229b7298c3a2"] = true,
	["ccb89e10fe751c1cca51d8b3790d0fae37c5620c8921b8a7544f0becf5e949f3ea392ec21a81768388faad5cd903195f"] = true,
	["54638529dc7c940b0ec53a94739d071789f5db29159bb60274b6dff29f3c8ff0ce8f842e9590f05bd6d4e033cf2bebff"] = true,
	["e0f72cfebaff1f7fe38abb47aca99f7f9365f7684093047fd2edcfa50ceed17c64db226c59175f6be5845a75c5a3fe5d"] = true
}

local function GetExecutorName(): string
	local Ok: boolean, Name: any = SPcall(identifyexecutor)
	return Ok and Name or "Unknown Executor"
end

local function GetFunctionAddress(Func: (...any) -> any): string?
	local Addr: string = SToString(Func)
	local Start: number?, End: number? = SFind(Addr, "0x", 1, true)
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
	
	local Ok: boolean, Constants: any = SPcall(debug.getconstants, Func)
	if not Ok or not Constants then return false end
	
	local Matches: number = 0
	for I: number = 1, #Constants do
		local Const: any = Constants[I]
		for J: number = 1, #TargetConstants do
			if MatchesConstant(Const, TargetConstants[J]) then
				Matches += 1
				break
			end
		end
	end
	
	return Matches == #TargetConstants
end

local function CheckUpvalues(Func: (...any) -> any, TargetUpvalues: {string}): boolean
	if not debug.getupvalues then return false end
	
	local Ok: boolean, Upvalues: any = SPcall(debug.getupvalues, Func)
	if not Ok or not Upvalues then return false end
	
	local Matches: number = 0
	for Name: any, Value: any in SPairs(Upvalues) do
		if SType(Name) == "string" then
			local LowerName: string = SLower(Name)
			for I: number = 1, #TargetUpvalues do
				if LowerName == SLower(TargetUpvalues[I]) then
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
	return SFind(Source, Search, 1, true) ~= nil
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
	
	local Ok: boolean, Hash: any = SPcall(getfunctionhash, Func)
	return Ok and Hash == TargetHash
end

local function CheckScriptHash(Func: (...any) -> any, TargetHash: string): boolean
	if not getscripthash or not getscripts then return false end
	
	local Ok: boolean, Info: any = SPcall(debug.getinfo, Func)
	if not Ok or not Info or not Info.source then return false end
	
	local Source: string = Info.source
	if Source:sub(1, 1) == "@" then
		Source = Source:sub(2)
	end
	
	local AllScripts: {LuaSourceContainer} = getscripts()
	for I: number = 1, #AllScripts do
		local Scr: LuaSourceContainer = AllScripts[I]
		if Scr:GetFullName() == Source or Scr.Name == Source then
			local Ok2: boolean, Hash: any = SPcall(getscripthash, Scr)
			return Ok2 and Hash == TargetHash
		end
	end
	
	return false
end

local function IsRobloxDefaultByHash(Scr: LuaSourceContainer): boolean
	if not getscripthash then return false end
	
	local Ok: boolean, Hash: any = SPcall(getscripthash, Scr)
	if not Ok or not Hash then return false end
	
	return RobloxDefaultHashes[Hash] == true
end

local function ShouldHook(Func: (...any) -> any, Options: HookOptions): boolean
	if not islclosure or not islclosure(Func) then return false end
	
	local Ok: boolean, Info: any = SPcall(debug.getinfo, Func)
	if not Ok or not Info then return false end
	
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
		local Ok: boolean, Constants: any = SPcall(debug.getconstants, Func)
		if Ok and Constants then
			for I: number = 1, #Constants do
				local Const: any = Constants[I]
				local ConstType: string = SType(Const)
				
				if ConstType == "string" then
					SPcall(debug.setconstant, Func, I, "")
				elseif ConstType == "number" then
					SPcall(debug.setconstant, Func, I, 0)
				elseif ConstType == "boolean" then
					SPcall(debug.setconstant, Func, I, false)
				end
			end
		end
	end
	
	if debug.getupvalues and debug.setupvalue then
		local Ok: boolean, Upvalues: any = SPcall(debug.getupvalues, Func)
		if Ok and Upvalues then
			for Name: any, Value: any in SPairs(Upvalues) do
				SPcall(debug.setupvalue, Func, Name, nil)
			end
		end
	end
end

local function GetAllFunctions(): {any}
	local Processed: {[any]: boolean} = {}
	local AllFunctions: {any} = {}
	local Count: number = 0
	
	if getgc then
		local Ok: boolean, GcFuncs: any = SPcall(getgc, false)
		if Ok and GcFuncs then
			for I: number = 1, #GcFuncs do
				local Func: any = GcFuncs[I]
				if SType(Func) == "function" and not Processed[Func] then
					if isexecutorclosure and isexecutorclosure(Func) then
						continue
					end
					
					if islclosure and not islclosure(Func) then
						continue
					end
					
					Count += 1
					AllFunctions[Count] = Func
					Processed[Func] = true
				end
			end
		end
	end
	
	local Reg: {any}? = nil
	if getreg then
		SPcall(function(): ()
			Reg = getreg()
		end)
	elseif getregistry then
		SPcall(function(): ()
			Reg = getregistry()
		end)
	end
	
	if Reg then
		for I: number = 1, #Reg do
			local Obj: any = Reg[I]
			if SType(Obj) == "function" and not Processed[Obj] then
				if isexecutorclosure and isexecutorclosure(Obj) then
					continue
				end
				
				if islclosure and not islclosure(Obj) then
					continue
				end
				
				Count += 1
				AllFunctions[Count] = Obj
				Processed[Obj] = true
			end
		end
	end
	
	return AllFunctions
end

function Bynew.Find(PossibleAC: string?): {string}
	local Found: {string} = {}
	local FoundSet: {[string]: boolean} = {}
	local Count: number = 0
	
	if PossibleAC then
		local SearchLower: string = SLower(PossibleAC)
		local Functions: {any} = GetAllFunctions()
		
		for I: number = 1, #Functions do
			local Func: any = Functions[I]
			if SType(Func) == "function" then
				local Ok: boolean, Info: any = SPcall(debug.getinfo, Func)
				if Ok and Info and Info.source then
					local Source: string = SLower(SToString(Info.source))
					if SFind(Source, SearchLower, 1, true) and not FoundSet[Info.source] then
						Count += 1
						Found[Count] = Info.source
						FoundSet[Info.source] = true
					end
				end
			end
		end
		
		if Count > 0 then
			for I: number = 1, Count do
				SWarn(Found[I])
			end
		end
		
		if setclipboard then
			setclipboard(table.concat(Found, "\n"))
		elseif toclipboard then
			toclipboard(table.concat(Found, "\n"))
		end
		
		return Found
	end
	
	local FoundSrc: {[string]: boolean} = {}
	local ScriptCache: {[string]: LuaSourceContainer} = {}
	
	if getscripts then
		SPcall(function(): ()
			local AllScripts: {LuaSourceContainer} = getscripts()
			for I: number = 1, #AllScripts do
				local Scr: LuaSourceContainer = AllScripts[I]
				if Scr:IsA("LocalScript") or Scr:IsA("ModuleScript") then
					if IsRobloxDefaultByHash(Scr) then
						continue
					end
					
					local FullPath: string = Scr:GetFullName()
					ScriptCache[FullPath] = Scr
					ScriptCache[Scr.Name] = Scr
				end
			end
		end)
	end
	
	local Functions: {any} = GetAllFunctions()
	
	for I: number = 1, #Functions do
		local F: any = Functions[I]
		if SType(F) == "function" then
			local Ok: boolean, Info: any = SPcall(debug.getinfo, F)
			if Ok and Info and Info.source then
				local SrcName: string = Info.source
				if SrcName:sub(1, 1) == "@" then
					SrcName = SrcName:sub(2)
				end
				
				local Scr: LuaSourceContainer? = ScriptCache[SrcName]
				if Scr then
					local FullPath: string = Scr:GetFullName()
					if not FoundSrc[FullPath] then
						FoundSrc[FullPath] = true
					end
				else
					if not FoundSrc[SrcName] then
						FoundSrc[SrcName] = true
					end
				end
			end
		end
	end
	
	local Ok: boolean, RepFirst: any = SPcall(function(): Instance
		return Services.ReplicatedFirst
	end)
	
	if Ok and RepFirst then
		for Idx: number, Child: Instance in RepFirst:GetDescendants() do
			if Child:IsA("LocalScript") or Child:IsA("ModuleScript") then
				if IsRobloxDefaultByHash(Child) then
					continue
				end
				
				local FullPath: string = Child:GetFullName()
				if not FoundSrc[FullPath] then
					FoundSrc[FullPath] = true
				end
			end
		end
	end
	
	if getnilinstances then
		local Ok2: boolean, NilInsts: any = SPcall(getnilinstances)
		if Ok2 and NilInsts then
			for Idx: number, Inst: any in NilInsts do
				if SType(Inst) == "userdata" and typeof(Inst) == "Instance" then
					if Inst:IsA("LocalScript") or Inst:IsA("ModuleScript") then
						if IsRobloxDefaultByHash(Inst) then
							continue
						end
						
						local FullPath: string = Inst:GetFullName()
						if not FoundSrc[FullPath] then
							FoundSrc[FullPath] = true
						end
					end
				end
			end
		end
	end
	
	for FullPath: string, _ in FoundSrc do
		local Category: string = ""
		local ScriptName: string = ""
		
		if SFind(FullPath, "ReplicatedFirst", 1, true) then
			Category = "ReplicatedFirst."
			local Parts: {string} = {}
			local Current: string = ""
			for I: number = 1, #FullPath do
				local Char: string = FullPath:sub(I, I)
				if Char == "." then
					if #Current > 0 then
						Parts[#Parts + 1] = Current
						Current = ""
					end
				else
					Current = Current .. Char
				end
			end
			if #Current > 0 then
				Parts[#Parts + 1] = Current
			end
			ScriptName = Parts[#Parts] or FullPath
		else
			Category = "Nil."
			local Parts: {string} = {}
			local Current: string = ""
			for I: number = 1, #FullPath do
				local Char: string = FullPath:sub(I, I)
				if Char == "." then
					if #Current > 0 then
						Parts[#Parts + 1] = Current
						Current = ""
					end
				else
					Current = Current .. Char
				end
			end
			if #Current > 0 then
				Parts[#Parts + 1] = Current
			end
			ScriptName = Parts[#Parts] or FullPath
		end
		
		local FinalName: string = Category .. ScriptName
		if not FoundSet[FinalName] then
			Count += 1
			Found[Count] = FinalName
			FoundSet[FinalName] = true
		end
	end
	
	if Count > 0 then
		for I: number = 1, Count do
			SWarn(Found[I])
		end
	end
	
	if setclipboard then
		setclipboard(table.concat(Found, "\n"))
	elseif toclipboard then
		toclipboard(table.concat(Found, "\n"))
	end
	
	return Found
end

function Bynew.Hook(Options: string | HookOptions, Callback: ((fn: (...any) -> any) -> ())?): number
	if not (getgc or getreg or getregistry) then
		SWarn(`[{GetExecutorName()}] doesn't support: getgc, getreg or getregistry`)
		return 0
	end
	
	local HookOpts: HookOptions = SType(Options) == "string" and {ScriptName = Options} or Options
	local Functions: {any} = GetAllFunctions()
	local Hooked: number = 0
	
	for I: number = 1, #Functions do
		local Func: any = Functions[I]
		
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
	
	for I: number = 1, #Functions do
		local Func: any = Functions[I]
		
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
