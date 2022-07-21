--!strict

local packages = script.Parent
local Fusion = require(packages.coldfusion)
local Maid = require(packages.maid)

export type State = Fusion.State
export type ValueState = Fusion.ValueState
export type Fuse = Fusion.Fuse

local Construct = require(script.Construct)

local Isotope = {}
Isotope.ClassName = "Isotope"
Isotope.__index = Isotope

function Isotope:Destroy()
	if self._isAlive ~= true then return end
	self._isAlive = false
	self._Maid:Destroy()
	for k, v in pairs(self) do
		self[k] = nil
	end
end

function Isotope:Import(stateOrVal, altValue): State
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

function Isotope:IsA(className):boolean
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

function Isotope.new()
	local self = setmetatable({}, Isotope)
	self._isAlive = true
	self._Maid = Maid.new()
	self._Fuse = Fusion.fuse(self._Maid)
	return self
end

export type Isotope = typeof(Isotope.new())

return Isotope