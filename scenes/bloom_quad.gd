extends TextureRect

@onready var vp := $"../SubViewportContainer/SubViewport"

func _ready():
	await get_tree().process_frame

	size = get_tree().get_root().size
	position = Vector2.ZERO

	texture = vp.get_texture()

	material = ShaderMaterial.new()
	material.shader = preload("res://shaders/bloom.gdshader")
func _enter_tree():
	get_tree().get_root().size_changed.connect(_on_window_resized)

func _on_window_resized():
	size = get_tree().get_root().size
