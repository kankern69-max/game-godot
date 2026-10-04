extends Resource
class_name TechNodeResource

@export var id: String = ""
@export var title: String = ""
@export var img_atlas: Vector2i
@export var img_size: Vector2
@export var research_cost: float = 0.0
@export var aquired_techs: Array[TechNodeResource] = []
@export var unlocked_components: Array[String] = []
@export var unlocked_orders: Array[String] = []

func can_unlock() -> bool:
	if Global.unlocked_techs.has(id):
		return false
	
	for prereq in aquired_techs:
		if not Global.unlocked_techs.has(prereq.id):
			return false
	
	return true
