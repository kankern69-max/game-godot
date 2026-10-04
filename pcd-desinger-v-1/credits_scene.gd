extends Control

@export var scroll_speed: float = 80.0
@onready var credits_label: RichTextLabel = $CreditsLabel

func _process(delta: float) -> void:
	credits_label.position.y -= scroll_speed * delta
