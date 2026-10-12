extends "res://tests/round214_community_followup_live.gd"
## Supplement the valid 14/16 run only with public-to-voice and community revisit.

func _run() -> void:
	output = "res://验证记录/round214_社区工作台/revisit_"+Time.get_datetime_string_from_system().replace(":","-")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DisplayServer.window_set_size(Vector2i(800,600))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	var rate := demo.clock.renderer.transport.sample_rate
	await until_frame(rate*5)
	await map_community("west-2")
	var panel = demo.community_workbench
	await press_button(panel.planning_button)
	await create_timer(0.3).timeout
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	await create_timer(0.7).timeout
	var public: Dictionary = {}
	for possible: Dictionary in First.opportunities(demo.shown_world)["public_candidates"]:
		if str(possible["community_id"]) == "west-2": public = possible; break
	for button: Button in demo.planning_guide.actions.get_children():
		if str(button.get_meta("anchor_kind","")) == "civic": await press_button(button); break
	await click_map(demo.point(Vector2(float(public["position"][0]),float(public["position"][1]))))
	var boundary: int = demo.planning_guide.next_action.get("expected_boundary_frame",-1)
	await until_frame(boundary+rate)
	if not demo.planning_guide.opened: await tap(KEY_P)
	await create_timer(0.3).timeout
	check(demo.planning_guide.next_action.get("state","") == "ready","actual_public_result_is_ready_at_the_heard_boundary")
	await tap(KEY_ENTER)
	await create_timer(0.7).timeout
	check(demo.menu.visible and demo._expression_context(),"actual_public_feedback_enters_voice_without_closing_its_open_panel")
	await press_button(demo.expression_choices["warm"])
	check(await playing(),"same_community_warm_audition_really_plays")
	await tap(KEY_ENTER)
	boundary = int(demo.pending_expression_choice.get("boundary_frame",-1))
	check(boundary > 0 and await until_frame(boundary+rate),"actual_warm_author_is_confirmed_and_heard")
	demo.model.submit({"kind":"mute","community":"west-2","enabled":true})
	demo.model.submit({"kind":"solo","community":"west-1"})
	await hear_controls()
	await tap(KEY_C)
	await create_timer(0.5).timeout
	for button: Button in panel.community_rows.get_children():
		if str(button.get_meta("community_id","")) == "west-2": await press_button(button); break
	await create_timer(0.5).timeout
	check(panel.state["count"] >= 9 and panel.state["public_sites"].size() == 1 and panel.state["authors"].size() == 1 and panel.state["reservations"].size() == 1,"same_community_revisit_shows_real_civic_author_and_land")
	await capture("00_同一街坊_亲建文化馆暖庭与留白")
	await press_button(panel.listen_button)
	await hear_controls()
	var root_id: String = panel.state["authors"][0]["root_id"]
	panel.scroll.ensure_control_visible(panel.author_rows.get_child(0))
	await process_frame
	await press_button(panel.author_rows.get_child(0))
	await hear_controls()
	check(not panel.opened and demo.menu.visible and demo.selected_id == root_id and demo.context.get("kind","") == "retune","community_author_action_opens_that_actual_root")
	check(demo.model.audible_score().get("listener_community","").is_empty(),"author_handoff_clears_prior_temporary_and_saved_community_solo")
	check(not bool(demo.model.audible_score().get("muted_communities",{}).get("west-2",false)),"explicit_author_handoff_hears_the_previously_muted_community")
	await capture("01_街坊作者入口回到真实暖庭")
	FileAccess.open(output+"live.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"author_root":root_id,"scope":"Only affected public-to-voice, actual workbench revisit, and author listening handoff. Preserved 14/16 run proves other entry/listening/scope behavior; no relabel or repeat of that run. Actual GPU/WASAPI, no human verdict."},"\t")+"\n")
	print("ROUND214_COMMUNITY_REVISIT ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures)," output=",output)
	demo.clock.stop_output()
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
