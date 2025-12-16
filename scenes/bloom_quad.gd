extends TextureRect

@onready var vp := $"../SubViewportContainer/SubViewport"

func _ready():
	size = vp.size
	position = Vector2.ZERO

	texture = vp.get_texture()

	material = ShaderMaterial.new()
	material.shader = preload("res://shaders/bloom.gdshader")
	
	vp.size_changed.connect(_on_window_resized)

func _on_window_resized():
	size = vp.size
	
	position = Vector2.ZERO
	
	print("Resized bloom quad to size ", size)
