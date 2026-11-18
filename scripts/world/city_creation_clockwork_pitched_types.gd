extends RefCounted
## Authored silhouettes keep the four existing clockwork prototype identities.
const P=preload("res://scripts/world/city_creation_roof_primitives.gd")
static func build(kind:String,slope:float,sides:Array,feature:bool)->Array:
	var parts:Array=[];P.box(parts,"ClockRoofPlinth",Vector3(1.8,.10,1.8),Vector3(0,.025,0),"stone")
	match kind:
		"sawtooth_atrium":saw(parts,slope,sides,feature)
		"clock_turret":clock(parts,slope,feature)
		"iron_conservatory":vault(parts,slope,sides)
		"guild_arcade":guild(parts,slope,sides)
	return parts
static func saw(parts:Array,slope:float,sides:Array,feature:bool)->void:
	var rise:=.6*slope
	var crest:=.11+rise
	for tooth in range(3):
		var z:float=-.9+tooth*.6;var end:=z+.6
		P.prism(parts,"SawtoothSlope",[Vector3(-.9,.11,z),Vector3(-.9,crest,end),Vector3(.9,crest,end),Vector3(.9,.11,z)],"slate")
		P.box(parts,"SawtoothFoldedRidge",Vector3(1.8,.045,.085),Vector3(0,crest+.006,end-.0425),"copper")
		if rise>.10:
			P.quad(parts,"SawtoothGlazing",Vector3(-.9,.11,end-.012),Vector3(.9,.11,end-.012),Vector3(.9,crest-.022,end-.012),Vector3(-.9,crest-.022,end-.012),"atrium_glass")
			for column:float in [-.60,0.,.60]:
				P.box(parts,"SawtoothMullion",Vector3(.032,rise,.028),Vector3(column,.11+rise*.5,end-.014),"iron")
			P.box(parts,"SawtoothSill",Vector3(1.8,.055,.07),Vector3(0,.125,end-.035),"iron")
		for side:float in [-1.,1.]:
			if Vector2(side,0) in sides:
				P.end_face(parts,"SawtoothEndCheek",[Vector3(side*.9,.075,z),Vector3(side*.9,.075,end),Vector3(side*.9,crest,end)],"atrium_brick")
				P.beam(parts,"SawtoothVerge",Vector3(side*.88,.117,z),Vector3(side*.88,crest+.007,end-.02),.04,"copper")
	if feature and rise>.10:
		var top:=crest+minf(rise,.36);var foot:=.11+rise*.20;var axis:=Vector3(-.32,0,0)
		P.cylinder(parts,"AtriumVentStack",.139,.127,top-foot,axis+Vector3.UP*((foot+top)*.5),"atrium_brick")
		P.cylinder(parts,"AtriumVentCollar",.15,.15,.05,axis+Vector3.UP*top,"copper")
		P.cylinder(parts,"AtriumVentThroat",.104,.104,.10,axis+Vector3.UP*(top+.065),"iron")
		P.cylinder(parts,"AtriumVentHood",.19,.065,.09,axis+Vector3.UP*(top+.15),"copper")
static func clock(parts:Array,slope:float,feature:bool)->void:
	var rise:=.9*slope;var peak:=.1+rise
	for side:float in [-1.,1.]:P.prism(parts,"CopperHipShoulder",[Vector3(side*.9,.10,-.9),Vector3(side*.9,.10,.9),Vector3(0,peak,.9),Vector3(0,peak,-.9)],"slate")
	for z:float in [-.9,.9]:P.end_face(parts,"ClockShoulderEnd",[Vector3(-.9,.1,z),Vector3(.9,.1,z),Vector3(0,peak,z)],"stone")
	if not feature:return
	var lift:=maxf(0.,rise-.42);var spire:=maxf(.04,.53*rise/.42)
	P.cylinder(parts,"OctagonalClockDrum",.59,.59,1.14,Vector3(0,.63+lift,0),"stone");P.cylinder(parts,"ClockCopperCornice",.66,.66,.10,Vector3(0,1.22+lift,0),"copper")
	P.cylinder(parts,"CopperClockSpire",.65,.65 if is_zero_approx(slope) else .06,spire,Vector3(0,1.255+lift+spire*.5,0),"copper");P.cylinder(parts,"ClockFinial",.035,.035,.20,Vector3(0,1.255+lift+spire+.075,0),"iron")
	preload("res://scripts/world/city_creation_clock_roof_dial.gd").build(parts,lift)
static func vault(parts:Array,slope:float,sides:Array)->void:
	var rise:=.86*slope
	for i in range(14):
		var a:=PI*i/14.;var b:=PI*(i+1)/14.;var p:=Vector2(cos(a)*.86,.22+sin(a)*rise);var q:=Vector2(cos(b)*.86,.22+sin(b)*rise)
		P.quad(parts,"BarrelGlazing",Vector3(p.x,p.y,-.9),Vector3(p.x,p.y,.9),Vector3(q.x,q.y,.9),Vector3(q.x,q.y,-.9),"glass",true)
		for z:float in [-.88,0.,.88]:P.beam(parts,"ConservatoryArch",Vector3(cos(a)*.88,.22+sin(a)*rise,z),Vector3(cos(b)*.88,.22+sin(b)*rise,z),.055,"iron")
		for z:float in [-.9,.9]:
			if Vector2(0,signf(z)) in sides:P.end_face(parts,"ConservatoryEndGlass",[Vector3(0,.22,z),Vector3(p.x,p.y,z),Vector3(q.x,q.y,z)],"glass")
	for x:float in [-.88,.88]:
		P.beam(parts,"ConservatoryCopperEave",Vector3(x,.10,-.9),Vector3(x,.10,.9),.075,"copper");P.beam(parts,"ConservatoryBase",Vector3(x,.10,-.9),Vector3(x,.24,-.9),.065,"iron")
	for x:float in [-.60,.60]:
		for z:float in [-.55,.55]:
			# Low vaults carry the retained pots on a real rooftop plinth.
			var roof:=.22+sqrt(1.-pow((absf(x)-.15)/.86,2.))*rise;var inside:=.22+sqrt(1.-pow((absf(x)+.18)/.86,2.))*rise;var lift:=roof-.08+.02 if inside<.69 else 0.
			if lift>0.:P.box(parts,"ConservatoryPotPlinth",Vector3(.32,.045,.32),Vector3(x,roof-.0025,z),"copper")
			P.cylinder(parts,"ConservatoryPot",.11,.15,.20,Vector3(x,.18+lift,z),"copper");P.crown(parts,"ConservatoryPlant",Vector3(x,.39+lift,z),Vector3(.18,.28,.18),"leaf")
static func guild(parts:Array,slope:float,sides:Array)->void:
	var peak:=.12+.9*slope
	P.prism(parts,"GuildGableLeft",[Vector3(-.9,.12,-.9),Vector3(-.9,.12,.9),Vector3(0,peak,.9),Vector3(0,peak,-.9)],"slate")
	P.prism(parts,"GuildGableRight",[Vector3(0,peak,-.9),Vector3(0,peak,.9),Vector3(.9,.12,.9),Vector3(.9,.12,-.9)],"slate")
	for side:Vector2 in sides:
		if absf(side.y)<.5:continue
		P.end_face(parts,"GuildStonePediment",[Vector3(-.9,.10,side.y*.9),Vector3(.9,.10,side.y*.9),Vector3(0,peak,side.y*.9)],"stone");P.beam(parts,"GuildCornice",Vector3(-.92,.12,side.y*.92),Vector3(.92,.12,side.y*.92),.10,"copper")
