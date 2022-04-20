local packages = script.Parent
local Fusion = require(packages:WaitForChild("coldfusion"))
local Maid = require(packages:WaitForChild("maid"))

local Isotope = {}
Isotope.ClassName = "Isotope"
Isotope.__index = Isotope

--[[
	@startuml
	!theme crt-amber
	class Isotope {

	}
	@enduml
]]--
function Isotope:Destroy()
	-- if self.Instance and self.Instance.Get then
	-- 	local val = self.Instance:Get()
	-- 	if val then
	-- 		val:Destroy()
	-- 	end
	-- elseif self.Instance and self.Instance:IsA("Instance") then
	-- 	self.Instance:Destroy()
	-- end
	self._Maid:Destroy()
	for k, v in pairs(self) do
		if (typeof(v) == "table" and v.kind == "State") or typeof(v) == "Instance" then
			v:Destroy()
		end
		self[k] = nil
	end
end

function Isotope.import(stateOrVal, altValue)
	if type(stateOrVal) == "table" and stateOrVal.type == "state" then
		return stateOrVal
	elseif stateOrVal ~= nil then
		return Fusion.Value(stateOrVal)
	else
		return Fusion.Value(altValue)
	end
end

function Isotope:Construct()
	Fusion.construct(self)
end

function Isotope:IsA(className)
	if className == "Isotope" then return true end
	if self.ClassName == className then return true end
	local checkList = {}
	local function getClasses(tabl)
		local meta = getmetatable(tabl)
		if meta and checkList[meta] == nil then
			checkList[meta] = true
			if meta.ClassName == className then
				return true
			else
				return getClasses(meta)
			end
		end
		return false
	end
	return getClasses(self)
end

function Isotope.new(config)
	local self = setmetatable({}, Isotope)
	self._Maid = Maid.new()
	return self
end

return Isotope