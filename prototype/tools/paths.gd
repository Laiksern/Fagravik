extends "res://tools/playthrough.gd"
## Tester forløp A, B og C av Toras båt fra ettermiddagen og fram til natten.
## Kjør: godot --headless --path prototype res://tools/paths.tscn


func _run() -> void:
	# A: Ingrid forteller Ragna selv.
	await _afternoon()
	await _see_boat_and_chest()
	await _go("V1", 170)
	await _act("ragna", "talk", ["Kisten din.", "Det var Tora.", "Ingenting."])
	_expect("ingrid_told")
	_expect("chest_fixed")
	await _go("B1", 1300)
	await _act("tora", "talk", [])
	await _meal_reaches_night()
	# B: Liv lapper kisten i stillhet.
	await _afternoon()
	await _see_boat_and_chest()
	await _act("tora", "talk", ["Treverket er fra kisten", "Hva er du egentlig redd for?", "Kanskje Liv kan fikse", "Ingenting."])
	_expect("tora_secret")
	await _go("L1", 160)
	await _act("liv", "talk", ["Kan du reparere en kiste?", "Kan du lappe den", "Ingenting."])
	_expect("chest_secret")
	await _meal_reaches_night()
	# C: Tora forteller selv, kisten forblir skadet.
	await _afternoon()
	await _see_boat_and_chest()
	await _act("tora", "talk", ["Treverket er fra kisten", "Hva er du egentlig redd for?", "Jeg blir med deg"])
	_expect("tora_told")
	if State.f("chest_fixed"):
		failures.append("C: kisten skulle ikke vært reparert")
	await _meal_reaches_night()


func _afternoon() -> void:
	State.reset()
	State.give("lykt")
	State.give("fint_tre")
	for f in ["a_arrive", "inn_scene", "met_tora", "k3_intro", "bell_reported", "wants_talg"]:
		State.apply("set:" + f)
	State.phase = "ettermiddag"


func _see_boat_and_chest() -> void:
	await _go("V1", 170)
	await _act("kiste", "examine", [])
	await _go("B1", 1300)
	await _act("tora", "talk", ["Hva har du bak ryggen?", "Ingenting."])
	_expect("knows_source")


func _meal_reaches_night() -> void:
	await _go("V1", 170)
	await _act("ragna", "talk", ["Jeg er klar for kveldsmåltidet."])
	await _settle([], 30.0)
	_expect_phase("natt")
	_expect_room("V2")
