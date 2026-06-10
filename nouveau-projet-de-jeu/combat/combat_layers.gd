class_name CombatLayers

const ARENA := 1
const CHARACTER_A := 2
const CHARACTER_B := 3
const PROJECTILE_A := 4
const PROJECTILE_B := 5
const CHARACTER_C := 6
const CHARACTER_D := 7
const PROJECTILE_C := 8
const PROJECTILE_D := 9

const CHARACTER_LAYERS := [CHARACTER_A, CHARACTER_B, CHARACTER_C, CHARACTER_D]
const PROJECTILE_LAYERS := [PROJECTILE_A, PROJECTILE_B, PROJECTILE_C, PROJECTILE_D]

static func bit(layer_number: int) -> int:
	return 1 << (layer_number - 1)

## Masque couvrant toutes les couches personnage (pour hitbox de mêlée)
static func all_character_mask() -> int:
	var mask := 0
	for l: int in CHARACTER_LAYERS:
		mask |= bit(l)
	return mask
