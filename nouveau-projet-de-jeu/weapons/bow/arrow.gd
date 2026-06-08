class_name Arrow
extends RapierRigidBody2D

@export var damage: int = 10

@onready var _hitbox: RapierArea2D = $RapierArea2D

func _ready() -> void:
	_hitbox.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is Character:
		body.take_damage(damage)
	queue_free()

func launch(direction: Vector2, speed: float, owner_layer: int, target_layer: int) -> void:
	rotation = direction.angle()
	linear_velocity = direction.normalized() * speed
	collision_layer = CombatLayers.bit(owner_layer)
	collision_mask = CombatLayers.bit(target_layer) | CombatLayers.bit(CombatLayers.ARENA)
	# The hitbox is a separate Area2D with its own collision_layer/collision_mask
	# (Area2D does not inherit these from the parent RigidBody2D). Without setting
	# them here, body_entered would never fire for the intended target, defeating
	# the spec's intent ("the arrow only hits its target"). This is a minimal,
	# necessary addition mirroring the body's own layer/mask configuration.
	_hitbox.collision_layer = collision_layer
	_hitbox.collision_mask = collision_mask
