extends Node
## Spilltilstand: tidsfase, flagg, inventar og notatbok.
##
## Betingelser (brukt i alle datafiler) er tekst:
##   "flagg"            flagget er satt
##   "!flagg"           flagget er ikke satt
##   "flagg=verdi"      flagget har akkurat denne verdien
##   "has:gjenstand"    Ingrid bærer gjenstanden
##   "phase:fase"       nåværende tidsfase
##   "room:ID"          nåværende rom
##   "a&b"              begge må stemme
##   "a|b"              én av dem må stemme (binder sterkere enn &)
## Operasjoner: "set:flagg", "set:flagg=verdi", "unset:flagg",
##   "give:gjenstand", "take:gjenstand", "phase:fase".

signal changed

const PHASES := ["prolog", "morgen", "formiddag", "ettermiddag", "kveld", "natt"]

var phase := "prolog"
var room := ""
var flags := {}
var inventory: Array = []
var held := ""
var notebook := ""


func reset() -> void:
	phase = "prolog"
	room = ""
	flags = {}
	inventory = []
	held = ""
	notebook = ""
	changed.emit()


func f(key: String) -> bool:
	var v = flags.get(key, false)
	if v is bool:
		return v
	return str(v) != ""


func has_item(id: String) -> bool:
	return id in inventory


func give(id: String) -> void:
	if not has_item(id):
		inventory.append(id)


func take(id: String) -> void:
	inventory.erase(id)
	if held == id:
		held = ""


func check(cond: String) -> bool:
	cond = cond.strip_edges()
	if cond == "":
		return true
	for term in cond.split("&"):
		var any := false
		for atom in term.split("|"):
			if _atom(atom.strip_edges()):
				any = true
				break
		if not any:
			return false
	return true


func _atom(a: String) -> bool:
	var neg := a.begins_with("!")
	if neg:
		a = a.substr(1)
	var ok: bool
	if a.begins_with("has:"):
		ok = has_item(a.substr(4))
	elif a.begins_with("phase:"):
		ok = phase == a.substr(6)
	elif a.begins_with("room:"):
		ok = room == a.substr(5)
	elif "=" in a:
		var kv := a.split("=", true, 1)
		ok = str(flags.get(kv[0], "")) == kv[1]
	else:
		ok = f(a)
	return ok != neg


func apply(op: String) -> void:
	var parts := op.split(":", true, 1)
	var arg := parts[1] if parts.size() > 1 else ""
	match parts[0]:
		"set":
			if "=" in arg:
				var kv := arg.split("=", true, 1)
				flags[kv[0]] = kv[1]
			else:
				flags[arg] = true
		"unset":
			flags.erase(arg)
		"give":
			give(arg)
		"take":
			take(arg)
		"phase":
			assert(arg in PHASES, "Ukjent fase: " + arg)
			phase = arg
		_:
			push_error("Ukjent operasjon: " + op)
	_derive()
	changed.emit()


## Slutninger spillet trekker i bakgrunnen, uten å si det til spilleren.
func _derive() -> void:
	# Har Ingrid sett både skaden på kisten og Toras båt, kan hun ta det opp.
	if f("saw_chest_damage") and f("tora_showed"):
		flags["knows_source"] = true
	# Når Ingrid forteller Ragna, får Liv lappe kisten.
	if f("ingrid_told"):
		flags["chest_fixed"] = true
