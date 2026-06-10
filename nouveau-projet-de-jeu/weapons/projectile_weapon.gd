class_name ProjectileWeapon
extends Weapon

@onready var _spawn_point: Marker2D = $SpawnPoint
@onready var _draw_animation: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

@export var projectile_scene: PackedScene
@export var projectile_damage: int = 10
@export var projectile_speed: float = 500.0
@export var projectile_layer: int = CombatLayers.PROJECTILE_A
@export var draw_animation_name: StringName = &"draw"

var _active_projectiles: Array[Node2D] = []

func _ready() -> void:
	if _draw_animation:
		_draw_animation.animation_finished.connect(_on_draw_animation_finished)

func _perform_action() -> void:
	if _draw_animation:
		_draw_animation.play(draw_animation_name)
	else:
		_fire()

func _on_draw_animation_finished() -> void:
	if _draw_animation.animation == draw_animation_name:
		_fire()

func _fire() -> void:
	var target := _nearest_living_enemy()
	if target == null:
		_finish_action()
		return
	var projectile: Arrow = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = _spawn_point.global_position
	projectile.damage = projectile_damage
	_active_projectiles.append(projectile)
	projectile.tree_exited.connect(func() -> void: _active_projectiles.erase(projectile))
	var aim_direction := (target.global_position - _spawn_point.global_position).normalized()
	projectile.launch(aim_direction, projectile_speed, projectile_layer, target_layer)
	if _draw_animation:
		_draw_animation.stop()
		_draw_animation.frame = 0
	_finish_action()
