class_name Difficulty
extends RefCounted

const NAMES := ["Santai", "Biasa", "Kepam Gila"]
const TIMER := [1.3, 1.0, 0.75]
const LIPAS := [0.8, 1.0, 1.25]
const SPREAD := [0.7, 1.0, 1.4]
const RUSH := [14.0, 10.0, 7.0]
const LINE := [0.8, 1.0, 1.3]


static func idx() -> int:
	return clampi(GameState.difficulty, 0, NAMES.size() - 1)


static func name_of(i: int) -> String:
	return NAMES[clampi(i, 0, NAMES.size() - 1)]


static func timer_mult() -> float:
	return TIMER[idx()]


static func lipas_mult() -> float:
	return LIPAS[idx()]


static func spread_mult() -> float:
	return SPREAD[idx()]


static func rush_time() -> float:
	return RUSH[idx()]


static func line_mult() -> float:
	return LINE[idx()]
