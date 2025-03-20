@tool
extends Camera2D
class_name CameraController

# 基础移动速度
var base_camera_speed = 800.0
# 基础加速倍率
var base_sprint_multiplier = 2.0
# 移动插值速度
var movement_interpolation_speed = 15.0
# 当前速度向量
var current_velocity = Vector2.ZERO
# 加速度系数
var acceleration = 8.0
# 减速度系数
var deceleration = 10.0
# 缩放速度调整系数
var zoom_speed_factor = 0.8
# 最小移动速度倍率
var min_speed_multiplier = 0.5
# 最大移动速度倍率
var max_speed_multiplier = 2.0
# 缩放限制
var min_zoom = 0.1
var max_zoom = 2.0
var zoom_speed = 0.1
# 缩放插值速度
var zoom_interpolation_speed = 10.0
# 目标缩放值
var target_zoom = 1.0
# 是否正在缩放
var is_zooming = false
# 缩放更新计时器
var zoom_update_timer = 0.0
# 缩放更新间隔
var zoom_update_interval = 0.15

signal map_update_requested

func _ready():
	target_zoom = zoom.x
	InputMap.load_from_project_settings()

func _process(delta):
	# 处理摄像机移动
	var input = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		input.x += 1
	if Input.is_action_pressed("move_left"):
		input.x -= 1
	if Input.is_action_pressed("move_down"):
		input.y += 1
	if Input.is_action_pressed("move_up"):
		input.y -= 1
	
	# 处理缩放插值
	if zoom.x != target_zoom:
		# 获取鼠标在世界空间中的位置
		var mouse_pos = get_viewport().get_mouse_position()
		var viewport_size = get_viewport_rect().size
		var old_mouse_pos = get_screen_center_position() + (mouse_pos - viewport_size/2) / zoom.x
		
		# 应用缩放
		var new_zoom = lerp(zoom.x, target_zoom, delta * zoom_interpolation_speed)
		if abs(new_zoom - target_zoom) < 0.001:
			new_zoom = target_zoom
			is_zooming = false
			map_update_requested.emit()
		zoom = Vector2(new_zoom, new_zoom)
		
		# 计算新的摄像机位置以保持鼠标位置不变
		var new_mouse_pos = get_screen_center_position() + (mouse_pos - viewport_size/2) / zoom.x
		position += old_mouse_pos - new_mouse_pos
		
		# 使用计时器控制地图更新频率
		zoom_update_timer += delta
		if zoom_update_timer >= zoom_update_interval:
			zoom_update_timer = 0.0
			map_update_requested.emit()
	
	# 根据缩放级别计算目标速度
	var zoom_factor = 1.0 / zoom.x
	var speed_multiplier = get_speed_multiplier(zoom.x)
	var target_speed = base_camera_speed * pow(zoom_factor, zoom_speed_factor) * speed_multiplier
	
	# 检查是否按下加速键并计算最终目标速度
	if Input.is_action_pressed("sprint"):
		target_speed *= base_sprint_multiplier
	
	# 计算目标速度向量
	var target_velocity = input.normalized() * target_speed
	
	# 根据输入状态选择合适的加速度
	var acceleration_factor = acceleration if input != Vector2.ZERO else deceleration
	
	# 使用加速度平滑过渡到目标速度
	current_velocity = current_velocity.lerp(target_velocity, delta * acceleration_factor)
	
	# 如果速度很小，直接设为零（避免微小抖动）
	if current_velocity.length() < 1.0:
		current_velocity = Vector2.ZERO
	
	# 移动摄像机
	if current_velocity != Vector2.ZERO:
		position += current_velocity * delta
		map_update_requested.emit()

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# 获取鼠标在世界空间中的位置
			var mouse_pos = get_viewport().get_mouse_position()
			var viewport_size = get_viewport_rect().size
			var old_mouse_pos = get_screen_center_position() + (mouse_pos - viewport_size/2) / zoom.x
			
			# 设置新的缩放值
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				set_target_zoom(zoom_speed)  # 放大
			else:
				set_target_zoom(-zoom_speed)  # 缩小
			
			# 计算新的摄像机位置以保持鼠标位置不变
			var new_mouse_pos = get_screen_center_position() + (mouse_pos - viewport_size/2) / zoom.x
			position += old_mouse_pos - new_mouse_pos

func set_target_zoom(zoom_delta: float):
	target_zoom = clamp(target_zoom + zoom_delta, min_zoom, max_zoom)
	is_zooming = true
	zoom_update_timer = zoom_update_interval

func get_speed_multiplier(zoom_scale: float) -> float:
	# 计算缩放比例（相对于最小缩放）
	var zoom_ratio = (zoom_scale - min_zoom) / (max_zoom - min_zoom)
	# 使用平滑的插值计算速度倍率
	var speed_multiplier = lerp(max_speed_multiplier, min_speed_multiplier, zoom_ratio)
	return speed_multiplier 
