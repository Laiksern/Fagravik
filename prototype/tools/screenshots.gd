extends Node
## Tar skjermbilder av noen nøkkelscener til docs/bilder.
## Kjør (krever skjerm, f.eks. xvfb-run): godot --path prototype res://tools/screenshots.tscn

const OUT := "res://../docs/bilder/"

var main: Node2D


func _ready() -> void:
	main = load("res://main.tscn").instantiate()
	add_child(main)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(0.5)
	await _shot("prolog", "prolog", "P2", 1100, ["p_out", "p_hook", "p_swapped", "p_alarm"], "")
	await _shot("ankomst", "morgen", "A1", 1300, ["a_arrive"], "a_audun")
	await _shot("vertshuset", "morgen", "V1", 800, ["a_arrive", "met_tora"], "inn_scene")
	await _shot("klokken", "formiddag", "K3", 820, ["a_arrive", "inn_scene", "met_tora", "k3_intro"], "")
	await _shot("storbrua", "ettermiddag", "B1", 900, ["a_arrive", "inn_scene", "met_tora", "k3_intro", "bell_reported"], "")
	await _shot("natt", "natt", "V2", 700, ["a_arrive", "inn_scene", "night_bell", "n_start"], "")
	get_tree().quit()


func _shot(file: String, phase: String, room: String, x: float, flags: Array, dialogue: String) -> void:
	State.reset()
	for f in flags:
		State.apply("set:" + f)
	State.phase = phase
	main.hook_time = main.t - 10.0
	main.center_lbl.text = ""
	await main.go_room(room, x)
	if main.mode == "dialogue":
		main._end_dialogue()
	if dialogue != "":
		main.start_dialogue(dialogue)
		if main.dlg_choices.is_empty() and dialogue == "inn_scene":
			for i in 6:
				main._step()
	await _wait(0.6)
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + file + ".png"))
	if main.mode == "dialogue":
		main._end_dialogue()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout
