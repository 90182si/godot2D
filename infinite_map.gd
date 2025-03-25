@tool
extends MapManager

# 网格大小常量


# 相机控制器引用
@onready var camera_controller = $Camera2D
# 随机图标管理器引用
@onready var random_icon_manager: RandomIconManager

func _ready():
	# 检查相机控制器
	print("Checking Camera2D setup...")
	
	if not camera_controller:
		push_error("Camera2D node not found!")
		return
	
	print("Camera2D node found: ", camera_controller)
	print("Current script: ", camera_controller.get_script())
	
	# 如果没有脚本，添加脚本
	if not camera_controller.get_script():
		print("Attaching CameraController script...")
		var script = load("res://scripts/camera_controller.gd")
		if script:
			camera_controller.set_script(script)
		else:
			push_error("Failed to load CameraController script!")
			return
	
	# 初始化随机图标管理器
	print("Initializing RandomIconManager...")
	var random_icon_template = $RandomIcon
	if not random_icon_template:
		push_error("RandomIcon template node not found!")
		return
		
	# 创建随机图标管理器节点
	var manager_node = Node2D.new()
	manager_node.name = "RandomIconManager"
	
	# 添加脚本到管理器节点
	var manager_script = load("res://scripts/random_icon_manager.gd")
	if not manager_script:
		push_error("Failed to load RandomIconManager script!")
		return
		
	manager_node.set_script(manager_script)
	add_child(manager_node)
	# 等待一帧确保节点已经进入场景树
	await get_tree().process_frame
	
	# 将模板图标移动到管理器节点下
	remove_child(random_icon_template)
	manager_node.add_child(random_icon_template)
	
	random_icon_manager = manager_node
	
	# 初始化随机图标管理器，使用与地图图标相同的大小
	print("Icon size being passed to RandomIconManager: ", GRID_SIZE)
	random_icon_manager._init_with_template(GRID_SIZE, random_icon_template)
	
	# 连接相机更新信号
	if not camera_controller.has_signal("map_update_requested"):
		push_error("Camera controller does not have map_update_requested signal!")
		print("Available signals: ", camera_controller.get_signal_list())
		return
		
	camera_controller.map_update_requested.connect(_on_map_update_requested)
	
	# 调用父类的 _ready
	super()
	
	# 初始化时立即更新一次地图
	update_map()

func _on_map_update_requested():
	update_map()

func update_map():
	# 计算可见区域的图标范围（考虑缩放）
	var cam_pos = camera_controller.position
	var zoom = camera_controller.zoom.x
	var visible_size = viewport_size / zoom
	
	# 计算基础范围（增加缓冲区）
	var base_start_x = floor((cam_pos.x - visible_size.x/2))
	var base_end_x = ceil((cam_pos.x + visible_size.x/2))
	var base_start_y = floor((cam_pos.y - visible_size.y/2))
	var base_end_y = ceil((cam_pos.y + visible_size.y/2))
	
	# 计算实际显示范围
	var range_x = base_end_x - base_start_x
	var range_y = base_end_y - base_start_y
	
	var start_x = base_start_x + (base_end_x - base_start_x - range_x) / 2
	var end_x = start_x + range_x
	var start_y = base_start_y + (base_end_y - base_start_y - range_y) / 2
	var end_y = start_y + range_y
	
	# 记录新的图标位置
	var new_positions = {}
	var icons_to_remove = icons.duplicate()
	
	var buffer_size = get_adjusted_buffer_size()
	# 创建需要的图标
	for x in range(base_start_x/icon_size-1-buffer_size, base_end_x/icon_size+1+buffer_size):
		for y in range(base_start_y/icon_size-1-buffer_size, base_end_y/icon_size+1+buffer_size):
			var pos = Vector2(x, y)
			new_positions[pos] = true
			if icons.has(pos):
				icons_to_remove.erase(pos)
			elif icon_pool.size() > 0:
				create_icon(pos)
	
	# 移除不需要的图标
	for pos in icons_to_remove:
		remove_icon(pos)
	
	# 在可见区域内随机生成一些图标（如果还没有生成过）
	if not random_icon_manager.random_icons_generated:
		print("Generating initial random icons in visible area...")
		var total_icons = 500  # 先生成一小部分图标测试
		var icons_generated = 0
		
		while icons_generated < total_icons:
			var grid_x = randi_range(-200,200)
			var grid_y = randi_range(-200,200)
			var grid_pos = Vector2(grid_x, grid_y)
			
			if random_icon_manager.create_icon_at_grid(grid_pos):
				print("Generated random icon at: ", grid_pos)
			
			icons_generated += 1
		
		random_icon_manager.random_icons_generated = true
	
	# 更新随机图标的可见性
	random_icon_manager.update_random_icons_visibility(
		start_x/64-buffer_size, 
		end_x/64+buffer_size, 
		start_y/64-buffer_size, 
		end_y/64+buffer_size)
