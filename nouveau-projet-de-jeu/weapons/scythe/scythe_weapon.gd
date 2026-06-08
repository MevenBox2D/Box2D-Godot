class_name ScytheWeapon
extends Weapon

@export var melee_damage: int = 15
@export var wind_up_angle: float = 1.8
@export var wind_up_duration: float = 0.5
@export var release_duration: float = 0.08
@export var dash_impulse: float = 300.0

@onready var _hitbox: RapierArea2D = $Hitbox

enum SwingPhase { NONE, WIND_UP, RELEASE }

var _swing_phase: SwingPhase = SwingPhase.NONE
var _swing_timer: float = 0.0
var _swing_offset: float = 0.0

func _ready() -> void:
	_hitbox.monitoring = false
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = CombatLayers.all_character_mask()
	_hitbox.body_entered.connect(_on_hitbox_body_entered)

func _follow_and_aim() -> void:
	if character == null:
		return
	global_position = character.global_position
	var target := _nearest_living_enemy()
	if target == null:
		return
	global_rotation = (target.global_position - global_position).angle() + _swing_offset

func _physics_process(delta: float) -> void:
	_follow_and_aim()
	match _state:
		State.TRACKING:
			_process_tracking(delta)
		State.ACTING:
			_update_swing(delta)
		State.COOLDOWN:
			_process_cooldown(delta)

func _perform_action() -> void:
	_swing_phase = SwingPhase.WIND_UP
	_swing_timer = 0.0

func _update_swing(delta: float) -> void:
	_swing_timer += delta
	match _swing_phase:
		SwingPhase.WIND_UP:
			var t := clampf(_swing_timer / wind_up_duration, 0.0, 1.0)
			_swing_offset = lerpf(0.0, wind_up_angle, t)
			if _swing_timer >= wind_up_duration:
				_swing_phase = SwingPhase.RELEASE
				_swing_timer = 0.0
				_hitbox.monitoring = true
				var target := _nearest_living_enemy()
				if target:
					character.dash_toward(target, dash_impulse)
		SwingPhase.RELEASE:
			var t := clampf(_swing_timer / release_duration, 0.0, 1.0)
			_swing_offset = lerpf(wind_up_angle, 0.0, t)
			if _swing_timer >= release_duration:
				_swing_phase = SwingPhase.NONE
				_swing_offset = 0.0
				_hitbox.monitoring = false
				_finish_action()

func _on_hitbox_body_entered(body: Node) -> void:
	if body is Character and character.enemies.has(body):
		body.take_damage(melee_damage)
