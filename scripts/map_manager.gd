@tool
extends Node2D
class_name MapManager

# 视口大小
var viewport_size = Vector2.ZERO
# 图标大小（固定为128）
var icon_size = 256.0
# 基础缓冲区大小
var base_buffer_size = 1
# 图标节点引用
@onready var icon_template = $GridBackground
# 摄像机引用
@onready var camera = $Camera2D
# 存储已创建的图标
var icons = {}
# 图标对象池
var icon_pool = []
# 对象池大小
var pool_size = 200000

func _ready():
	# 隐藏模板图标
	icon_template.visible = false
	# 获取视口大小
	viewport_size = get_viewport_rect().size
	# 连接窗口大小改变信号
	get_tree().root.connect("size_changed", _on_viewport_size_changed)
	# 初始化对象池
	_init_icon_pool()

func _init_icon_pool():
	for i in range(pool_size):
		var new_icon = icon_template.duplicate()
		new_icon.visible = false
		new_icon.modulate.a = 0.5
		add_child(new_icon)
		icon_pool.push_back(new_icon)

func _on_viewport_size_changed():
	# 更新视口大小
	viewport_size = get_viewport_rect().size
	# 重新计算并更新地图
	update_map()

func get_adjusted_buffer_size():
	# 根据缩放级别动态调整缓冲区大小
	var zoom_factor = camera.zoom.x / 0.1  # 相对于最小缩放的比例
	return ceil(base_buffer_size * sqrt(zoom_factor) * 2)

func update_map():
	# 计算可见区域的图标范围（考虑缩放）
	var cam_pos = camera.position
	var zoom = camera.zoom.x
	var visible_size = viewport_size / zoom
	
	# 获取动态缓冲区大小
	var buffer_size = get_adjusted_buffer_size()
	
	# 计算基础范围（增加缓冲区）
	var base_start_x = floor((cam_pos.x - visible_size.x/2) / icon_size) - buffer_size
	var base_end_x = ceil((cam_pos.x + visible_size.x/2) / icon_size) + buffer_size
	var base_start_y = floor((cam_pos.y - visible_size.y/2) / icon_size) - buffer_size
	var base_end_y = ceil((cam_pos.y + visible_size.y/2) / icon_size) + buffer_size
	
	# 计算实际显示范围
	var range_x = base_end_x - base_start_x
	var range_y = base_end_y - base_start_y
	
	# 如果范围太大，进行限制
	if range_x * range_y > pool_size * 1:  # 保留20%的池容量作为缓冲
		var tmp_scale = sqrt(pool_size * 1 / (range_x * range_y))
		range_x = floor(range_x * tmp_scale)
		range_y = floor(range_y * tmp_scale)
	
	var start_x = base_start_x + (base_end_x - base_start_x - range_x) / 2
	var end_x = start_x + range_x
	var start_y = base_start_y + (base_end_y - base_start_y - range_y) / 2
	var end_y = start_y + range_y
	
	# 记录新的图标位置
	var new_positions = {}
	var icons_to_remove = icons.duplicate()
	
	# 创建需要的图标
	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			var pos = Vector2(x, y)
			new_positions[pos] = true
			if icons.has(pos):
				icons_to_remove.erase(pos)
			elif icon_pool.size() > 0:
				create_icon(pos)
	
	# 移除不需要的图标
	for pos in icons_to_remove:
		remove_icon(pos)

func create_icon(grid_pos: Vector2):
	if icon_pool.size() > 0:
		var icon = icon_pool.pop_back()
		icon.visible = true
		icon.position = grid_pos * icon_size
		icon.modulate.a = 0.5
		icons[grid_pos] = icon

func remove_icon(grid_pos: Vector2):
	if icons.has(grid_pos):
		var icon = icons[grid_pos]
		icon.visible = false
		icon_pool.push_back(icon)
		icons.erase(grid_pos)

func clear_all_icons():
	for icon in icons.values():
		icon.visible = false
		icon_pool.push_back(icon)
	icons.clear() 
