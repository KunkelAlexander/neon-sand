extends SubViewportContainer

# Resize SubViewportContainer to match root viewport
func _ready():
	_resize()
	get_tree().get_root().size_changed.connect(_resize)

func _resize():
	size = get_tree().get_root().size
	print("Subviewport container resized to get_tree().get_root().size = ", size)
