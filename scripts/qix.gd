extends CharacterBody2D

@export var speed = 200.0
@export var direction_change_probability = 0.02
var boundary_min: Vector2
var boundary_max: Vector2

func _ready():
	# 初期速度をランダムに設定
	velocity = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized() * speed
	
	# 境界を設定
	var image_layers = get_parent().get_node("ImageLayers")
	if image_layers and image_layers.top_image:
		var top_image = image_layers.top_image
		var size = top_image.get_rect().size * top_image.scale
		boundary_min = top_image.global_position - size/2
		boundary_max = top_image.global_position + size/2
	else:
		# デフォルトの境界
		var parent = get_parent()
		boundary_min = Vector2.ZERO
		boundary_max = Vector2(600, 600)  # 仮の値

func _physics_process(delta):
	# 一定確率で方向転換
	if randf() < direction_change_probability:
		change_direction()
	
	# 境界に達したら反射
	if position.x <= boundary_min.x or position.x >= boundary_max.x:
		velocity.x = -velocity.x
	if position.y <= boundary_min.y or position.y >= boundary_max.y:
		velocity.y = -velocity.y
	
	# 移動と衝突検出
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
		
	# プレイヤーの描画線との衝突チェック
	check_line_collision()

func change_direction():
	# ランダムな新しい方向に変更
	var angle = randf_range(0, 2 * PI)
	velocity = Vector2(cos(angle), sin(angle)) * speed

func check_line_collision():
	# プレイヤーが描画中の線との衝突をチェック
	var player = get_parent().get_node("Player")
	if player and player.drawing:
		var draw_line = get_parent().get_node("DrawingLine")
		if draw_line and draw_line.points.size() > 1:
			# 簡易的な衝突判定
			for i in range(draw_line.points.size() - 1):
				var segment_start = draw_line.to_global(draw_line.points[i])
				var segment_end = draw_line.to_global(draw_line.points[i + 1])
				
				# 線分とQixの距離を計算
				var closest_point = Geometry2D.get_closest_point_to_segment(global_position, segment_start, segment_end)
				var distance = global_position.distance_to(closest_point)
				
				# 一定距離以下なら衝突
				if distance < 20:  # 仮の衝突範囲
					# プレイヤーの描画を失敗させる
					player.drawing_fail()
