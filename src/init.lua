--!strict

local packages = script.Parent
local Fusion = require(packages.coldfusion)
local Maid = require(packages.maid)

export type State = Fusion.State
export type ValueState = Fusion.ValueState
export type Fuse = Fusion.Fuse
export type Maid = Maid.Maid

local Construct = require(script.Construct)

export type Isotope = {
	ClassName: string,
	_isAlive: boolean?,
	_Maid: Maid?,
	_Fuse: Fuse?,
	IsA: (self: Isotope, className: string) -> boolean,
	Construct: (self: Isotope) -> nil,
	Import: (self: Isotope, default: State | ValueState | any?, alt: any?) -> nil,
	Destroy: ((self: Isotope) -> nil)?,
	new: () -> Isotope,
	[any]: any?,
	__index: Isotope,
}


local Isotope = {}
Isotope.ClassName = "Isotope"
Isotope.__index = Isotope

function Isotope.Destroy(self: Isotope)
	if self._isAlive ~= true then return end
	self._isAlive = false
	self._Maid:Destroy()
	for k, v in pairs(self) do
		self[k] = nil
	end
end

function Isotope.Import(self: Isotope, stateOrVal, altValue): State
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

function Isotope.IsA(self: Isotope, className):boolean
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

function Isotope.new(): Isotope
	local maid: Maid = Maid.new()
	local fuse: Fuse = Fusion.fuse(maid)
	local self: any = {
		_isAlive = true,
		_Maid = maid,
		_Fuse = fuse,
	}
	setmetatable(self, Isotope)
	return self
end

return Isotope