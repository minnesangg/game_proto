extends Node2D

@onready var animated_sprite = $AnimatedSprite2D

var chest_open = false

func _ready():
	animated_sprite.animation = "idle"  # Установка анимации "open" по умолчанию

func _on_body_entered(body):
	if body.name == "Player":
		open_chest()

func _on_body_exited(body):
	if body.name == "Player":
		pass

func open_chest():
	if not chest_open:
		chest_open = true
		animated_sprite.play("open")

