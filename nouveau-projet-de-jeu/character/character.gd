class_name Character
extends RapierRigidBody2D

const MAX_HP := 100

signal hp_changed(current_hp: int, max_hp: int)
signal died

var current_hp: int = MAX_HP
var opponent: Character = null

func take_damage(amount: int) -> void:
	if current_hp <= 0:
		return
	current_hp = maxi(current_hp - amount, 0)
	hp_changed.emit(current_hp, MAX_HP)
	if current_hp == 0:
		died.emit()
