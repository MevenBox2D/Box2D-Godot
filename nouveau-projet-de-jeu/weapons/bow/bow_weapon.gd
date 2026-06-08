class_name BowWeapon
extends RapierRigidBody2D

enum State { TRACKING, DRAWING, FIRING, COOLDOWN }

const ArrowScene := preload("res://weapons/bow/arrow.tscn")

@export var character: Character
@export var joint: RapierPinJoint2D
@export var time_before_draw: float = 1.5
@export var cooldown_duration: float = 1.0
@export var arrow_damage: int = 10
@export var arrow_speed: float = 500.0
@export var projectile_layer: int = CombatLayers.PROJECTILE_A
@export var target_layer: int = CombatLayers.CHARACTER_B

@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _nock_point: Marker2D = $NockPoint

var _state: State = State.TRACKING
var _state_timer: float = 0.0
var _frozen_target_angle: float = 0.0

func _ready() -> void:
	if joint:
		joint.motor_position_enabled = true
	_animation_player.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	match _state:
		State.TRACKING:
			_process_tracking(delta)
		State.COOLDOWN:
			_process_cooldown(delta)
		# DRAWING et FIRING sont pilotés par animation/instanciation, pas par le temps ici

func _process_tracking(delta: float) -> void:
	if character == null or character.opponent == null or joint == null:
		return
	var to_opponent: Vector2 = character.opponent.global_position - global_position
	joint.motor_position_target_angle = to_opponent.angle()

	_state_timer += delta
	if _state_timer >= time_before_draw:
		_state_timer = 0.0
		_start_drawing()

func _start_drawing() -> void:
	_state = State.DRAWING
	_frozen_target_angle = joint.motor_position_target_angle  # figé pendant le bandage (spec §3)
	_animation_player.play("draw")

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "draw":
		_fire()

func _fire() -> void:
	_state = State.FIRING
	var arrow: Arrow = ArrowScene.instantiate()
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = _nock_point.global_position
	arrow.damage = arrow_damage
	arrow.launch(Vector2.RIGHT.rotated(_frozen_target_angle), arrow_speed, projectile_layer, target_layer)

	_state = State.COOLDOWN
	_state_timer = 0.0

func _process_cooldown(delta: float) -> void:
	_state_timer += delta
	if _state_timer >= cooldown_duration:
		_state_timer = 0.0
		_state = State.TRACKING
