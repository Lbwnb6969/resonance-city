extends RefCounted
## Fixed-size clock faces move with the drum; roof slope never distorts them.
const P=preload("res://scripts/world/city_creation_roof_primitives.gd")
static func build(parts:Array,lift:float)->void:
	for angle:float in [0.,PI*.5,PI,PI*1.5]:
		var local:Array=[];var basis:=Basis(Vector3.UP,angle);var at:=Vector3(sin(angle)*.555,.89+lift,cos(angle)*.555)
		P.cylinder(local,"RomanClockDisc",.225,.225,.035,Vector3.ZERO,"stone",24,Basis(Vector3.RIGHT,PI*.5))
		for i in range(12):
			var theta:=TAU*i/12.;var center:=Vector3(sin(theta)*.186,cos(theta)*.186,.023);P.beam(local,"ClockHourMark",center*.95,Vector3(center.x*1.07,center.y*1.07,.023),.008,"copper")
		for row:Array in [["XII",Vector2(0,.143)],["III",Vector2(.15,0)],["VI",Vector2(0,-.15)],["IX",Vector2(-.15,0)]]:
			var text:String=row[0];var offset:Vector2=row[1]
			for index in range(text.length()):
				var x:float=offset.x+(index-float(text.length()-1)*.5)*.023;var y:float=offset.y;var strokes:Array=[]
				if text[index]=="I":strokes=[[Vector2(x,y-.022),Vector2(x,y+.022)]]
				elif text[index]=="V":strokes=[[Vector2(x-.009,y+.022),Vector2(x,y-.022)],[Vector2(x,y-.022),Vector2(x+.009,y+.022)]]
				else:strokes=[[Vector2(x-.009,y-.022),Vector2(x+.009,y+.022)],[Vector2(x-.009,y+.022),Vector2(x+.009,y-.022)]]
				for stroke:Array in strokes:P.beam(local,"ClockRomanLetter",Vector3(stroke[0].x,stroke[0].y,.027),Vector3(stroke[1].x,stroke[1].y,.027),.005,"iron")
		P.beam(local,"ClockShortHand",Vector3(0,0,.04),Vector3(.09,.08,.04),.013,"iron");P.beam(local,"ClockLongHand",Vector3(0,0,.044),Vector3(-.045,.14,.044),.009,"iron");P.cylinder(local,"ClockAxle",.02,.02,.025,Vector3(0,0,.04),"copper",8,Basis(Vector3.RIGHT,PI*.5))
		for part:Dictionary in local:
			var points:Array=[]
			for point:Vector3 in part.vertices:points.append(at+basis*point)
			P.face(parts,str(part.name),points,str(part.material))
