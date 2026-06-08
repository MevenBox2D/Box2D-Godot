class_name CombatLayers

const ARENA := 1
const CHARACTER_A := 2
const CHARACTER_B := 3
const PROJECTILE_A := 4
const PROJECTILE_B := 5

## Bit correspondant à un numéro de calque Godot (1-indexé)
static func bit(layer_number: int) -> int:
	return 1 << (layer_number - 1)
