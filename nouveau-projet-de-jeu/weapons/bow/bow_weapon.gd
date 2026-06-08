class_name BowWeapon
extends RapierRigidBody2D

enum State { TRACKING, DRAWING, FIRING, COOLDOWN }

@export var character: Character
@export var joint: RapierPinJoint2D
@export var time_before_draw: float = 1.5

var _state: State = State.TRACKING
var _state_timer: float = 0.0

func _ready() -> void:
	if joint:
		joint.motor_position_enabled = true

func _physics_process(delta: float) -> void:
	match _state:
		State.TRACKING:
			_process_tracking(delta)

func _process_tracking(delta: float) -> void:
	if character == null or character.opponent == null or joint == null:
		return
	var to_opponent: Vector2 = character.opponent.global_position - global_position
	joint.motor_position_target_angle = to_opponent.angle()

	_state_timer += delta
	if _state_timer >= time_before_draw:
		_state_timer = 0.0
		_state = State.DRAWING  # branché en Task 7
