extends "res://tools/check_creation_renaissance_roof_pitch_live.gd"
const CivicFixture=preload("res://tools/fixtures/city_creation_civic_fixture.gd")
var natural_id:="h1"
func open_editor()->void:
 demo.select_tool(4);demo.spatial_popover.open_for_house(natural_id);await settle();quiet();await ui_click(demo.spatial_popover.inspector.appearance_button);await settle()
func run()->void:
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
 if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
 var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
 demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();control=demo.get_meta("roof_pitch_control")
 var fixture:Dictionary=CivicFixture.build();var city:RefCounted=fixture.city;natural_id=str(fixture.court_ids[0]);city.set_house_era(natural_id,"pastoral")
 check(city.set_house_architecture(natural_id,"peristyle").ok,"actual courtyard and upper gallery qualify for peristyle through native API")
 await show(city,Vector2(-25,-21),"内院连柱保留自然屋盖");demo.zoom=24.;demo.pitch=.8;demo._update_camera();await settle();quiet();await open_editor()
 var before:Dictionary=demo.state.snapshot();var house_root:Node3D=demo.town.house_roots[natural_id]
 check(not demo.state.courtyard_plans().is_empty() and house_root.get_meta("arcade_faces",[]).any(func(f):return f.source=="peristyle_terrace"),"real closed court and inward upper gallery remain built")
 check(not control.row.is_visible_in_tree() and not control.handle.is_visible_in_tree(),"natural peristyle has no forced slope UI or pending adaptation message")
 check(demo.state.snapshot()==before,"opening appearance keeps courtyard author data exact");await capture("peristyle_original")
 for era:String in ["pastoral","renaissance"]:
  city=State.new();city.initialize_free();city.add_house(Vector2(-28,-20));city.set_house_era("h1",era);check(city.set_house_architecture("h1","rotunda").ok,"native round hall selection "+era);natural_id="h1"
  await show(city,Vector2(-28,-20),"圆厅保留穹顶 "+era);demo.zoom=12.;demo.pitch=.7;demo._update_camera();await settle();quiet();await open_editor();before=demo.state.snapshot();house_root=demo.town.house_roots.h1
  check((house_root.has_meta("ancient_rotunda_cella") if era=="pastoral" else not house_root.find_children("RenaissanceDome_*","Node3D",true,false).is_empty() and not house_root.get_meta("domes",[]).is_empty()),"actual original dome builder remains "+era)
  check(not control.row.is_visible_in_tree() and not control.handle.is_visible_in_tree() and demo.state.snapshot()==before,"original curved hall retains author data without forced slope UI "+era);await capture("rotunda_"+era)
 # A compatible dormant recipe still has a real escape route and native Undo.
 city=State.new();city.restore(before);city.houses[0].roof_pitch={"version":1,"degrees":45.};await show(city,Vector2(-28,-20),"旧坡度配方可恢复原顶");await settle();quiet();await open_editor();before=demo.state.snapshot()
 check(control.row.is_visible_in_tree() and not control.slider.editable and not control.reset.disabled and control.label.text=="保留原有屋盖","dormant legacy recipe keeps original reset without offering deformation")
 await ui_click(control.reset);await settle();quiet();await open_editor();check(not demo.state.houses[0].has("roof_pitch") and not control.row.is_visible_in_tree(),"native original button removes dormant recipe and hides unnecessary row")
 await key(KEY_Z,true);await settle();quiet();await open_editor();check(demo.state.houses==before.houses and control.row.is_visible_in_tree(),"native Undo restores exact dormant recipe and reset access")
 city=State.new();city.initialize_free();city.add_house(Vector2(-28,-20));await show(city,Vector2(-28,-20),"普通瓦顶仍可调坡");await settle();quiet();await open_editor();check(control.row.is_visible_in_tree() and control.slider.editable and control.handle.visible,"ordinary roof keeps existing creative pitch controls")
 facts.elapsed_seconds=(Time.get_ticks_msec()-began)/1000.;facts.source_sha256={"res://scripts/ui/city_creation_roof_pitch_control.gd":FileAccess.get_file_as_string("res://scripts/ui/city_creation_roof_pitch_control.gd").sha256_text()};await modern_report(personal)
