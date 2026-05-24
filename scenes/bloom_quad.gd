extends TextureRect

@onready var vp := $"../SubViewportContainer/SubViewport"

var shaders := [
	preload("res://shaders/tv_bloom.gdshader"),
	preload("res://shaders/bloom.gdshader"),
	preload("res://shaders/passthrough.gdshader"),
	preload("res://shaders/mirror.gdshader"),
	preload("res://shaders/pixelation.gdshader"),
	preload("res://shaders/aberration.gdshader"),
	preload("res://shaders/desert.gdshader"),
	preload("res://shaders/kaleidoscope.gdshader"),
]

var shader_index := 0
var shader_material := ShaderMaterial.new()

func _ready():
	size = vp.size
	position = Vector2.ZERO
	texture = vp.get_texture()

	material = shader_material
	_set_shader(shader_index)

	vp.size_changed.connect(_on_window_resized)

func _set_shader(index: int) -> void:
	shader_index = index % shaders.size()
	shader_material.shader = shaders[shader_index]

func next_shader() -> void:
	_set_shader(shader_index + 1)

func previous_shader() -> void:
	_set_shader(shader_index - 1)

func _on_window_resized():
	size = vp.size
	position = Vector2.ZERO
	print("Resized bloom quad to size ", size)


func _on_shader_button_pressed() -> void:
	next_shader()
