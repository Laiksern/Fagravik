extends RefCounted
## Alle dialoger og fortellerscener i prototypen.
##
## En dialog er en ordbok med noder. Spillet starter i "start".
## Hver node er en liste med steg som kjøres i rekkefølge:
##   {"s": taler, "t": tekst}     replikk ("" er forteller, ukjente navn vises som de står)
##   {"choices": [...]}           valg: {"t": tekst, "if": betingelse, "goto": node | "end": true, "do": [...]}
##   {"do": [...]}                operasjoner (se state.gd), "sfx:lyd" og "event:hendelse"
##   {"goto": node} / {"end": true}
## Alle steg kan ha "if": steget hoppes over når betingelsen ikke stemmer.
## Hendelser ("event:...") kjøres når dialogen er ferdig.
##
## Hjelpeprinsipp: ingen linje skal tolke for spilleren. Personer kan ta feil,
## og fortelleren beskriver bare det Ingrid ser og hører.


static func all() -> Dictionary:
	return {
		# ================================================================ PROLOG
		"p_intro": {"start": [
			{"s": "", "t": "Våren 1054."},
			{"do": ["sfx:sung"]},
			{"s": "mor", "t": "♪ Sov nå, vesle, vinden er stille, elva går sakte forbi …"},
			{"s": "mor", "t": "♪ Bronsen skal vake når natta blir kald, og mor skal synge for deg."},
		]},
		"p_friend": {
			"start": [
				{"if": "p_swapped", "goto": "after"},
				{"s": "venn", "t": "Byttelek! Du får kappa mi, og jeg får din."},
				{"s": "venn", "t": "Så er du meg, og jeg er deg, og ingen vet noe."},
				{"choices": [
					{"t": "Bytt kappe.", "goto": "swap"},
					{"t": "Ikke nå.", "goto": "no"},
				]},
			],
			"swap": [
				{"do": ["set:p_swapped", "sfx:cloth"]},
				{"s": "", "t": "Den røde kappa blir hennes. Den blå blir din. Den lukter av henne."},
				{"s": "venn", "t": "Hvis noen roper på deg nå, er det meg de mener."},
				{"do": ["set:p_alarm"]},
				{"s": "Noen ute", "t": "Elva! Elva går over!"},
				{"s": "mor", "t": "Løp til hovet og slå bronsen. Fort, så alle hører det!"},
				{"s": "", "t": "Venninnen er allerede ute av døra."},
			],
			"no": [{"s": "venn", "t": "Feiging. Jeg spør igjen."}],
			"after": [{"s": "venn", "t": "Hysj. Ikke si det til noen."}],
		},
		"p_outside": {"start": [
			{"s": "Noen", "t": "Bronsen! Hvem slår bronsen?"},
			{"s": "", "t": "Regnet slår deg i ansiktet. Elva brøler et sted i mørket."},
		]},
		"p_hook": {"start": [
			{"s": "", "t": "Kroken under taket er tom."},
			{"s": "", "t": "Bronsen som alltid henger der, henger ikke der."},
			{"do": ["set:p_hook"]},
			{"s": "", "t": "Over elva: et lys. En kvinne med lykt. Hun roper noe."},
		]},
		"p_end": {"start": [
			{"do": ["set:p_ended"]},
			{"s": "", "t": "Hun roper igjen. Regnet tar ordene."},
			{"s": "", "t": "Så kommer vannet."},
			{"do": ["event:prologue_end"]},
		]},

		# ================================================================ MORGEN
		"a_arrive": {
			"start": [
				{"s": "hallvard", "t": "Fagravik! Kjenn på lufta, Ingrid. Tjære, salt og noen som baker."},
				{"s": "hallvard", "t": "Jeg må telle papirer med årmannen. Gå i forveien til vertshuset. Ragna heter hun som har det."},
				{"choices": [
					{"t": "Hvor er vertshuset?", "goto": "where"},
					{"t": "Greit.", "end": true},
				]},
			],
			"where": [{"s": "hallvard", "t": "Langs brygga. Det er bare én brygge, Ingrid. Du klarer det."}],
		},
		"a_hallvard": {
			"start": [
				{"s": "hallvard", "t": "Vertshuset, Ingrid. Jeg kommer."},
				{"choices": [
					{"t": "Hvorfor oss? Det finnes klokkestøpere i Nidaros.", "if": "!asked_why", "goto": "why"},
					{"t": "Jeg går.", "end": true},
				]},
			],
			"why": [
				{"do": ["set:asked_why"]},
				{"s": "hallvard", "t": "Fordi de spurte meg."},
				{"s": "hallvard", "t": "Og fordi de betaler godt."},
			],
		},
		"a_audun": {
			"start": [
				{"s": "audun", "t": "Kongens årmann. Du er lærlingen?"},
				{"choices": [
					{"t": "Ingrid. Jeg er med Hallvard.", "if": "!asked_audun_name", "goto": "name"},
					{"t": "Hva gjør en årmann?", "if": "!asked_audun_job", "goto": "job"},
					{"t": "Ingenting.", "end": true},
				]},
			],
			"name": [
				{"do": ["set:asked_audun_name"]},
				{"s": "audun", "t": "Hallvard."},
				{"s": "audun", "t": "Hallvard. Ja."},
				{"s": "", "t": "Han setter et merke på tavla. Så ett til."},
			],
			"job": [
				{"do": ["set:asked_audun_job"]},
				{"s": "audun", "t": "Jeg teller det som kommer i land, og det som går ut. Og jeg husker."},
				{"goto": "start"},
			],
		},
		"a_tora": {
			"start": [
				{"if": "tora_a1", "goto": "again"},
				{"do": ["set:tora_a1"]},
				{"s": "tora", "t": "Er det verktøy i den kassa? Hva slags verktøy?"},
				{"choices": [
					{"t": "En stemmehammer.", "goto": "hammer"},
					{"t": "Hvem er du?", "goto": "who"},
				]},
			],
			"hammer": [
				{"s": "tora", "t": "Hva stemmer man med en hammer?"},
				{"s": "ingrid", "t": "Klokker."},
				{"s": "tora", "t": "Kirkeklokka er sprukket. Folk sier det er et dårlig tegn. Mor sier det er dårlig bronse."},
			],
			"who": [
				{"s": "tora", "t": "Ingen!"},
				{"s": "", "t": "Hun forsvinner bak fiskekassene før du rekker å spørre igjen."},
			],
			"again": [{"s": "tora", "t": "Jeg følger ikke etter deg. Jeg går bare samme vei."}],
		},
		"a_worker": {"start": [
			{"s": "worker", "t": "Ser du spiret der oppe? Den første kirkeklokka i hele fjorden. Før Vangsnes, før alle."},
			{"s": "worker", "t": "Synd hun sprakk. Men den var først."},
		]},
		"inn_scene": {"start": [
			{"s": "ragna", "t": "Klokkestøperne! Kom inn, kom inn. Det trekker."},
			{"s": "", "t": "Ved langbordet sitter en jente med noe i fanget. Når Ragna snur seg, er det borte under bordet."},
			{"s": "ragna", "t": "Tora, hils på gjestene."},
			{"do": ["set:met_tora"]},
			{"s": "tora", "t": "Hei."},
			{"s": "hallvard", "t": "Hallvard. Og dette er Ingrid, lærlingen min. Den beste jeg har hatt, men ikke si det til henne."},
			{"s": "ragna", "t": "Ingrid. Og hvem er mora di, Ingrid?"},
			{"s": "hallvard", "t": "Signe het hun."},
			{"s": "", "t": "Ragna setter fra seg kruset."},
			{"s": "ragna", "t": "Signe. Ja vel. Dere skal få rommet øverst, med utsikt mot kirken."},
			{"s": "hallvard", "t": "Jeg setter fra meg sakene. Snakk med meg når du er klar, så går vi opp til klokken."},
		]},
		"v_hallvard_go": {
			"start": [
				{"s": "hallvard", "t": "Klar?"},
				{"choices": [
					{"t": "Klar.", "goto": "go"},
					{"t": "Ikke ennå.", "goto": "wait"},
				]},
			],
			"wait": [{"s": "hallvard", "t": "Ikke for lenge. Bronse venter, men prester gjør det ikke."}],
			"go": [
				{"s": "hallvard", "t": "Opp fra brygga, over Torget, og følg bakken til kirken. Jeg går i forveien."},
				{"do": ["phase:formiddag"]},
			],
		},
		"v_tora": {
			"start": [
				{"if": "phase:morgen", "s": "tora", "t": "Du så ingenting under bordet."},
				{"if": "phase:morgen", "end": true},
				{"s": "tora", "t": "Har du sett på klokka? Blir den hel igjen?"},
				{"choices": [
					{"t": "Hallvard kan fikse det meste.", "goto": "fix"},
					{"t": "Det vet jeg ikke ennå.", "goto": "dunno"},
				]},
			],
			"fix": [{"s": "tora", "t": "Det meste. Ikke alt, da."}],
			"dunno": [{"s": "tora", "t": "Du er ærlig. Det er rart."}],
		},
		"r_hum": {"start": [
			{"do": ["sfx:cup", "set:ragna_hum"]},
			{"s": "", "t": "Et krus slår i gulvet."},
			{"s": "ragna", "t": "Å, se nå. Klumsete."},
			{"s": "ragna", "t": "Den visa … nei. Den har jeg aldri hørt."},
		]},

		# ================================================================ RAGNA
		"r_ragna": {
			"start": [
				{"if": "phase:morgen", "s": "ragna", "t": "Sett deg, sett deg. Eller ikke. Dere er visst travle folk."},
				{"if": "phase:formiddag", "s": "ragna", "t": "Glemte du noe, eller er det bare her det er varmt?"},
				{"if": "phase:ettermiddag", "s": "ragna", "t": "Suppe om en stund. Ikke spør hva som er i den."},
				{"goto": "menu"},
			],
			"menu": [{"choices": [
				{"t": "Fortell om Fagravik.", "if": "!asked_town", "goto": "town"},
				{"t": "Kjente du mora mi?", "if": "!asked_signe", "goto": "signe"},
				{"t": "Bor det noen under brua?", "if": "saw_under_bridge&!asked_r_bridge", "goto": "bridge"},
				{"t": "Hallvard trenger talg.", "if": "wants_talg&!has:talg&!talg_given", "goto": "talg"},
				{"t": "Kisten din. Det mangler en bit av lokket.", "if": "knows_source&!tora_told&!ingrid_told", "goto": "chest"},
				{"t": "Jeg er klar for kveldsmåltidet.", "if": "phase:ettermiddag", "goto": "meal"},
				{"t": "Ingenting.", "end": true},
			]}],
			"town": [
				{"do": ["set:asked_town"]},
				{"s": "ragna", "t": "Fisk, tømmer og folk som vet for mye om hverandre. Og en bru vi er stoltere av enn vi burde."},
				{"s": "ragna", "t": "Og nå en kirke med klokke. Fjordens første. Det kommer du til å høre mange ganger."},
				{"goto": "menu"},
			],
			"signe": [
				{"do": ["set:asked_signe"]},
				{"s": "ragna", "t": "Mange heter Signe. Var hun herfra?"},
				{"s": "ingrid", "t": "Jeg vet ikke. Hun snakket aldri om hvor hun kom fra."},
				{"s": "ragna", "t": "Nei. Det er mange som ikke gjør det."},
				{"goto": "menu"},
			],
			"bridge": [
				{"do": ["set:asked_r_bridge"]},
				{"s": "ragna", "t": "Under brua? Nei, kjære deg. Der bor ingen. Bare måker og gamle planker."},
				{"goto": "menu"},
			],
			"talg": [
				{"do": ["give:talg"]},
				{"s": "ragna", "t": "Talg skal han få. Og si at han skal spise, ikke bare regne."},
				{"goto": "menu"},
			],
			"chest": [
				{"s": "ragna", "t": "Jeg vet det."},
				{"s": "ragna", "t": "Jeg vet bare ikke hvem."},
				{"choices": [
					{"t": "Det var Tora. Hun har skåret en båt av den.", "goto": "tell"},
					{"t": "Jeg vet ikke heller.", "goto": "menu"},
				]},
			],
			"tell": [
				{"do": ["set:ingrid_told"]},
				{"s": "ragna", "t": "Tora."},
				{"s": "", "t": "Ragna ser ned i disken en lang stund."},
				{"s": "ragna", "t": "Takk for at du sa det. Liv får lappe den."},
				{"goto": "menu"},
			],
			"meal": [
				{"s": "ragna", "t": "Da setter vi oss. Ikke hent Hallvard, han kommer når han lukter maten."},
				{"do": ["event:meal"]},
			],
		},

		# ================================================================ KIRKEN
		"k3_intro": {"start": [
			{"s": "hallvard", "t": "Der er hun. Første klokke i fjorden, sier de, og de sier det ofte."},
			{"s": "hallvard", "t": "Se på henne. Lytt til henne. Så forteller du meg hva hun sier."},
		]},
		"k3_hallvard": {
			"start": [
				{"if": "bell_reported", "goto": "busy"},
				{"s": "hallvard", "t": "Vel?"},
				{"choices": [
					{"t": "Sprekken er ny. Kantene er skarpe.", "if": "bell_crack&!rep_crack", "goto": "crack"},
					{"t": "Noen har reparert henne før. Med andre verktøy enn våre.", "if": "bell_repair&!rep_repair", "goto": "repair"},
					{"t": "Hun er støpt i to omganger.", "if": "bell_seam&!rep_seam", "goto": "seam"},
					{"t": "Det er en tone til. Under grunntonen.", "if": "bell_second&!rep_second", "goto": "second"},
					{"t": "Ikke ferdig ennå.", "end": true},
				]},
			],
			"crack": [
				{"do": ["set:rep_crack"]},
				{"s": "hallvard", "t": "Ja. Et år, kanskje to. Kulde, eller en kølle i feil hånd."},
				{"goto": "check"},
			],
			"repair": [
				{"do": ["set:rep_repair"]},
				{"s": "hallvard", "t": "…"},
				{"s": "hallvard", "t": "Godt sett. Gammelt arbeid. Ikke dårlig, bare gammeldags."},
				{"goto": "check"},
			],
			"seam": [
				{"do": ["set:rep_seam"]},
				{"s": "hallvard", "t": "Godt øye."},
				{"goto": "check"},
			],
			"second": [
				{"do": ["set:rep_second"]},
				{"s": "hallvard", "t": "Urenhet. Gammel bronse som er smeltet om. Det hender."},
				{"goto": "check"},
			],
			"check": [
				{"if": "rep_crack&rep_repair", "goto": "done"},
				{"goto": "start"},
			],
			"done": [
				{"s": "hallvard", "t": "Da vet vi hva vi har med å gjøre. Jeg trenger ettermiddagen til å regne."},
				{"s": "hallvard", "t": "Gå ut og se byen. Si fra når du er sulten. Og om du går forbi Ragna: talg. Jeg trenger talg."},
				{"do": ["set:bell_reported", "set:wants_talg", "phase:ettermiddag"]},
			],
			"busy": [{"s": "hallvard", "t": "Tall, Ingrid. Stille, vær så snill."}],
		},
		"e_hallvard": {
			"start": [
				{"s": "hallvard", "t": "Hm?"},
				{"choices": [
					{"t": "Talg, fra Ragna.", "if": "has:talg", "goto": "talg"},
					{"t": "Hvorfor oss? Det finnes klokkestøpere i Nidaros.", "if": "!asked_why", "goto": "why"},
					{"t": "Jeg er klar for kveldsmåltidet.", "goto": "meal"},
					{"t": "Ingenting.", "end": true},
				]},
			],
			"talg": [
				{"do": ["take:talg", "set:talg_given"]},
				{"s": "hallvard", "t": "Du er gull verdt. Ikke si det til noen, da blir du dyr."},
				{"goto": "start"},
			],
			"why": [
				{"do": ["set:asked_why"]},
				{"s": "hallvard", "t": "Fordi de spurte meg."},
				{"s": "hallvard", "t": "Og fordi de betaler godt."},
				{"goto": "start"},
			],
			"meal": [
				{"s": "hallvard", "t": "Gå i forveien. Jeg kommer når tallene går opp."},
				{"do": ["event:meal"]},
			],
		},
		"k_eirik": {
			"start": [
				{"if": "!met_eirik", "s": "eirik", "t": "Velkommen. Du må være klokkestøperens lærling. Eirik, prest her, så godt jeg kan."},
				{"if": "met_eirik", "s": "eirik", "t": "Ingrid."},
				{"do": ["set:met_eirik"]},
				{"goto": "menu"},
			],
			"menu": [{"choices": [
				{"t": "Når sprakk klokken?", "if": "!asked_e_crack", "goto": "crack"},
				{"t": "Hvem har reparert klokken før?", "if": "bell_repair&!asked_e_repair", "goto": "repair"},
				{"t": "Det er risset noe under dørterskelen.", "if": "saw_rune&!asked_e_rune", "goto": "rune"},
				{"t": "Ingenting.", "end": true},
			]}],
			"crack": [
				{"do": ["set:asked_e_crack"]},
				{"s": "eirik", "t": "Ved midtsommer. Vi har ikke ringt med henne siden."},
				{"s": "eirik", "t": "Folk sier det er et tegn. Jeg sier det er kulde og dårlig bronse. Kanskje vi har rett alle sammen."},
				{"goto": "menu"},
			],
			"repair": [
				{"do": ["set:asked_e_repair"]},
				{"s": "eirik", "t": "Før? Nei. Hun er ny. Hun har aldri vært reparert."},
				{"goto": "menu"},
			],
			"rune": [
				{"do": ["set:asked_e_rune"]},
				{"s": "eirik", "t": "Gammelt tømmer. Kirken er bygget av stokker som har stått andre steder før."},
				{"s": "eirik", "t": "Gud kan bruke gammelt tre like godt som nytt."},
				{"goto": "menu"},
			],
		},

		# ================================================================ BYFOLK
		"t_audun": {
			"start": [
				{"s": "audun", "t": "Lærlingen. Har mesteren din funnet ut hva klokken feiler?"},
				{"choices": [
					{"t": "Den er sprukket.", "goto": "a"},
					{"t": "Det må du spørre ham om.", "goto": "b"},
				]},
			],
			"a": [{"s": "audun", "t": "Det visste vi. Det var ikke det jeg spurte om."}],
			"b": [
				{"s": "audun", "t": "Det skal jeg."},
				{"s": "", "t": "Han går ikke. Han blir stående og se mot kirkebakken."},
			],
		},
		"s_sjur": {
			"start": [
				{"if": "!met_sjur", "s": "sjur", "t": "Klokkestøpere, hva? Da har dere kommet for å høre på den gamle damen i tårnet."},
				{"if": "met_sjur", "s": "sjur", "t": "Jenta med hammeren."},
				{"do": ["set:met_sjur"]},
				{"goto": "menu"},
			],
			"menu": [{"choices": [
				{"t": "Fortell en historie.", "goto": "story"},
				{"t": "Bor det noen under brua?", "if": "saw_under_bridge&!asked_s_bridge", "goto": "bridge"},
				{"t": "Se på båten til Tora.", "if": "room:B1&tora_showed&!talked_sjur_wood&!ingrid_told", "goto": "boat"},
				{"t": "Ingenting.", "end": true},
			]}],
			"story": [
				{"if": "!sjur_story", "goto": "s1"},
				{"if": "sjur_story=1", "goto": "s2"},
				{"if": "sjur_story=2", "goto": "s3"},
				{"s": "sjur", "t": "Nei, nå er jeg tom. Kom igjen i morgen, så har jeg funnet på noen nye. Eller husket dem."},
				{"goto": "menu"},
			],
			"s1": [
				{"do": ["set:sjur_story=1"]},
				{"s": "sjur", "t": "Nøkken bor i Fagraelva. Om natta spiller han fele under brua."},
				{"s": "sjur", "t": "Hører du ham, skal du ikke gå nærmere. Han har tatt bedre folk enn deg."},
				{"goto": "menu"},
			],
			"s2": [
				{"do": ["set:sjur_story=2"]},
				{"s": "sjur", "t": "Draugen ror i en halv båt. Ser du ham, har havet bestemt seg."},
				{"s": "sjur", "t": "Jeg har sett ham to ganger. Jeg er her ennå, så han bommer av og til."},
				{"goto": "menu"},
			],
			"s3": [
				{"do": ["set:sjur_story=3"]},
				{"s": "sjur", "t": "De gamle sa at det fantes en bronse som ropte når elva ville ta noen."},
				{"s": "sjur", "t": "Da visste alle at de skulle løpe."},
				{"s": "sjur", "t": "Nå har vi kirkeklokke. Den ringer når presten vil."},
				{"goto": "menu"},
			],
			"bridge": [
				{"do": ["set:asked_s_bridge"]},
				{"s": "sjur", "t": "Under brua? Der bor ingen. Måker og gamle planker."},
				{"s": "", "t": "Han trommer videre mot treverket."},
				{"goto": "menu"},
			],
			"boat": [
				{"do": ["set:talked_sjur_wood", "give:seil"]},
				{"s": "sjur", "t": "La meg se, jenta."},
				{"s": "", "t": "Sjur snur båten i hendene. Han kjenner på kjølen med tommelen."},
				{"s": "sjur", "t": "Det der er ikke vanlig furu. Det er tømmer fra oppe ved den gamle renna."},
				{"s": "sjur", "t": "Det fløt ned en vår for lenge siden. Fint tre. Sånt får man ikke tak i lenger."},
				{"s": "tora", "t": "Jeg fant det."},
				{"s": "sjur", "t": "Mm."},
				{"s": "", "t": "Han tar et stykke seilduk fra lommen, skjærer det til og gir det til deg."},
				{"s": "sjur", "t": "Hun trenger seil. Knuten tar dere selv."},
				{"goto": "menu"},
			],
		},
		"l_liv": {
			"start": [
				{"if": "!met_liv", "s": "liv", "t": "Klokkestøperens jente. Bronse og bjeller. Her lager vi ting som flyter."},
				{"if": "met_liv", "s": "liv", "t": "Ja?"},
				{"do": ["set:met_liv"]},
				{"goto": "menu"},
			],
			"menu": [{"choices": [
				{"t": "Hva lager du?", "if": "!asked_liv_work", "goto": "work"},
				{"t": "Kan du reparere en kiste?", "if": "knows_source&!talked_liv_chest&!chest_fixed", "goto": "chest"},
				{"t": "Kan du lappe den uten at Ragna merker det?", "if": "talked_liv_chest&tora_secret&!chest_fixed", "goto": "secret"},
				{"t": "Jeg har et stykke fint tre.", "if": "talked_liv_chest&talked_sjur_wood&has:fint_tre&!chest_fixed", "goto": "wood"},
				{"t": "Ingenting.", "end": true},
			]}],
			"work": [
				{"do": ["set:asked_liv_work"]},
				{"s": "liv", "t": "Færinger, mest. Årer. Det folk trenger, ikke det de vil ha."},
				{"s": "liv", "t": "Ikke rør høvelen."},
				{"goto": "menu"},
			],
			"chest": [
				{"do": ["set:talked_liv_chest"]},
				{"s": "liv", "t": "Hvilken kiste?"},
				{"s": "ingrid", "t": "Ragnas sjømannskiste. Det mangler en bit av lokket."},
				{"s": "liv", "t": "Og biten er …?"},
				{"s": "", "t": "Du sier ingenting. Liv ser lenge på deg."},
				{"s": "liv", "t": "Tora har gått rundt med noe under armen i en uke."},
				{"s": "liv", "t": "Jeg kan lappe kisten. Men da må biten tilbake, og den båten tas fra hverandre."},
				{"s": "liv", "t": "Med mindre jeg får et stykke tre som tåler å stå ved siden av det gamle. Det har jeg ikke."},
				{"goto": "menu"},
			],
			"secret": [
				{"do": ["set:chest_fixed", "set:chest_secret"]},
				{"s": "liv", "t": "Merker det? Ragna kjenner hver skramme i det huset."},
				{"s": "liv", "t": "Men greit. Jeg tar det før maten, med det treet jeg har."},
				{"goto": "menu"},
			],
			"wood": [
				{"do": ["take:fint_tre", "set:wood_given", "set:chest_fixed"]},
				{"s": "liv", "t": "La meg se."},
				{"s": "liv", "t": "Dette er godt tre. Sparte du det til noe?"},
				{"choices": [
					{"t": "Svennestykket mitt.", "goto": "wood_true"},
					{"t": "Ikke til noe viktig.", "goto": "wood_lie"},
				]},
			],
			"wood_true": [
				{"s": "liv", "t": "Da er du dummere enn jeg trodde. Og snillere."},
				{"s": "liv", "t": "Jeg skal gjøre det pent. Båten får beholde biten sin."},
				{"goto": "menu"},
			],
			"wood_lie": [
				{"s": "liv", "t": "Nei vel. Ingen sparer tre som dette til noe uviktig, men nei vel."},
				{"s": "liv", "t": "Jeg skal gjøre det pent. Båten får beholde biten sin."},
				{"goto": "menu"},
			],
		},

		# ================================================================ TORA
		"t_tora": {
			"start": [
				{"if": "room:B2", "goto": "launch"},
				{"if": "ingrid_told", "goto": "cold"},
				{"if": "tora_told", "goto": "after"},
				{"if": "!tora_showed", "s": "tora", "t": "Ikke se. Jeg holder på med noe."},
				{"if": "tora_showed", "s": "tora", "t": "Hva nå?"},
				{"goto": "menu"},
			],
			"menu": [{"choices": [
				{"t": "Hva har du bak ryggen?", "if": "!tora_showed", "goto": "show"},
				{"t": "Treverket er fra kisten til mora di.", "if": "knows_source&!tora_confessed", "goto": "confess"},
				{"t": "Hva er du egentlig redd for?", "if": "tora_confessed&!tora_told", "goto": "fear"},
				{"t": "Sjur har laget et seil til deg.", "if": "has:seil", "goto": "sail"},
				{"t": "Har du laget noe annet?", "if": "tora_showed&!saw_tora_map", "goto": "map"},
				{"t": "Ingenting.", "end": true},
			]}],
			"show": [
				{"do": ["set:tora_showed"]},
				{"s": "tora", "t": "… En båt. Jeg har laget den selv. Ikke le."},
				{"s": "", "t": "Båten er skåret i mørkt, tett tre. På kjølen er det et merke: en ring med tre streker under. I kanten, ferske knivspor."},
				{"goto": "menu"},
			],
			"confess": [
				{"do": ["set:tora_confessed"]},
				{"s": "tora", "t": "…"},
				{"s": "tora", "t": "Jeg trodde den var skrap. Den sto i boden med lokket løst, og ingen brukte den."},
				{"s": "tora", "t": "Så kom mor og satte seg ved den. Hun bare satt der. Lenge."},
				{"s": "tora", "t": "Ikke si det til henne. Vær så snill."},
				{"goto": "menu"},
			],
			"fear": [
				{"s": "tora", "t": "At hun blir lei seg. Det var fars kiste. Det er det eneste hun har igjen etter ham."},
				{"s": "tora", "t": "Det og meg."},
				{"choices": [
					{"t": "Jeg blir med deg, hvis du vil fortelle det selv.", "goto": "tell"},
					{"t": "Kanskje Liv kan fikse kisten uten at hun merker noe.", "if": "!tora_secret&!chest_fixed", "goto": "secret"},
					{"t": "Jeg vet ikke.", "goto": "menu"},
				]},
			],
			"tell": [
				{"s": "tora", "t": "Nå? …"},
				{"s": "tora", "t": "Greit. Før jeg ombestemmer meg."},
				{"do": ["event:tora_tells"]},
			],
			"secret": [
				{"do": ["set:tora_secret"]},
				{"s": "tora", "t": "Kan hun det? Uten at mor ser det?"},
				{"s": "tora", "t": "Spør henne. Jeg sier ingenting til noen."},
				{"goto": "menu"},
			],
			"sail": [
				{"do": ["take:seil", "set:boat_rigged"]},
				{"s": "tora", "t": "Sjur? Til meg?"},
				{"s": "", "t": "Hun knyter seilet fast med tunga i munnviken."},
				{"s": "tora", "t": "Bli med ned under brua. Hun skal på vannet!"},
			],
			"map": [
				{"do": ["set:saw_tora_map"]},
				{"s": "tora", "t": "Et kart. Over hele Fagravik. Bedre enn årmannens."},
				{"s": "", "t": "Kartet er tegnet med kull på et bordstykke: brygga, Torget, brua, kirken. Oppe ved Skogporten har hun tegnet et lite hus."},
				{"s": "tora", "t": "Det står der. Jeg har sett det. Det er bare ingen andre som tegner det."},
				{"goto": "menu"},
			],
			"launch": [
				{"if": "boat_launched", "goto": "launched"},
				{"s": "tora", "t": "Hold i tauet. Ikke slipp før jeg sier det."},
				{"s": "tora", "t": "Nå!"},
				{"do": ["sfx:splash", "set:boat_launched"]},
				{"s": "", "t": "Båten tar vannet. Strømmen burde føre den ut mot fjorden."},
				{"s": "", "t": "I stedet glir den oppover elva, mot skogen, til den er borte."},
				{"s": "tora", "t": "Den kommer tilbake. Det gjør de alltid."},
			],
			"launched": [{"s": "tora", "t": "Den kommer tilbake. Du får se."}],
			"cold": [
				{"s": "tora", "t": "Du sa det til mor."},
				{"s": "", "t": "Hun snur seg bort."},
			],
			"after": [
				{"s": "tora", "t": "Mor sa at jeg får beholde båten. Hun sa det to ganger."},
				{"goto": "menu"},
			],
		},
		"tora_tells": {
			"start": [
				{"s": "", "t": "Tora går foran deg inn i vertshuset. Så blir hun stående."},
				{"s": "tora", "t": "Mor. Jeg har gjort noe."},
				{"s": "", "t": "Hun forteller om boden, kniven og båten. Det tar lang tid, for hun begynner på nytt to ganger."},
				{"if": "chest_fixed", "goto": "fixed"},
				{"s": "ragna", "t": "Fars kiste."},
				{"s": "", "t": "Ragna går bort til kisten og legger hånden på lokket, der biten mangler."},
				{"s": "ragna", "t": "Den har stått der i tolv år. Jeg sitter ved den når jeg savner ham."},
				{"s": "ragna", "t": "Men du kom og sa det selv. Det er verdt mer enn et lokk."},
				{"goto": "end"},
			],
			"fixed": [
				{"s": "ragna", "t": "Jeg så at noen hadde vært ved kisten. Liv har aldri klart å skjule et høvelspor."},
				{"if": "wood_given", "s": "ragna", "t": "Men det treet er ikke Livs. Det er for fint."},
				{"s": "", "t": "Hun ser på deg. Så på Tora."},
				{"s": "ragna", "t": "Kom hit, begge to."},
				{"goto": "end"},
			],
			"end": [{"do": ["set:tora_told"]}],
		},

		# ================================================================ KVELD
		"meal": {
			"start": [
				{"do": ["sfx:fire"]},
				{"s": "", "t": "Kveld. Ildstedet, langbordet og stemmer over hverandre."},
				{"s": "ragna", "t": "Spis, alle sammen. Sjur, albuene."},
				{"s": "sjur", "t": "Albuene mine har sittet ved dette bordet lenger enn du har eid det."},
				{"s": "ragna", "t": "Og like lenge har jeg sagt det."},
				{"s": "hallvard", "t": "Ingrid spiser som en svenn allerede. Det er det eneste hun gjør som en svenn."},
				{"choices": [
					{"t": "Jeg slo i hvert fall ikke tommelen med hammeren i dag.", "goto": "tease1"},
					{"t": "Jeg lærer av mesteren.", "goto": "tease2"},
					{"t": "(Si ingenting.)", "goto": "tora"},
				]},
			],
			"tease1": [
				{"s": "hallvard", "t": "Én gang! Og det var i Bergen, og det var kaldt!"},
				{"s": "", "t": "Liv ler. Hun ser ut som hun ikke hadde tenkt å gjøre det."},
				{"goto": "tora"},
			],
			"tease2": [
				{"s": "hallvard", "t": "Hør på henne. Smiger og fiskesuppe."},
				{"goto": "tora"},
			],
			"tora": [
				{"if": "tora_told", "goto": "tora_told"},
				{"if": "ingrid_told", "goto": "tora_a"},
				{"if": "chest_fixed", "goto": "tora_b"},
				{"s": "", "t": "Tora sitter med hendene under bordet hele måltidet."},
				{"goto": "liv"},
			],
			"tora_told": [
				{"s": "tora", "t": "Ingrid hjalp meg med noe i dag."},
				{"s": "ragna", "t": "Det gjorde hun."},
				{"if": "wood_given", "s": "", "t": "Kisten står ved veggen. Den nye biten i lokket er lysere enn resten."},
				{"if": "boat_launched", "s": "tora", "t": "Og båten min seilte oppover elva. Oppover! Sjur, si at det går an."},
				{"if": "boat_launched", "s": "sjur", "t": "Det går an. Om elva vil."},
				{"goto": "liv"},
			],
			"tora_a": [
				{"s": "", "t": "Tora sitter ytterst på benken, så langt fra deg som det går an."},
				{"s": "ragna", "t": "Tora, du kan sitte nærmere."},
				{"s": "tora", "t": "Jeg sitter fint."},
				{"goto": "liv"},
			],
			"tora_b": [
				{"s": "", "t": "Ragna stopper ved kisten på vei til bordet. Hun stryker over lokket. Over den nye biten."},
				{"s": "ragna", "t": "Liv."},
				{"s": "liv", "t": "Hm?"},
				{"s": "ragna", "t": "Ingenting."},
				{"s": "", "t": "Resten av måltidet er det stille i den enden av bordet. Tora ser ikke opp fra skåla."},
				{"goto": "liv"},
			],
			"liv": [
				{"if": "wood_given", "s": "liv", "t": "Du er ikke så ille, for å være klokkestøper."},
				{"if": "!wood_given&met_liv", "s": "liv", "t": "Klokkestøpere. Jeg trodde dere var like hverandre, alle sammen."},
				{"if": "!wood_given&met_liv", "s": "liv", "t": "Kanskje ikke helt."},
				{"goto": "audun"},
			],
			"audun": [
				{"do": ["sfx:door"]},
				{"s": "", "t": "Døra går. Audun kommer inn, og etter ham presten."},
				{"s": "audun", "t": "Hallvard. Tinget vil snakke med deg om tre dager."},
				{"s": "hallvard", "t": "Om klokken?"},
				{"s": "audun", "t": "Om klokken."},
				{"s": "", "t": "Ingen sier noe. Ragna fyller på krusene, også de som er fulle."},
				{"s": "", "t": "Audun går. Eirik blir stående ved døra og varmer hendene."},
				{"s": "sjur", "t": "Landvettene må få sitt før vinterkveldene. Ellers—"},
				{"s": "", "t": "Eirik ser opp i taket som om han teller bjelker."},
				{"s": "eirik", "t": "Velsignet mat, Ragna. God natt, alle sammen."},
				{"goto": "quiet"},
			],
			"quiet": [
				{"do": ["sfx:fire"]},
				{"s": "", "t": "Ilden. Skjeer mot treskåler. Ingen trenger å si noe."},
				{"choices": [{"t": "(Bli sittende.)", "goto": "stay"}]},
			],
			"stay": [
				{"s": "", "t": "…"},
				{"s": "hallvard", "t": "Seng, Ingrid. Vi begynner tidlig."},
				{"do": ["event:night"]},
			],
		},

		# ================================================================ NATT
		"n_start": {"start": [
			{"s": "", "t": "Natt. Huset knirker og setter seg. Hallvard snorker bak forhenget i alkoven."},
			{"s": "", "t": "Så slutter han."},
			{"do": ["event:night_timer"]},
		]},
		"n_bell": {"start": [
			{"s": "", "t": "Én tone. Dyp, fra et sted over byen."},
			{"s": "", "t": "Så ingenting."},
		]},
		"n_hallvard": {
			"start": [
				{"if": "night_talk", "goto": "again"},
				{"s": "", "t": "Hallvard står ved vinduet. Han har støvlene på."},
				{"s": "ingrid", "t": "Du hørte den."},
				{"s": "hallvard", "t": "Gammelt tømmer. Kald vind."},
				{"s": "ingrid", "t": "Det var bronse."},
				{"s": "hallvard", "t": "Sov videre, Ingrid."},
				{"do": ["set:night_talk"]},
			],
			"again": [
				{"s": "hallvard", "t": "Sov, sa jeg."},
				{"s": "", "t": "Han ser ikke bort fra vinduet."},
			],
		},
		"n_sing": {"start": [
			{"do": ["set:n_sing", "sfx:sung_far"]},
			{"s": "", "t": "Noen synger. Lavt, et sted ved vannet."},
			{"s": "", "t": "♪ … elva går sakte forbi …"},
			{"s": "", "t": "Du kan ikke høre hvor stemmen kommer fra."},
		]},
		"n_bed": {"start": [
			{"s": "", "t": "Ingrid legger seg. Hun ligger lenge våken og lytter."},
			{"do": ["event:end_game"]},
		]},
	}
