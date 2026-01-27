local Bynew = {}

local Svc = setmetatable({}, {
	__index = function(Self, Name)
		Self[Name] = game:GetService(Name);
		return Self[Name];
	end;
});

type HookOptions = {
	ScriptName: string?,
	FunctionName: string?,
	FunctionAddress: string?,
	FunctionHash: string?,
	Constants: {any}?,
	Upvalues: {string}?
}

function Bynew.Get(Argz)
	local Res = {};
	
	if Argz.Upvalues then
		local Ups = {};
		local Idx = 1;
		while true do
			local Nm, Val = debug.getupvalue(Argz.Upvalues, Idx);
			if not Nm then break end;
			Ups[Nm] = Val;
			Idx = Idx + 1;
		end;
		Res.Upvalues = Ups;
	end;
	
	if Argz.Constants then
		local Consts = {};
		local I = 1;
		while true do
			local V = debug.getconstant(Argz.Constants, I);
			if V == nil then break end;
			Consts[I] = V;
			I = I + 1;
		end;
		Res.Constants = Consts;
	end;
	
	if Argz.Info then
		Res.Info = debug.getinfo(Argz.Info);
	end;
	
	if Argz.GC then
		Res.GC = getgc(Argz.GC == "tables");
	end;
	
	if Argz.Scripts then
		Res.Scripts = getscripts();
	end;
	
	if Argz.Nil then
		Res.Nil = getnilinstances();
	end;
	
	if Argz.Name then
		local FnList = {};
		for _, Fn in getgc(false) do
			if type(Fn) == "function" and islclosure(Fn) and not isexecutorclosure(Fn) then
				local Inf = debug.getinfo(Fn);
				if Inf and Inf.name and Inf.name:lower() == Argz.Name:lower() then
					FnList[#FnList + 1] = Fn;
				end;
			end;
		end;
		Res.Functions = FnList;
	end;
	
	if Argz.Source then
		local Fns = {};
		local Srch = Argz.Source:lower();
		
		for _, F in getgc(false) do
			if type(F) ~= "function" then continue end;
			if not islclosure(F) or isexecutorclosure(F) then continue end;
			
			local Info = debug.getinfo(F);
			if Info and Info.source then
				local Src = tostring(Info.source):lower();
				if Src:find(Srch, 1, true) then
					Fns[#Fns + 1] = F;
				end;
			end;
		end;
		Res.Functions = Fns;
	end;
	
	if Argz.Constant then
		local Funcs = {};
		for _, Fn in getgc(false) do
			if type(Fn) == "function" and islclosure(Fn) and not isexecutorclosure(Fn) then
				local Cnsts = debug.getconstants(Fn);
				for _, C in Cnsts do
					if C == Argz.Constant or (type(C) == "string" and type(Argz.Constant) == "string" and C:lower() == Argz.Constant:lower()) then
						Funcs[#Funcs + 1] = Fn;
						break;
					end;
				end;
			end;
		end;
		Res.Functions = Funcs;
	end;
	
	if Argz.Upvalue then
		local Flist = {};
		for _, Func in getgc(false) do
			if type(Func) ~= "function" then continue end;
			if not islclosure(Func) then continue end;
			if isexecutorclosure(Func) then continue end;
			
			local Upvals = debug.getupvalues(Func);
			for N, _ in Upvals do
				if type(N) == "string" and N:lower() == Argz.Upvalue:lower() then
					Flist[#Flist + 1] = Func;
					break;
				end;
			end;
		end;
		Res.Functions = Flist;
	end;
	
	if Argz.Search then
		local Found = {};
		local Cache = {};
		local Cnt = 0;
		
		local Search = Argz.Search:lower();
		
		for _, F in getgc(false) do
			if type(F) == "function" and islclosure(F) and not isexecutorclosure(F) then
				local I = debug.getinfo(F);
				if I and I.source then
					local S = tostring(I.source):lower();
					if S:find(Search, 1, true) and not Cache[I.source] then
						Cnt = Cnt + 1;
						Found[Cnt] = I.source;
						Cache[I.source] = true;
					end;
				end;
			end;
		end;
		
		for Idx = 1, Cnt do
			warn(Found[Idx]);
		end;
		
		if setclipboard then
			setclipboard(table.concat(Found, "\n"));
		end;
		
		Res.Sources = Found;
	end;
	
	if Argz.All then
		local Found = {};
		local Set = {};
		local Count = 0;
		
		local Srcs = {};
		
		for _, Fn in getgc(false) do
			if type(Fn) == "function" then
				if not islclosure(Fn) then continue end;
				if isexecutorclosure(Fn) then continue end;
				
				local Info = debug.getinfo(Fn);
				if not Info then continue end;
				if not Info.source then continue end;
				
				local Src = Info.source;
				if Src:sub(1, 1) == "@" then
					Src = Src:sub(2);
				end;
				
				if not Srcs[Src] then
					Srcs[Src] = true;
				end;
			end;
		end;
		
		for _, Ch in Svc.ReplicatedFirst:GetDescendants() do
			if Ch:IsA("LocalScript") or Ch:IsA("ModuleScript") then
				local P = Ch:GetFullName();
				if not Srcs[P] then
					Srcs[P] = true;
				end;
			end;
		end;
		
		for _, Inst in getnilinstances() do
			if Inst:IsA("LocalScript") or Inst:IsA("ModuleScript") then
				local Path = Inst:GetFullName();
				Srcs[Path] = true;
			end;
		end;
		
		for P, _ in pairs(Srcs) do
			local Cat = "";
			local Nm = "";
			
			if P:find("ReplicatedFirst", 1, true) then
				Cat = "ReplicatedFirst.";
				local Pts = {};
				for Pt in P:gmatch("[^%.]+") do
					Pts[#Pts + 1] = Pt;
				end;
				Nm = Pts[#Pts] or P;
			else
				Cat = "Nil.";
				local Parts = {};
				for Part in P:gmatch("[^%.]+") do
					Parts[#Parts + 1] = Part;
				end;
				Nm = Parts[#Parts] or P;
			end;
			
			local Final = Cat .. Nm;
			if not Set[Final] then
				Count = Count + 1;
				Found[Count] = Final;
				Set[Final] = true;
			end;
		end;
		
		for I = 1, Count do
			warn(Found[I]);
		end;
		
		if setclipboard then
			setclipboard(table.concat(Found, "\n"));
		end;
		
		Res.Scripts = Found;
	end;
	
	return Res;
end;

function Bynew.Set(Argz)
	if Argz.Upvalue then
		local Idx = 1;
		while true do
			local Nm = debug.getupvalue(Argz.Upvalue.Func, Idx);
			if not Nm then break end;
			if Nm == Argz.Upvalue.Name then
				debug.setupvalue(Argz.Upvalue.Func, Idx, Argz.Upvalue.Value);
				return;
			end;
			Idx = Idx + 1;
		end;
	end;
	
	if Argz.Constant then
		debug.setconstant(Argz.Constant.Func, Argz.Constant.Index, Argz.Constant.Value);
	end;
end;

function Bynew.Hook(Argz: string | HookOptions, Cb)
	if not hookfunction then return 0 end;
	
	local Opts = type(Argz) == "string" and {ScriptName = Argz} or Argz;
	local Hooked = 0;
	
	for _, Fn in getgc(false) do
		if type(Fn) ~= "function" then continue end;
		if not islclosure(Fn) then continue end;
		if isexecutorclosure(Fn) then continue end;
		
		local Info = debug.getinfo(Fn);
		if not Info or not Info.source then continue end;
		
		local Match = true;
		
		if Opts.ScriptName then
			local Src = tostring(Info.source):lower();
			if not Src:find(Opts.ScriptName:lower(), 1, true) then
				Match = false;
			end;
		end;
		
		if Opts.FunctionName and Match then
			if not Info.name or Info.name:lower() ~= Opts.FunctionName:lower() then
				Match = false;
			end;
		end;
		
		if Opts.FunctionAddress and Match then
			local Addr = tostring(Fn);
			local Start, End = Addr:find("0x", 1, true);
			if Start then
				local FnAddr = Addr:sub(Start);
				if FnAddr:lower() ~= Opts.FunctionAddress:lower() then
					Match = false;
				end;
			else
				Match = false;
			end;
		end;
		
		if Opts.FunctionHash and Match then
			if getfunctionhash then
				local Hash = getfunctionhash(Fn);
				if Hash ~= Opts.FunctionHash then
					Match = false;
				end;
			else
				Match = false;
			end;
		end;
		
		if Opts.Constants and Match then
			local Cnsts = debug.getconstants(Fn);
			local Mtch = 0;
			for _, C in Cnsts do
				for _, Tgt in Opts.Constants do
					if C == Tgt or (type(C) == "string" and type(Tgt) == "string" and C:lower() == Tgt:lower()) then
						Mtch = Mtch + 1;
						break;
					end;
				end;
			end;
			if Mtch ~= #Opts.Constants then
				Match = false;
			end;
		end;
		
		if Opts.Upvalues and Match then
			local Ups = debug.getupvalues(Fn);
			local Mtch = 0;
			for N, _ in Ups do
				if type(N) == "string" then
					for _, TgtUp in Opts.Upvalues do
						if N:lower() == TgtUp:lower() then
							Mtch = Mtch + 1;
							break;
						end;
					end;
				end;
			end;
			if Mtch ~= #Opts.Upvalues then
				Match = false;
			end;
		end;
		
		if Match then
			hookfunction(Fn, Cb or function() end);
			Hooked = Hooked + 1;
		end;
	end;
	
	return Hooked;
end;

function Bynew.Replace(Argz: string | HookOptions, Cb)
	return Bynew.Hook(Argz, Cb);
end;

return Bynew;
