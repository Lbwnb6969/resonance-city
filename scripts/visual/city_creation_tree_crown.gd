extends RefCounted
const Spray=preload("res://scripts/visual/city_creation_leaf_spray.gd")
const Shoots=preload("res://scripts/visual/city_creation_leaf_shoots.gd")
## Preserve the measured top of every old authored-scale/seed variant.
const TOPS:={"olive":[2.8128805,2.8135345,2.8118298],"cypress":[3.51,3.51,3.51],"golden_tree":[2.9580762,2.9634233,2.9609222],"weeping_willow":[2.9842463,2.9842463,2.9842463],"shrub":[.8142289,.8438250,.8006845]}
static func append(f,leaves:Dictionary,wood:Dictionary,rng:RandomNumberGenerator,variant:int,kind:String)->void:
	match kind:
		"olive":olive(f,leaves,wood,rng,variant)
		"cypress":cypress(f,leaves,wood,rng,variant)
		"golden_tree":golden(f,leaves,wood,rng,variant)
		"weeping_willow":preload("res://scripts/visual/city_creation_weeping_willow.gd").append(f,leaves,wood,rng,variant)
		_:kind="shrub";shrub(f,leaves,wood,rng,variant)
	var top:=0.
	for data:Dictionary in [leaves,wood]:
		for point:Vector3 in data.vertices:top=maxf(top,point.y)
	var target:float=TOPS[kind][variant];var scale_y:=target/top
	for data:Dictionary in [leaves,wood]:
		for i in range(data.vertices.size()):
			data.vertices[i].y*=scale_y;data.normals[i]=(data.normals[i]*Vector3(1.,1./scale_y,1.)).normalized()
	for i in range(leaves.colors.size()):leaves.colors[i].a=clampf(leaves.vertices[i].y/target,0.,1.)
	for i in range(wood.colors.size()):wood.colors[i].a=0. if wood.vertices[i].y<=.04 else clampf(wood.vertices[i].y/target,0.,1.)
static func olive(f,leaves:Dictionary,wood:Dictionary,rng:RandomNumberGenerator,variant:int)->void:
	var fork:=Vector3((variant-1)*.11,1.02,.04);f._branch(wood,Vector3.ZERO,fork,.12,.063)
	for arm in range(5):
		var angle:=arm*2.39996+variant*.51;var radial:=Vector3(cos(angle),0,sin(angle));var side:=Vector3(-radial.z,0,radial.x)
		var elbow:=fork+radial*.40+Vector3(0,.28+rng.randf()*.15,0)
		var end:=fork+radial*(.70+rng.randf()*.12)+Vector3(0,.54+rng.randf()*.36,0)
		f._branch(wood,fork,elbow,.056,.032);f._branch(wood,elbow,end,.032,.014)
		for twig in range(2):
			var tip:=end+radial*.17+side*(-.20 if twig==0 else .22)+Vector3(0,.10 if twig==0 else .36,0)
			f._branch(wood,end,tip,.016,.004);Shoots.append(f,leaves,wood,tip,tip+Vector3(0,.035,0),Vector3(.40,.31,.37),rng,"olive",2.9,75)
static func cypress(f,leaves:Dictionary,wood:Dictionary,rng:RandomNumberGenerator,variant:int)->void:
	var tip:=Vector3((variant-1)*.065,3.23,.04);f._branch(wood,Vector3.ZERO,tip,.085,.008,"cypress")
	for tier in range(18):
		var t:=float(tier)/17.;var angle:=tier*2.39996+variant*.64;var radial:=Vector3(cos(angle),0,sin(angle))
		var width:=sin(pow(t,.72)*PI)*.20+.065;var start:=tip*(.19+t*.75);var end:=start+radial*width*.65+Vector3(0,.12,0)
		f._branch(wood,start,end,.024*(1.-t)+.005,.003,"cypress");Spray.append(f,leaves,end,Vector3(width*.70+.035,.27-t*.11,width*.65+.035),rng,"cypress",3.51,52)
	Spray.append(f,leaves,tip+Vector3(0,.10,0),Vector3(.075,.20,.075),rng,"cypress",3.51,48)
static func golden(f,leaves:Dictionary,wood:Dictionary,rng:RandomNumberGenerator,variant:int)->void:
	var fork:=Vector3((variant-1)*.07,1.16,.02);f._branch(wood,Vector3.ZERO,fork,.14,.068,"golden_tree")
	for arm in range(6):
		var angle:=arm*2.39996+variant*.42;var radial:=Vector3(cos(angle),0,sin(angle));var side:=Vector3(-radial.z,0,radial.x)
		var bend:=fork+radial*.47+Vector3(0,.30+rng.randf()*.15,0);var end:=fork+radial*(.86+rng.randf()*.15)+Vector3(0,.55+rng.randf()*.40,0)
		f._branch(wood,fork,bend,.058,.032,"golden_tree");f._branch(wood,bend,end,.032,.012,"golden_tree")
		for twig in range(2):
			var at:=end+side*(-.21 if twig==0 else .22)+radial*.15+Vector3(0,.09 if twig==0 else .31,0)
			f._branch(wood,end,at,.014,.004,"golden_tree");Shoots.append(f,leaves,wood,at,at,Vector3(.43,.33,.40),rng,"golden",3.1,78)
static func shrub(f,leaves:Dictionary,wood:Dictionary,rng:RandomNumberGenerator,variant:int)->void:
	for arm in range(7):
		var angle:=arm*2.39996+variant*.53;var at:=Vector3(cos(angle)*.31,.32+rng.randf()*.24,sin(angle)*.31)
		f._branch(wood,Vector3.ZERO,at,.024,.004,"olive");Spray.append(f,leaves,at,Vector3(.28,.23,.26),rng,"shrub",.86,48)
