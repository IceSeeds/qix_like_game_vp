extends Node

var top_images = []
var bottom_images = []
var used_pairs = []

func _ready():
	load_available_images()

func load_available_images():
	# 利用可能な画像を読み込む
	var dir = DirAccess.open("res://images/top")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".png"):
				top_images.append("res://images/top/" + file_name)
			file_name = dir.get_next()
	
	dir = DirAccess.open("res://images/bottom")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".png"):
				bottom_images.append("res://images/bottom/" + file_name)
			file_name = dir.get_next()
	
	print("読み込んだ画像: ", top_images.size(), "個のトップ画像, ", bottom_images.size(), "個のボトム画像")
	
	# テスト用のアイコンを一時的に追加
	if top_images.size() == 0:
		top_images.append("res://icon.svg")
		print( "top_img, test用画像" )
	if bottom_images.size() == 0:
		bottom_images.append("res://icon.svg")
		print( "bottom_img, test用画像" )

func get_random_image_pair():
	# 画像ペアをランダムに選択
	if top_images.size() == 0 or bottom_images.size() == 0:
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
