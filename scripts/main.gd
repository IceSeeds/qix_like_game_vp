extends Node2D

func _ready():
	setup_layout()
	setup_input_map()

func setup_layout():
	# 画面設定 (1920x1080)
	var screen_size = Vector2(1920, 1080)
	get_viewport().size = screen_size
	
	# 画像エリアを画面中央に配置
	var game_area = $GameArea
	# 中央に配置
	game_area.position = Vector2((screen_size.x - 600) / 2, (screen_size.y - 600) / 2)  # 仮の大きさとして600x600を使用
	
	# UIを画面右側に配置
	var ui_area = $UIArea
	ui_area.position = Vector2(game_area.position.x + 650, 20)  # ゲームエリアの右側
	
	# プレイヤーの初期位置
	var player = $GameArea/Player
	if player:
		player.position = Vector2(300, 300)  # ゲームエリア内の位置

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
