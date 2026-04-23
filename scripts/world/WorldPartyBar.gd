extends PanelContainer

## Minimal lead-demon picker: cycles [member GameState.active_party_index].


func _ready() -> void:
	%BtnPrev.pressed.connect(_on_prev_pressed)
	%BtnNext.pressed.connect(_on_next_pressed)
	GameState.party_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var lead: Dictionary = GameState.get_active_demon()
	var demon_name := "—"
	if not lead.is_empty():
		var d: DemonData = lead.get("data") as DemonData
		if d:
			demon_name = d.display_name
	%LeadLabel.text = "Lead: %s  (%d/%d)" % [demon_name, GameState.active_party_index + 1, GameState.party.size()]
	%BtnPrev.disabled = GameState.party.size() <= 1
	%BtnNext.disabled = GameState.party.size() <= 1


func _on_prev_pressed() -> void:
	GameState.cycle_active_party(-1)
	_refresh()


func _on_next_pressed() -> void:
	GameState.cycle_active_party(1)
	_refresh()
