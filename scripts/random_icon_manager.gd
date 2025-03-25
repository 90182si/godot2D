@tool
@icon("res://icon.svg")
extends Node2D
class_name RandomIconManager

# 网格大小常量
const GRID_SIZE = 64

# RandomIcon 大小（相对于网格大小的比例）
var random_icon_size: float
# 随机图标节点引用
var random_icon_template: Sprite2D
# 随机图标对象池
var random_icon_pool = []
# 随机图标对象池大小
var random_pool_size = 50000
# 存储已创建的随机图标
var random_icons = {}
# 随机图标生成范围
var random_icon_range = 50000
# 随机图标生成概率
var random_icon_chance = 0.5
# 是否已生成随机图标
var random_icons_generated = false
# 随机图标的 z 值
var random_icon_z = 1.0
# 基础图标大小
var icon_size: float

func _ready():
	# 启用鼠标输入
	set_process_input(true)

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# 获取鼠标点击的全局位置
			var click_pos = get_global_mouse_position()
			
			# 转换为网格坐标
			var grid_x = floor(click_pos.x / GRID_SIZE)
			var grid_y = floor(click_pos.y / GRID_SIZE)
			var grid_pos = Vector2(grid_x, grid_y)
			
			# 在网格位置生成图标
			create_icon_at_grid(grid_pos)
			
			# 确保事件不会继续传递
			get_viewport().set_input_as_handled()
		#点击左键删除节点
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			# 获取鼠标点击的全局位置
			var click_pos = get_global_mouse_position()
			
			# 转换为网格坐标
			var grid_x = floor(click_pos.x / GRID_SIZE)
			var grid_y = floor(click_pos.y / GRID_SIZE)
			var grid_pos = Vector2(grid_x, grid_y)
			
			# 删除网格位置的图标
			remove_random_icon(grid_pos)			

func create_icon_at_grid(grid_pos: Vector2) -> bool:
	# 检查模板是否有效
	if random_icon_template == null:
		push_error("Random icon template is null!")
		return false
		
	# 如果这个位置已经有图标或者没有可用的图标，则返回
	if random_icons.has(grid_pos):
		return false
		
	if random_icon_pool.size() == 0:
		return false
		
	var icon = random_icon_pool.pop_back()
	
	# 将图标放在网格中心点
	var pixel_x = int(grid_pos.x) * GRID_SIZE + GRID_SIZE/2.0
	var pixel_y = int(grid_pos.y) * GRID_SIZE + GRID_SIZE/2.0
	
	icon.position = Vector2(pixel_x, pixel_y)
	icon.z_index = random_icon_z
	
	# 确保图标大小正确
	if icon is Sprite2D:
		var target_scale = random_icon_size / icon.texture.get_size().x
		icon.scale = Vector2(target_scale, target_scale)
	
	# 使用网格坐标作为键
	random_icons[grid_pos] = icon
	
	# 确保图标可见
	icon.visible = true
	icon.modulate.a = 1.0
	
	return true

func _init_with_template(base_icon_size: float, template: Sprite2D):
	if template == null:
		push_error("Template is null in _init_with_template!")
		return
		
	icon_size = base_icon_size
	random_icon_size = GRID_SIZE * 1  # 将图标大小设置为网格的100%
	random_icon_template = template
	
	# 设置 RandomIcon 模板的大小
	var scale_tmp = Vector2(
		random_icon_size / random_icon_template.texture.get_size().x,
		random_icon_size / random_icon_template.texture.get_size().y
	)
	random_icon_template.scale = scale_tmp
	
	# 隐藏模板图标
	random_icon_template.visible = false
	# 设置随机图标的 z 值
	random_icon_template.z_index = int(random_icon_z)
	
	# 清空现有的对象池
	clear_all_random_icons()
	# 初始化对象池
	_init_random_icon_pool()

func _init_random_icon_pool():
	if random_icon_template == null:
		push_error("RandomIcon template is null!")
		return
		
	for i in range(random_pool_size):
		var new_icon = random_icon_template.duplicate()
		new_icon.visible = false  # 初始时设置为不可见
		new_icon.z_index = random_icon_z
		add_child(new_icon)
		random_icon_pool.push_back(new_icon)

func generate_random_icons():
	if random_icons_generated or random_icon_template == null:
		return
		
	var total_icons = 10000  # 要生成的总图标数
	var icons_generated = 0
	
	# 生成范围（以网格为单位）
	var range_size = 50000  # 在-50到50的网格范围内随机生成
	
	while icons_generated < total_icons and random_icon_pool.size() > 0:
		# 随机选择一个网格位置
		var grid_x = randi_range(-range_size, range_size)
		var grid_y = randi_range(-range_size, range_size)
		var grid_pos = Vector2(grid_x, grid_y)
		
		# 尝试在该位置创建图标
		if create_icon_at_grid(grid_pos):
			icons_generated += 1
	
	random_icons_generated = true

func update_random_icons_visibility(start_x: int, end_x: int, start_y: int, end_y: int):
	var _visible_count = 0
	var _total_checked = 0
	
	# 计算可见范围的大小
	var visible_range_x = end_x - start_x
	var visible_range_y = end_y - start_y
	
	# 如果可见范围太大，进行限制
	if visible_range_x * visible_range_y > random_pool_size * 0.8:
		var tmp_scale = sqrt(random_pool_size * 0.8 / (visible_range_x * visible_range_y))
		visible_range_x = floor(visible_range_x * tmp_scale)
		visible_range_y = floor(visible_range_y * tmp_scale)
		
		# 调整范围以保持中心点
		end_x -= visible_range_x/2
		end_y -= visible_range_y/2
		start_x = end_x - visible_range_x
		start_y = end_y - visible_range_y
	
	# 遍历所有图标
	for grid_pos in random_icons:
		_total_checked += 1
		var icon = random_icons[grid_pos]
		
		# 简单的可见性检查 - 直接使用传入的范围
		var should_be_visible = (
			grid_pos.x >= start_x and
			grid_pos.x <= end_x and
			grid_pos.y >= start_y and
			grid_pos.y <= end_y
		)
		
		# 直接设置可见性
		if should_be_visible:
			_visible_count += 1
			icon.visible = true
			
			# 检查周围RandomIcon节点数量
			var directions = [
				Vector2(0, -1),  # 上
				Vector2(0, 1),   # 下
				Vector2(-1, 0),  # 左
				Vector2(1, 0)    # 右
			]
			
			var adjacent_count = 0
			for dir in directions:
				var check_pos = grid_pos + dir
				if random_icons.has(check_pos):
					adjacent_count += 1
			
			# 如果周围RandomIcon节点数量大于等于3，设置透明度为1
			if adjacent_count >= 3:
				icon.modulate.a = 1.0
			else:
				icon.modulate.a = 0.5
			
			# 确保图标大小正确
			if icon is Sprite2D:
				var target_scale = random_icon_size / icon.texture.get_size().x
				if icon.scale != Vector2(target_scale, target_scale):
					icon.scale = Vector2(target_scale, target_scale)
		else:
			# 如果不在可见范围内，直接隐藏
			if icon.visible:
				icon.visible = false
				icon.modulate.a = 0.0
	
	# 打印调试信息
	print("随机图标更新信息:")
	print("可见范围: X(", start_x, " ~ ", end_x, ") Y(", start_y, " ~ ", end_y, ")")
	print("可见图标数量: ", _visible_count)
	print("检查总数: ", _total_checked)
	print("----------------------------------------")

func remove_random_icon(grid_pos: Vector2):
	# 直接使用网格坐标
	if random_icons.has(grid_pos):
		var icon = random_icons[grid_pos]
		icon.visible = false
		random_icon_pool.push_back(icon)
		random_icons.erase(grid_pos)

func clear_all_random_icons():
	for icon in random_icons.values():
		icon.visible = false
		random_icon_pool.push_back(icon)
	random_icons.clear() 
