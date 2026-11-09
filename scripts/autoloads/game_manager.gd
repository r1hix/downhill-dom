extends Node

## Global Game Manager for Downhill Domination
## Manages race state, scoring, player stats, and global events

signal race_started
signal race_finished(time: float, rank: int)
signal score_added(amount: int, reason: String)
signal adrenaline_changed(current: float, max_val: float)

var race_time: float = 0.0
var is_racing: bool = false
var score: int = 0
var total_takedowns: int = 0
var player_rank: int = 1
var total_racers: int = 4

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if is_racing:
		race_time += delta

func start_race() -> void:
	race_time = 0.0
	score = 0
	total_takedowns = 0
	is_racing = true
	emit_signal("race_started")

func finish_race(rank: int) -> void:
	if not is_racing:
		return
	is_racing = false
	player_rank = rank
	emit_signal("race_finished", race_time, player_rank)

func add_score(points: int, reason: String = "") -> void:
	score += points
	emit_signal("score_added", points, reason)

func register_takedown() -> void:
	total_takedowns += 1
	add_score(1000, "RIVAL TAKEDOWN!")

