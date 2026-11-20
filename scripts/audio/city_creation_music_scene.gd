extends RefCounted
## Scene tags are for isolated candidates and are read from signed manifests.
static func at(city:RefCounted,focus:Vector2,zoom:float)->String:
	if city.microclimate=="sun_shower":return "sun_shower"
	if city.houses.size()<=1:return "first_home"
	if zoom>28.:return ""
	if city.water_clearance(focus)<5.2:return "river"
	for house:Dictionary in city.houses:
		var origin:=Vector2(house.origin[0],house.origin[1])
		if focus.distance_squared_to(origin)<144.:return ""
	return "meadow"
