extends RapierRigidBody2D

# --- CONFIGURATION (Modifiable dans l'Inspecteur) ---
@export_category("Moteur Tank")
## Vitesse de rotation maximale appliquée aux roues
@export var vitesse_moteur : float = 15.0
## Puissance du freinage naturel des roues quand on lâche les touches
@export var friction_roues : float = 1.0

@export_category("Configuration du Grab")
## Limite la vitesse du tank pour éviter qu'il ne s'envole à la souris
@export var vitesse_max_grab : float = 500.0
## Distance max du centre pour attraper le tank (0 = n'importe où sur l'écran)
@export var distance_clic_max : float = 0.0


# --- VARIABLES INTERNES ---
var _liste_roues : Array[RigidBody2D] = []
var _est_en_train_de_grab : bool = false
var _corps_souris_temporaire : StaticBody2D

# On utilise le nodepath pour s'assurer de trouver le joint, peu importe son nom
@onready var _joint_souris : PinJoint2D = $"../JointSouris"


# --- FONCTIONS PRINCIPALES ---

func _ready() -> void:
	# 1. Détection automatique des roues de type RigidBody2D dans la scène racine
	var parent = get_parent()
	if parent:
		for enfant in parent.get_children():
			if enfant is RigidBody2D and enfant != self:
				_liste_roues.append(enfant)
				# On applique la friction initiale aux roues
				enfant.physics_material_override = PhysicsMaterial.new()
				enfant.physics_material_override.friction = friction_roues

	# 2. Création dynamique du point d'ancrage invisible pour la souris
	_corps_souris_temporaire = StaticBody2D.new()
	if parent:
		parent.add_child.call_deferred(_corps_souris_temporaire)


func _physics_process(_delta: float) -> void:
	_gerer_deplacement_clavier()
	_gerer_mouvement_souris()


func _input(event: InputEvent) -> void:
	# Détection du clic gauche de la souris
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Si la distance est à 0 ou que la souris est assez proche du tank
			var distance_souris = global_position.distance_to(get_global_mouse_position())
			if distance_clic_max == 0.0 or distance_souris < distance_clic_max:
				_activer_grab()
		else:
			if _est_en_train_de_grab:
				_desactiver_grab()


# --- LOGIQUE INTERNE (Fonctions privées) ---

## Gère les contrôles clavier/manette pour faire tourner les roues
func _gerer_deplacement_clavier() -> void:
	var direction := Input.get_axis("reculer", "avancer")
	
	for roue in _liste_roues:
		if direction != 0.0:
			roue.angular_velocity = direction * vitesse_moteur
		else:
			# Laisse la physique et la friction arrêter la roue naturellement
			pass


## Met à jour la position de la souris et bride la vitesse pour éviter les bugs physiques
func _gerer_mouvement_souris() -> void:
	if _est_en_train_de_grab and _corps_souris_temporaire:
		_corps_souris_temporaire.global_position = get_global_mouse_position()
		
		# Sécurité anti-téléportation / explosion physique :
		if linear_velocity.length() > vitesse_max_grab:
			linear_velocity = linear_velocity.limit_length(vitesse_max_grab)


## Connecte le tank au point de pivot de la souris
func _activer_grab() -> void:
	if _joint_souris and _corps_souris_temporaire:
		_est_en_train_de_grab = true
		_joint_souris.global_position = get_global_mouse_position()
		_joint_souris.node_a = _corps_souris_temporaire.get_path()
		_joint_souris.node_b = get_path()


## Libère le tank du point de pivot de la souris
func _desactiver_grab() -> void:
	if _joint_souris:
		_est_en_train_de_grab = false
		_joint_souris.node_a = NodePath("")
		_joint_souris.node_b = NodePath("")
