local mod = ...

--------------------------------------------------------------------------
local COMP_ANTENNA = {
	TypeName = "COMP_ANTENNA",
	ParentType = "COMPONENT",
	Properties = {
		{ Name = "RotationSpeedX", Type = "float", Default = 0.5 },
		{ Name = "RotationSpeedY", Type = "float", Default = 1.0 },
		{ Name = "AngleRangeX", Type = "float[2]", Default = { -0.5, 0.3} },
	}
}

--------------------------------------------------------------------------
function COMP_ANTENNA:create()
	self._timer = 0
end

--------------------------------------------------------------------------
function COMP_ANTENNA:init()
	self._rotationX = self.AngleRangeX[1] + math.random() * (self.AngleRangeX[2] - self.AngleRangeX[1])
	self._rotationY = math.random() * math.pi
	self:chooseRandomSequence()
end

--------------------------------------------------------------------------
function COMP_ANTENNA:chooseRandomSequence()
	local rnd = math.random()
	self._reverse = (math.random() < 0.5)
	
	if rnd < 0.4 then
		self._timer = math.random() * 4
		self._sequence = "ROTATE_Y"
	elseif rnd < 0.7 then
		self._timer = math.random() * 2
		self._sequence = "ROTATE_X"
	else
		self._timer = math.random() * 6
		self._sequence = "WAIT"
	end
end

--------------------------------------------------------------------------
function COMP_ANTENNA:update()
	local dt = self:getLevel():getDeltaTime()
	self._timer = self._timer - dt
	
	if self._timer < 0 then
		self:chooseRandomSequence()
	end
	
	if self._reverse then
		dt = dt * -1
	end
	
	if self._sequence == "ROTATE_Y" then
		self._rotationY = self._rotationY + self.RotationSpeedY * dt
	elseif self._sequence == "ROTATE_X" then
		self._rotationX = self._rotationX + self.RotationSpeedX * dt
		self._rotationX = math.min(self._rotationX, self.AngleRangeX[2])
		self._rotationX = math.max(self._rotationX, self.AngleRangeX[1])
	elseif self._sequence == "WAIT" then
		-- nothing
	end
	
	self:getOwner():setRotationX(self._rotationX)
	self:getOwner():rotateY(self._rotationY)
end

--------------------------------------------------------------------------
mod:registerClass(COMP_ANTENNA)