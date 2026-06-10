class_name CombatFX

## Point d'entrée unique pour tous les effets visuels du combat.
## Entièrement code-driven — pas de scènes de particules à maintenir.
## La couleur est paramétrable pour les futurs effets de statut (poison, feu…).

const _BASE_SPEED := 80.0
const _SPEED_PER_DMG := 5.0
const _MAX_PARTICLES := 32

static func spawn_impact(tree: SceneTree, position: Vector2, damage: int, color: Color = Color(1.0, 0.45, 0.1)) -> void:
	var p := CPUParticles2D.new()
	tree.current_scene.add_child(p)
	p.global_position = position
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = 0.35
	p.amount = clampi(4 + damage * 2, 4, _MAX_PARTICLES)
	p.initial_velocity_min = _BASE_SPEED + damage * _SPEED_PER_DMG
	p.initial_velocity_max = (_BASE_SPEED + damage * _SPEED_PER_DMG) * 1.8
	p.scale_amount_min = 1.5 + damage * 0.06
	p.scale_amount_max = 3.0 + damage * 0.12
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.color = color
	p.emitting = true
	tree.create_timer(p.lifetime + 0.1).timeout.connect(p.queue_free)

static func spawn_bounce(tree: SceneTree, position: Vector2, impact_speed: float) -> void:
	var p := CPUParticles2D.new()
	tree.current_scene.add_child(p)
	p.global_position = position
	p.one_shot = true
	p.explosiveness = 0.9
	p.lifetime = 0.25
	p.amount = clampi(int(impact_speed / 40.0), 3, 12)
	p.initial_velocity_min = impact_speed * 0.15
	p.initial_velocity_max = impact_speed * 0.35
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.spread = 140.0
	p.gravity = Vector2.ZERO
	p.color = Color(0.85, 0.85, 0.85)
	p.emitting = true
	tree.create_timer(p.lifetime + 0.1).timeout.connect(p.queue_free)
