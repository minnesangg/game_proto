extends Label

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _ready():
	pass # Replace with function body.
func _process(delta):
	text = " " + str($"../../Player/Player".health)
