class_name GameManager
extends Node2D

## Configuration du combat depuis l'Inspector :
##   character_scene  → glisser character.tscn
##   weapon_scenes    → un élément par joueur, dans l'ordre voulu
##                      ex : [scythe_weapon.tscn, bow_weapon.tscn, bow_weapon.tscn] = 1v1v1
##   health_bar_scene → glisser health_bar.tscn
## Le nombre de joueurs = weapon_scenes.size().

@export var character_scene: PackedScene
@export var weapon_scenes: Array[PackedScene] = []
@export var health_bar_scene: PackedScene

const SPAWN_SETS := {
	2: [0, 3],
	3: [0, 1, 2],
	4: [0, 1, 2, 3],
}

@onready var _arena: Node2D = $Arena
@onready var _result_label: Label = $ResultLabel

var _characters: Array[Character] = []
var _weapons: Array[Weapon] = []
var _health_bars: Array[HealthBar] = []
var _combat_over := false
var _pending_deaths: Array[Character] = []

func _ready() -> void:
	_spawn_all()
	_setup_enemies()
	_setup_weapons()

func _spawn_all() -> void:
	var n := weapon_scenes.size()
	var indices: Array = SPAWN_SETS.get(n, range(n))
	var spawns_root := _arena.get_node("SpawnPoints")

	for i in n:
		# Personnage
		var character: Character = character_scene.instantiate()
		add_child(character)
		character.name = "Character%d" % i
		var sp: Marker2D = spawns_root.get_node("SpawnPoint%d" % indices[i])
		character.global_position = sp.global_position
		character.collision_layer = CombatLayers.bit(CombatLayers.CHARACTER_LAYERS[i])
		_set_character_mask(character, i, n)
		character.died.connect(_on_character_died.bind(character))
		_characters.append(character)

		# Arme
		var weapon: Weapon = weapon_scenes[i].instantiate()
		add_child(weapon)
		weapon.name = "Weapon%d" % i
		_weapons.append(weapon)

		# Barre de vie
		var bar: HealthBar = health_bar_scene.instantiate() if health_bar_scene else null
		if bar:
			add_child(bar)
			bar.target = character
		_health_bars.append(bar)

	_result_label.visible = false

func _set_character_mask(character: Character, own_index: int, n: int) -> void:
	var mask := CombatLayers.bit(CombatLayers.ARENA)
	for j in n:
		if j == own_index:
			continue
		mask |= CombatLayers.bit(CombatLayers.CHARACTER_LAYERS[j])
		mask |= CombatLayers.bit(CombatLayers.PROJECTILE_LAYERS[j])
	character.collision_mask = mask

func _setup_enemies() -> void:
	# Chaque personnage a tous les autres comme ennemis.
	for i in _characters.size():
		for j in _characters.size():
			if i != j:
				_characters[i].enemies.append(_characters[j])

func _setup_weapons() -> void:
	for i in _weapons.size():
		var w := _weapons[i]
		w.character = _characters[i]
		# target_layer = premier ennemi — pour compatibilité ProjectileWeapon (mask Arrow)
		var next := (i + 1) % _characters.size()
		w.target_layer = CombatLayers.CHARACTER_LAYERS[next]
		if w is ProjectileWeapon:
			(w as ProjectileWeapon).projectile_layer = CombatLayers.PROJECTILE_LAYERS[i]

func _on_character_died(character: Character) -> void:
	if _combat_over:
		return
	_pending_deaths.append(character)
	_cleanup_player(character)
	call_deferred("_resolve_combat_end")

func _cleanup_player(character: Character) -> void:
	var i := _characters.find(character)
	if i == -1:
		return
	var weapon := _weapons[i]
	if weapon is ProjectileWeapon:
		for p in (weapon as ProjectileWeapon)._active_projectiles:
			if is_instance_valid(p):
				p.queue_free()
	weapon.queue_free()
	if _health_bars[i]:
		_health_bars[i].queue_free()

func _resolve_combat_end() -> void:
	if _combat_over or _pending_deaths.is_empty():
		return
	var alive := _characters.filter(func(c: Character) -> bool: return not _pending_deaths.has(c))
	if alive.size() > 1:
		return
	_combat_over = true
	for w in _weapons:
		if is_instance_valid(w):
			w.set_physics_process(false)
	for c in _characters:
		if is_instance_valid(c):
			c.freeze = true
	if alive.is_empty():
		_show_result("Match nul !")
	else:
		_show_result("Victoire de %s !" % alive[0].name)

func _show_result(text: String) -> void:
	_result_label.text = text
	_result_label.visible = true
