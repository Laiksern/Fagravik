extends RefCounted
## Personer, gjenstander og hvor folk befinner seg i hver tidsfase.
##
## En "handling" (brukt i talk/examine/listen og i rom-objekter) er enten
##   "tekst"                              en fortellerlinje
##   {"s": taler, "t": tekst}             en replikk
##   {"d": dialog-id}                     starter en dialog
##   {"do": [...], "snd": lyd, ...}       operasjoner og lyd i tillegg
## eller en liste av slike med "if": den første som stemmer, brukes.


static func names() -> Dictionary:
	return {
		"ingrid": "Ingrid", "hallvard": "Hallvard", "ragna": "Ragna", "tora": "Tora",
		"liv": "Liv", "sjur": "Sjur", "eirik": "Eirik", "audun": "Audun",
		"worker": "Lossearbeider", "mor": "Mor", "venn": "Venninnen",
	}


static func items() -> Dictionary:
	return {
		"lykt": {"name": "Signes lykt", "desc": "Mors gamle lykt. Messingen er bulket på den ene siden, og glasset er nytt."},
		"fint_tre": {"name": "Et stykke fint tre", "desc": "Lyst og tett. Du har spart det til svennestykket ditt i to år."},
		"talg": {"name": "Talg", "desc": "En klump talg i et kålblad. Fra Ragna, til Hallvard."},
		"seil": {"name": "Seilduk", "desc": "Et lite seil Sjur skar til. Det er ment for Toras båt."},
	}


static func npcs() -> Dictionary:
	return {
		"hallvard": {
			"c": Color(0.55, 0.38, 0.22), "h": 112.0,
			"talk": [
				{"if": "phase:morgen&!inn_scene", "d": "a_hallvard"},
				{"if": "phase:morgen", "d": "v_hallvard_go"},
				{"if": "phase:formiddag", "d": "k3_hallvard"},
				{"if": "phase:ettermiddag", "d": "e_hallvard"},
				{"if": "phase:natt", "d": "n_hallvard"},
			],
			"examine": [
				{"if": "phase:natt", "t": "Fullt påkledd. Støvlene er våte i tuppen."},
				{"if": "room:K3", "t": "Han tok tårntrappa i halvmørket uten å se ned. Som om føttene kjente trinnene."},
				{"t": "Hallvard. Det er mer grått i skjegget enn i fjor."},
			],
			"hum": {"s": "hallvard", "t": "Ikke den, Ingrid."},
		},
		"ragna": {
			"c": Color(0.33, 0.52, 0.34), "h": 104.0,
			"talk": [{"d": "r_ragna"}],
			"examine": "Ragna tørker et krus. Hun holder det i venstre hånd.",
			"hum": "Ragna fortsetter å tørke det samme kruset.",
		},
		"tora": {
			"c": Color(0.86, 0.72, 0.28), "h": 72.0,
			"talk": [
				{"if": "phase:morgen&!inn_scene", "d": "a_tora"},
				{"if": "phase:morgen|phase:formiddag", "d": "v_tora"},
				{"d": "t_tora"},
			],
			"examine": [
				{"if": "phase:morgen&!inn_scene", "t": "En jente med kull på fingrene. Hun later som hun ikke følger etter deg."},
				{"t": "Tora. Kull på fingrene og et sår på knoken."},
			],
			"hum": {"s": "tora", "t": "Den er trist. Lær meg den."},
		},
		"liv": {
			"c": Color(0.25, 0.55, 0.58), "h": 106.0,
			"talk": [
				{"if": "room:S1", "s": "liv", "t": "Ikke nå. Jeg kjøper tjære, og tjæremannen jukser hvis jeg ser bort."},
				{"d": "l_liv"},
			],
			"examine": "Liv. Sagflis i håret. Hun ser ikke opp når hun snakker.",
		},
		"sjur": {
			"c": Color(0.45, 0.5, 0.62), "h": 100.0,
			"talk": [{"d": "s_sjur"}],
			"examine": "Sjur banker fingrene mot det nærmeste treverket: tre korte, ett langt, tre korte. Igjen og igjen.",
			"hum": "Sjur slutter å tromme. Han begynner igjen når du er ferdig.",
		},
		"eirik": {
			"c": Color(0.18, 0.18, 0.2), "h": 110.0,
			"talk": [{"d": "k_eirik"}],
			"examine": [
				{"if": "room:K2&!eirik_page", "do": ["set:eirik_page"], "t": "Eirik blar i kirkeboka. Han tar ut en løs side, bretter den og stikker den innenfor kappa, glatt som en vane."},
				{"t": "Eirik. Prestekappa er for tynn for høsten."},
			],
			"hum": {"s": "eirik", "t": "Vakker. Ikke en salme, men vakker."},
		},
		"audun": {
			"c": Color(0.5, 0.16, 0.16), "h": 114.0,
			"talk": [
				{"if": "phase:morgen", "d": "a_audun"},
				{"d": "t_audun"},
			],
			"examine": "Audun står med ryggen mot noe, alltid, slik at han ser alle.",
		},
		"worker": {
			"c": Color(0.5, 0.48, 0.44), "h": 108.0,
			"talk": [{"d": "a_worker"}],
			"examine": "Saltvann i skjegget. Han løfter to kasser om gangen, for at noen skal se det.",
			"hum": {"s": "worker", "t": "Syng heller noe vi kan!"},
		},
		"mor": {
			"c": Color(0.36, 0.3, 0.34), "h": 104.0,
			"talk": [
				{"if": "p_alarm", "s": "mor", "t": "Løp, sa jeg! Bronsen!"},
				{"t": "Mor synger videre og stryker deg over håret uten å se opp."},
			],
			"examine": "Hun synger med ryggen til. Håret er flettet for natta.",
		},
		"venn": {
			"c": Color(0.3, 0.42, 0.75), "h": 70.0,
			"talk": [{"d": "p_friend"}],
			"examine": "Hun er like gammel som deg og like høy. I mørket kunne dere vært den samme.",
		},
	}


## Hvor en person står: [rom, x] eller [] hvis personen ikke er i prototypeområdet.
static func place(id: String, s) -> Array:
	var p: String = s.phase
	match id:
		"mor":
			if p == "prolog":
				return ["P1", 200]
		"venn":
			if p == "prolog" and not s.f("p_alarm"):
				return ["P1", 820]
		"hallvard":
			match p:
				"morgen": return ["V1", 330] if s.f("inn_scene") else ["A1", 1150]
				"formiddag", "ettermiddag": return ["K3", 1250]
				"kveld": return ["V1", 690]
				"natt": return ["V2", 1000] if s.f("night_bell") else []
		"audun":
			match p:
				"morgen": return ["A1", 1290]
				"ettermiddag": return ["T1", 1500]
		"worker":
			if p == "morgen":
				return ["A1", 420]
		"ragna":
			if p in ["morgen", "formiddag", "ettermiddag", "kveld"]:
				return ["V1", 960]
		"tora":
			match p:
				"morgen": return ["V1", 1180] if s.f("inn_scene") else ["A1", 760]
				"formiddag": return ["S1", 900]
				"ettermiddag":
					if s.f("boat_rigged") and not s.f("boat_launched") and not s.f("ingrid_told"):
						return ["B2", 1240]
					if s.f("tora_told"):
						return ["V1", 1180]
					return ["B1", 800]
				"kveld": return ["V1", 600]
		"liv":
			match p:
				"morgen": return ["S1", 1500]
				"formiddag", "ettermiddag": return ["L1", 680]
				"kveld": return ["V1", 820]
		"sjur":
			match p:
				"morgen": return ["S1", 620]
				"formiddag", "ettermiddag": return ["B1", 1160]
				"kveld": return ["V1", 1090]
		"eirik":
			match p:
				"morgen", "formiddag": return ["K2", 880]
				"ettermiddag": return ["K1", 820]
	return []


## Hva en person sier eller gjør når Ingrid viser fram en gjenstand.
static func item_reaction(item: String, npc: String):
	var r := {
		"lykt": {
			"ragna": {"s": "ragna", "t": "Gammel messing. Sånne lages ikke lenger."},
			"sjur": "Sjur slutter å tromme. «Hvor har du den fra?» Han venter ikke på svar.",
			"liv": {"s": "liv", "t": "Fin. Men messing kan jeg ikke lappe."},
			"tora": {"s": "tora", "t": "Får jeg tenne den? Bare litt?"},
			"hallvard": "«Ha den i vesken, Ingrid.» Han ser ikke på den.",
			"eirik": {"s": "eirik", "t": "En lykt for en lang vei."},
			"audun": "Audun ser på lykta. Så på deg. Han sier ingenting.",
			"worker": {"s": "worker", "t": "Messing! Kan du selge den?"},
		},
		"fint_tre": {
			"liv": {"s": "liv", "t": "Fint tre. Ta vare på det."},
			"hallvard": {"s": "hallvard", "t": "Svennestykket ditt. Ikke bruk det på tull."},
		},
		"talg": {
			"hallvard": {"s": "hallvard", "t": "Talg! Si det med ord, Ingrid. Snakk med meg."},
		},
		"seil": {
			"tora": {"s": "tora", "t": "Er det til meg? Si det, da!"},
		},
	}
	if r.has(item) and r[item].has(npc):
		return r[item][npc]
	return null
