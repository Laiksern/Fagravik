extends SceneTree
## Sjekker at datafilene henger sammen: dialognoder, rom, dører, lyder og hendelser.
## Kjør: godot --headless --path prototype --script res://tools/validate.gd

const Rooms := preload("res://data/rooms.gd")
const Dialogues := preload("res://data/dialogues.gd")
const World := preload("res://data/world.gd")
const SfxScript := preload("res://scripts/sfx.gd")

const EVENTS := ["prologue_end", "meal", "night", "tora_tells", "night_timer", "end_game"]

var errors: Array = []
var rooms := {}
var dialogues := {}


func _initialize() -> void:
	rooms = Rooms.all()
	dialogues = Dialogues.all()
	var names := World.names()
	for id in dialogues:
		var d: Dictionary = dialogues[id]
		if not d.has("start"):
			errors.append("Dialog %s mangler start" % id)
		for node in d:
			for step in d[node]:
				_check_ops(step.get("do", []), "%s/%s" % [id, node])
				if step.has("goto") and not d.has(step.goto):
					errors.append("%s/%s: goto %s finnes ikke" % [id, node, step.goto])
				var s: String = step.get("s", "")
				if s != "" and s == s.to_lower() and not names.has(s):
					errors.append("%s/%s: ukjent taler %s" % [id, node, s])
				for c in step.get("choices", []):
					_check_ops(c.get("do", []), "%s/%s" % [id, node])
					if c.has("goto") and not d.has(c.goto):
						errors.append("%s/%s: valg til %s finnes ikke" % [id, node, c.goto])
	for rid in rooms:
		var r: Dictionary = rooms[rid]
		for side in ["left", "right"]:
			if r.has(side):
				_check_exit(r[side], rid)
		for o in r.get("objects", []):
			if o.has("door"):
				_check_exit(o.door, rid)
			for key in ["examine", "listen", "use", "zone"]:
				_check_action(o.get(key), "%s/%s" % [rid, o.get("id", "?")])
		for tr in r.get("enter", []):
			_check_action(tr, rid + "/enter")
	for nid in World.npcs():
		var n: Dictionary = World.npcs()[nid]
		for key in ["talk", "examine", "hum"]:
			_check_action(n.get(key), "npc " + nid)
	if errors.is_empty():
		print("OK: %d dialoger, %d rom" % [dialogues.size(), rooms.size()])
		quit(0)
	else:
		for e in errors:
			printerr(e)
		quit(1)


func _check_exit(e: Dictionary, where: String) -> void:
	if not rooms.has(e.get("to", "")):
		errors.append("%s: utgang til ukjent rom %s" % [where, e.get("to")])
	elif float(e.get("x", -1)) < 0 or float(e.x) > float(rooms[e.to].w):
		errors.append("%s: startpunkt utenfor rommet %s" % [where, e.to])


func _check_action(a, where: String) -> void:
	if a == null or a is String:
		return
	if a is Array:
		for x in a:
			_check_action(x, where)
		return
	if a.has("d") and not dialogues.has(a.d):
		errors.append("%s: ukjent dialog %s" % [where, a.d])
	if a.has("snd") and not a.snd in SfxScript.NAMES:
		errors.append("%s: ukjent lyd %s" % [where, a.snd])
	_check_ops(a.get("do", []), where)


func _check_ops(ops: Array, where: String) -> void:
	for op in ops:
		var p: PackedStringArray = op.split(":", true, 1)
		match p[0]:
			"set", "unset", "give", "take":
				pass
			"phase":
				if not p[1] in ["prolog", "morgen", "formiddag", "ettermiddag", "kveld", "natt"]:
					errors.append("%s: ukjent fase %s" % [where, p[1]])
			"sfx":
				if not p[1] in SfxScript.NAMES:
					errors.append("%s: ukjent lyd %s" % [where, p[1]])
			"event":
				if not p[1] in EVENTS:
					errors.append("%s: ukjent hendelse %s" % [where, p[1]])
			_:
				errors.append("%s: ukjent operasjon %s" % [where, op])
