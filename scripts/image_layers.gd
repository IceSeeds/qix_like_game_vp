extends Node2D

var bottom_image: Sprite2D
var top_image: Sprite2D
var mask_bitmap: BitMap
var current_mask_texture: ImageTexture

func _ready():
	# 画像の初期化
	bottom_image = $BottomImage
	top_image = $TopImage
	
	# 初期状態では空の状態にしておく
	if bottom_image and top_image:
		# 画像サイズを設定
		bottom_image.scale = Vector2(1, 1)
		top_image.scale = Vector2(1, 1)

		# 中央揃えにして座標変換を簡素化
		bottom_image.centered = true
		top_image.centered = true

		# さらに、画像の位置を明示的に設定
		bottom_image.position = Vector2(0, 0)
		top_image.position = Vector2(0, 0)
		
		# デバッグ情報
		print("Top image scale: ", top_image.scale)
		print("Top image position: ", top_image.position)
		
		# 画像セレクタから初期画像をロード
		var image_selector = get_parent().get_node("ImageSelector")
		if image_selector:
			var initial_pair = image_selector.get_random_image_pair()
			print(initial_pair)
			if initial_pair:
				load_image_pair(initial_pair["top"], initial_pair["bottom"])
				auto_fit_image()
			else:
				# 画像が見つからない場合は空の状態を初期化
				init_empty_state()
				print("画像が見つからない場合は空の状態を初期化")
		else:
			print("image_selectorが見つからない場合は空の状態を初期化")
			init_empty_state()

# 画像がない場合の初期化
func init_empty_state():
	# 透明な画像を作成
	var empty_image = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	empty_image.fill(Color(0, 0, 0, 0))
	
	var empty_texture = ImageTexture.create_from_image(empty_image)
	
	bottom_image.texture = empty_texture
	top_image.texture = empty_texture
	
	# マスクの初期化
	init_mask()

func init_mask():
	# マスクの初期化
	var img = top_image.texture.get_image()
	# アルファ用にコンバート
	img.convert(Image.FORMAT_RGBA8)

	mask_bitmap = BitMap.new()
	mask_bitmap.create_from_image_alpha(img)
	
	# マスク用テクスチャの初期化
	current_mask_texture = ImageTexture.create_from_image(img)
	
	# シェーダーマテリアルの設定
	var shader_material = ShaderMaterial.new()
	
	# シェーダーファイルの読み込み
	var shader = load("res://shaders/mask.gdshader")
	if shader:
		shader_material.shader = shader
	else:
		print("not found sheder file")
	
	shader_material.set_shader_parameter("mask_texture", current_mask_texture)
	top_image.material = shader_material

# Qix風切り取りアルゴリズム
func cut_area(area_points):
	if area_points.size() < 3:
		print("切り取りに必要な点の数が不足しています")
		return 0.0
	
	print("切り取りポイント数: ", area_points.size())
	
	# テクスチャサイズを取得
	var tex_img = top_image.texture.get_image()
	var texture_size = Vector2(tex_img.get_width(), tex_img.get_height())
	
	# マスク画像を取得（編集用）
	var mask_image = current_mask_texture.get_image()
	
	# デバッグ情報
	print("テクスチャサイズ: ", texture_size)
	print("画像スケール: ", top_image.scale)
	
	
	return 0


func load_image_pair(top_path, bottom_path):
	# 新しい画像をロード
	var top_texture = load(top_path)
	var bottom_texture = load(bottom_path)
	
	if top_texture and bottom_texture:
		# 画像を設定
		bottom_image.texture = bottom_texture
		top_image.texture = top_texture
		
		# 下層画像を赤色に設定（視覚的差異のため）
		bottom_image.modulate = Color(1, 0, 0, 1)
		
		# マスクを初期化
		init_mask()
		
		print("新しい画像ペアをロードしました")
		return true
	
	print("画像のロードに失敗しました")
	return false

func auto_fit_image():
	# 表示したい領域のサイズ（例：画面の中央部分）
	var container_size = Vector2(600, 600) # 任意のサイズに変更可能
	
	if bottom_image and bottom_image.texture and top_image and top_image.texture:
		var texture_size = top_image.texture.get_size()
		
		# 縦横比を維持しながら画像全体が表示されるようにスケール計算
		var scale_x = container_size.x / texture_size.x
		var scale_y = container_size.y / texture_size.y
		var scale_factor = min(scale_x, scale_y)
		
		# スケールを両方の画像に適用
		bottom_image.scale = Vector2(scale_factor, scale_factor)
		top_image.scale = Vector2(scale_factor, scale_factor)
		
		print("画像を自動的に調整しました。スケール: ", scale_factor)
