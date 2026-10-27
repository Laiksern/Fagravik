extends Node
## Automatisk gjennomspilling fra prolog til slutt, gjennom den rikeste
## løsningen av Toras båt (forløp D). Feiler med kode 1 hvis noe stopper opp.
## Kjør: godot --headless --path prototype res://tools/playthrough.tscn

var main: Node2D
var failures: Array = []


func _ready() -> void:
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await _frames(5)
	await _run()
	if failures.is_empty():
		print("GJENNOMSPILLING OK")
		get_tree().quit(0)
	else:
		for f in failures:
			printerr("FEIL: ", f)
		get_tree().quit(1)


func _run() -> void:
	main._new_game()
	await _settle([])
	# --- prolog
	await _act("venn", "talk", ["Bytt kappe."])
	_expect("p_alarm")
	await _act("dor", "talk", [])
	_expect_room("P2")
	await _act("krok", "talk", [])
	_expect("p_hook")
	main.player_x = 1300.0
	await _settle([], 30.0)
	_expect_room("A1")
	_expect_phase("morgen")
	_expect_item("lykt")
	# --- morgen
	await _act("audun", "talk", ["Ingrid. Jeg er med Hallvard."])
	await _go("V1", 170)
	_expect("inn_scene")
	await _act("hallvard", "talk", ["Klar."])
	_expect_phase("formiddag")
	# --- formiddag: klokken
	await _go("K3", 200)
	_expect("k3_intro")
	await _act("sprekk", "examine", [])
	await _act("reparasjon", "examine", [])
	await _act("skjot", "examine", [])
	await _act("skjot_h", "listen", [])
	_expect("bell_second")
	await _go("K2", 1280)
	await _act("eirik", "examine", [])
	_expect("eirik_page")
	await _go("K3", 200)
	await _act("hallvard", "talk", ["Det er en tone til", "Sprekken er ny", "Noen har reparert"])
	_expect_phase("ettermiddag")
	# --- ettermiddag
	await _go("V1", 170)
	main.player_x = 900.0
	main._update_focus()
	main.hum()
	await _settle([], 10.0)
	_expect("ragna_hum")
	await _act("kiste", "examine", [])
	await _act("ragna", "talk", ["Hallvard trenger talg.", "Ingenting."])
	_expect_item("talg")
	await _go("B1", 1300)
	await _act("tora", "talk", ["Hva har du bak ryggen?", "Har du laget noe annet?", "Ingenting."])
	_expect("knows_source")
	_expect("saw_tora_map")
	await _act("tora", "talk", ["Treverket er fra kisten", "Ingenting."])
	_expect("tora_confessed")
	await _act("sjur", "talk", ["Se på båten til Tora.", "Ingenting."])
	_expect_item("seil")
	await _go("L1", 160)
	await _act("liv", "talk", ["Kan du reparere en kiste?", "Jeg har et stykke fint tre.", "Svennestykket mitt.", "Ingenting."])
	_expect("wood_given")
	await _go("B1", 1300)
	await _act("tora", "talk", ["Hva er du egentlig redd for?", "Jeg blir med deg"])
	_expect("tora_told")
	_expect_room("V1")
	await _act("tora", "talk", ["Sjur har laget et seil til deg."])
	_expect("boat_rigged")
	await _go("B2", 1560)
	await _act("drivved", "examine", [])
	await _act("plankene", "talk", [])
	_expect("gangway_open")
	await _act("tora", "talk", [])
	_expect("boat_launched")
	await _go("K3", 200)
	await _act("hallvard", "talk", ["Talg, fra Ragna.", "Jeg er klar for kveldsmåltidet."])
	_expect("talg_given")
	await _settle(["Jeg slo i hvert fall", "(Bli sittende.)"], 30.0)
	# --- natt
	_expect_phase("natt")
	_expect_room("V2")
	await _settle([], 30.0)
	_expect("night_bell")
	await _act("hallvard", "talk", [])
	_expect("night_talk")
	await _go("S1", 1750)
	await _act("vaat_baat", "examine", [])
	_expect("saw_wet_boat")
	await _go("B2", 1560)
	_expect("n_sing")
	await _go("V2", 420)
	await _act("seng", "talk", [])
	await _frames(400)
	if main.mode != "end":
		failures.append("Spillet nådde ikke slutten (modus %s)" % main.mode)


# --- hjelpere ------------------------------------------------------------

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## Kjører dialoger og overganger til spilleren har kontroll igjen.
func _settle(prefs: Array, max_seconds := 20.0) -> void:
	var stuck := 0
	var deadline := Time.get_ticks_msec() + int(max_seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		match main.mode:
			"dialogue":
				if main.dlg_choices.is_empty():
					main._step()
				else:
					main.choose(_pick(prefs))
				stuck = 0
			"busy":
				stuck = 0
			"play":
				stuck += 1
				if stuck > 30 and main.night_timer <= 0.0 and not main.humming:
					return
			"end":
				return
		await get_tree().process_frame


func _pick(prefs: Array) -> int:
	for p in prefs:
		for i in main.dlg_choices.size():
			if main.dlg_choices[i].t.begins_with(p):
				prefs.erase(p)
				return i
	# ellers: siste valg (som regel «Ingenting»)
	return main.dlg_choices.size() - 1


func _act(id: String, how: String, prefs: Array) -> void:
	var o := {}
	for x in main.objects:
		if x.get("id", "") == id:
			o = x
	if o.is_empty():
		failures.append("Fant ikke %s i %s (fase %s)" % [id, main.room_id, State.phase])
		return
	main.player_x = float(o.x)
	main._update_focus()
	if main.focus.get("id", "") != id:
		failures.append("Fokus på %s i stedet for %s" % [main.focus.get("id", "?"), id])
		return
	match how:
		"talk": main.interact()
		"examine": main.examine()
		"listen": main.listen()
	await _settle(prefs)


func _go(room: String, x: float) -> void:
	await main.go_room(room, x)
	await _settle([])


func _expect(flag: String) -> void:
	if not State.f(flag):
		failures.append("Flagget %s er ikke satt (rom %s, fase %s)" % [flag, main.room_id, State.phase])


func _expect_item(item: String) -> void:
	if not State.has_item(item):
		failures.append("Ingrid mangler %s" % item)


func _expect_room(r: String) -> void:
	if main.room_id != r:
		failures.append("Forventet rom %s, var i %s" % [r, main.room_id])


func _expect_phase(p: String) -> void:
	if State.phase != p:
		failures.append("Forventet fase %s, var %s" % [p, State.phase])
