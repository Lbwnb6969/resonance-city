extends "res://tools/check_creation_rotated_road_preview_live.gd"
## The previously failing default gesture; no Alt or synthetic direction override.
func motion(at:Vector2,alt:bool=false)->void:
	var event:=InputEventMouseMotion.new();event.device=92;event.position=screen(at);event.global_position=event.position;event.alt_pressed=alt;root.push_input(event,true);await process_frame
func button(at:Vector2,pressed:bool,index:int=MOUSE_BUTTON_LEFT)->void:
	var event:=InputEventMouseButton.new();event.device=92;event.position=screen(at);event.global_position=event.position;event.pressed=pressed;event.button_index=index;root.push_input(event,true);await process_frame
