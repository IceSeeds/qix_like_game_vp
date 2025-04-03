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
		#bottom_image.scale = Vector2(5, 5)
		#top_image.scale = Vector2(5, 5)
		bottom_image.scale = Vector2(1, 1)
		top_image.scale = Vector2(1, 1)
		
		# 画像セレクタから初期画像をロード
		var image_selector = get_parent().get_node("ImageSelector")
		if image_selector:
			var initial_pair = image_selector.get_random_image_pair()
			print( initial_pair )
			if initial_pair:
				load_image_pair(initial_pair["top"], initial_pair["bottom"])
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
	
	# デバッグ情報
	print("領域の点数: ", area_points.size())
	
	# テクスチャサイズを取得
	var tex_img = top_image.texture.get_image()
	var texture_size = tex_img.get_size()
	print("テクスチャサイズ: ", texture_size)
	
	# マスク画像を直接作成
	var mask_image = tex_img.duplicate()
	
	# 画面座標からテクスチャ座標への変換を改善
	var local_points = []
	for point in area_points:
		# グローバル座標からトップ画像のローカル座標へ
		var local_point = top_image.to_local(point)
		# スケール調整（より正確に）
		var tex_point = Vector2(
			local_point.x / top_image.scale.x,
			local_point.y / top_image.scale.y
		)
		local_points.append(tex_point)
	
	# ポリゴンの描画（フィル処理）
	var polygon = PackedVector2Array(local_points)
	
	# 単純なバウンディングボックス方式から、
	# Godotの画像処理機能を使用した方法に変更
	var temp_img = Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	temp_img.fill(Color(0, 0, 0, 0))  # 透明で初期化
	
	# ポリゴンを白で描画（これがマスクになる）
	for y in range(texture_size.y):
		for x in range(texture_size.x):
			if is_point_in_polygon(Vector2(x, y), polygon):
				temp_img.set_pixel(x, y, Color(1, 1, 1, 1))
	
	# マスク画像を作成し、切り取り部分を透明に
	for y in range(texture_size.y):
		for x in range(texture_size.x):
			if temp_img.get_pixel(x, y).a > 0.5:  # マスク部分
				mask_bitmap.set_bit(x, y, false)  # ビットマップを更新
				mask_image.set_pixel(x, y, Color(0, 0, 0, 0))  # 透明にする
	
	# マスクテクスチャを更新
	current_mask_texture.update(mask_image)
	
	# 切り取られたピクセル数のカウント
	var count = 0
	for y in range(texture_size.y):
		for x in range(texture_size.x):
			if not mask_bitmap.get_bit(x, y):
				count += 1
	
	# 切り取り割合を計算
	var total_pixels = texture_size.x * texture_size.y
	var percentage = (count / float(total_pixels)) * 100
	print("修正されたピクセル数: ", count)
	print("切り取り割合: ", percentage, "%")
	
	return percentage

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
