class_name MeleeWeapon
extends Weapon

@export var melee_damage: int = 15
@export var attack_duration: float = 0.2

@onready var _hitbox: RapierArea2D = $Hitbox

var _attack_timer: float = 0.0

func _ready() -> void:
	_hitbox.monitoring = false
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = CombatLayers.all_character_mask()
	_hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _state == State.ACTING:
		_attack_timer += delta
		if _attack_timer >= attack_duration:
			_hitbox.monitoring = false
			_finish_action()

func _perform_action() -> void:
	_attack_timer = 0.0
	_hitbox.monitoring = true

func _on_hitbox_body_entered(body: Node) -> void:
	if body is Character and character.enemies.has(body):
		body.take_damage(melee_damage)
