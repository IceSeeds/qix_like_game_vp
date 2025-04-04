extends Node2D

func _ready():
	setup_layout()
	setup_input_map()

func setup_layout():
	# 画面設定 (1920x1080)
	var screen_size = Vector2(1920, 1080)
	get_viewport().size = screen_size
	
	# 画像サイズを指定
	var image_width = 1344
	var image_height = 1728
	
	# 画像が画面に収まるようにスケール調整
	var scale_x = screen_size.x / image_width
	var scale_y = screen_size.y / image_height
	var scale_factor = min(scale_x, scale_y) * 0.9  # 少し余白を持たせる
	
	var scaled_width = image_width * scale_factor
	var scaled_height = image_height * scale_factor
	
	# 画像エリアを画面中央に配置
	var game_area = $GameArea
	game_area.position = Vector2((screen_size.x - scaled_width) / 2, (screen_size.y - scaled_height) / 2)
	
	# 背景の追加
	var background = ColorRect.new()
	background.color = Color(0.2, 0.2, 0.2)  # 暗めのグレー
	background.size = Vector2(scaled_width, scaled_height)
	background.position = Vector2(0, 0)  # GameAreaのローカル座標系での位置
	
	# 背景をGameAreaの最背面に追加
	game_area.add_child(background)
	background.z_index = -2  # 他の要素より後ろに表示
	
	# UIを画面右側に配置
	var ui_area = $UIArea
	ui_area.position = Vector2(game_area.position.x + scaled_width + 20, 20)
	
	# プレイヤーの初期位置
	var player = $GameArea/Player
	if player:
		player.position = Vector2(scaled_width/2, scaled_height/2)  # ゲームエリア内の中央
	
	# 画像レイヤーのスケールも調整
	# 画像レイヤーノードを取得
	var image_layers = $GameArea/ImageLayers
	image_layers.position = Vector2(scaled_width/2, scaled_height/2)
	if image_layers:
		var top_image = image_layers.get_node("TopImage")
		var bottom_image = image_layers.get_node("BottomImage")
		if top_image and bottom_image:
			# 画像のスケールを自動調整
			top_image.scale = Vector2(scale_factor, scale_factor)
			bottom_image.scale = Vector2(scale_factor, scale_factor)

func setup_input_map():
	# 入力マップの設定
	if not InputMap.has_action("draw_slow"):
		InputMap.add_action("draw_slow")
		var event = InputEventKey.new()
		event.keycode = KEY_Z
		InputMap.action_add_event("draw_slow", event)
	
	if not InputMap.has_action("draw_fast"):
		InputMap.add_action("draw_fast")
		var event = InputEventKey.new()
		event.keycode = KEY_X
		InputMap.action_add_event("draw_fast", event)
