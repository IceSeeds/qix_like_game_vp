extends CharacterBody2D

@export var speed = 300.0
var drawing = false
var draw_points = []
var draw_mode = "slow"  # "slow" または "fast"
var drawing_line: Line2D
var can_draw = true

# プレイヤースクリプトに追加
var boundary_min = Vector2.ZERO
var boundary_max = Vector2.ZERO

# 壁上にいるかの判定用
var on_boundary = true
var last_position = Vector2.ZERO

func _ready():
	drawing_line = get_node("../DrawingLine")
	last_position = position

func _physics_process(delta):
	# 移動処理
	var direction = Vector2.ZERO
	
	# 水平・垂直の入力を個別に処理
	if Input.is_action_pressed("ui_right"):
		direction.x = 1
	elif Input.is_action_pressed("ui_left"):
		direction.x = -1
	
	if Input.is_action_pressed("ui_down"):
		direction.y = 1
	elif Input.is_action_pressed("ui_up"):
		direction.y = -1
	
	# 水平・垂直のどちらかのみ移動可能
	if direction.x != 0 && direction.y != 0:
		# 両方入力されている場合は、x方向を優先
		direction.y = 0
	
	if direction != Vector2.ZERO:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
	
	# 現在位置を保存
	last_position = position
	
	move_and_slide()

	# 移動後に境界チェック
	position.x = clamp(position.x, boundary_min.x, boundary_max.x)
	position.y = clamp(position.y, boundary_min.y, boundary_max.y)
	
	# 壁上にいるかをチェック
	check_boundary_position()
	
	# 壁から離れた時に描画を開始
	if !drawing && !on_boundary && can_draw:
		start_drawing("slow")  # デフォルトはslow、必要に応じて変更可能
	
	# 壁に戻った時に描画を終了
	if drawing && on_boundary:
		end_drawing()
	
	# 描画中なら点を追加
	if drawing:
		# 重要: DrawingLineの座標系にプレイヤーの座標を変換する
		var local_pos = drawing_line.to_local(global_position)
		draw_points.append(local_pos)
		drawing_line.points = PackedVector2Array(draw_points)

# 壁上にいるかを判定する関数
func check_boundary_position():
	var tolerance = 1.0  # 判定の許容誤差
	
	on_boundary = false
	
	# 左右の壁
	if abs(position.x - boundary_min.x) < tolerance || abs(position.x - boundary_max.x) < tolerance:
		on_boundary = true
	
	# 上下の壁
	if abs(position.y - boundary_min.y) < tolerance || abs(position.y - boundary_max.y) < tolerance:
		on_boundary = true
	
	# ここに領域内の他の壁（すでに描画済みの線など）の判定も追加できます

func set_movement_boundary(min_pos: Vector2, max_pos: Vector2):
	boundary_min = min_pos
	boundary_max = max_pos

func start_drawing(mode):
	drawing = true
	draw_mode = mode
	draw_points.clear()
	
	# 重要: 最初の点も座標変換する
	var local_pos = drawing_line.to_local(global_position)
	draw_points.append(local_pos)
	print("描画開始: ", local_pos)
	
	# 描画線の設定
	drawing_line.clear_points()
	drawing_line.add_point(local_pos)
	
	if mode == "slow":
		drawing_line.default_color = Color(0, 1, 0, 1)  # 緑色 (SLOW DRAW)
		drawing_line.width = 1
	else:
		drawing_line.default_color = Color(1, 0, 0, 1)  # 赤色 (FAST DRAW)

func end_drawing():
	if drawing and draw_points.size() > 2:
		# 最後の点を追加
		var last_point = drawing_line.to_local(global_position)
		draw_points.append(last_point)
		
		# 最初の点に戻る
		var first_point = draw_points[0]
		draw_points.append(first_point)
		
		# 描画線を更新
		drawing_line.points = PackedVector2Array(draw_points)
		
		# グローバル座標に変換
		var global_points = []
		for point in draw_points:
			global_points.append(drawing_line.to_global(point))
		
		# 切り取り処理
		var percentage = get_node("../ImageLayers").cut_area(global_points)
		print("切り取り処理完了 - 割合: ", percentage, "%")
		
		# UIに進捗を反映
		var ui_manager = get_parent().get_parent().get_node("UIManager")
		if ui_manager:
			ui_manager.update_progress(percentage)
			ui_manager.update_score(draw_points.size() * (2 if draw_mode == "fast" else 1))
		
		# デバッグ - 切り取られた領域の可視化
		var debug_line = Line2D.new()
		debug_line.points = PackedVector2Array(draw_points)
		debug_line.default_color = Color(1, 1, 0, 0.5)  # 黄色半透明
		debug_line.width = 1.0
		debug_line.z_index = 5
		get_parent().add_child(debug_line)
	
	# 描画状態をリセット
	drawing = false
	draw_points.clear()
	drawing_line.clear_points()
