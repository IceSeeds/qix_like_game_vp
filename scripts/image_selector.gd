extends Node

var top_images = []
var bottom_images = []
var used_pairs = []

var load_avaiable: bool = false

func _ready():
	load_available_images()

func load_available_images():
	if load_avaiable:
		return null
	
	# 利用可能な画像を読み込む
	var dir = DirAccess.open("res://images/top")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".png") or file_name.ends_with(".jpg"):
				top_images.append("res://images/top/" + file_name)
			file_name = dir.get_next()
	
	dir = DirAccess.open("res://images/bottom")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".png") or file_name.ends_with(".jpg"):
				bottom_images.append("res://images/bottom/" + file_name)
			file_name = dir.get_next()
	
	print("読み込んだ画像: ", top_images.size(), "個のトップ画像, ", bottom_images.size(), "個のボトム画像")
	
	# 画像がない場合はデモ用のダミー画像を作成
	if top_images.size() == 0:
		create_dummy_image("res://images/top/demo_top.png")
		top_images.append("res://images/top/demo_top.png")
	
	if bottom_images.size() == 0:
		create_dummy_image("res://images/bottom/demo_bottom.png")
		bottom_images.append("res://images/bottom/demo_bottom.png")
	
	load_avaiable = true

# デモ用のダミー画像を作成
func create_dummy_image(path):
	var img = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	
	# 色を塗る
	var is_top = "top" in path
	var color = Color(0, 0, 1, 1) if is_top else Color(1, 0, 0, 1)
	img.fill(color)
	
	# 簡単な模様を描く
	for x in range(128):
		for y in range(128):
			if (x + y) % 16 == 0:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	
	# 画像を保存
	var dir = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	
	img.save_png(path)

func get_random_image_pair():
	#読み込みチェック
	load_available_images()

	# 画像ペアをランダムに選択
	if top_images.size() == 0 or bottom_images.size() == 0:
		print( "画像ペアをランダムに選択が空配列" )
		return null
	
	var pair = {
		"top": top_images[randi() % top_images.size()],
		"bottom": bottom_images[randi() % bottom_images.size()]
	}
	
	# 履歴管理（あまりに多くの画像がある場合は調整が必要）
	if used_pairs.size() >= min(top_images.size(), bottom_images.size()):
		used_pairs.clear()
	
	used_pairs.append(pair)
	return pair
