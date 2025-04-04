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
		#print("Top image size: ", top_image.texture.get_size())
		print("Top image scale: ", top_image.scale)
		print("Top image position: ", top_image.position)
		
		# 画像セレクタから初期画像をロード
		var image_selector = get_parent().get_node("ImageSelector")
		if image_selector:
			var initial_pair = image_selector.get_random_image_pair()
			print( initial_pair )
			if initial_pair:
				load_image_pair(initial_pair["top"], initial_pair["bottom"])
				auto_fit_image()
			else:
				# 画像が見つからない場合は空の状態を初期化
				init_empty_state()
				print( "画像が見つからない場合は空の状態を初期化" )
		else:
			print( "image_selectorが見つからない場合は空の状態を初期化" )
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
		# シェーダーファイルがない場合はコードから生成
		shader_material.shader = Shader.new()
		shader_material.shader.code = """
		shader_type canvas_item;
		uniform sampler2D mask_texture : hint_default_white;
		
		void fragment() {
			vec4 color = texture(TEXTURE, UV);
			float mask = texture(mask_texture, UV).a;
			color.a *= mask;
			COLOR = color;
		}
		"""
	
	shader_material.set_shader_parameter("mask_texture", current_mask_texture)
	top_image.material = shader_material

func cut_area(area_points):
	if area_points.size() < 3:
		return 0.0
	
	print("cut_area関数開始 - 点の数: ", area_points.size())
	# テクスチャサイズを取得
	var tex_img = top_image.texture.get_image()
	var texture_size = tex_img.get_size()
	
	# マスク画像を取得
	var mask_image = current_mask_texture.get_image()
	
	# 座標変換
	var polygon_points = []
	for point in area_points:
		# グローバル座標から画像の正規化座標に変換
		var local_pos = top_image.to_local(point)
		# 正規化座標からピクセル座標に変換
		var pixel_pos = Vector2i(
			(local_pos.x + texture_size.x / 2.0) / top_image.scale.x,
			(local_pos.y + texture_size.y / 2.0) / top_image.scale.y
		)
		polygon_points.append(pixel_pos)
	
	# バウンディングボックスを計算して処理範囲を限定
	var min_x = texture_size.x
	var min_y = texture_size.y
	var max_x = 0
	var max_y = 0
	
	for point in polygon_points:
		min_x = min(min_x, point.x)
		min_y = min(min_y, point.y)
		max_x = max(max_x, point.x)
		max_y = max(max_y, point.y)
	
	# 範囲をテクスチャ内に制限
	min_x = max(0, min_x)
	min_y = max(0, min_y)
	max_x = min(texture_size.x - 1, max_x)
	max_y = min(texture_size.y - 1, max_y)
	
	# カウント用変数
	var cut_pixels = 0
	
	# バウンディングボックス内のみを処理
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if is_point_in_polygon(Vector2(x, y), polygon_points):
				# ピクセルがポリゴン内にある場合、マスクを更新
				if mask_bitmap.get_bit(x, y):
					mask_bitmap.set_bit(x, y, false)
					mask_image.set_pixel(x, y, Color(0, 0, 0, 0))
					cut_pixels += 1
	
	# マスクテクスチャを更新
	current_mask_texture.update(mask_image)
	
	# 切り取り割合を計算
	var total_pixels = texture_size.x * texture_size.y
	var percentage = (cut_pixels / float(total_pixels)) * 100
	print("修正されたピクセル数: ", cut_pixels)
	print("切り取り割合: ", percentage, "%")
	
	# 現在の切り取り状況に新しく切り取ったピクセルを加える
	var current_cut_pixels = calculate_cut_pixels()
	var total_percentage = (current_cut_pixels / float(total_pixels)) * 100
	print("合計切り取り割合: ", total_percentage, "%")
	
	return total_percentage  # 累積の切り取り割合を返す

# 点が領域内にあるかチェックするヘルパー関数
func is_point_in_polygon(point, polygon):
	var inside = false
	var j = polygon.size() - 1
	
	for i in range(polygon.size()):
		if ((polygon[i].y > point.y) != (polygon[j].y > point.y)) and \
		   (point.x < polygon[i].x + (polygon[j].x - polygon[i].x) * (point.y - polygon[i].y) / (polygon[j].y - polygon[i].y)):
			inside = not inside
		j = i
	
	return inside

# 切り取り割合を計算
func calculate_cut_percentage():
	var total_pixels = mask_bitmap.get_size().x * mask_bitmap.get_size().y
	var cut_pixels = calculate_cut_pixels()
	return (cut_pixels / float(total_pixels)) * 100

# 切り取ったピクセル数を計算
func calculate_cut_pixels():
	var count = 0
	for y in range(mask_bitmap.get_size().y):
		for x in range(mask_bitmap.get_size().x):
			if not mask_bitmap.get_bit(x, y):
				count += 1
	return count

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
