extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label
@onready var match_label = $score_match

var current_score:int = 0
var points_to_win:int = 1500
var current_count:int = 150
var number_attemps:int = 17
var original_number_attemps:int = number_attemps
var time_counter:float=0
var end_game_mode:bool
var game_ended:bool = false
signal send_end_game_mode(game_mode:bool)
signal finish_game(end_of_game:bool)
signal win_game(win:bool)

func _ready():
	end_game_mode = false
	reset_game()

func reset_game():
	number_attemps += 1
	match_label.text = str(points_to_win)
	score_label.text = "0"
	emit_signal("send_end_game_mode",end_game_mode)
	if end_game_mode:
		counter_label.text = str(number_attemps)
		print("END GAME BY MOVES NUMBER OZYOZY")
	else:
		counter_label.text = str(current_count)
		print("END GAME BY TIMER OZYOZY")

func _process(delta):
	if (counter_label.text == "0" or current_score >= points_to_win) and not game_ended:
		game_ended = true
		if counter_label.text == "0":
			emit_signal("finish_game",game_ended)
		if current_score >= points_to_win:
			emit_signal("win_game",game_ended)
	if not end_game_mode and not game_ended:
		time_counter += delta
		if time_counter >= 0.99:
			current_count -= 1
			time_counter = 0
			counter_label.text = str(current_count)
			if current_count == 0:
				end_game_mode = true

func _on_grid_increase_points(value:int):
	var new_current_score:int = (value+current_score)
	current_score = new_current_score
	var new_score:String = str(current_score)
	score_label.text = new_score

func _on_grid_reduce_attemps():
	if end_game_mode and not game_ended:
		number_attemps -= 1
		counter_label.text = str(number_attemps)

func _on_bottom_ui_button_on_pressed():
	end_game_mode = not end_game_mode
	current_score = 0
	number_attemps = original_number_attemps
	current_count = 150
	reset_game()
