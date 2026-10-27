extends RefCounted
## Gråbokskartet, bygget etter «Fagravik – forslag til prototypekart v0.1».
##
## Rom:      name, w (bredde), interior, wall/ground (farger), amb (lydteppe),
##           left/right (kantutganger), walk_min/walk_max, decor, objects, enter.
## Utgang:   {"to": rom, "x": startpunkt, "lock": [{"if": betingelse, "t": tekst}]}
## Objekt:   id, name, x, w, h, y (underkant), c (farge), if (synlig når),
##           hidden (ingen navnelapp), mat (materiale for lytting),
##           examine / listen / use (handlinger, se world.gd), door (utgang),
##           zone (usynlig sone: x0, x1 og en handling som utløses én gang).
## Dekor:    x, w, h, y, c, label, if; "water" tegnes som vann, "spire" som spir, "ridge" som fjellrygg.
## enter:    [{"if": betingelse, "do": [...], "d": dialog}] når spilleren kommer inn.

const SKY := Color(0.62, 0.74, 0.86)
const FAR := Color(0.42, 0.5, 0.58)
const MOUNTAIN := Color(0.36, 0.43, 0.5)
const FOREST := Color(0.16, 0.26, 0.2)
const WATER := Color(0.2, 0.38, 0.5)
const RIVER := Color(0.26, 0.36, 0.38)
const WOOD := Color(0.45, 0.33, 0.22)
const DARK_WOOD := Color(0.3, 0.21, 0.14)
const STONE := Color(0.5, 0.5, 0.48)
const DOOR := Color(0.24, 0.16, 0.1)
const PATH := Color(0.55, 0.5, 0.4)
const DETAIL := Color(0.62, 0.56, 0.42)
const SPIRE := Color(0.26, 0.2, 0.16)

const NIGHT_LOCK_A1 := [{"if": "phase:natt", "t": "Kaia ligger mørk. Ikke dit i natt."}]


static func all() -> Dictionary:
	return {
		# ------------------------------------------------------------ PROLOG
		"P1": {
			"name": "", "w": 1280, "interior": true, "amb": "rain",
			"wall": Color(0.3, 0.24, 0.2), "ground": Color(0.24, 0.18, 0.13),
			"objects": [
				{"id": "ildsted", "name": "Ildstedet", "x": 440, "w": 150, "h": 70, "c": Color(0.6, 0.28, 0.12), "mat": "stone",
					"examine": "Det knitrer. Det er varmt helt ut i tærne."},
				{"id": "vindu", "name": "Vinduet", "x": 640, "y": 470, "w": 150, "h": 110, "c": Color(0.13, 0.16, 0.24),
					"examine": [
						{"if": "p_alarm", "t": "Lys ute i regnet. Folk løper mot elva."},
						{"t": "Regnet renner nedover hinna. Elva høres bedre enn den synes."},
					]},
				{"id": "dor", "name": "Døra", "x": 1180, "w": 70, "h": 150, "c": DOOR,
					"door": {"to": "P2", "x": 160, "lock": [{"if": "!p_alarm", "t": "Det regner. Mor vil ha deg inne."}]}},
			],
			"enter": [{"if": "!p_intro", "do": ["set:p_intro"], "d": "p_intro"}],
		},
		"P2": {
			"name": "", "w": 1800, "amb": "rain", "walk_max": 1330, "rain": true,
			"sky": Color(0.1, 0.12, 0.17), "ground": Color(0.18, 0.16, 0.12),
			"decor": [
				{"x": 900, "y": 420, "w": 1800, "h": 160, "c": Color(0.08, 0.1, 0.12)},
				{"x": 1600, "y": 600, "w": 520, "h": 40, "c": RIVER, "water": true, "rise": true},
				{"x": 1720, "y": 562, "w": 160, "h": 20, "c": Color(0.15, 0.14, 0.1)},
			],
			"objects": [
				{"id": "dor", "name": "Døra", "x": 90, "w": 70, "h": 150, "c": DOOR,
					"door": {"to": "P1", "x": 1100, "lock": [{"if": "p_hook", "t": "Det er for sent å snu."}]}},
				{"id": "hov", "name": "Hovet", "x": 880, "w": 340, "h": 250, "c": Color(0.2, 0.17, 0.14), "mat": "wood",
					"examine": "Det gamle hovet ved elva. Taket er lavt og svart av regn."},
				{"id": "krok", "name": "Kroken", "x": 960, "y": 410, "w": 34, "h": 34, "c": Color(0.55, 0.48, 0.36),
					"use": [{"if": "!p_hook", "d": "p_hook"}, "Kroken er tom."],
					"examine": [{"if": "!p_hook", "d": "p_hook"}, "Kroken er tom."]},
				{"id": "elv", "name": "Elva", "x": 1290, "w": 60, "h": 10, "c": RIVER,
					"examine": "Brun og fort. Den har gått over steinene."},
				{"id": "kvinne", "name": "Kvinnen med lykta", "x": 1720, "y": 552, "w": 26, "h": 88, "c": Color(0.42, 0.36, 0.3),
					"glow": true, "if": "p_hook", "examine": {"d": "p_end"}, "use": {"d": "p_end"}},
				{"id": "sone", "zone": {"x0": 1240, "x1": 1800, "if": "p_hook&!p_ended", "d": "p_end"}},
			],
			"enter": [{"if": "!p_out", "do": ["set:p_out"], "d": "p_outside"}],
		},
		# ------------------------------------------------------------ BYEN
		"A1": {
			"name": "Ankomstkaia", "w": 1800, "walk_max": 1640,
			"left": {"to": "S1", "x": 2300},
			"decor": [
				{"x": 900, "y": 470, "w": 1800, "h": 200, "c": MOUNTAIN, "ridge": true},
				{"x": 420, "y": 540, "w": 380, "h": 26, "c": FAR, "label": "Storbrua"},
				{"x": 960, "y": 470, "w": 18, "h": 150, "c": SPIRE, "label": "Kirkespiret", "spire": true},
				{"x": 1730, "y": 720, "w": 160, "h": 200, "c": WATER, "water": true},
			],
			"objects": [
				{"id": "baat", "name": "Båten", "x": 1700, "y": 610, "w": 200, "h": 60, "c": DARK_WOOD, "mat": "wood",
					"examine": "Båten dere kom med. Mannskapet er allerede i gang med neste last."},
				{"id": "verktoy", "name": "Verktøykassa", "x": 1480, "w": 70, "h": 40, "c": WOOD, "mat": "hollow",
					"examine": "Hallvards verktøykasse. Stemmehammeren din ligger øverst, der den skal."},
				{"id": "toll", "name": "Tollbordet", "x": 1160, "w": 130, "h": 70, "c": WOOD, "mat": "wood",
					"examine": "Tavla er full av streker. Noen er strøket over og skrevet på nytt."},
				{"id": "kasse", "name": "Kasse", "x": 930, "w": 70, "h": 60, "c": WOOD, "mat": "hollow",
					"examine": "En kasse som er spikret igjen. Et segl er brent inn i treet: et skip under en vekt."},
				{"id": "fisk", "name": "Fiskekasser", "x": 620, "w": 170, "h": 50, "c": Color(0.55, 0.55, 0.6), "mat": "wood",
					"examine": "Sild. Så mye sild at lufta blir sølvfarget."},
				{"id": "under", "name": "Under brua", "x": 400, "y": 566, "w": 30, "h": 22, "c": Color(0.12, 0.12, 0.14),
					"if": "phase:morgen",
					"examine": {"do": ["set:saw_under_bridge"], "t": "Langt borte, nede ved brupilarene, står noen helt stille. Du blunker, og det er bare skygger."}},
			],
			"enter": [{"if": "!a_arrive", "do": ["set:a_arrive"], "d": "a_arrive"}],
		},
		"S1": {
			"name": "Saltbrygga", "w": 2400,
			"left": {"to": "T1", "x": 1900},
			"right": {"to": "A1", "x": 100, "lock": NIGHT_LOCK_A1},
			"decor": [
				{"x": 1200, "y": 470, "w": 2400, "h": 180, "c": MOUNTAIN, "ridge": true},
				{"x": 380, "y": 500, "w": 300, "h": 22, "c": FAR, "label": "Storbrua"},
				{"x": 760, "y": 450, "w": 16, "h": 140, "c": SPIRE, "label": "Kirkespiret", "spire": true},
				{"x": 1750, "y": 600, "w": 360, "h": 260, "c": Color(0.5, 0.36, 0.26), "label": "Vertshuset"},
				{"x": 1050, "y": 600, "w": 300, "h": 210, "c": Color(0.52, 0.28, 0.2)},
			],
			"objects": [
				{"id": "planker", "name": "Planker", "x": 260, "w": 80, "h": 120, "c": DARK_WOOD, "mat": "hollow",
					"if": "!gangway_open",
					"examine": "Plankene er spikret fast over en gammel åpning mot elvebredden. Det trekker kaldt mellom dem."},
				{"id": "gang", "name": "Gangen under brua", "x": 260, "w": 80, "h": 120, "c": Color(0.1, 0.1, 0.1),
					"if": "gangway_open", "door": {"to": "B2", "x": 330}},
				{"id": "munning", "name": "Elvemunningen", "x": 470, "w": 120, "h": 16, "c": RIVER,
					"examine": "Elva møter fjorden her. Brunt vann inn i grønt."},
				{"id": "tau", "name": "Tauverk", "x": 700, "w": 120, "h": 40, "c": Color(0.62, 0.55, 0.38),
					"examine": "Tau kveilet i hauger. Noen har spleiset pent, noen ikke."},
				{"id": "boder", "name": "Sjøbodene", "x": 1050, "w": 120, "h": 120, "c": DOOR, "mat": "wood",
					"examine": "Bodene står på påler over vannet. Det lukter tjære og tang."},
				{"id": "fiskebod", "name": "Fiskeboden", "x": 1350, "w": 130, "h": 120, "c": WOOD, "mat": "wood",
					"examine": [
						{"if": "phase:natt", "t": "Lukket. Måkene sitter på taket og venter."},
						{"t": "Kona i boden synger mens hun sløyer. Ikke en vise du kjenner."},
					]},
				{"id": "vertshus", "name": "Vertshuset", "x": 1750, "w": 80, "h": 150, "c": DOOR,
					"door": {"to": "V1", "x": 170}},
				{"id": "vaat_baat", "name": "Toras båt", "x": 1850, "w": 46, "h": 22, "c": DARK_WOOD,
					"if": "phase:natt&boat_launched", "mat": "hollow",
					"examine": {"do": ["set:saw_wet_boat"], "t": "Toras båt står på trappa utenfor vertshuset. Den er våt, og det henger tang i seilet. På kjølen, ved siden av ringen med de tre strekene: et svakt nytt merke. En bue, som en klokke sett fra siden."}},
			],
		},
		"V1": {
			"name": "Vertshuset", "w": 1600, "interior": true,
			"wall": Color(0.46, 0.34, 0.24), "ground": Color(0.34, 0.24, 0.16),
			"objects": [
				{"id": "dor", "name": "Døra ut", "x": 100, "w": 70, "h": 150, "c": DOOR, "door": {"to": "S1", "x": 1750}},
				{"id": "ildsted", "name": "Ildstedet", "x": 440, "w": 160, "h": 80, "c": Color(0.6, 0.28, 0.12), "mat": "stone",
					"examine": [
						{"if": "phase:natt", "t": "Glørne lyser fortsatt."},
						{"t": "Gryta henger over ilden. Det har den gjort i alle år, sier Ragna."},
					]},
				{"id": "langbord", "name": "Langbordet", "x": 760, "w": 320, "h": 46, "c": WOOD, "mat": "wood",
					"examine": "Hakk i kanten der folk har slått kruset i bordet. Mange hakk."},
				{"id": "disk", "name": "Disken", "x": 1000, "w": 150, "h": 80, "c": DARK_WOOD, "mat": "wood",
					"examine": "Disken er skrubbet blank. En rekke krus, alle med hanken mot venstre."},
				{"id": "kiste", "name": "Sjømannskisten", "x": 1320, "w": 110, "h": 55, "c": Color(0.3, 0.2, 0.16),
					"examine": [
						{"if": "chest_fixed", "t": "Sjømannskisten. Lokket er helt igjen; den nye biten er lysere enn resten."},
						{"do": ["set:saw_chest_damage"], "t": "En gammel sjømannskiste. Tømmermerke på siden: en ring med tre streker under. I lokket mangler en utskåret bit; kantene er ferske knivspor."},
					],
					"listen": {"snd": "hollow", "t": "Hul, dyp klang. Treverket er tettere enn noe annet i dette huset."}},
				{"id": "trapp", "name": "Trappa opp", "x": 1510, "w": 80, "h": 170, "c": DARK_WOOD, "door": {"to": "V2", "x": 130}},
			],
			"enter": [{"if": "phase:morgen&!inn_scene", "do": ["set:inn_scene"], "d": "inn_scene"}],
		},
		"V2": {
			"name": "Ingrids rom", "w": 1100, "interior": true,
			"wall": Color(0.42, 0.32, 0.24), "ground": Color(0.32, 0.23, 0.16),
			"decor": [{"x": 960, "y": 600, "w": 260, "h": 230, "c": Color(0.36, 0.27, 0.2), "label": "Hallvards alkove"}],
			"objects": [
				{"id": "trapp", "name": "Trappa ned", "x": 90, "w": 80, "h": 170, "c": DARK_WOOD, "door": {"to": "V1", "x": 1450}},
				{"id": "seng", "name": "Senga", "x": 380, "w": 200, "h": 46, "c": Color(0.6, 0.55, 0.4),
					"use": [
						{"if": "night_talk", "d": "n_bed"},
						{"if": "phase:natt", "t": "Du får ikke sove. Du ligger og lytter."},
						{"t": "Halmen stikker. Den lukter av andre folks netter."},
					]},
				{"id": "kasse", "name": "Verktøykassa", "x": 600, "w": 70, "h": 40, "c": WOOD, "mat": "hollow",
					"examine": "Verktøykassa. Stemmehammeren har du med deg; resten ligger her."},
				{"id": "brev", "name": "Brevet", "x": 760, "y": 540, "w": 50, "h": 26, "c": Color(0.85, 0.8, 0.65),
					"examine": "Hallvards bestillingsbrev. Seglet er ikke kirkens kors. Det er et skip under en vekt."},
				{"id": "veske", "name": "Reisevesken", "x": 840, "w": 60, "h": 46, "c": DARK_WOOD, "if": "night_bell",
					"examine": "Hallvards reiseveske. Ferdig pakket, og snøret knyttet med dobbel knute."},
				{"id": "vindu", "name": "Vinduet", "x": 1040, "y": 460, "w": 80, "h": 110, "c": Color(0.5, 0.62, 0.72),
					"examine": [
						{"if": "night_bell", "t": "Spiret står svart mot himmelen. Ingen lys i tårnet."},
						{"t": "Kirkebakken, og spiret mot himmelen."},
					]},
			],
			"enter": [{"if": "phase:natt&!n_start", "do": ["set:n_start"], "d": "n_start"}],
		},
		"T1": {
			"name": "Torget", "w": 2000,
			"left": {"to": "B1", "x": 1650},
			"right": {"to": "S1", "x": 100},
			"decor": [
				{"x": 1000, "y": 450, "w": 2000, "h": 160, "c": MOUNTAIN, "ridge": true},
				{"x": 150, "y": 520, "w": 300, "h": 140, "c": FOREST, "label": "Skogen"},
				{"x": 1000, "y": 420, "w": 20, "h": 180, "c": SPIRE, "label": "Kirkespiret", "spire": true},
				{"x": 1880, "y": 540, "w": 240, "h": 90, "c": WATER, "label": "Fjorden og mastene"},
				{"x": 1500, "y": 600, "w": 260, "h": 200, "c": Color(0.48, 0.38, 0.3)},
			],
			"objects": [
				{"id": "boder", "name": "Markedsbodene", "x": 320, "w": 220, "h": 90, "c": Color(0.6, 0.45, 0.3), "mat": "wood",
					"examine": [
						{"if": "phase:natt", "t": "Tomme boder med skoddene for."},
						{"t": "Ull, lin, honning, kammer av bein. Noen prøver å selge deg en kniv."},
					]},
				{"id": "smie", "name": "Smieskiltet", "x": 620, "y": 470, "w": 50, "h": 50, "c": STONE, "mat": "metal",
					"examine": "Et skilt med en hammer. Smia ligger et annet sted; skiltet ble hengende igjen."},
				{"id": "bakken", "name": "Kirkebakken", "x": 1000, "w": 120, "h": 170, "c": PATH,
					"door": {"to": "K1", "x": 160, "lock": [{"if": "phase:natt", "t": "Bakken er bekmørk. Ikke i natt."}]}},
				{"id": "bronn", "name": "Brønnen", "x": 1240, "w": 100, "h": 70, "c": STONE, "mat": "stone",
					"examine": "Vannet ligger langt nede. Det lukter jern.",
					"listen": {"snd": "stone", "t": "Steinen svarer tett og kort. Langt nede: et ekko som kommer litt for sent."}},
				{"id": "livdor", "name": "Livs verksted", "x": 1500, "w": 80, "h": 150, "c": DOOR,
					"door": {"to": "L1", "x": 160, "lock": [{"if": "phase:natt", "t": "Mørkt. Liv sover, eller later som."}]}},
				{"id": "baker", "name": "Bakerboden", "x": 1780, "w": 140, "h": 100, "c": Color(0.66, 0.5, 0.3), "mat": "wood",
					"examine": [
						{"if": "phase:morgen", "t": "Brødet er så ferskt at det damper."},
						{"if": "phase:natt", "t": "Lukket. Det lukter brød likevel."},
						{"t": "Tomt for brød. Bakeren ser fornøyd ut."},
					]},
			],
		},
		"L1": {
			"name": "Livs verksted", "w": 1200, "interior": true,
			"wall": Color(0.5, 0.42, 0.32), "ground": Color(0.4, 0.33, 0.24),
			"objects": [
				{"id": "dor", "name": "Døra ut", "x": 100, "w": 70, "h": 150, "c": DOOR, "door": {"to": "T1", "x": 1500}},
				{"id": "deler", "name": "Båtdeler", "x": 330, "w": 160, "h": 70, "c": WOOD, "mat": "wood",
					"examine": "Spant, bordganger og en halvferdig åre."},
				{"id": "benk", "name": "Høvelbenken", "x": 540, "w": 180, "h": 60, "c": DARK_WOOD, "mat": "wood",
					"examine": "Slitt blank. Høvelen ligger med eggen vendt bort, slik man gjør når man er nøye."},
				{"id": "tre", "name": "Tømmerstabelen", "x": 860, "w": 160, "h": 110, "c": Color(0.62, 0.5, 0.34),
					"examine": "Furu, eik, bjørk og ask, sortert etter hvor tørre de er.",
					"listen": {"snd": "wood", "t": "Du banker lett på stokk etter stokk. Furu, eik, bjørk. Alle svarer som de skal."}},
				{"id": "brev", "name": "Et brev", "x": 1060, "y": 500, "w": 46, "h": 30, "c": Color(0.85, 0.8, 0.65),
					"examine": "Et brev med segl: et skip under en vekt. Tall, og en sum som er streket under to ganger."},
			],
		},
		"B1": {
			"name": "Storbrua", "w": 1800, "walk_min": 60, "amb": "river", "ground_h": 26.0,
			"right": {"to": "T1", "x": 120},
			"ground": Color(0.48, 0.36, 0.24),
			"decor": [
				{"x": 900, "y": 470, "w": 1800, "h": 160, "c": MOUNTAIN, "ridge": true},
				{"x": 300, "y": 560, "w": 600, "h": 200, "c": FOREST, "label": "Skogsiden"},
				{"x": 1650, "y": 540, "w": 300, "h": 80, "c": WATER, "label": "Fjorden"},
				{"x": 900, "y": 720, "w": 1800, "h": 90, "c": RIVER, "water": true},
				{"x": 900, "y": 560, "w": 1800, "h": 8, "c": DARK_WOOD},
			],
			"objects": [
				{"id": "motsatt", "name": "Den andre siden", "x": 70, "w": 40, "h": 110, "c": Color(0.2, 0.2, 0.2),
					"if": "!phase:natt", "examine": "Brua fortsetter mot skogsiden. Dit har du ikke noe ærend i dag."},
				{"id": "skikkelse", "name": "Noe på brua", "x": 120, "w": 22, "h": 100, "c": Color(0.06, 0.06, 0.08),
					"hidden": true, "if": "phase:natt&night_bell",
					"examine": "Der står noen. Eller en stolpe. Det er for langt å se, og det står helt stille."},
				{"id": "utsikt", "name": "Utsikten", "x": 520, "w": 80, "h": 10, "c": DARK_WOOD,
					"examine": [
						{"if": "phase:natt", "t": "Mørkt vann, mørk skog. Det er vanskelig å si hvor langt det er til den andre siden."},
						{"t": "Fjorden på den ene siden, skogen på den andre. Elva kommer ut av skogen som om den har hastverk."},
					]},
				{"id": "nede", "name": "Nede ved vannet", "x": 860, "y": 690, "w": 40, "h": 50, "c": Color(0.1, 0.1, 0.12),
					"if": "phase:ettermiddag&!orm_gone",
					"examine": {"do": ["set:saw_under_bridge", "set:orm_gone"], "t": "Nede ved vannet, under brua, sitter noen på huk. Når du ser igjen, er det bare en stein."}},
				{"id": "pilar", "name": "Brupilaren", "x": 1060, "w": 50, "h": 70, "c": STONE, "mat": "wood",
					"examine": [
						{"if": "phase:morgen|phase:formiddag", "do": ["set:saw_watermark"], "t": "Du lener deg over rekkverket. På pilaren under deg er det et hakk i treverket. Vannet står like under det."},
						{"if": "phase:ettermiddag", "do": ["set:saw_watermark"], "t": "Vannet står akkurat ved hakket i pilaren."},
						{"do": ["set:saw_watermark"], "t": "Vannet står over hakket i pilaren. Ikke mye. Litt."},
					]},
				{"id": "trapp", "name": "Trappa ned til vannet", "x": 1460, "w": 80, "h": 130, "c": PATH, "door": {"to": "B2", "x": 1560}},
				{"id": "boder", "name": "Bodene ved brofestet", "x": 1680, "w": 150, "h": 100, "c": Color(0.6, 0.45, 0.3), "mat": "wood",
					"examine": [
						{"if": "phase:natt", "t": "Skoddene er for. Noen har glemt en fiskekurv."},
						{"t": "Små boder som klamrer seg til brua. En kone selger røkt laks og meninger."},
					]},
			],
		},
		"B2": {
			"name": "Under brua", "w": 1800, "amb": "river",
			"sky": Color(0.32, 0.36, 0.38), "ground": Color(0.36, 0.34, 0.3),
			"decor": [
				{"x": 900, "y": 300, "w": 1800, "h": 60, "c": DARK_WOOD, "label": "Storbrua over deg"},
				{"x": 520, "y": 600, "w": 30, "h": 330, "c": DARK_WOOD},
				{"x": 1340, "y": 600, "w": 30, "h": 330, "c": DARK_WOOD},
				{"x": 900, "y": 720, "w": 1800, "h": 100, "c": RIVER, "water": true},
			],
			"objects": [
				{"id": "drivved", "name": "Drivved", "x": 260, "w": 120, "h": 70, "c": Color(0.5, 0.45, 0.38), "mat": "wood",
					"if": "!found_gangway",
					"examine": {"do": ["set:found_gangway"], "t": "Bak drivveden: gamle planker over en gang. Det trekker luft fra den andre siden."}},
				{"id": "plankene", "name": "Plankene", "x": 260, "w": 90, "h": 120, "c": DARK_WOOD, "mat": "hollow",
					"if": "found_gangway&!gangway_open",
					"examine": "Gamle planker over en gang langs elvebredden. De sitter løsere enn de ser ut.",
					"use": {"do": ["set:gangway_open"], "snd": "wood", "t": "Du vrir plankene løs. Gangen bak følger elvebredden, mot brygga."}},
				{"id": "gang", "name": "Gangen", "x": 260, "w": 90, "h": 120, "c": Color(0.1, 0.1, 0.1),
					"if": "gangway_open", "door": {"to": "S1", "x": 330}},
				{"id": "skikkelse", "name": "Skikkelsen", "x": 430, "w": 34, "h": 100, "c": Color(0.12, 0.11, 0.12),
					"if": "phase:ettermiddag&!orm_gone",
					"examine": {"do": ["set:orm_gone", "set:saw_under_bridge"], "t": "Han ser opp. Så er han borte mellom pålene."}},
				{"id": "orm_sone", "zone": {"x0": 0, "x1": 720, "if": "phase:ettermiddag&!orm_gone", "do": ["set:orm_gone", "set:saw_under_bridge"]}},
				{"id": "teppe", "name": "Et teppe", "x": 640, "w": 110, "h": 30, "c": Color(0.4, 0.36, 0.3),
					"examine": [
						{"if": "phase:ettermiddag", "t": "En bunt fiskeskinn og et ullteppe. Ullen er fortsatt varm."},
						{"t": "En bunt fiskeskinn og et ullteppe. Kaldt."},
					]},
				{"id": "riss", "name": "Rissene", "x": 860, "y": 500, "w": 36, "h": 36, "c": Color(0.36, 0.3, 0.24), "hidden": true, "mat": "wood",
					"examine": {"do": ["set:saw_bow_mark"], "t": "Langt inne på en stokk, nesten borte: en bue, som en klokke sett fra siden."}},
				{"id": "fundament", "name": "Fundamentene", "x": 1040, "w": 200, "h": 200, "c": STONE, "mat": "stone",
					"examine": "Gamle steinfundamenter. Eldre enn brua over dem."},
				{"id": "merke", "name": "Tømmermerket", "x": 1170, "y": 520, "w": 40, "h": 40, "c": DETAIL, "mat": "wood",
					"examine": {"do": ["set:saw_timber_mark"], "t": "Risset inn i en gammel stokk: en ring med tre streker under. Halvt grodd igjen."}},
				{"id": "elvekant", "name": "Elvekanten", "x": 1320, "w": 100, "h": 12, "c": RIVER,
					"examine": "Elva går fort og blank her. Den tar med seg det den får."},
				{"id": "trapp", "name": "Trappa opp", "x": 1600, "w": 80, "h": 170, "c": PATH, "door": {"to": "B1", "x": 1460}},
			],
			"enter": [{"if": "phase:natt&!n_sing", "d": "n_sing"}],
		},
		"K1": {
			"name": "Kirkebakken", "w": 1400,
			"decor": [
				{"x": 700, "y": 600, "w": 1400, "h": 300, "c": FOREST, "label": "Skogen bak kirken"},
				{"x": 1150, "y": 600, "w": 340, "h": 260, "c": Color(0.36, 0.26, 0.18), "label": "Stavkirken"},
				{"x": 1150, "y": 340, "w": 24, "h": 150, "c": SPIRE, "spire": true},
			],
			"objects": [
				{"id": "ned", "name": "Ned til Torget", "x": 100, "w": 110, "h": 160, "c": PATH, "door": {"to": "T1", "x": 1000}},
				{"id": "utsikt", "name": "Utsikten", "x": 360, "w": 80, "h": 10, "c": STONE,
					"examine": "Herfra ser du nesten alt: brygga, Torget, Storbrua. Fjorden blank bak mastene, skogen svart bak kirken."},
				{"id": "mur", "name": "Kirkegårdsmuren", "x": 640, "w": 260, "h": 60, "c": STONE, "mat": "stone",
					"examine": "Kirkegården er ny. Bare tre graver ennå."},
				{"id": "dor", "name": "Kirkedøra", "x": 1140, "w": 80, "h": 160, "c": DOOR, "door": {"to": "K2", "x": 160}},
				{"id": "terskel", "name": "Dørterskelen", "x": 1200, "w": 26, "h": 8, "c": DARK_WOOD, "hidden": true, "mat": "wood",
					"examine": {"do": ["set:saw_rune"], "t": "Under dørterskelen, der ingen ser: en rune, risset dypt. Den er eldre enn døra."}},
			],
		},
		"K2": {
			"name": "Stavkirken", "w": 1400, "interior": true,
			"wall": Color(0.4, 0.3, 0.22), "ground": Color(0.3, 0.22, 0.15),
			"objects": [
				{"id": "dor", "name": "Døra ut", "x": 100, "w": 70, "h": 160, "c": DOOR, "door": {"to": "K1", "x": 1140}},
				{"id": "soyle", "name": "Søylen", "x": 440, "w": 40, "h": 320, "c": DARK_WOOD, "mat": "wood",
					"examine": "Gulvet rundt søylen er slitt i en ring, som om noen har gått rundt og rundt den. Lenge."},
				{"id": "alter", "name": "Alteret", "x": 680, "w": 160, "h": 90, "c": Color(0.55, 0.45, 0.3), "mat": "wood",
					"examine": "Lys, et kors og et klede med ny brodering."},
				{"id": "kirkebok", "name": "Kirkeboka", "x": 960, "w": 60, "h": 70, "c": Color(0.5, 0.36, 0.22),
					"examine": [
						{"if": "eirik_page|phase:ettermiddag", "t": "Kirkeboka. En av de løse sidene er borte. Tråden i ryggen er fersk revet."},
						{"t": "Kirkeboka. Navn, datoer, dåp. Noen av sidene ligger løse."},
					]},
				{"id": "trapp", "name": "Tårntrappa", "x": 1290, "w": 80, "h": 200, "c": DARK_WOOD, "door": {"to": "K3", "x": 200}},
			],
		},
		"K3": {
			"name": "Klokkerommet", "w": 1500, "interior": true,
			"wall": Color(0.58, 0.5, 0.4), "ground": Color(0.42, 0.34, 0.26),
			"objects": [
				{"id": "trapp", "name": "Trappa ned", "x": 100, "w": 80, "h": 170, "c": DARK_WOOD, "door": {"to": "K2", "x": 1280}},
				{"id": "stillas", "name": "Stillaset", "x": 360, "w": 110, "h": 300, "c": WOOD, "mat": "wood",
					"examine": "Stillaset er nytt. Noen har bundet det sammen i hast."},
				{"id": "tau", "name": "Klokketauet", "x": 540, "y": 560, "w": 12, "h": 300, "c": Color(0.62, 0.55, 0.38),
					"examine": "Tauet er knyttet fast oppe ved bjelken, så ingen skal kunne ringe."},
				{"id": "klokke", "name": "Klokken", "x": 850, "y": 520, "w": 280, "h": 250, "c": Color(0.66, 0.5, 0.24),
					"examine": "Bronsen er ny, sier de. Den er blankere enn den er gammel.",
					"listen": {"snd": "bell_crack", "do": ["set:bell_listened"], "t": "Tonen brytes. Det skramler i den, som et skår i en stemme."}},
				{"id": "sprekk", "name": "Sprekken", "x": 760, "y": 520, "w": 40, "h": 70, "c": Color(0.25, 0.18, 0.1),
					"examine": {"do": ["set:bell_crack"], "t": "En sprekk fra kanten og oppover, en håndsbredd lang. Kantene er skarpe."},
					"listen": {"snd": "bell_crack", "do": ["set:bell_listened"], "t": "Ved sprekken surrer det, som en flue i et glass."}},
				{"id": "reparasjon", "name": "Reparasjonen", "x": 880, "y": 460, "w": 40, "h": 40, "c": Color(0.5, 0.42, 0.3),
					"examine": {"do": ["set:bell_repair"], "t": "Noen har reparert her før. Verktøysporene går på skrå, ikke slik Hallvard lærte deg."},
					"listen": {"snd": "bell_old", "do": ["set:bell_listened"], "t": "Matt. Klangen dør fortere her."}},
				{"id": "skjot", "name": "Skjøten", "x": 960, "y": 520, "w": 26, "h": 200, "c": Color(0.63, 0.48, 0.24), "hidden": true,
					"examine": {"do": ["set:bell_seam"], "t": "Nesten usynlig: en tynn linje der bronsen skifter farge. To støp, smeltet sammen."},
					"listen": {"snd": "bell_ok", "do": ["set:bell_listened"], "t": "Ren klang, akkurat her."}},
				{"id": "skjot_h", "name": "Skjøten", "x": 996, "y": 520, "w": 26, "h": 200, "c": Color(0.66, 0.5, 0.24), "hidden": true,
					"examine": "Bronsen er kaldere på denne siden.",
					"listen": {"snd": "bell_second", "do": ["set:bell_second", "set:bell_listened"], "t": "Under grunntonen: en annen tone. Dypere. Den kommer ikke fra der du slo."}},
				{"id": "bord", "name": "Arbeidsbordet", "x": 1180, "w": 150, "h": 70, "c": WOOD, "mat": "wood",
					"examine": "Kritt, tråd og en vokstavle full av Hallvards tall."},
				{"id": "glugg", "name": "Gluggen", "x": 1410, "y": 440, "w": 70, "h": 110, "c": Color(0.5, 0.62, 0.72),
					"examine": "Skogen bak kirken. Et sted der inne går veien gjennom Skogporten."},
			],
			"enter": [{"if": "phase:formiddag&!k3_intro", "do": ["set:k3_intro"], "d": "k3_intro"}],
		},
	}
