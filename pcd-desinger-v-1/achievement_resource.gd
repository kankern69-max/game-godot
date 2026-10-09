class_name AchievementResource
extends Resource

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var target_amount: int = 1

var current_amount: int = 0
var is_unlocked: bool = false

func progress(amount: int= 1) -> bool:
	if is_unlocked:
		return false
		
		current_amount += amount
		if current_amount >= target_amount:
			is_unlocked = true
			return true
			
	return false
