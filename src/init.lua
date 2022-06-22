local packages = script.Parent
local Fusion = require(packages:WaitForChild("coldfusion"))
local Maid = require(packages:WaitForChild("maid"))

local Construct = require(script:WaitForChild("Construct"))

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
	self._Maid:Destroy()
	for k, v in pairs(self) do
		self[k] = nil
	end
end

function Isotope:Import(stateOrVal, altValue)
	if type(stateOrVal) == "table" and stateOrVal.IsA and stateOrVal:IsA("State") then
		return stateOrVal
	elseif stateOrVal ~= nil then
		return self._Fuse.Value(stateOrVal)
	else
		return self._Fuse.Value(altValue)
	end
end

function Isotope:Construct()
	Construct(self)
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
	self._Fuse = Fusion.fuse(self._Maid)
	return self
end

return Isotope