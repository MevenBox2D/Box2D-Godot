class_name Weapon
extends Node2D

enum State { TRACKING, ACTING, COOLDOWN }

@export var character: Character
@export var time_before_action: float = 1.5
@export var cooldown_duration: float = 1.0
@export var target_layer: int = CombatLayers.CHARACTER_B

var _state: State = State.TRACKING
var _state_timer: float = 0.0

func _physics_process(delta: float) -> void:
	_follow_and_aim()
	match _state:
		State.TRACKING:
			_process_tracking(delta)
		State.COOLDOWN:
			_process_cooldown(delta)

func _follow_and_aim() -> void:
	if character == null:
		return
	global_position = character.global_position
	var target := _nearest_living_enemy()
	if target == null:
		return
	global_rotation = (target.global_position - global_position).angle()

## Retourne l'ennemi vivant le plus proche parmi character.enemies.
func _nearest_living_enemy() -> Character:
	var nearest: Character = null
	var min_dist_sq := INF
	for enemy in character.enemies:
		if not is_instance_valid(enemy) or enemy.current_hp <= 0:
			continue
		var d := character.global_position.distance_squared_to(enemy.global_position)
		if d < min_dist_sq:
			min_dist_sq = d
			nearest = enemy
	return nearest

func _process_tracking(delta: float) -> void:
	_state_timer += delta
	if _state_timer >= time_before_action:
		_state_timer = 0.0
		_state = State.ACTING
		_perform_action()

func _process_cooldown(delta: float) -> void:
	_state_timer += delta
	if _state_timer >= cooldown_duration:
		_state_timer = 0.0
		_state = State.TRACKING

func _perform_action() -> void:
	_finish_action()

func _finish_action() -> void:
	_state = State.COOLDOWN
	_state_timer = 0.0
