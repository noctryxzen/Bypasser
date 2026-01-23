--!strict

local GetService: (Instance, string) -> Instance = clonefunction(game.GetService)
local Reference: (Instance) -> Instance = cloneref or function(X: Instance): Instance return X end
local SType: (any) -> string = clonefunction(type)
local SPcall: ((...any) -> ...any, ...any) -> (boolean, ...any) = clonefunction(pcall)
local SPairs: <K, V>({[K]: V}) -> ((any, any) -> (any, any), any, any) = clonefunction(pairs)
local SRawget: <K, V>({[K]: V}, K) -> V = clonefunction(rawget)
local SRawset: <K, V>({[K]: V}, K, V) -> () = clonefunction(rawset)
local SWarn: (string) -> () = clonefunction(warn)
local SToString: (any) -> string = clonefunction(tostring)
local SLower: (string) -> string = clonefunction(string.lower)

local Services: {[string]: Instance} = setmetatable({}, {
	__index = function(S: any, N: string): Instance
		S[N] = Reference(GetService(game, N))
		return S[N]
	end
})

local ExecutorName: string, ExecutorVersion: string = identifyexecutor()

type BynewData = {
	Hooks: {[any]: {Original: any, Active: boolean}};
	Cache: {[string]: any};
}

type HookOptions = {
	ScriptName: string?,
	Path: string?,
	Constants: {any}?,
	Upvalues: {string}?,
	Hash: string?,
	FunctionName: string?
}

type BynewMethods = {
	Hook: (Target: string | HookOptions) -> number;
	RestoreHooks: () -> ();
}

type Bynew = BynewData & BynewMethods

local Bynew: Bynew = {} :: Bynew
Bynew.__index = Bynew
Bynew.Hooks = {}
Bynew.Cache = {}

function Bynew.Hook(Target: string | HookOptions): number
	if not getgc and not filtergc then
		SWarn(`[{ExecutorName}] doesn't support: getgc or filtergc`)
		return 0
	end
	
	local Find: HookOptions = SType(Target) == "string" and {ScriptName = Target} or Target
	local Destroyed: number = 0
	
	local ok: boolean, noo: any = SPcall(function(): ()
		local Functions: {any}
		
		if filtergc then
			local FilterOptions: {[string]: any} = {}
			local UseFilter: boolean = false
			
			if Find.FunctionName then
				FilterOptions.Name = Find.FunctionName
				UseFilter = true
			end
			
			if Find.ScriptName then
				FilterOptions.Source = Find.ScriptName
				UseFilter = true
			end
			
			if Find.Constants and #Find.Constants > 0 then
				FilterOptions.Constants = Find.Constants
				UseFilter = true
			end
			
			if Find.Upvalues and #Find.Upvalues > 0 then
				FilterOptions.Upvalues = Find.Upvalues
				UseFilter = true
			end
			
			if UseFilter then
				local ok2: boolean, Result: any = SPcall(filtergc, "function", FilterOptions)
				if ok2 and Result then
					Functions = SType(Result) == "table" and Result or {Result}
				else
					Functions = getgc and getgc(false) or {}
				end
			else
				Functions = getgc and getgc(false) or {}
			end
		else
			Functions = getgc(false)
		end
		
		for Index: number = 1, #Functions do
			local Function: any = Functions[Index]
			
			if SType(Function) == "function" and islclosure and islclosure(Function) then
				local ok3: boolean, Information: any = SPcall(debug.getinfo, Function)
				
				if not ok3 or not Information then
					continue
				end
				
				local Found: boolean = false
				
				if Find.ScriptName and Information.source then
					local Source: string = SLower(SToString(Information.source))
					local SearchName: string = SLower(Find.ScriptName)
					if string.find(Source, SearchName, 1, true) then
						Found = true
					end
				end
				
				if not Found and Find.Path and Information.source then
					local FullPath: string = SLower(SToString(Information.source))
					local SearchPath: string = SLower(Find.Path)
					
					if string.find(FullPath, SearchPath, 1, true) then
						Found = true
					end
					
					if not Found then
						for ServiceName: string, Service: Instance in SPairs(Services) do
							if string.find(SearchPath, SLower(ServiceName), 1, true) then
								local ok4: boolean = SPcall(function(): ()
									local Parts: {string} = string.split(Find.Path, ".")
									local Current: Instance = Service
									
									for PartIndex: number = 2, #Parts do
										local NextChild: Instance? = Current:FindFirstChild(Parts[PartIndex])
										
										if not NextChild then
											NextChild = Current:FindFirstChildOfClass(Parts[PartIndex])
										end
										
										if not NextChild then
											break
										end
										
										Current = NextChild
									end
									
									if Current and Current ~= Service then
										for Index2: number, Descendant: Instance in Current:GetDescendants() do
											if Descendant:IsA("LocalScript") or Descendant:IsA("Script") or Descendant:IsA("ModuleScript") then
												local DescendantName: string = SLower(Descendant.Name)
												local DescendantFullName: string = SLower(Descendant:GetFullName())
												
												if string.find(FullPath, DescendantName, 1, true) or string.find(FullPath, DescendantFullName, 1, true) then
													Found = true
													break
												end
											end
										end
									end
								end)
								
								if Found then break end
							end
						end
					end
				end
				
				if not Found and Find.FunctionName and Information.name then
					local FuncName: string = SLower(Information.name)
					local SearchFunc: string = SLower(Find.FunctionName)
					if FuncName == SearchFunc then
						Found = true
					end
				end
				
				if not Found and Find.Hash and getfunctionhash then
					local ok5: boolean, FunctionHash: any = SPcall(getfunctionhash, Function)
					
					if ok5 and FunctionHash == Find.Hash then
						Found = true
					end
				end
				
				if not Found and Find.Constants and debug.getconstants then
					local ok6: boolean, Constants: any = SPcall(debug.getconstants, Function)
					
					if ok6 and Constants then
						for ConstantIndex: number = 1, #Constants do
							local Constant: any = Constants[ConstantIndex]
							
							for TargetIndex: number = 1, #Find.Constants do
								local TargetConstant: any = Find.Constants[TargetIndex]
								
								if SType(Constant) == "string" and SType(TargetConstant) == "string" then
									if SLower(Constant) == SLower(TargetConstant) then
										Found = true
										break
									end
								elseif Constant == TargetConstant then
									Found = true
									break
								end
							end
							
							if Found then break end
						end
					end
				end
				
				if not Found and Find.Upvalues and debug.getupvalues then
					local ok7: boolean, FunctionUpvalues: any = SPcall(debug.getupvalues, Function)
					
					if ok7 and FunctionUpvalues then
						for UpvalueName: any, UpvalueValue: any in SPairs(FunctionUpvalues) do
							for TargetIndex: number = 1, #Find.Upvalues do
								local TargetUpvalueName: string = SLower(Find.Upvalues[TargetIndex])
								
								if SType(UpvalueName) == "string" then
									if SLower(UpvalueName) == TargetUpvalueName then
										Found = true
										break
									end
								elseif SType(UpvalueName) == "number" then
									local UpvalueNameAsString: string = SLower(SToString(UpvalueName))
									if UpvalueNameAsString == TargetUpvalueName then
										Found = true
										break
									end
								end
							end
							
							if Found then break end
						end
					end
				end
				
				if Found then
					if debug.getconstants and debug.setconstant then
						local ok8: boolean, Constants: any = SPcall(debug.getconstants, Function)
						
						if ok8 and Constants then
							for ConstantIndex: number = 1, #Constants do
								local Constant: any = Constants[ConstantIndex]
								local ConstantType: string = SType(Constant)
								
								if ConstantType == "string" then
									SPcall(debug.setconstant, Function, ConstantIndex, "")
								elseif ConstantType == "number" then
									SPcall(debug.setconstant, Function, ConstantIndex, 0)
								elseif ConstantType == "boolean" then
									SPcall(debug.setconstant, Function, ConstantIndex, false)
								end
							end
						end
					end
					
					if debug.getupvalues and debug.setupvalue then
						local ok9: boolean, FunctionUpvalues: any = SPcall(debug.getupvalues, Function)
						
						if ok9 and FunctionUpvalues then
							for UpvalueName: any, UpvalueValue: any in SPairs(FunctionUpvalues) do
								SPcall(debug.setupvalue, Function, UpvalueName, nil)
							end
						end
					end
					
					if debug.getprotos then
						local ok10: boolean, Prototypes: any = SPcall(debug.getprotos, Function)
						
						if ok10 and Prototypes then
							for ProtoIndex: number = 1, #Prototypes do
								local ProtoFunction: any = Prototypes[ProtoIndex]
								
								if SType(ProtoFunction) == "function" then
									if debug.getconstants and debug.setconstant then
										local ok11: boolean, ProtoConstants: any = SPcall(debug.getconstants, ProtoFunction)
										
										if ok11 and ProtoConstants then
											for ProtoConstIndex: number = 1, #ProtoConstants do
												local ProtoConst: any = ProtoConstants[ProtoConstIndex]
												local ProtoConstType: string = SType(ProtoConst)
												
												if ProtoConstType == "string" then
													SPcall(debug.setconstant, ProtoFunction, ProtoConstIndex, "")
												elseif ProtoConstType == "number" then
													SPcall(debug.setconstant, ProtoFunction, ProtoConstIndex, 0)
												elseif ProtoConstType == "boolean" then
													SPcall(debug.setconstant, ProtoFunction, ProtoConstIndex, false)
												end
											end
										end
									end
									
									if debug.getupvalues and debug.setupvalue then
										local ok12: boolean, ProtoUpvalues: any = SPcall(debug.getupvalues, ProtoFunction)
										
										if ok12 and ProtoUpvalues then
											for ProtoUpName: any, ProtoUpVal: any in SPairs(ProtoUpvalues) do
												SPcall(debug.setupvalue, ProtoFunction, ProtoUpName, nil)
											end
										end
									end
								end
							end
						end
					end
					
					Bynew.Hooks[Function] = {
						Original = Function,
						Active = true
					}
					
					Destroyed += 1
				end
			end
		end
	end)
	
	if not ok then
		SWarn(`[{ExecutorName}] hook failed: {noo}`)
	end
	
	return Destroyed
end

function Bynew.RestoreHooks(): ()
	if not restorefunction then
		SWarn(`[{ExecutorName}] doesn't support: restorefunction`)
		return
	end
	
	for Function: any, Entry: any in SPairs(Bynew.Hooks) do
		if Entry.Active then
			local ok: boolean = SPcall(restorefunction, Function)
			if ok then
				Entry.Active = false
			end
		end
	end
	
	Bynew.Hooks = {}
	Bynew.Cache = {}
end

return Bynew
