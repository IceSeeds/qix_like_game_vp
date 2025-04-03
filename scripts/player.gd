extends CharacterBody2D

@export var speed = 300.0
var drawing = false
var draw_points = []
var draw_mode = "slow"  # "slow" または "fast"
var drawing_line: Line2D

func _ready():
	drawing_line = get_node("../DrawingLine")

func _physics_process(delta):
	# 移動処理
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	
	# 描画状態の処理
	if Input.is_action_just_pressed("ui_accept"):
		start_drawing("slow")
	elif Input.is_action_just_pressed("ui_select"):
		start_drawing("fast")
	elif Input.is_action_just_released("ui_accept") or Input.is_action_just_released("ui_select"):
		end_drawing()
	
	# 描画中なら点を追加
	if drawing:
		# 重要: DrawingLineの座標系にプレイヤーの座標を変換する
		var local_pos = drawing_line.to_local(global_position)
		draw_points.append(local_pos)
		drawing_line.points = PackedVector2Array(draw_points)

func start_drawing(mode):
	drawing = true
	draw_mode = mode
	draw_points.clear()
	
	# 重要: 最初の点も座標変換する
	var local_pos = drawing_line.to_local(global_position)
	draw_points.append(local_pos)
	
	# 描画線の設定
	drawing_line.clear_points()
	drawing_line.add_point(local_pos)
	
	if mode == "slow":
		drawing_line.default_color = Color(0, 1, 0, 1)  # 緑色 (SLOW DRAW)
	else:
		drawing_line.default_color = Color(1, 0, 0, 1)  # 赤色 (FAST DRAW)

# player.gd の end_drawing 関数に追加
func end_drawing():
	if drawing and draw_points.size() > 2:
		# 最後の点を追加して閉じる
		draw_points.append(draw_points[0])
		drawing_line.points = PackedVector2Array(draw_points)
		
		# グローバル座標に変換
		var global_points = []
		for point in draw_points:
			global_points.append(drawing_line.to_global(point))
		
		var percentage = get_node("../ImageLayers").cut_area(global_points)
		print("切り取り処理完了 - 割合: ", percentage, "%")

		# UIに進捗を反映
		var ui_manager = get_parent().get_parent().get_node("UIManager")
		if ui_manager:
			ui_manager.update_progress(percentage)
			
			# 描画モードに応じたスコア計算
			var area_size = draw_points.size()  # 簡易的な面積計算
			var points = area_size * (2 if draw_mode == "fast" else 1)
			ui_manager.update_score(points)
		
		# デバッグ - 切り取られた領域の可視化（オプション）
		var debug_line = Line2D.new()
		debug_line.points = PackedVector2Array(draw_points)
		debug_line.default_color = Color(1, 1, 0, 0.5)  # 黄色半透明
		debug_line.width = 1.0
		get_parent().add_child(debug_line)
