class_name Character
extends RapierRigidBody2D

const MAX_HP := 100
const INITIAL_SPEED_RANGE := Vector2(150.0, 300.0)

signal hp_changed(current_hp: int, max_hp: int)
signal died

var current_hp: int = MAX_HP
var enemies: Array[Character] = []

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	var angle: float = randf_range(0.0, TAU)
	var speed: float = randf_range(INITIAL_SPEED_RANGE.x, INITIAL_SPEED_RANGE.y)
	linear_velocity = Vector2.RIGHT.rotated(angle) * speed
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	died.connect(_on_died)

func _on_died() -> void:
	visible = false
	collision_layer = 0
	collision_mask = 0
	freeze = true

func _on_body_entered(body: Node) -> void:
	if body.collision_layer & CombatLayers.bit(CombatLayers.ARENA):
		CombatFX.spawn_bounce(get_tree(), global_position, linear_velocity.length())

func dash_toward(target: Node2D, impulse: float = 400.0) -> void:
	var direction := (target.global_position - global_position).normalized()
	apply_central_impulse(direction * impulse)

func take_damage(amount: int, fx_color: Color = Color(1.0, 0.45, 0.1)) -> void:
	if current_hp <= 0:
		return
	current_hp = maxi(current_hp - amount, 0)
	hp_changed.emit(current_hp, MAX_HP)
	CombatFX.spawn_impact(get_tree(), global_position, amount, fx_color)
	_flash_hit()
	if current_hp == 0:
		died.emit()

func _flash_hit() -> void:
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color.RED, 0.05)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.15)
