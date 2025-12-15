extends SubViewport

func _ready():
	_resize()
	get_tree().get_root().size_changed.connect(_resize)

func _resize():
	size = get_tree().get_root().size
	print("Subviewport resized:", size)
