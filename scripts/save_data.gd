extends Node
# Progress, best scores and accessibility options. Writes only its own sections of user://settings.cfg.

const CFG := "user://settings.cfg"

var opts := {"reduce_motion": false, "high_contrast": false, "large_touch": false, "left_hand": false, "mute_blur": true, "captions": false}
var has_save := false
var last_loss := ""
var best := {}
var _seen_step := -1
var _seen_loss := ""
var _seen_won := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var c := ConfigFile.new()
	if c.load(CFG) == OK:
		for k in opts:
			opts[k] = bool(c.get_value("options", k, opts[k]))
		has_save = c.has_section_key("progress", "step") and int(c.get_value("progress", "step")) > 0
		last_loss = str(c.get_value("progress", "last_loss", ""))
		best = c.get_value("best", "scores", {})
	_seen_step = GameState.step


func _write(fn: Callable) -> void:
	var c := ConfigFile.new()
	c.load(CFG)
	fn.call(c)
	c.save(CFG)


func set_opt(k: String, v: bool) -> void:
	opts[k] = v
	_write(func(c: ConfigFile) -> void: c.set_value("options", k, v))


func opt(k: String) -> bool:
	return bool(opts.get(k, false))


func _process(_d: float) -> void:
	if GameState.step != _seen_step:
		_seen_step = GameState.step
		if GameState.step > 0 and not GameState.over:
			_save_progress()
		for id in GameState.scores:
			if float(GameState.scores[id]) > float(best.get(id, 0.0)):
				best[id] = GameState.scores[id]
		_write(func(c: ConfigFile) -> void: c.set_value("best", "scores", best))
	if GameState.lose_reason != "" and GameState.lose_reason != _seen_loss:
		_seen_loss = GameState.lose_reason
		last_loss = _seen_loss
		_write(func(c: ConfigFile) -> void:
			c.set_value("progress", "last_loss", last_loss)
			c.set_value("progress", "step", 0)
			c.set_value("endings", _seen_loss, true))
		has_save = false
	if GameState.won and not _seen_won:
		_seen_won = true
		_write(func(c: ConfigFile) -> void:
			c.set_value("endings", "win", true)
			c.set_value("progress", "step", 0))
		has_save = false


func _save_progress() -> void:
	has_save = true
	_write(func(c: ConfigFile) -> void:
		c.set_value("progress", "step", GameState.step)
		c.set_value("progress", "scores", GameState.scores)
		c.set_value("progress", "soap", GameState.soap)
		c.set_value("progress", "tissue", GameState.tissue)
		c.set_value("progress", "kuman", GameState.kuman)
		c.set_value("progress", "spread", GameState.spread)
		c.set_value("progress", "gf_left", GameState.gf_left))


func load_progress() -> bool:
	var c := ConfigFile.new()
	if c.load(CFG) != OK or not c.has_section_key("progress", "step"):
		return false
	GameState.reset()
	GameState.step = int(c.get_value("progress", "step"))
	GameState.scores = c.get_value("progress", "scores", {})
	GameState.soap = int(c.get_value("progress", "soap", 0))
	GameState.tissue = int(c.get_value("progress", "tissue", 0))
	GameState.kuman = int(c.get_value("progress", "kuman", 0))
	GameState.spread = float(c.get_value("progress", "spread", 0.0))
	GameState.gf_left = float(c.get_value("progress", "gf_left", GameState.GF_TIME))
	GameState.intro_seen = true
	_seen_step = GameState.step
	return true


func endings_seen() -> Array:
	var c := ConfigFile.new()
	var out := []
	if c.load(CFG) == OK and c.has_section("endings"):
		out = c.get_section_keys("endings")
	return out


func lang_chosen() -> bool:
	var c := ConfigFile.new()
	return c.load(CFG) == OK and bool(c.get_value("game", "lang_chosen", false))


func mark_lang_chosen() -> void:
	_write(func(c: ConfigFile) -> void: c.set_value("game", "lang_chosen", true))
