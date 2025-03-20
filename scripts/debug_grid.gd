@tool
extends Node2D

const GRID_SIZE = 64

func _ready():
	# 设置为顶层绘制，这样就不会受父节点变换的影响
	top_level = true
	# 确保在最上层显示
	z_index = 1000

func _draw():
	# 获取相机和视口信息
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
		
	var viewport_size = get_viewport_rect().size
	var zoom = camera.zoom
	
	# 计算世界视图大小
	var world_view_width = viewport_size.x / zoom.x
	var world_view_height = viewport_size.y / zoom.y
	
	# 获取相机位置
	var camera_pos = camera.global_position
	
	# 计算可见区域的网格范围
	var start_x = int(floor((camera_pos.x - world_view_width/2) / GRID_SIZE))
	var end_x = int(ceil((camera_pos.x + world_view_width/2) / GRID_SIZE))
	var start_y = int(floor((camera_pos.y - world_view_height/2) / GRID_SIZE))
	var end_y = int(ceil((camera_pos.y + world_view_height/2) / GRID_SIZE))
	
	# 计算可见区域边界
	var visible_rect = Rect2(
		Vector2(start_x * GRID_SIZE, start_y * GRID_SIZE),
		Vector2((end_x - start_x) * GRID_SIZE, (end_y - start_y) * GRID_SIZE)
	)
	
	# 绘制半透明填充
	draw_rect(visible_rect, Color(0, 1, 0, 0.1), true)
	# 绘制边框
	draw_rect(visible_rect, Color(0, 1, 0), false, 2.0)

func _process(_delta):
	# 更新全局位置以跟随相机
	var camera = get_viewport().get_camera_2d()
	if camera:
		global_position = Vector2.ZERO
		global_scale = Vector2.ONE
		global_rotation = 0
	queue_redraw() 