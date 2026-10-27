--------------------------------------------------------------------------
polygon.createRectangle = function(_size, _offset)

	if _offset == nil then _offset = { 0, 0 } end
	local halfWidth = _size[1] * 0.5
	local halfHeight = _size[2] * 0.5
	return { 
		{ _offset[1] + halfWidth, _offset[2] + halfHeight },
		{ _offset[1] - halfWidth, _offset[2] + halfHeight },
		{ _offset[1] - halfWidth, _offset[2] - halfHeight },
		{ _offset[1] + halfWidth, _offset[2] - halfHeight },
	}
end

--------------------------------------------------------------------------
polygon.createCircle = function(_radius, _offset, _step)

	if _offset == nil then _offset = { 0, 0 } end
	if _step == nil then _step = 8 end
	
	_step = math.min(_step, 20)
	_step = math.max(_step, 3)
	
	local poly = {}
	
	for i=1,_step do
		local a = i * 2 * math.pi / _step
		table.insert(poly, { _offset[1] + math.cos(a) * _radius, _offset[2] + math.sin(a) * _radius })
	end
	
	return poly
end