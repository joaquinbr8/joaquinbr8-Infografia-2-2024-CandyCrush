extends TextureRect

@onready var screen = $MarginContainer
@onready var text_game = $MarginContainer/VBoxContainer3/VBoxContainer/state_game
var able_change_game_mode:bool = true
var game_ended_already: bool = false
signal button_on_pressed

func _process(delta):
	var mouse = get_global_mouse_position()
	if able_change_game_mode:
		if (Input.is_action_just_pressed("ui_touch") and
		mouse.x >= 8 and mouse.y >= 928 and mouse.x <= 165 and mouse.y <= 965):
			emit_signal("button_on_pressed")

func _on_grid_can_change_gme_mode(value):
	if not game_ended_already:
		able_change_game_mode = value

func _on_top_ui_finish_game(end_of_game):
	text_game.text = "YOU LOSE!"
	able_change_game_mode = false
	game_ended_already = true

func _on_top_ui_win_game(win):
	text_game.text = "COLOR CRUSH!"
	able_change_game_mode = false
	game_ended_already = true
