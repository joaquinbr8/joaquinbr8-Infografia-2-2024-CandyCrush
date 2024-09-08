extends Node2D

@export var color: String
@export var row_texture: Texture2D
@export var column_texture: Texture2D
@export var adjacent_texture: Texture2D
@export var color_bomb_texture: Texture2D


var is_row_bomb = false
var is_column_bomb = false
var is_adjacent_bomb = false
var is_color_bomb = false


#var move_tween;
var matched = false


#func _ready():
	#move_tween = get_node("move_tween")

func move(target):
	var move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_ELASTIC)
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "position", target, 0.4)

func make_column_bomb():
	if column_texture == null:
		print("Error: column_texture is null")
	else:
		print("Assigning column bomb texture")
		$Sprite2D.texture = column_texture
		$Sprite2D.modulate = Color(1, 1, 1, 1)

func make_row_bomb():
	if row_texture == null:
		print("Error: row_texture is null")
	else:
		print("Assigning row bomb texture")
		is_row_bomb = true
		$Sprite2D.texture = row_texture
		$Sprite2D.modulate = Color(1, 1, 1, 1)

func make_adjacent_bomb():
	if adjacent_texture == null:
		print("Error: adjacent_texture is null")
	else:
		print("Assigning adjacent bomb texture")
		is_adjacent_bomb = true
		$Sprite2D.texture = adjacent_texture
		$Sprite2D.modulate = Color(1, 1, 1, 1)

func make_color_bomb():
	is_color_bomb = true
	$Sprite2D.texture = color_bomb_texture
	$Sprite2D.modulate = Color(1, 1, 1, 1)
	color = "Color"

func dim():
	$Sprite2D.modulate = Color(1, 1, 1, 0.5)
