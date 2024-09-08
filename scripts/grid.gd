extends Node2D

# state machine
enum {WAIT, MOVE}
var state

# grid
@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

@export var global_score: int = 0
var multi_score:int = 1
signal increase_points(value:int)
signal reduce_attemps

var end_game:bool = false
var game_over_mode:bool = false
var winner_of_game:bool = false

# piece array
var possible_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_green_piece.tscn"),
	preload("res://scenes/pink_piece.tscn"),
	preload("res://scenes/yellow_piece.tscn"),
	preload("res://scenes/orange_piece.tscn"),
]

# current pieces in scene
var all_pieces = []
var current_matches = []

# swap back
var piece_one = null
var piece_two = null
var last_place = Vector2.ZERO
var last_direction = Vector2.ZERO
var move_checked = false

# touch variables
var first_touch = Vector2.ZERO
var final_touch = Vector2.ZERO
var is_controlling = false

signal can_change_game_mode(value:bool)

# Called when the node enters the scene tree for the first time.
func _ready():
	state = MOVE
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()
	if game_over_mode:
		emit_signal("reduce_attemps")

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array
	
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start - offset * row
	return Vector2(new_x, new_y)
	
func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)
	
func in_grid(column, row):
	return column >= 0 and column < width and row >= 0 and row < height
	
func spawn_pieces():
	for i in width:
		for j in height:
			# random number
			var rand = randi_range(0, possible_pieces.size() - 1)
			# instance 
			var piece = possible_pieces[rand].instantiate()
			# repeat until no matches
			var max_loops = 100
			var loops = 0
			while (match_at(i, j, piece.color) and loops < max_loops):
				rand = randi_range(0, possible_pieces.size() - 1)
				loops += 1
				piece = possible_pieces[rand].instantiate()
			add_child(piece)
			piece.position = grid_to_pixel(i, j)
			# fill array with pieces
			all_pieces[i][j] = piece

func match_at(i, j, color):
	# check left
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color and all_pieces[i - 2][j].color == color:
				return true
	# check down
	if j> 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true

func touch_input():
	var mouse_pos = get_global_mouse_position()
	var grid_pos = pixel_to_grid(mouse_pos.x, mouse_pos.y)
	if Input.is_action_just_pressed("ui_touch") and in_grid(grid_pos.x, grid_pos.y):
		first_touch = grid_pos
		is_controlling = true
		
	# release button
	if Input.is_action_just_released("ui_touch") and in_grid(grid_pos.x, grid_pos.y) and is_controlling:
		is_controlling = false
		final_touch = grid_pos
		touch_difference(first_touch, final_touch)

func swap_pieces(column, row, direction: Vector2):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if first_piece == null or other_piece == null:
		return
	# swap
	if is_color_bomb(first_piece, other_piece):
		if first_piece.color == "Color":
			match_color(other_piece.color)
			match_and_dim(first_piece)
			add_to_array(Vector2(column, row))
		else:
			match_color(first_piece.color)
			match_and_dim(other_piece)
			add_to_array(Vector2(column + direction.x, row + direction.y))
	state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	all_pieces[column][row] = other_piece
	all_pieces[column + direction.x][row + direction.y] = first_piece
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))
	#emit_signal("reduce_attemps",global_attemps)
	print("moviendo pieza")
	if not move_checked:
		find_matches()

func is_color_bomb(piece_one, piece_two):
	if piece_one.color == "Color" or piece_two.color == "Color":
		return true
	return false

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = MOVE
	move_checked = false

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	# should move x or y?
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
	if abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(delta):
	if state == MOVE:
		touch_input()
	if (end_game or winner_of_game) and state != WAIT:
		game_over()
		var text_game_over:String = "GANASTE OZYOZY" if winner_of_game else "PERDISTE :()"
		print(text_game_over)

func is_piece_null(column, row):
	if all_pieces[column][row] == null:
		return true
	return false

func match_and_dim(item):
	item.matched = true
	item.dim()

func find_matches():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				# detect horizontal matches
				if (
					i > 0 and i < width -1 
					and 
					all_pieces[i - 1][j] != null and all_pieces[i + 1][j]
					and 
					all_pieces[i - 1][j].color == current_color and all_pieces[i + 1][j].color == current_color
				):
					all_pieces[i - 1][j].matched = true
					all_pieces[i - 1][j].dim()
					all_pieces[i][j].matched = true
					all_pieces[i][j].dim()
					all_pieces[i + 1][j].matched = true
					all_pieces[i + 1][j].dim()
					#mod
					add_to_array(Vector2(i,j))
					add_to_array(Vector2(i +1,j))
					add_to_array(Vector2(i - 1, j))
					
				# detect vertical matches
				if (
					j > 0 and j < height -1 
					and 
					all_pieces[i][j - 1] != null and all_pieces[i][j + 1]
					and 
					all_pieces[i][j - 1].color == current_color and all_pieces[i][j + 1].color == current_color
				):
					all_pieces[i][j - 1].matched = true
					all_pieces[i][j - 1].dim()
					all_pieces[i][j].matched = true
					all_pieces[i][j].dim()
					all_pieces[i][j + 1].matched = true
					all_pieces[i][j + 1].dim()
					#mod
					add_to_array(Vector2(i,j))
					add_to_array(Vector2(i , j+1))
					add_to_array(Vector2(i, j -1))
	get_bombed_pieces()
	get_parent().get_node("destroy_timer").start()
#new method
func get_bombed_pieces():
	print("Checking for bombed pieces")
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					if all_pieces[i][j].is_column_bomb:
						match_all_in_column(i)
					elif all_pieces[i][j].is_row_bomb:
						match_all_in_row(j)
					elif all_pieces[i][j].is_adjacent_bomb:
						find_adjacent_pieces(i, j)
#NUEVO METODO
func add_to_array(value, array_to_add = current_matches):
	if !array_to_add.has(value):
		array_to_add.append(value)

#new method
func find_bombs():
	# Iterate over the current_matches array
	for i in current_matches.size():
		# Store some values for this match
		var current_column = current_matches[i].x
		var current_row = current_matches[i].y
		var current_color = all_pieces[current_column][current_row].color
		var col_matched = 0
		var row_matched = 0
		# Iterate over the current matches to check for column, row, and color
		for j in current_matches.size():
			var this_column = current_matches[j].x
			var this_row = current_matches[j].y
			var this_color = all_pieces[current_column][current_row].color
			if this_column == current_column and current_color == this_color:
				col_matched += 1
			if this_row == current_row and this_color == current_color:
				row_matched += 1
		# 0 is an adj bomb, 1, is a row bomb, and 2 is a column bomb
		# 3 is a color bomb
		if col_matched == 5 or row_matched == 5:
			print("creating color bomb")
			make_bomb(3, current_color)
			return
		elif col_matched >= 3 and row_matched >= 3:
			print("creating adjacent bomb")
			make_bomb(0, current_color)
			return
		elif col_matched == 4:
			print("creating row bomb")
			make_bomb(1, current_color)
			return
		elif row_matched == 4:
			print("creating column bomb")
			make_bomb(2, current_color)
			return
			
#new method
func make_bomb(bomb_type, color):
	print("Making bomb of type: ", bomb_type, " with color: ", color)
	for i in current_matches.size():
		var current_column = current_matches[i].x
		var current_row = current_matches[i].y
		print("Checking piece at column:", current_column, " row:", current_row)
		if all_pieces[current_column][current_row] == piece_one and piece_one.color == color:
			piece_one.matched = false
			print("Calling change_bomb with bomb_type:", bomb_type)
			change_bomb(bomb_type, piece_one)
		if all_pieces[current_column][current_row] == piece_two and piece_two.color == color:
			piece_two.matched = false
			print("Calling change_bomb with bomb_type:", bomb_type) 
			change_bomb(bomb_type, piece_two)
			
			
#new method
func change_bomb(bomb_type, piece):
	if bomb_type == 0:
		print("adjacent bomb")
		piece.make_adjacent_bomb()
	elif bomb_type == 1:
		print("row bomb")
		piece.make_row_bomb()
	elif bomb_type == 2:
		print("column bomb")
		piece.make_column_bomb()
	elif bomb_type == 3:
		print("color bomb")
		piece.make_color_bomb()
	
func destroy_matched():
	find_bombs()#new
	var was_matched = false
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				was_matched = true
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null
				global_score += 10
	move_checked = true
	if was_matched:
		emit_signal("increase_points",global_score*multi_score)
		global_score = 0
		get_parent().get_node("collapse_timer").start()
	else:
		swap_back()
	current_matches.clear()

func match_color(color):
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].color == color:
					match_and_dim(all_pieces[i][j])
					add_to_array(Vector2(i,j))


func clear_board():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				match_and_dim(all_pieces[i][j])
				add_to_array(Vector2(i,j))


func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				print(i, j)
				# look above
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("refill_timer").start()

func refill_columns():
	if multi_score < 3:
		multi_score += 1
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				# random number
				var rand = randi_range(0, possible_pieces.size() - 1)
				# instance 
				var piece = possible_pieces[rand].instantiate()
				# repeat until no matches
				var max_loops = 100
				var loops = 0
				while (match_at(i, j, piece.color) and loops < max_loops):
					rand = randi_range(0, possible_pieces.size() - 1)
					loops += 1
					piece = possible_pieces[rand].instantiate()
				add_child(piece)
				piece.position = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i, j))
				# fill array with pieces
				all_pieces[i][j] = piece
				
	check_after_refill()

func check_after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i, j, all_pieces[i][j].color):
				find_matches()
				get_parent().get_node("destroy_timer").start()
				return
	multi_score = 1
	emit_signal("reduce_attemps")
	emit_signal("can_change_game_mode",true)
	state = MOVE
	move_checked = false
#new methods
func match_all_in_column(column):
	for i in height:
		if all_pieces[column][i] != null:
			if all_pieces[column][i].is_row_bomb:
				match_all_in_row(i)
			if all_pieces[column][i].is_adjcent_bomb:
				find_adjacent_pieces(column, i)
			all_pieces[column][i].matched = true;

func match_all_in_row(row):
	for i in width:
		if all_pieces[i][row] != null:
			if all_pieces[i][row].is_column_bomb:
				match_all_in_column(i)
			if all_pieces[i][row].is_adjacent_bomb:
				find_adjacent_pieces(i , row)
			all_pieces[i][row].matched = true;

#new method
func find_adjacent_pieces(column, row):
	for i in range(-1, 2):
		for j in range(-1, 2):
			if in_grid(column + i, row + j):
				if all_pieces[column + i][row + j] != null:
					if all_pieces[column][i].is_row_bomb:
						match_all_in_row(i)
					if all_pieces[i][row].is_column_bomb:
						match_all_in_column(i)
					all_pieces[column + i][row + j].matched = true;
	


func _on_destroy_timer_timeout():
	print("destroy")
	destroy_matched()

func _on_collapse_timer_timeout():
	print("collapse")
	emit_signal("can_change_game_mode",false)
	collapse_columns()

func _on_refill_timer_timeout():
	print("reffill")
	refill_columns()
	
func game_over():
	state = WAIT

func _on_top_ui_send_end_game_mode(game_mode):
	game_over_mode = game_mode

func _on_top_ui_finish_game(end_of_game):
	end_game = end_of_game

func _on_top_ui_win_game(win):
	winner_of_game = win
