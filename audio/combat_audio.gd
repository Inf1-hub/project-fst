extends Node
## Small cached synthesized cues, capped voices; replace with authored audio later.
var voices: Array[AudioStreamPlayer] = []
var cache: Dictionary = {}
var cursor := 0


func _ready() -> void:
	for index in 6:
		var voice := AudioStreamPlayer.new()
		voice.bus = "SFX"
		add_child(voice)
		voices.append(voice)
	for spec in [[180, .3], [760, .09], [100, .1], [330, .08], [540, .12]]:
		make_tone(float(spec[0]), float(spec[1]))


func make_tone(frequency: float, duration: float) -> AudioStreamWAV:
	var key := "%s_%s" % [frequency, duration]
	if cache.has(key): return cache[key]
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var length := int(stream.mix_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(length * 2)
	for index in length:
		var t := float(index) / stream.mix_rate
		var sample := sin(TAU * frequency * t) * pow(1 - float(index) / length, 2) * .5
		bytes.encode_s16(index * 2, int(sample * 32767))
	stream.data = bytes
	cache[key] = stream
	return stream


func play_tone(frequency: float, duration: float, volume: float) -> void:
	if DisplayServer.get_name() == "headless": return
	cursor = (cursor + 1) % voices.size()
	voices[cursor].stream = make_tone(frequency, duration)
	voices[cursor].volume_db = linear_to_db(volume)
	voices[cursor].play()


func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	cache.clear()
