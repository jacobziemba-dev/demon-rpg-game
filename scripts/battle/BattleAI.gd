class_name BattleAI
extends RefCounted

## Simple enemy posture: desperate demons hit harder when low on HP.


static func enemy_attack_bonus(_wild: DemonData, wild_hp: int, wild_max_hp: int) -> int:
	if wild_max_hp <= 0:
		return 0
	if wild_hp * 3 <= wild_max_hp:
		return 2
	return 0
