class_name HealthBar
extends Node2D

@export var target: Character

@onready var _progress_bar: ProgressBar = $ProgressBar

func _ready() -> void:
	if target:
		target.hp_changed.connect(_on_hp_changed)
		_on_hp_changed(target.current_hp, Character.MAX_HP)

func _process(_delta: float) -> void:
	if target:
		global_position = target.global_position

func _on_hp_changed(current_hp: int, max_hp: int) -> void:
	_progress_bar.max_value = max_hp
	_progress_bar.value = current_hp
