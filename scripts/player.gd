extends CharacterBody2D

@export var speed = 300.0
var draw_mode = "slow"  # "slow" または "fast"
var drawing_line: Line2D

# プレイヤースクリプトに追加
var boundary_min = Vector2.ZERO
var boundary_max = Vector2.ZERO

# 壁上にいるかの判定用
var on_boundary = true
var last_position = Vector2.ZERO
var start_wall = ""  # 描画開始時の壁

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

# 現在のプレイヤーがどの壁にいるかを判断する関数
func get_wall_position():
	var tolerance = 1.0
	
	# 左壁
	if abs(position.x - boundary_min.x) < tolerance:
		return "left"
	
	# 右壁
	if abs(position.x - boundary_max.x) < tolerance:
		return "right"
	
	# 上壁
	if abs(position.y - boundary_min.y) < tolerance:
		return "top"
	
	# 下壁
	if abs(position.y - boundary_max.y) < tolerance:
		return "bottom"
	
	return "none"  # 壁上にいない場合

func set_movement_boundary(min_pos: Vector2, max_pos: Vector2):
	boundary_min = min_pos
	boundary_max = max_pos

func start_drawing(mode):
	
	if mode == "slow":
		drawing_line.default_color = Color(0, 1, 0, 1)  # 緑色 (SLOW DRAW)
		drawing_line.width = 2
	else:
		drawing_line.default_color = Color(1, 0, 0, 1)  # 赤色 (FAST DRAW)
		drawing_line.width = 2

func end_drawing():
	pass
