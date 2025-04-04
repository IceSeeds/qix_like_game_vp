extends Node

var score = 0
var level = 1
var lives = 3
var progress = 0.0

# UI要素への参照
var score_label: Label
var level_label: Label
var lives_label: Label
var progress_bar: ProgressBar

func _ready():
	setup_ui()

func setup_ui():
	# UIエリアを取得
	var ui_area = get_parent().get_node("UIArea")
	
	# スコア表示
	score_label = Label.new()
	score_label.text = "スコア: " + str(score)
	score_label.position = Vector2(20, 20)
	ui_area.add_child(score_label)
	
	# レベル表示
	level_label = Label.new()
	level_label.text = "レベル: " + str(level)
	level_label.position = Vector2(20, 60)
	ui_area.add_child(level_label)
	
	# 残機表示
	lives_label = Label.new()
	lives_label.text = "残機: " + str(lives)
	lives_label.position = Vector2(20, 100)
	ui_area.add_child(lives_label)
	
	# 進行度ゲージ
	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = progress
	progress_bar.size = Vector2(200, 20)
	progress_bar.position = Vector2(20, 140)
	ui_area.add_child(progress_bar)

func update_score(points):
	score += points
	score_label.text = "スコア: " + str(score)

func update_progress(percentage):
	progress = percentage
	progress_bar.value = progress
	
	# 75%以上で次のレベルへ
	if progress >= 75.0:
		next_level()

func next_level():
	level += 1
	level_label.text = "レベル: " + str(level)
	progress = 0.0
	progress_bar.value = progress
	
	# 新しい画像ペアをロード
	var image_selector = get_parent().get_node("ImageSelector")
	if image_selector:
		var new_pair = image_selector.get_random_image_pair()
		if new_pair:
			# 画像を更新
			var image_layers = get_parent().get_node("GameArea/ImageLayers")
			if image_layers:
				image_layers.load_image_pair(new_pair["top"], new_pair["bottom"])
				print("レベル ", level, " の新しい画像をロードしました")

func lose_life():
	lives -= 1
	lives_label.text = "残機: " + str(lives)

	if lives <= 0:
		game_over()

func game_over():
	print("ゲームオーバー")
	# ゲームオーバー画面表示
