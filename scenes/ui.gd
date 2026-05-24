extends CanvasLayer


func _ready():
	get_tree().get_root().size_changed.connect(_resize_ui)
	
func _resize_ui() -> void:
	var h := get_tree().root.size.y

	var ui_scale := 2.5 if h >= 2160 else \
		1.8 if h >= 1440 else \
		1.4 if h >= 1080 else \
		1.1 if h >= 720 else \
		1.0

	$UI.position = Vector2.ZERO
	$UI.scale = Vector2.ONE * ui_scale
