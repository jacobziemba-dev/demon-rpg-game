extends Control

@onready var list: ItemList = %DemonList
@onready var name_label: Label = %DetailName
@onready var stats_label: Label = %DetailStats
@onready var portrait: TextureRect = %DetailPortrait


func _ready() -> void:
	GameState.grimoire_changed.connect(_refresh)
	list.item_selected.connect(_on_select)
	_refresh()


func _refresh() -> void:
	list.clear()
	for d in GameState.grimoire:
		if d is DemonData:
			list.add_item((d as DemonData).display_name, (d as DemonData).portrait)
	if GameState.grimoire.is_empty():
		name_label.text = "Empty"
		stats_label.text = "Capture wild demons by winning battles."
		portrait.texture = null
	else:
		list.select(0)
		call_deferred("_on_select", 0)


func _on_select(idx: int) -> void:
	if idx < 0 or idx >= GameState.grimoire.size():
		return
	var d: DemonData = GameState.grimoire[idx]
	name_label.text = d.display_name
	stats_label.text = "HP: %d  ATK: %d  DEF: %d" % [d.max_hp, d.attack, d.defense]
	portrait.texture = d.portrait


func _on_back_pressed() -> void:
	await SceneRouter.go_to_main_menu()
