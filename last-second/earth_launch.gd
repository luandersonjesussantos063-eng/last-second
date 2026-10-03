extends Node3D


func _ready() -> void:

	print("### EARTHLAUNCH EXECUTOU ###")


	var canvas := CanvasLayer.new()

	canvas.layer = 100

	get_tree().root.add_child(canvas)


	var fundo := ColorRect.new()

	fundo.color = Color(
		1.0,
		0.0,
		0.0,
		1.0
	)

	fundo.position = Vector2.ZERO

	fundo.size = get_viewport().get_visible_rect().size

	canvas.add_child(fundo)


	var texto := Label.new()

	texto.text = "EARTHLAUNCH EXECUTOU"

	texto.position = Vector2(
		50.0,
		50.0
	)

	texto.add_theme_font_size_override(
		"font_size",
		40
	)

	canvas.add_child(texto)
