extends Node

signal achievement_unlocked(achievement: AchievementResource)

@export var achievements: Array[AchievementResource] = []

func _ready() -> void:
	print("AchievementManager is gestart!")
	var first_circuit = load("res://ui/first_circuit.tres")
	if first_circuit:
		achievements.append(first_circuit)
		print("Achievement geladen: ", first_circuit.id)

func add_progress(achievement_id: String, amount: int = 1) -> void:
	for ach in achievements:
		if ach.id == achievement_id:
			var just_unlocked = ach.progress(amount)
			if just_unlocked:
				print("🎉 ACHIEVEMENT UNLOCKED: ", ach.title)
				achievement_unlocked.emit(ach)
			break
