extends RefCounted
## Releasing the native window releases pointer gestures, never authored edits.
static func lost(demo:Node3D)->void:
 demo.strum_hold.cancel()
 if not demo.is_node_ready():return
 demo.orbiting=false;demo.panning=false;demo.camera_rig.navigation.dragging=false
 if demo.has_meta("batch_edit"):
  var batch=demo.get_meta("batch_edit")
  if batch.selection.dragging:batch.selection.dragging=false;batch.queue_redraw()
 if demo.has_meta("house_rotation_input"):
  var rotation=demo.get_meta("house_rotation_input")
  if not rotation.target.is_empty():rotation.finish(false)
 if demo.house_drawing or demo.road_drawing or demo.vegetation_drawing or demo.water_drawing or demo.district_drawing or demo.district_link_drawing or (demo.terrain_brush!=null and demo.terrain_brush.drawing):demo._cancel_draft()
