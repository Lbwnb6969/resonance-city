--------------------------------------------------------------------------
math.randomf = function(...)
	local arg = { ... }
	if #arg == 0 then
		return math.random()
	elseif #arg == 1 then
		return math.random() * arg[1]
	else
		return arg[1] + math.random() * (arg[2] - arg[1])
	end
end