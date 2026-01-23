--!strict

local GetService: (Instance, string) -> Instance = clonefunction(game.GetService)
local Reference: (Instance) -> Instance = cloneref or function(X: Instance): Instance return X end
local SType: (any) -> string = clonefunction(type)
local SPcall: ((...any) -> ...any, ...any) -> (boolean, ...any) = clonefunction(pcall)
local SPairs: <K, V>({[K]: V}) -> ((any, any) -> (any, any), any, any) = clonefunction(pairs)
local SToString: (any) -> string = clonefunction(tostring)
local SWarn: (string) -> () = clonefunction(warn)
local SFind: (string, string, number?, boolean?) -> (number?, number?) = clonefunction(string.find)

local Services: {[string]: Instance} = setmetatable({}, {
	__index = function(S: any, N: string): Instance
		S[N] = Reference(GetService(game, N))
		return S[N]
	end
})

local ExecutorName: string, ExecutorVersion: string = identifyexecutor()

type HookOptions = {
	ScriptName: string?,
	Path: string?,
	Constants: {any}?,
	Upvalues: {string}?,
	Hash: string?,
	FunctionName: string?
}

type BynewData = {
	Hooks: {[any]: {Original: any, Active: boolean}};
	Cache: {[string]: any};
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
	if not getgc then
		SWarn(`[{ExecutorName}] doesn't support: getgc`)
		return 0
	end
	
	local Find: HookOptions = SType(Target) == "string" and {ScriptName = Target} or Target
	local Destroyed: number = 0
	
	local ok: boolean, noo: any = SPcall(function(): ()
		local Gc: {any} = getgc(false)
		
		for I: number = 1, #Gc do
			local Func: any = Gc[I]
			
			if SType(Func) == "function" and islclosure and islclosure(Func) then
				local ok3: boolean, Info: any = SPcall(debug.getinfo, Func)
				
				if not ok3 or not Info then
					continue
				end
				
				local Found: boolean = false
				
				if Find.ScriptName and Info.source then
					local Source: string = SToString(Info.source)
					if SFind(Source, Find.ScriptName, 1, true) then
						Found = true
					end
				end
				
				if not Found and Find.Path and Info.source then
					local FullPath: string = SToString(Info.source)
					if SFind(FullPath, Find.Path, 1, true) then
						Found = true
					end
				end
				
				if not Found and Find.FunctionName and Info.name then
					if Info.name == Find.FunctionName then
						Found = true
					end
				end
				
				if not Found and Find.Hash and getfunctionhash then
					local ok5: boolean, FunctionHash: any = SPcall(getfunctionhash, Func)
					
					if ok5 and FunctionHash == Find.Hash then
						Found = true
					end
				end
				
				if not Found and Find.Constants and debug.getconstants then
					local ok6: boolean, Constants: any = SPcall(debug.getconstants, Func)
					
					if ok6 and Constants then
						for ConstantIndex: number = 1, #Constants do
							local Constant: any = Constants[ConstantIndex]
							
							for TargetIndex: number = 1, #Find.Constants do
								local TargetConstant: any = Find.Constants[TargetIndex]
								
								if Constant == TargetConstant then
									Found = true
									break
								end
							end
							
							if Found then break end
						end
					end
				end
				
				if not Found and Find.Upvalues and debug.getupvalues then
					local ok7: boolean, FunctionUpvalues: any = SPcall(debug.getupvalues, Func)
					
					if ok7 and FunctionUpvalues then
						for UpvalueName: any, UpvalueValue: any in SPairs(FunctionUpvalues) do
							for TargetIndex: number = 1, #Find.Upvalues do
								local TargetUpvalueName: string = Find.Upvalues[TargetIndex]
								
								if SType(UpvalueName) == "string" then
									if UpvalueName == TargetUpvalueName then
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
						local ok8: boolean, Constants: any = SPcall(debug.getconstants, Func)
						
						if ok8 and Constants then
							for ConstantIndex: number = 1, #Constants do
								local Constant: any = Constants[ConstantIndex]
								local ConstantType: string = SType(Constant)
								
								if ConstantType == "string" then
									SPcall(debug.setconstant, Func, ConstantIndex, "")
								elseif ConstantType == "number" then
									SPcall(debug.setconstant, Func, ConstantIndex, 0)
								elseif ConstantType == "boolean" then
									SPcall(debug.setconstant, Func, ConstantIndex, false)
								end
							end
						end
					end
					
					if debug.getupvalues and debug.setupvalue then
						local ok9: boolean, FunctionUpvalues: any = SPcall(debug.getupvalues, Func)
						
						if ok9 and FunctionUpvalues then
							for UpvalueName: any, UpvalueValue: any in SPairs(FunctionUpvalues) do
								SPcall(debug.setupvalue, Func, UpvalueName, nil)
							end
						end
					end
					
					if debug.getprotos then
						local ok10: boolean, Prototypes: any = SPcall(debug.getprotos, Func)
						
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
					
					if hookfunction then
						SPcall(hookfunction, Func, function(): ()
							return
						end)
					end
					
					Bynew.Hooks[Func] = {
						Original = Func,
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
