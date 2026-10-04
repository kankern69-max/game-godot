extends Resource
class_name OrderResource

@export var id: String
@export var title: String
@export var discription: String
@export var requirements: Array[OrderRequirement] = []
@export var reward_points: int
@export var reward_money: int

func is_coplete(components: Array) -> bool:
	for r in requirements:
		if not r.is_met(components):
			return false
	return true
