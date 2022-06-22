-- constructs an OOP instance
local package = script.Parent
local packages = package.Parent
local maidConstructor = require(packages:WaitForChild("maid"))
local signalConstructor = require(packages:WaitForChild("signal"))

local attributeTypes = {
	string = true,
	boolean = true,
	number = true,
	UDim = true,
	UDim2 = true,
	BrickColor = true,
	Color3 = true,
	Vector2 = true,
	Vector3 = true,
	NumberSequence = true,
	ColorSequence = true,
	NumberRange = true,
	Rect = true,
}

local valueTypes = {
	boolean = "BoolValue",
	BrickColor = "BrickColorValue",
	CFrame = "CFrameValue",
	Color3 = "Color3Value",
	number = "NumberValue",
	Instance = "ObjectValue",
	Ray = "RayValue",
	string = "StringValue",
	Vector3 = "Vector3Value",
	["nil"] = "ObjectValue",
}

local metaTags = {
	__index = true,
	__newindex = true,
	__call = true,
	__concat = true,
	__unm = true,
	__add = true,
	__sub = true,
	__mul = true,
	__div = true,
	__mod = true,
	__pow = true,
	__tostring = true,
	__metatable = true,
	__eq = true,
	__lt = true,
	__le = true,
	__mode = true,
	__len = true,
}

function assembleObject(tabl)
	local object = {}
	local meta = getmetatable(tabl)
	if meta then
		meta = assembleObject(meta)
	end
	for k, v in pairs(getmetatable(tabl) or {}) do
		if not metaTags[k] then
			object[k] = v
		end
	end
	for k, v in pairs(tabl) do
		object[k] = v
	end
	return object
end

return function(object)
	local self = assembleObject(object)

	local Value = object._Fuse.Value
	local Computed = object._Fuse.Computed

	local maid = self._Maid
	assert(maid ~= nil, "No maid found")

	local _Instance
	if object.Instance ~= nil then
		if typeof(object.Instance) == "Instance" then
			_Instance = Value(object.Instance)
			maid:GiveTask(object.Instance.Destroying:Connect(function()
				_Instance:Set(nil)
				pcall(function()
					maid:Destroy()
				end)
			end))
		else
			_Instance = object.Instance
		end
	else
		_Instance = Computed(function()
			local inst = self:Build()
			self._Maid.Instance = inst
			return inst
		end)
	end

	local function setFunction(inst, key, value)
		if not inst then
			self._Maid["f_"..key] = nil
		end
		local bindableFunction = Instance.new("BindableFunction", inst)
		bindableFunction.Name = key
		self._Maid["f_"..key] = bindableFunction
		bindableFunction.OnInvoke = function(...)
			return value(self, ...)
		end
	end

	local function setEvent(inst, key, value)
		if not inst then
			self._Maid["f_"..key] = nil
			self._Maid["f_event_"..key] = nil
		end
		local bindableEvent = Instance.new("BindableEvent", inst)
		bindableEvent.Name = key
		self._Maid["f_"..key] = bindableEvent
		self._Maid["f_event_"..key] = value:Connect(function(...)
			bindableEvent:Fire(...)
		end)
	end

	local function valueContainer(inst, key, value)
		local valMaid = maidConstructor.new()
		local signal = signalConstructor.new()
		
		local readFromStateEnabled = true
		local writeToStateEnabled = value:IsA("Value")

		return {
			_Maid = valMaid,
			signal = signal,
			Destroy = function(s)
				valMaid:Destroy()
			end,
			Build = Computed(value, function(val)
				if not readFromStateEnabled then return end

				local typ = typeof(val)
				local isAttribute = attributeTypes[typ]
				local isObject = valueTypes[typ]

				if isAttribute then
					valMaid.ObjectChanged = nil
					valMaid.Object = nil
					inst:SetAttribute(key, val)
					if writeToStateEnabled then
						valMaid.AttributeChanged = inst:GetAttributeChangedSignal(key):Connect(function()
							signal:Fire(inst:GetAttribute(key))
						end)
					end
				elseif isObject then
					valMaid.AttributeChanged = nil
					inst:SetAttribute(key, nil)
					if not valMaid.Object or valMaid.Object.ClassName ~= isObject then
						valMaid.Object = Instance.new(isObject, inst)
						valMaid.Object.Name = key
					end
					if typeof(val) == "CFrame" then
						valMaid.Object:SetAttribute("Position", val.Position)
						valMaid.Object:SetAttribute("XVector", val.XVector)
						valMaid.Object:SetAttribute("YVector", val.YVector)
						valMaid.Object:SetAttribute("ZVector", val.ZVector)
					end
					valMaid.Object.Value = val
					if writeToStateEnabled then
						valMaid.ObjectChanged = valMaid.Object:GetPropertyChangedSignal("Value"):Connect(function()
							signal:Fire(valMaid.Object.Value)
						end)
					end
				else
					valMaid.ObjectChanged = nil
					valMaid.AttributeChanged = nil
					valMaid.Object = nil
				end

				if writeToStateEnabled then
					valMaid.Signal = signal:Connect(function(v)
						value:Set(v)
					end)
				end
			end),
		}

	end

	local function setProperty(inst, key, value)
		-- print("Setting property", inst:GetFullName(), key, value)
		if not inst then
			-- print("Not inst")
			self._Maid["se_"..key] = nil
			self._Maid["s_"..key] = nil
			self._Maid["v_"..key] = nil
			return
		end
	
		local val = valueContainer(inst, key, value)
		self._Maid["vc_"..key] = val
		self._Maid["s_"..key] = value:Connect(function()
			if val and val.Build then
				val.Build:Get()
			end
		end)
	end

	for key, value in pairs(self) do
		if string.sub(key, 1, 1) ~= "_" then
			Computed(_Instance, function(inst)
				if typeof(value) == "function" then
					if key ~= "new" and key ~= "Construct" and key ~= "Destroy" then
						setFunction(inst, key, value)
					end
				elseif typeof(value) == "RBXScriptSignal" or (type(value) == "table" and value.ClassName == "Signal") then
					setEvent(inst, key, value)
				elseif typeof(value) == "table" and value.IsA and value:IsA("State") then
					if key ~= "Instance" then
						setProperty(inst, key, value)
					end
				end
			end)
		end
	end

	return _Instance
end