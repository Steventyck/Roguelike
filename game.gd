extends Node2D

var player_pos := Vector2(360, 640)
var player_speed := 350.0
var player_hp := 100.0
var max_hp := 100.0
var score := 0
var game_over := false

var touch_start := Vector2.ZERO
var move_dir := Vector2.ZERO
var is_touching := false

var enemies := []
var bullets := []
var spawn_timer := 0.0
var shoot_timer := 0.0
var difficulty := 1.0

func _input(event):
	if game_over:
		if event is InputEventScreenTouch and event.pressed:
			restart_game()
		return
		
	if event is InputEventScreenTouch:
		if event.pressed:
			is_touching = true
			touch_start = event.position
		else:
			is_touching = false
			move_dir = Vector2.ZERO
	elif event is InputEventScreenDrag and is_touching:
		var diff = event.position - touch_start
		if diff.length() > 10:
			move_dir = diff.normalized()
		else:
			move_dir = Vector2.ZERO

func restart_game():
	player_pos = Vector2(360, 640)
	player_hp = max_hp
	score = 0
	difficulty = 1.0
	enemies.clear()
	bullets.clear()
	game_over = false

func _process(delta):
	queue_redraw()
	if game_over:
		return
		
	difficulty += delta * 0.05
	player_pos += move_dir * player_speed * delta
	player_pos.x = clamp(player_pos.x, 30, 690)
	player_pos.y = clamp(player_pos.y, 30, 1250)
	
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = max(0.3, 1.5 / difficulty)
		spawn_enemy()
		
	shoot_timer -= delta
	if shoot_timer <= 0 and enemies.size() > 0:
		shoot_timer = 0.45
		shoot_nearest()
		
	for i in range(bullets.size() - 1, -1, -1):
		var b = bullets[i]
		b.pos += b.dir * 700.0 * delta
		if b.pos.x < -50 or b.pos.x > 770 or b.pos.y < -50 or b.pos.y > 1330:
			bullets.remove_at(i)
			
	for i in range(enemies.size() - 1, -1, -1):
		var e = enemies[i]
		var dir = (player_pos - e.pos).normalized()
		e.pos += dir * e.speed * delta
		
		if e.pos.distance_to(player_pos) < 35:
			player_hp -= 25 * delta
			if player_hp <= 0:
				player_hp = 0
				game_over = true
				
		for j in range(bullets.size() - 1, -1, -1):
			if e.pos.distance_to(bullets[j].pos) < 28:
				e.hp -= 1
				bullets.remove_at(j)
				if e.hp <= 0:
					enemies.remove_at(i)
					score += 10
				break

func spawn_enemy():
	var side = randi() % 4
	var pos = Vector2.ZERO
	match side:
		0: pos = Vector2(randf_range(0, 720), -30)
		1: pos = Vector2(randf_range(0, 720), 1310)
		2: pos = Vector2(-30, randf_range(0, 1280))
		3: pos = Vector2(750, randf_range(0, 1280))
	enemies.append({"pos": pos, "speed": randf_range(110, 170) * min(difficulty, 2.0), "hp": 2})

func shoot_nearest():
	var nearest = enemies[0]
	var min_dist = player_pos.distance_to(nearest.pos)
	for e in enemies:
		var d = player_pos.distance_to(e.pos)
		if d < min_dist:
			min_dist = d
			nearest = e
	var dir = (nearest.pos - player_pos).normalized()
	bullets.append({"pos": player_pos, "dir": dir})

func _draw():
	draw_rect(Rect2(0, 0, 720, 1280), Color(0.12, 0.12, 0.16))
	
	for b in bullets:
		draw_circle(b.pos, 8, Color(1.0, 0.9, 0.2))
		
	for e in enemies:
		draw_circle(e.pos, 20, Color(0.9, 0.25, 0.25))
		
	draw_circle(player_pos, 22, Color(0.2, 0.7, 1.0))
	
	draw_rect(Rect2(40, 40, 200, 20), Color(0.3, 0.1, 0.1))
	draw_rect(Rect2(40, 40, 200 * (player_hp / max_hp), 20), Color(0.2, 0.85, 0.3))
	
	if is_touching and not game_over:
		draw_arc(touch_start, 50, 0, TAU, 32, Color(1, 1, 1, 0.3), 3.0)
		draw_circle(touch_start + move_dir * 30, 15, Color(1, 1, 1, 0.5))
		
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(520, 60), "SCORE: " + str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
	
	if game_over:
		draw_rect(Rect2(0, 0, 720, 1280), Color(0, 0, 0, 0.6))
		draw_string(font, Vector2(180, 600), "GAME OVER", HORIZONTAL_ALIGNMENT_CENTER, 360, 52, Color.RED)
		draw_string(font, Vector2(160, 670), "Tap to restart", HORIZONTAL_ALIGNMENT_CENTER, 400, 32, Color.WHITE)
