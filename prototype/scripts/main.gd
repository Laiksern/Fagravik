extends Node2D
## Gråboks-prototypen «Den første tonen».
##
## Alt innhold ligger i data/: rooms.gd (kart), world.gd (personer og
## gjenstander) og dialogues.gd (samtaler). Denne fila tegner rommene som
## enkle rektangler, flytter Ingrid, kjører dialoger og styrer overgangene.

const Rooms := preload("res://data/rooms.gd")
const Dialogues := preload("res://data/dialogues.gd")
const World := preload("res://data/world.gd")

const FLOOR_Y := 600.0
const SPEED := 340.0
const VIEW := Vector2(1280, 720)
const REACH := 24.0
const HUM_RANGE := 460.0
const NIGHT_BELL_DELAY := 7.0

const PHASE_TINT := {
	"prolog": Color(0.55, 0.58, 0.72),
	"morgen": Color(1.0, 0.96, 0.9),
	"formiddag": Color(1, 1, 1),
	"ettermiddag": Color(1.0, 0.92, 0.78),
	"kveld": Color(0.75, 0.68, 0.8),
	"natt": Color(0.42, 0.46, 0.66),
}
const SKY_BY_PHASE := {
	"morgen": Color(0.78, 0.84, 0.92),
	"formiddag": Color(0.62, 0.76, 0.9),
	"ettermiddag": Color(0.9, 0.78, 0.6),
	"kveld": Color(0.36, 0.3, 0.46),
	"natt": Color(0.06, 0.08, 0.15),
}

var rooms := {}
var dialogues := {}
var npcs := {}
var items := {}
var names := {}

var room_id := ""
var room := {}
var objects: Array = []
var player_x := 0.0
var facing := 1.0
var walk_t := 0.0
var focus := {}
var mode := "title" # title, play, dialogue, inventory, notebook, busy, end
var t := 0.0
var shake := 0.0
var humming := false
var night_timer := -1.0
var hook_time := -1.0
var edge_msg_cooldown := 0.0

# dialog
var dlg := {}
var dlg_steps: Array = []
var dlg_i := 0
var dlg_choices: Array = []
var dlg_sel := 0
var dlg_queue: Array = []
var pending_events: Array = []

# grensesnitt
var cam: Camera2D
var tint: CanvasModulate
var font: Font
var box: PanelContainer
var speaker_lbl: Label
var text_lbl: Label
var choice_box: VBoxContainer
var place_lbl: Label
var held_lbl: Label
var fade: ColorRect
var center_lbl: Label
var inv_panel: PanelContainer
var inv_list: VBoxContainer
var inv_desc: Label
var inv_sel := 0
var note_panel: PanelContainer
var note_edit: TextEdit


func _ready() -> void:
	rooms = Rooms.all()
	dialogues = Dialogues.all()
	npcs = World.npcs()
	items = World.items()
	names = World.names()
	font = ThemeDB.fallback_font
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	tint = CanvasModulate.new()
	add_child(tint)
	_build_ui()
	_show_title()
	Sfx.prewarm()


# ======================================================================= UI

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)

	place_lbl = _label(26, Color(1, 1, 1, 0.9))
	place_lbl.position = Vector2(32, 24)
	place_lbl.modulate.a = 0.0
	ui.add_child(place_lbl)

	held_lbl = _label(18, Color(1, 0.95, 0.8))
	held_lbl.position = Vector2(860, 24)
	held_lbl.size = Vector2(390, 30)
	held_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui.add_child(held_lbl)

	box = _panel(Vector2(80, 500), Vector2(1120, 196))
	ui.add_child(box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	box.add_child(vb)
	speaker_lbl = _label(20, Color(1, 0.85, 0.55))
	vb.add_child(speaker_lbl)
	text_lbl = _label(22, Color(0.95, 0.95, 0.92))
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_lbl.custom_minimum_size = Vector2(1080, 0)
	vb.add_child(text_lbl)
	choice_box = VBoxContainer.new()
	vb.add_child(choice_box)
	box.hide()

	inv_panel = _panel(Vector2(340, 140), Vector2(600, 380))
	ui.add_child(inv_panel)
	var ivb := VBoxContainer.new()
	ivb.add_theme_constant_override("separation", 8)
	inv_panel.add_child(ivb)
	ivb.add_child(_label(24, Color(1, 0.85, 0.55), "Det Ingrid bærer"))
	inv_list = VBoxContainer.new()
	ivb.add_child(inv_list)
	inv_desc = _label(18, Color(0.85, 0.85, 0.8))
	inv_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inv_desc.custom_minimum_size = Vector2(560, 0)
	ivb.add_child(inv_desc)
	ivb.add_child(_label(15, Color(0.6, 0.6, 0.6), "Enter: ta i hånden   ·   Esc: lukk"))
	inv_panel.hide()

	note_panel = _panel(Vector2(200, 60), Vector2(880, 600))
	ui.add_child(note_panel)
	var nvb := VBoxContainer.new()
	note_panel.add_child(nvb)
	nvb.add_child(_label(24, Color(1, 0.85, 0.55), "Notatbok"))
	note_edit = TextEdit.new()
	note_edit.custom_minimum_size = Vector2(840, 500)
	note_edit.add_theme_font_size_override("font_size", 20)
	note_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	nvb.add_child(note_edit)
	nvb.add_child(_label(15, Color(0.6, 0.6, 0.6), "Esc: lukk"))
	note_panel.hide()

	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
	fade.size = VIEW
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fade)

	center_lbl = _label(26, Color(0.95, 0.93, 0.88))
	center_lbl.size = VIEW
	center_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.add_child(center_lbl)


func _label(size: int, color: Color, text := "") -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _panel(pos: Vector2, size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = pos
	p.size = size
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.07, 0.09, 0.92)
	sb.border_color = Color(0.5, 0.42, 0.3)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(18)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _show_title() -> void:
	mode = "title"
	room = {}
	Sfx.ambient("")
	fade.color.a = 1.0
	center_lbl.text = "FAGRAVIK\nDen første tonen · gråboks\n\n\n" \
		+ "← →  /  A D   gå          ↑  /  W   gå gjennom dør\n" \
		+ "E   snakk / bruk          Q   undersøk          F   lytt med stemmehammeren\n" \
		+ "H   nynne          I   det Ingrid bærer          N   notatbok\n\n\n" \
		+ "Trykk Enter for å begynne"


func _show_end() -> void:
	mode = "end"
	Sfx.ambient("")
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 2.5)
	await tw.finished
	center_lbl.text = "Slutt på prototypen.\n\n\nHva tror du klokkelyden betydde?\n\n\n\nEnter: tilbake til start"


func _toast_place() -> void:
	place_lbl.text = room.get("name", "")
	place_lbl.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(place_lbl, "modulate:a", 0.0, 1.0)


func _update_held() -> void:
	held_lbl.text = "I hånden: " + items[State.held].name if State.held != "" else ""


# ================================================================ SPILLSTART

func _new_game() -> void:
	State.reset()
	note_edit.text = ""
	night_timer = -1.0
	hook_time = -1.0
	center_lbl.text = ""
	dlg_queue.clear()
	pending_events.clear()
	await go_room("P1", 600)


func go_room(id: String, x: float) -> void:
	mode = "busy"
	if fade.color.a < 1.0:
		var tw := create_tween()
		tw.tween_property(fade, "color:a", 1.0, 0.25)
		await tw.finished
	room_id = id
	room = rooms[id]
	player_x = x
	State.room = id
	refresh_objects()
	Sfx.ambient(room.get("amb", ""))
	_update_camera(0.0)
	_toast_place()
	var tw2 := create_tween()
	tw2.tween_property(fade, "color:a", 0.0, 0.3)
	await tw2.finished
	mode = "play"
	_enter_triggers()


func _enter_triggers() -> void:
	for tr in room.get("enter", []):
		if State.check(tr.get("if", "")):
			if tr.has("do"):
				_ops(tr["do"])
			if tr.has("d"):
				start_dialogue(tr["d"])
	if mode == "play":
		_flush_events()


func refresh_objects() -> void:
	objects.clear()
	for o in room.get("objects", []):
		if State.check(o.get("if", "")):
			objects.append(o)
	for id in npcs:
		var p := World.place(id, State)
		if p.size() == 2 and p[0] == room_id:
			objects.append({"id": id, "npc": true, "x": float(p[1]), "w": 40.0, "h": npcs[id].h, "name": speaker_name(id)})
	_update_focus()


func speaker_name(id: String) -> String:
	if id == "tora" and not State.f("met_tora"):
		return "Jenta"
	return names.get(id, id)


# ================================================================ HOVEDLØKKE

func _process(delta: float) -> void:
	t += delta
	edge_msg_cooldown = maxf(edge_msg_cooldown - delta, 0.0)
	if mode == "play":
		_move(delta)
		_check_zones()
		if night_timer > 0.0:
			night_timer -= delta
			if night_timer <= 0.0:
				_night_bell()
	if not room.is_empty():
		_update_camera(delta)
	tint.color = PHASE_TINT.get(State.phase, Color.WHITE) if not room.is_empty() else Color.WHITE
	queue_redraw()


func _move(delta: float) -> void:
	var dir := 0.0
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
		dir += 1.0
	if dir == 0.0:
		walk_t = 0.0
		return
	facing = dir
	walk_t += delta
	var w: float = room.w
	player_x += dir * SPEED * delta
	var lo: float = room.get("walk_min", 30.0)
	var hi: float = room.get("walk_max", w - 30.0)
	if player_x < lo:
		player_x = lo
		if room.has("left") and lo <= 30.0:
			_try_exit(room.left)
	elif player_x > hi:
		player_x = hi
		if room.has("right") and hi >= w - 30.0:
			_try_exit(room.right)
	_update_focus()


func _try_exit(exit: Dictionary) -> void:
	var locked = _lock_text(exit)
	if locked != null:
		if edge_msg_cooldown <= 0.0:
			edge_msg_cooldown = 3.0
			say("", locked)
		return
	go_room(exit.to, float(exit.x))


func _lock_text(exit: Dictionary):
	for l in exit.get("lock", []):
		if State.check(l.get("if", "")):
			return l.t
	return null


func _check_zones() -> void:
	for o in objects:
		if o.has("zone"):
			var z: Dictionary = o.zone
			if player_x >= z.x0 and player_x <= z.x1 and State.check(z.get("if", "")):
				run_action(z)
				return


func _update_focus() -> void:
	focus = {}
	var best_w := INF
	var best_d := INF
	for o in objects:
		if o.has("zone"):
			continue
		var d: float = absf(player_x - o.x)
		var w: float = o.get("w", 60.0)
		if d > w / 2.0 + REACH:
			continue
		if w < best_w or (w == best_w and d < best_d):
			focus = o
			best_w = w
			best_d = d


func _update_camera(delta: float) -> void:
	var w: float = room.w
	var cx: float
	if w <= VIEW.x:
		cx = w / 2.0
	else:
		cx = clampf(player_x, VIEW.x / 2.0, w - VIEW.x / 2.0)
	shake = maxf(shake - delta * 2.0, 0.0)
	cam.position = Vector2(cx, VIEW.y / 2.0) + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * 10.0


# ================================================================ INNDATA

func _input(event: InputEvent) -> void:
	# Notatboka sluker tastene, så Esc må fanges før den.
	if mode == "notebook" and event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		State.notebook = note_edit.text
		note_panel.hide()
		note_edit.release_focus()
		mode = "play"
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k: int = event.physical_keycode
	match mode:
		"title":
			if k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE:
				_new_game()
		"end":
			if k == KEY_ENTER or k == KEY_KP_ENTER:
				_show_title()
		"dialogue":
			_dialogue_key(k)
		"inventory":
			_inventory_key(k)
		"play":
			_play_key(k)
	if OS.is_debug_build() and mode in ["play", "title"]:
		_debug_key(k)


func _play_key(k: int) -> void:
	match k:
		KEY_E, KEY_ENTER, KEY_SPACE:
			interact()
		KEY_UP, KEY_W:
			if focus.has("door"):
				use_door(focus.door)
		KEY_Q:
			examine()
		KEY_F:
			listen()
		KEY_H:
			hum()
		KEY_I, KEY_TAB:
			open_inventory()
		KEY_N:
			if State.phase != "prolog":
				mode = "notebook"
				note_panel.show()
				note_edit.grab_focus()
		KEY_ESCAPE:
			State.held = ""
			_update_held()


# ================================================================ HANDLINGER

func interact() -> void:
	if focus.is_empty():
		return
	if State.held != "":
		_use_held()
		return
	if focus.get("npc", false):
		run_action(resolve(npcs[focus.id].get("talk")))
	elif focus.has("door"):
		use_door(focus.door)
	elif focus.has("use"):
		run_action(resolve(focus.use))
	elif focus.has("examine"):
		run_action(resolve(focus.examine))


func examine() -> void:
	if focus.is_empty():
		return
	var a = resolve(npcs[focus.id].get("examine")) if focus.get("npc", false) else resolve(focus.get("examine"))
	if a == null:
		a = {"t": "Ingenting mer å se."}
	run_action(a)


func listen() -> void:
	if State.phase == "prolog":
		return
	if focus.is_empty():
		Sfx.play("wood")
		return
	if focus.get("npc", false):
		say("", "Ingrid senker hammeren. Ikke på folk.")
		return
	var a = resolve(focus.get("listen"))
	if a == null:
		var mat: String = focus.get("mat", "")
		if mat == "":
			say("", "Det er ingenting her å slå på.")
			return
		a = {"snd": mat, "t": "Det klinger som det skal."}
	run_action(a)


func use_door(door: Dictionary) -> void:
	var locked = _lock_text(door)
	if locked != null:
		say("", locked)
		return
	Sfx.play("door")
	go_room(door.to, float(door.x))


func hum() -> void:
	if humming or State.phase == "prolog":
		return
	humming = true
	var dur := Sfx.play("hum")
	await get_tree().create_timer(2.2).timeout
	if mode == "play":
		_hum_reaction()
	await get_tree().create_timer(maxf(dur - 2.2, 0.1)).timeout
	humming = false


func _hum_reaction() -> void:
	var nearest := {}
	var best := HUM_RANGE
	var hallvard_here := false
	for o in objects:
		if o.get("npc", false):
			if o.id == "hallvard":
				hallvard_here = true
			var d: float = absf(o.x - player_x)
			if d < best:
				best = d
				nearest = o
	if nearest.is_empty():
		return
	if nearest.id == "ragna" and not hallvard_here and not State.f("ragna_hum"):
		start_dialogue("r_hum")
		return
	var r = npcs[nearest.id].get("hum")
	if r != null:
		run_action(resolve(r))


func open_inventory() -> void:
	if State.inventory.is_empty():
		return
	mode = "inventory"
	inv_sel = 0
	_draw_inventory()
	inv_panel.show()


func _draw_inventory() -> void:
	for c in inv_list.get_children():
		c.queue_free()
	for i in State.inventory.size():
		var it: Dictionary = items[State.inventory[i]]
		var mark := "▸ " if i == inv_sel else "   "
		inv_list.add_child(_label(22, Color(1, 1, 1) if i == inv_sel else Color(0.7, 0.7, 0.7), mark + it.name))
	inv_desc.text = items[State.inventory[inv_sel]].desc


func _inventory_key(k: int) -> void:
	match k:
		KEY_UP, KEY_W:
			inv_sel = posmod(inv_sel - 1, State.inventory.size())
			_draw_inventory()
		KEY_DOWN, KEY_S:
			inv_sel = posmod(inv_sel + 1, State.inventory.size())
			_draw_inventory()
		KEY_ENTER, KEY_E, KEY_SPACE:
			State.held = State.inventory[inv_sel]
			_update_held()
			inv_panel.hide()
			mode = "play"
		KEY_ESCAPE, KEY_I, KEY_TAB:
			inv_panel.hide()
			mode = "play"


func _use_held() -> void:
	var it := State.held
	State.held = ""
	_update_held()
	if focus.get("npc", false):
		var r = World.item_reaction(it, focus.id)
		if r == null:
			r = "%s ser spørrende på deg." % focus.name
		run_action(resolve(r))
	elif focus.has("use_item") and focus.use_item.has(it):
		run_action(resolve(focus.use_item[it]))
	else:
		say("", "Det fører ingen steder.")


## Velger første handling som passer. Se world.gd for formatet.
func resolve(v):
	if v == null:
		return null
	if v is String:
		return {"t": v}
	if v is Dictionary:
		return v if State.check(v.get("if", "")) else null
	if v is Array:
		for e in v:
			var r = resolve(e)
			if r != null:
				return r
	return null


func run_action(a) -> void:
	if a == null:
		return
	if a.has("do"):
		_ops(a["do"])
	if a.has("snd"):
		Sfx.play(a.snd)
	if a.has("d"):
		start_dialogue(a.d)
	elif a.has("t"):
		say(a.get("s", ""), a.t)
	elif mode == "play":
		_flush_events()


func say(speaker: String, text: String) -> void:
	_start_tree({"start": [{"s": speaker, "t": text}]})


# ================================================================ DIALOG

func start_dialogue(id: String) -> void:
	if not dialogues.has(id):
		push_error("Mangler dialog: " + id)
		return
	if mode == "dialogue":
		dlg_queue.append(id)
		return
	_start_tree(dialogues[id])


func _start_tree(tree: Dictionary) -> void:
	dlg = tree
	mode = "dialogue"
	box.show()
	_goto("start")


func _goto(node: String) -> void:
	if not dlg.has(node):
		push_error("Mangler dialognode: " + node)
		_end_dialogue()
		return
	dlg_steps = dlg[node]
	dlg_i = 0
	_step()


func _step() -> void:
	while true:
		if dlg_i >= dlg_steps.size():
			_end_dialogue()
			return
		var s: Dictionary = dlg_steps[dlg_i]
		dlg_i += 1
		if s.has("if") and not State.check(s["if"]):
			continue
		if s.has("do"):
			_ops(s["do"])
		if s.has("goto"):
			_goto(s["goto"])
			return
		if s.get("end", false):
			_end_dialogue()
			return
		if s.has("t"):
			_show_line(s.get("s", ""), s.t)
			return
		if s.has("choices"):
			dlg_choices = s.choices.filter(func(c): return State.check(c.get("if", "")))
			if dlg_choices.is_empty():
				continue
			dlg_sel = 0
			_show_choices()
			return


func _show_line(speaker: String, text: String) -> void:
	speaker_lbl.text = speaker_name(speaker) if speaker != "" else ""
	speaker_lbl.visible = speaker != ""
	text_lbl.text = text
	text_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.92) if speaker != "" else Color(0.78, 0.8, 0.86))
	for c in choice_box.get_children():
		c.queue_free()
	dlg_choices = []


func _show_choices() -> void:
	speaker_lbl.visible = false
	text_lbl.text = ""
	_render_choices()


func _render_choices() -> void:
	for c in choice_box.get_children():
		c.queue_free()
	for i in dlg_choices.size():
		var sel := i == dlg_sel
		choice_box.add_child(_label(22, Color(1, 0.9, 0.6) if sel else Color(0.7, 0.7, 0.7), ("▸ " if sel else "   ") + dlg_choices[i].t))


func _dialogue_key(k: int) -> void:
	if dlg_choices.is_empty():
		if k in [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_Q]:
			_step()
		return
	match k:
		KEY_UP, KEY_W:
			dlg_sel = posmod(dlg_sel - 1, dlg_choices.size())
			_render_choices()
		KEY_DOWN, KEY_S:
			dlg_sel = posmod(dlg_sel + 1, dlg_choices.size())
			_render_choices()
		KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			choose(dlg_sel)
		_:
			if k >= KEY_1 and k <= KEY_9 and k - KEY_1 < dlg_choices.size():
				choose(k - KEY_1)


func choose(i: int) -> void:
	var c: Dictionary = dlg_choices[i]
	dlg_choices = []
	for ch in choice_box.get_children():
		ch.queue_free()
	if c.has("do"):
		_ops(c["do"])
	if c.has("goto"):
		_goto(c.goto)
	elif c.get("end", false):
		_end_dialogue()
	else:
		_step()


func _end_dialogue() -> void:
	box.hide()
	dlg = {}
	dlg_choices = []
	mode = "play"
	refresh_objects()
	if not pending_events.is_empty():
		_flush_events()
	elif not dlg_queue.is_empty():
		start_dialogue(dlg_queue.pop_front())


func _ops(ops: Array) -> void:
	for op in ops:
		var parts: PackedStringArray = op.split(":", true, 1)
		match parts[0]:
			"event":
				pending_events.append(parts[1])
			"sfx":
				Sfx.play(parts[1])
			_:
				State.apply(op)
				if op == "set:p_hook":
					hook_time = t
	refresh_objects()


func _flush_events() -> void:
	while not pending_events.is_empty():
		await _event(pending_events.pop_front())
	if mode == "play" and not dlg_queue.is_empty():
		start_dialogue(dlg_queue.pop_front())


# ================================================================ HENDELSER

func _event(name: String) -> void:
	match name:
		"prologue_end":
			await _prologue_end()
		"meal":
			State.phase = "kveld"
			await go_room("V1", 520)
			start_dialogue("meal")
		"night":
			State.phase = "natt"
			await go_room("V2", 420)
		"tora_tells":
			await go_room("V1", 1080)
			start_dialogue("tora_tells")
		"night_timer":
			if not State.f("night_bell"):
				night_timer = NIGHT_BELL_DELAY
		"end_game":
			await _show_end()
		_:
			push_error("Ukjent hendelse: " + name)


func _prologue_end() -> void:
	mode = "busy"
	Sfx.play("water_rush")
	shake = 1.0
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 2.0)
	await tw.finished
	Sfx.ambient("")
	await get_tree().create_timer(1.5).timeout
	center_lbl.text = "Fagravik\n\nhøsten 1082"
	await get_tree().create_timer(3.5).timeout
	center_lbl.text = ""
	State.phase = "morgen"
	State.give("lykt")
	State.give("fint_tre")
	await go_room("A1", 1500)


func _night_bell() -> void:
	night_timer = -1.0
	State.apply("set:night_bell")
	Sfx.play("bell_night")
	shake = 0.6
	refresh_objects()
	await get_tree().create_timer(1.2).timeout
	start_dialogue("n_bell")


# ================================================================ TEGNING

func _draw() -> void:
	if room.is_empty():
		return
	var w: float = room.w
	var interior: bool = room.get("interior", false)
	var back: Color = room.get("wall", Color(0.4, 0.33, 0.26)) if interior else room.get("sky", SKY_BY_PHASE.get(State.phase, Rooms.SKY))
	draw_rect(Rect2(-400, -400, w + 800, FLOOR_Y + 400), back)
	if interior:
		for i in range(0, int(w), 160):
			draw_rect(Rect2(i, 120, 6, FLOOR_Y - 120), back.darkened(0.12))
		draw_rect(Rect2(-400, 100, w + 800, 20), back.darkened(0.25))

	for d in room.get("decor", []):
		if State.check(d.get("if", "")):
			_draw_decor(d)

	draw_rect(Rect2(-400, FLOOR_Y, w + 800, room.get("ground_h", 400.0)), room.get("ground", Color(0.35, 0.3, 0.25)))
	draw_line(Vector2(-400, FLOOR_Y), Vector2(w + 400, FLOOR_Y), Color(0, 0, 0, 0.35), 2.0)

	for o in objects:
		if o.has("zone"):
			continue
		if o.get("npc", false):
			_draw_person(o.x, o.h, npcs[o.id].c, o.id == "venn" and State.f("p_swapped"))
		else:
			_draw_object(o)

	_draw_player()

	if room.get("rain", false) or (room_id == "P1"):
		_draw_rain(room_id == "P1")

	if not focus.is_empty() and mode == "play" and not focus.get("hidden", false):
		var top: float = focus.get("y", FLOOR_Y) - focus.get("h", 60.0) - 14.0
		var label: String = focus.get("name", "")
		var size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
		draw_string(font, Vector2(focus.x - size.x / 2.0, top), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.85))


func _draw_decor(d: Dictionary) -> void:
	var dw: float = d.w
	var dh: float = d.h
	var bottom: float = d.get("y", FLOOR_Y)
	if d.get("rise", false) and hook_time >= 0.0:
		dh += minf((t - hook_time) * 6.0, 40.0)
	var r := Rect2(d.x - dw / 2.0, bottom - dh, dw, dh)
	var c: Color = d.c
	if d.get("ridge", false):
		var pts := PackedVector2Array([Vector2(r.position.x, bottom)])
		var x := r.position.x
		while x < r.end.x:
			pts.append(Vector2(x, bottom - dh * (0.45 + 0.35 * absf(sin(x * 0.0041)) + 0.2 * absf(sin(x * 0.013)))))
			x += 90.0
		pts.append(Vector2(r.end.x, bottom - dh * 0.5))
		pts.append(Vector2(r.end.x, bottom))
		draw_colored_polygon(pts, c)
	elif d.get("spire", false):
		draw_colored_polygon(PackedVector2Array([Vector2(d.x - dw, bottom), Vector2(d.x, bottom - dh), Vector2(d.x + dw, bottom)]), c)
	else:
		draw_rect(r, c)
	if d.get("water", false):
		for i in range(int(r.position.x), int(r.end.x), 40):
			var yy := r.position.y + 4.0 + sin(t * 2.0 + i * 0.05) * 2.0
			draw_line(Vector2(i, yy), Vector2(i + 18, yy), c.lightened(0.25), 2.0)
	var label: String = d.get("label", "")
	if label != "":
		draw_string(font, Vector2(d.x - dw / 2.0, bottom - dh - 6.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.35))


func _draw_object(o: Dictionary) -> void:
	var ow: float = o.get("w", 60.0)
	var oh: float = o.get("h", 60.0)
	var bottom: float = o.get("y", FLOOR_Y)
	var r := Rect2(o.x - ow / 2.0, bottom - oh, ow, oh)
	var c: Color = o.get("c", Color(0.5, 0.5, 0.5))
	draw_rect(r, c)
	if o.has("door"):
		draw_rect(r, c.darkened(0.4), false, 3.0)
	if o.get("glow", false):
		var p := Vector2(o.x + 14.0, bottom - oh * 0.55)
		draw_circle(p, 40.0 + sin(t * 3.0) * 4.0, Color(1, 0.8, 0.4, 0.18))
		draw_circle(p, 8.0, Color(1, 0.85, 0.5, 0.9))


func _draw_person(x: float, h: float, c: Color, swapped_cloak := false) -> void:
	var body := Rect2(x - 16.0, FLOOR_Y - h * 0.78, 32.0, h * 0.78)
	if swapped_cloak:
		c = Color(0.75, 0.22, 0.2)
	draw_rect(body, c)
	draw_circle(Vector2(x, FLOOR_Y - h * 0.86), h * 0.11, c.lightened(0.35))


func _draw_player() -> void:
	var bob := absf(sin(walk_t * 10.0)) * 3.0 if walk_t > 0.0 else 0.0
	if State.phase == "prolog":
		var cloak := Color(0.3, 0.42, 0.75) if State.f("p_swapped") else Color(0.75, 0.22, 0.2)
		_draw_person(player_x, 72.0 + bob, cloak)
	else:
		_draw_person(player_x, 98.0 + bob, Color(0.86, 0.52, 0.24))
	var eye := Vector2(player_x + facing * 6.0, FLOOR_Y - (72.0 if State.phase == "prolog" else 98.0) * 0.87)
	draw_circle(eye, 2.0, Color(0.1, 0.1, 0.1))


func _draw_rain(window_only: bool) -> void:
	var c := Color(0.7, 0.75, 0.9, 0.35)
	if window_only:
		var wr := Rect2(565, 360, 150, 110)
		for i in 14:
			var x := wr.position.x + fmod(i * 37.0 + t * 40.0, wr.size.x)
			var y := wr.position.y + fmod(i * 53.0 + t * 400.0, wr.size.y - 14.0)
			draw_line(Vector2(x, y), Vector2(x - 3, y + 12), c, 1.5)
		return
	var cx := cam.position.x - VIEW.x / 2.0
	for i in 120:
		var x := cx + fmod(i * 97.0 + t * 60.0, VIEW.x + 40.0) - 20.0
		var y := fmod(i * 61.0 + t * 700.0, VIEW.y)
		draw_line(Vector2(x, y), Vector2(x - 6, y + 22), c, 1.5)


# ================================================================ FEILSØKING

## Hopp mellom faser for testing (bare i debug-bygg): F1–F4.
func _debug_key(k: int) -> void:
	var jumps := {
		KEY_F1: ["morgen", "A1", 1500, []],
		KEY_F2: ["formiddag", "K3", 600, ["a_arrive", "inn_scene", "met_tora"]],
		KEY_F3: ["ettermiddag", "B1", 1300, ["a_arrive", "inn_scene", "met_tora", "k3_intro", "bell_reported", "wants_talg"]],
		KEY_F4: ["natt", "V2", 420, ["a_arrive", "inn_scene", "met_tora", "k3_intro", "bell_reported"]],
	}
	if not jumps.has(k):
		return
	var j: Array = jumps[k]
	State.reset()
	State.give("lykt")
	State.give("fint_tre")
	for fl in j[3]:
		State.apply("set:" + fl)
	State.phase = j[0]
	center_lbl.text = ""
	night_timer = -1.0
	go_room(j[1], j[2])
