extends Node
## Midlertidig lyd, laget i koden: klokker, materialer, vuggevisen og vær.
## Alt erstattes av ekte lyd i vertical slice; her skal det bare være nok
## til at forskjellen på riktig og avvikende klang kan høres.

const RATE := 22050

## Lydene som finnes. Ukjente navn ignoreres stille.
const NAMES := [
	"bell_ok", "bell_crack", "bell_old", "bell_second", "bell_night",
	"wood", "hollow", "stone", "metal", "cup", "door", "cloth", "splash",
	"water_rush", "fire", "hum", "sung", "sung_far", "rain", "river",
]

const VOLUME := {
	"bell_night": 0.0, "hum": -8.0, "sung": -6.0, "sung_far": -14.0,
	"rain": -16.0, "river": -18.0, "fire": -10.0, "water_rush": -2.0,
}

## Morens vuggevise: [MIDI-tone, slag].
const MELODY := [
	[64, 1], [67, 1], [69, 1], [67, 1], [64, 2], [62, 1], [64, 1], [60, 2],
	[62, 1], [64, 1], [67, 1], [69, 1], [71, 2], [69, 1], [67, 1], [64, 2],
	[62, 1], [64, 1], [62, 1], [60, 1], [57, 3],
]

var _cache := {}
var _players: Array[AudioStreamPlayer] = []
var _amb: AudioStreamPlayer
var _amb_name := ""
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_amb = AudioStreamPlayer.new()
	add_child(_amb)


## Spiller en lyd og returnerer lengden i sekunder.
func play(name: String) -> float:
	var s := stream(name)
	if s == null:
		return 0.0
	var p := _free_player()
	p.stream = s
	p.volume_db = VOLUME.get(name, -6.0)
	p.play()
	return s.get_length()


func ambient(name: String) -> void:
	if name == _amb_name:
		return
	_amb_name = name
	_amb.stop()
	if name != "":
		_amb.stream = stream(name)
		_amb.volume_db = VOLUME.get(name, -16.0)
		_amb.play()


## Lager alle lydene på forhånd, én per bilde, så spillet ikke hakker senere.
func prewarm() -> void:
	for n in NAMES:
		stream(n)
		await get_tree().process_frame


func stream(name: String) -> AudioStreamWAV:
	if _cache.has(name):
		return _cache[name]
	if not name in NAMES:
		return null
	_rng.seed = hash(name)
	var s: PackedFloat32Array
	var loop := false
	match name:
		"bell_ok": s = _bell(196.0, 4.0, 1.0, false, false)
		"bell_crack": s = _bell(196.0, 3.0, 0.8, true, false)
		"bell_old": s = _lowpass(_bell(196.0, 2.0, 0.3, false, false), 0.25)
		"bell_second": s = _bell(196.0, 5.0, 1.0, false, true)
		"bell_night": s = _bell(98.0, 8.0, 1.8, false, true)
		"wood": s = _knock(170.0, 0.4, 0.0)
		"hollow": s = _knock(150.0, 1.0, 0.6)
		"stone": s = _stone()
		"metal": s = _metal(1.2)
		"cup": s = _mix(_metal(0.4), _knock(220.0, 0.5, 0.0), 0.12)
		"door": s = _knock(90.0, 0.6, 0.3)
		"cloth": s = _noise_burst(0.3, 0.08, 0.06)
		"splash": s = _noise_burst(0.9, 0.2, 0.35)
		"water_rush": s = _rush(4.0)
		"fire": s = _fire(3.0)
		"hum": s = _melody(0.42, 0.5, 0.0)
		"sung": s = _melody(0.55, 1.0, 0.0)
		"sung_far": s = _lowpass(_melody(0.6, 1.0, 0.02), 0.12)
		"rain":
			s = _rain(2.0)
			loop = true
		"river":
			s = _river(4.0)
			loop = true
	var w := _wav(s, loop)
	_cache[name] = w
	return w


func _free_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return _players[0]


# --- syntese -------------------------------------------------------------

func _bell(f0: float, dur: float, decay: float, cracked: bool, second: bool) -> PackedFloat32Array:
	var ratios := [0.5, 1.0, 1.183, 1.506, 2.0, 2.514, 2.662, 3.011]
	var amps := [0.35, 0.5, 0.3, 0.18, 0.32, 0.12, 0.1, 0.08]
	var decays := [3.5, 2.6, 2.0, 1.6, 1.3, 0.9, 0.8, 0.6]
	if cracked:
		ratios.append(1.012)
		amps.append(0.4)
		decays.append(1.2)
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var k_count := ratios.size()
	var env := []
	var mul := []
	var step := []
	for k in k_count:
		env.append(amps[k])
		mul.append(exp(-1.0 / (decays[k] * decay * RATE)))
		step.append(TAU * f0 * ratios[k] / RATE)
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for k in k_count:
			v += env[k] * sin(step[k] * i)
			env[k] *= mul[k]
		if i < 220:
			v += _rng.randf_range(-0.4, 0.4) * (1.0 - i / 220.0)
		if cracked:
			v += _rng.randf_range(-1.0, 1.0) * 0.22 * exp(-t / 0.4) * (0.5 + 0.5 * sin(TAU * 31.0 * t))
		if second:
			v += 0.28 * (1.0 - exp(-t / 0.9)) * exp(-t / (3.5 * decay)) * sin(TAU * f0 * 0.749 * t)
		out[i] = v
	return out


func _knock(freq: float, dur: float, body: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += 0.15 * (_rng.randf_range(-1.0, 1.0) - lp)
		var v := lp * 2.0 * exp(-t / 0.05) + 0.6 * sin(TAU * freq * t) * exp(-t / 0.08)
		if body > 0.0:
			v += body * (0.8 * sin(TAU * 110.0 * t) * exp(-t / 0.35) + 0.4 * sin(TAU * 233.0 * t) * exp(-t / 0.25))
		out[i] = v
	return out


func _stone() -> PackedFloat32Array:
	var n := int(0.25 * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var x := _rng.randf_range(-1.0, 1.0)
		lp += 0.3 * (x - lp)
		out[i] = (x - lp) * exp(-t / 0.015) + 0.3 * sin(TAU * 900.0 * t) * exp(-t / 0.02)
	return out


func _metal(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		out[i] = 0.4 * sin(TAU * 1250.0 * t) * exp(-t / 0.5) + 0.3 * sin(TAU * 1870.0 * t) * exp(-t / 0.35) + 0.2 * sin(TAU * 3100.0 * t) * exp(-t / 0.2)
	return out


func _noise_burst(dur: float, attack: float, decay: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += 0.1 * (_rng.randf_range(-1.0, 1.0) - lp)
		out[i] = lp * minf(t / attack, 1.0) * exp(-maxf(t - attack, 0.0) / decay)
	return out


func _rush(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += 0.05 * (_rng.randf_range(-1.0, 1.0) - lp)
		out[i] = lp * minf(t / 2.5, 1.0) * (1.0 - maxf(t - 3.5, 0.0) * 2.0)
	return out


func _fire(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var crackle := 0.0
	for i in n:
		lp += 0.02 * (_rng.randf_range(-1.0, 1.0) - lp)
		if _rng.randf() < 0.0006:
			crackle = 0.6
		crackle *= 0.995
		out[i] = lp * 0.6 + crackle * _rng.randf_range(-1.0, 1.0)
	return out


func _rain(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var x := _rng.randf_range(-1.0, 1.0)
		lp += 0.4 * (x - lp)
		out[i] = (x - lp) * 0.5 + lp * 0.3
	return out


func _river(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += 0.03 * (_rng.randf_range(-1.0, 1.0) - lp)
		out[i] = lp * (0.8 + 0.2 * sin(TAU * t / dur))
	return out


## Vuggevisen. voice=0.5 er nynning, 1.0 er sang med flere overtoner.
func _melody(beat: float, voice: float, breath: float) -> PackedFloat32Array:
	var total := 0.0
	for note in MELODY:
		total += note[1] * beat
	var n := int((total + 0.4) * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var i := 0
	for note in MELODY:
		var freq := 440.0 * pow(2.0, (note[0] - 69) / 12.0)
		var len_s: float = note[1] * beat
		var count := int(len_s * RATE)
		for j in count:
			var t := float(j) / RATE
			var vib := 1.0 + 0.006 * sin(TAU * 5.0 * (float(i) / RATE))
			phase += TAU * freq * vib / RATE
			var env := minf(t / 0.06, 1.0) * minf((len_s - t) / 0.08, 1.0)
			var v := sin(phase) + voice * (0.3 * sin(2.0 * phase) + 0.15 * sin(3.0 * phase) + 0.06 * sin(4.0 * phase))
			v += breath * _rng.randf_range(-1.0, 1.0) * 10.0
			out[i] = v * env * 0.5
			i += 1
	return out


func _lowpass(s: PackedFloat32Array, a: float) -> PackedFloat32Array:
	var lp := 0.0
	for i in s.size():
		lp += a * (s[i] - lp)
		s[i] = lp
	return s


func _mix(a: PackedFloat32Array, b: PackedFloat32Array, delay: float) -> PackedFloat32Array:
	var off := int(delay * RATE)
	var out := a.duplicate()
	out.resize(maxi(a.size(), b.size() + off))
	for i in b.size():
		out[i + off] += b[i] * 0.7
	return out


func _wav(s: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var peak := 0.001
	for v in s:
		peak = maxf(peak, absf(v))
	var gain := 0.9 / peak
	var bytes := PackedByteArray()
	bytes.resize(s.size() * 2)
	for i in s.size():
		bytes.encode_s16(i * 2, int(clampf(s[i] * gain, -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = s.size()
	return w
