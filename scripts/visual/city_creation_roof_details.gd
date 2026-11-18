extends RefCounted
## Raised outlines precede window lights; chimney siting respects both geometries.
static func build(r,parent:Node3D,house:Dictionary,palette:Array)->void:
	if r.state.house_era(house)=="clockwork" and preload("res://scripts/world/city_creation_clockwork_roof_pitch.gd").authored(house):preload("res://scripts/visual/city_creation_modern_roof_details.gd").build(r,parent,house,palette,preload("res://scripts/world/city_creation_clockwork_roof_pitch.gd").for_house(r.state,house).details);return
	if r.state.house_era(house)=="modern_eco" and preload("res://scripts/world/city_creation_modern_roof_pitch.gd").authored(house):preload("res://scripts/visual/city_creation_modern_roof_details.gd").build(r,parent,house,palette);return
	preload("res://scripts/visual/city_creation_gable_trim.gd").build(r,parent,house,palette)
	preload("res://scripts/visual/city_creation_terracotta_skylights.gd").build(r,parent,house,palette)
	preload("res://scripts/visual/city_creation_chimney_details.gd").build(r,parent,house,palette)
