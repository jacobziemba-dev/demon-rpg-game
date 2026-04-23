class_name DemonData
extends Resource

## Static definition for a demon (stats + display). Runtime HP lives in battle / party state.

@export var id: String = ""
@export var display_name: String = "Demon"
@export var portrait: Texture2D
@export var max_hp: int = 10
@export var attack: int = 2
@export var defense: int = 0
@export var signature_skill: SkillData
