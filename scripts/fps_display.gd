extends Label

var fps = 0
var frame_count = 0
var time = 0

func _ready():
	# 设置标签样式
	add_theme_font_size_override("font_size", 32)  # 增大字体
	add_theme_color_override("font_color", Color(1, 1, 1))
	add_theme_constant_override("outline_size", 4)  # 增大描边
	add_theme_color_override("font_outline_color", Color(0, 0, 0))
	
	# 设置位置
	position = Vector2(20, 20)  # 稍微调整位置
	# 设置文本
	text = "FPS: 0"
	# 设置自动换行
	autowrap_mode = TextServer.AUTOWRAP_OFF
	# 设置对齐方式
	horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vertical_alignment = VERTICAL_ALIGNMENT_TOP
	# 设置z_index确保显示在最上层
	z_index = 9999  # 使用更大的z_index值
	# 设置背景色以便于调试
	add_theme_stylebox_override("normal", create_stylebox(Color(0, 0, 0, 0.5)))
	
	print("FPS Display initialized")  # 调试信息

func create_stylebox(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style

func _process(delta):
	time += delta
	frame_count += 1
	
	# 每秒更新一次FPS
	if time >= 1.0:
		fps = frame_count / time
		text = "FPS: %d" % fps
		time = 0
		frame_count = 0 