class_name GameManager
extends Node2D

@onready var _arena: Node2D = $Arena
@onready var _character_a: Character = $CharacterA
@onready var _character_b: Character = $CharacterB
@onready var _bow_a: BowWeapon = $BowA
@onready var _bow_b: BowWeapon = $BowB
@onready var _health_bar_a: HealthBar = $HealthBarA
@onready var _health_bar_b: HealthBar = $HealthBarB
@onready var _result_label: Label = $ResultLabel

var _combat_over := false
var _pending_deaths: Array[Character] = []

func _ready() -> void:
	_character_a.global_position = _arena.get_node("SpawnPointA").global_position
	_character_b.global_position = _arena.get_node("SpawnPointB").global_position

	_character_a.opponent = _character_b
	_character_b.opponent = _character_a

	_health_bar_a.target = _character_a
	_health_bar_b.target = _character_b

	# NOTE: l'export `joint` de BowWeapon est de type RapierPinJoint2D (Object) ; ce genre de
	# référence inter-nœuds ne peut pas être sérialisé à la main dans un .tscn (seul l'inspecteur
	# de l'éditeur sait le faire). On le câble donc ici, juste avant _setup_weapon.
	_bow_a.joint = $JointA
	_bow_b.joint = $JointB

	_setup_weapon(_bow_a, _character_a, CombatLayers.PROJECTILE_A, CombatLayers.CHARACTER_B)
	_setup_weapon(_bow_b, _character_b, CombatLayers.PROJECTILE_B, CombatLayers.CHARACTER_A)

	_character_a.died.connect(_on_character_died.bind(_character_a))
	_character_b.died.connect(_on_character_died.bind(_character_b))

	_result_label.visible = false

func _setup_weapon(bow: BowWeapon, character: Character, projectile_layer: int, target_layer: int) -> void:
	bow.character = character
	bow.projectile_layer = projectile_layer
	bow.target_layer = target_layer

func _on_character_died(character: Character) -> void:
	_pending_deaths.append(character)
	# Laisse une frame pour qu'un éventuel double K.O. soit détecté avant de conclure
	call_deferred("_resolve_combat_end")

func _resolve_combat_end() -> void:
	if _combat_over or _pending_deaths.is_empty():
		return
	_combat_over = true
	_bow_a.set_physics_process(false)
	_bow_b.set_physics_process(false)

	if _pending_deaths.size() >= 2:
		_show_result("Match nul !")
	elif _pending_deaths[0] == _character_a:
		_show_result("Victoire du personnage B !")
	else:
		_show_result("Victoire du personnage A !")

func _show_result(text: String) -> void:
	_result_label.text = text
	_result_label.visible = true
