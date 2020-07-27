extends Node2D

# Was originally based off becky lavender's approach
# But the weird grammer generator stuff went too far over my head

# Instead I decided to implement a method similar to this irl role playing game stuff:
# https://forum.rpg.net/index.php?threads/necro-my-zelda-dungeon-generator.827119/

# Downside is that it's much less procedural, but it's easier to create hand crafted dungeons with different layouts
# But, it would still allow control over backtracking, linearity, etc once I bother implementing it

# TO DO:
# Add more dungeon start variation
# Clean Code
# Add support for locks and keys once implemented

enum SEGMENTS {START, LOCK, KEY, DUNGEON_ITEM, DUNGEON_LOCK, MINIBOSS, BOSS_KEY, BOSS_DOOR, REWARD, COMBAT, TRAVERSAL, PUZZLE, EMPTY}
enum DIRECTIONS {LEFT, RIGHT, UP, DOWN}

const WIDTH = 256 * 14/16;
const HEIGHT = 144 * 7/9;

var room_counter = 0
var ROOMS = {
		
		DOOR_UP = preload("res://maps/dungeon_prefabs/doors/door_up.tscn"),
		DOOR_DOWN = preload("res://maps/dungeon_prefabs/doors/door_down.tscn"),	
		DOOR_LEFT = preload("res://maps/dungeon_prefabs/doors/door_left.tscn"),
		DOOR_RIGHT = preload("res://maps/dungeon_prefabs/doors/door_right.tscn"),
	
		WALL_DOWN = preload("res://maps/dungeon_prefabs/walls/wall_down.tscn"),
		WALL_UP = preload("res://maps/dungeon_prefabs/walls/wall_up.tscn"),	
		WALL_LEFT = preload("res://maps/dungeon_prefabs/walls/wall_left.tscn"),
		WALL_RIGHT = preload("res://maps/dungeon_prefabs/walls/wall_right.tscn"),
		
		FLOOR = preload("res://maps/dungeon_prefabs/floor.tscn")
	
	}

func _ready():
	randomize() # Sets a random seed
	create_dungeon()

func _process(delta):
	# Resets Room layout
	if(Input.is_action_just_pressed("A")):
		create_dungeon()
#

# Reset Room layout if previous one exists
func create_dungeon() -> Room:
	for child in get_children():
		child.queue_free()
	var exceptions = {}
	var entrance_segments = generate_segments()
	var d = setup_room_layout(entrance_segments.turn_to_dungeon(), exceptions, Vector2(0,0), WIDTH, HEIGHT, true)
	while(d):
		print("tried again")
		for child in get_children():
			child.queue_free()		
		exceptions = {}
		entrance_segments = generate_segments()
		d = setup_room_layout(entrance_segments.turn_to_dungeon(), exceptions, Vector2(0,0), WIDTH, HEIGHT, true)
#	pprint_tree(entrance_segments)
	return d

# Used for testing room "depth"
func pprint_tree(node : Segment, prefix="", last=true):
	print(prefix, "`-" if last else "|- ", SEGMENTS.keys()[node._type])
	prefix += "\t" if last else "|   "
	var child_count = len(node._segments)
	for i in child_count:
		last = i == (child_count - 1)
		pprint_tree(node._segments[i], prefix, last)

# Defines a single room as a node that can have other nodes connected to it
class Segment:
	var _type : int = SEGMENTS.START;
	var _segments : Array = [];
	# Used for adding segments to ends of structures, not actually traversing the segments
	# I may just make a new class that inherits from it and called it segment or something like that, but this works for now
	var _start : Segment; 
	var _end : Segment;
	# Used for setting up connections with doors
	var _connected_to : Array = [];
	var _equivalent : Room;
	func _init(type: int = SEGMENTS.START, segments: Array = []):
		self._type = type;
		self._segments = segments;

	func set_start() -> Segment: # Used for initalizing segment, set's the head of the segment
		self._start = self;
		return self;
	
	func set_end() -> Segment: # Used for creating segment's end
		self._end = self;
		return self;
		
	# Used only for segments that are NOT a segment, otherwise itll add to the parent node, not the end
	func add_segment(new_segment: Segment) -> Segment: 
		self._segments.append(new_segment)
		self._connected_to.append(new_segment)
		new_segment._connected_to.append(self)
		
		if(self._start != null): 
			new_segment._start = self._start
		if(new_segment._end != null): 
			self._end = new_segment
		return self
	
	func add_segments(new_segments: Array) -> Segment:
		for segment in new_segments:
			self.add_segment(segment);
		return self
	
	# Used for appending to the end of a segment, to make sure that segments attach to the desired end node
	func add_to_end(new_segment) -> Segment: 
		if(typeof(new_segment) == TYPE_ARRAY):
			for segment in new_segment:
				self._end.add_segment(segment)
		else:
			self._end.add_segment(new_segment)
		return self
	
	func get_segments_list(include_self: bool = false) -> Array:
		var segments = self._segments.duplicate(true)
		var i = 0;
		while len(segments) > i:
			for segment in segments[i]._segments:
				segments.append(segment)
			i+=1
		if(include_self): segments.push_front(self)
		return segments
	
	func turn_to_dungeon() -> Room:
		var room = Room.new(self._type); 
		
		for segment in self._segments:
			var connected_room = segment.turn_to_dungeon()
			room.add_room(connected_room)
		self._equivalent = room
		return room
	
#	# Replaced with pprint_tree(node)
	# Was used for testing
	func represent(level = 0) -> String:
		var output = ""
		for i in level:
			output += "\t"
		output += SEGMENTS.keys()[self._type] + "\n"
		for segment in self._segments:
			output += segment.represent(level+1)
		return output
	

# Defines a room similary to a Segment, but includes the direction of where rooms are
class Room:
	var _type : int;
	var _child_rooms = []
	var _parent : Room;
	var _position : Vector2;
	
	var _connected_to = {
		0: null,
		1: null,
		2: null,
		3: null
	}
	
	func _init(type, pos=Vector2()):
		self._type = type
		self._position = pos
	
	func add_room(new_room: Room):
		_child_rooms.append(new_room)
		new_room._parent = self
	
func setup_room_layout(current: Room, taken_rooms: Dictionary, starting_position = Vector2(0,0), width_offset= WIDTH, height_offset=HEIGHT, is_entrance = false):
	
	if(is_entrance): taken_rooms[Vector2(0,0)] = current
	
	var available_directions = [Vector2(-WIDTH,0),
								Vector2(WIDTH, 0),
								Vector2(0,-HEIGHT),
								Vector2(0,HEIGHT)]
	
	var taken_room_positions = taken_rooms.keys()
	
	# Remove unavailable directions:
	for i in range(len(available_directions) -1, -1, -1):
		if taken_rooms.keys().has(current._position + available_directions[i]):
			available_directions.remove(i)
	
	if len(available_directions) < len(current._child_rooms):
		return true
	
	for room in current._child_rooms:
		# Set random directions
		var direction = (available_directions[randi()% available_directions.size()])

		# To make the space a little longer, and reduce the chance of big rooms being too close, I add a big chance that rooms are in a straight line (75 vs 25 percent)
		if(current._parent):
			var direction_from_parent = current._parent._position - current._position
			var next_position = current._position + direction_from_parent
			if(!taken_rooms.keys().has(next_position) and randf() < .75):
				direction = direction_from_parent
		
		var test_position = starting_position + Vector2(direction.x, direction.y)
		
		# Check position is not taken
		var attempt = 6
		while taken_rooms.keys().has(test_position):
			direction = (available_directions[randi()% available_directions.size()])
			test_position = starting_position + Vector2(direction.x, direction.y)
			attempt -= 1
			if(attempt == 0):
				print("Failed, trying again")
				return true
		var dir_enum;
		var opposite_dir_enum;
		
		# Godot is weird with match statements, values to compare cannot be constants or variables, or anything fancy
		match(Vector2(direction.x/WIDTH, direction.y/HEIGHT )):
			Vector2(0,-1):
				dir_enum = DIRECTIONS.UP
				opposite_dir_enum = DIRECTIONS.DOWN
			Vector2(0,1):
				dir_enum = DIRECTIONS.DOWN
				opposite_dir_enum = DIRECTIONS.UP
			Vector2(-1,0):
				dir_enum = DIRECTIONS.LEFT
				opposite_dir_enum = DIRECTIONS.RIGHT
			Vector2(1,0):
				dir_enum = DIRECTIONS.RIGHT
				opposite_dir_enum = DIRECTIONS.LEFT
		
		var previous_position = starting_position
		starting_position = test_position
		room._position = test_position
		taken_rooms[starting_position] = room
		
		current._connected_to[dir_enum] = room
		room._connected_to[opposite_dir_enum] = current 

		# If recursion breaks unexpectedly, it will force create_dungeon() to restart
		var is_broken = setup_room_layout(room, taken_rooms, starting_position, width_offset, height_offset)
		if is_broken == true: return true
		
		starting_position = previous_position # Resets the position to the parent room
		generate_room_chunk(room, room._position) # Handles what's in the room, the walls, and whatnot
		
	if(is_entrance):  generate_room_chunk(current, Vector2(0,0)) # Will skip the start room if not done
	return false

func generate_room_chunk(room : Room, pos):
	
	# Create dungeon floor
	var dungeon_floor = ROOMS.FLOOR.instance()
	add_child(dungeon_floor)
	dungeon_floor.position = pos
	
	# Used for dungeon walls / doors / locked doors (locked doors to be implemented)
	if(room._connected_to[DIRECTIONS.UP]):
		var wall = ROOMS.DOOR_UP.instance()
		add_child(wall)
		wall.position = pos
	else:
		var wall = ROOMS.WALL_UP.instance()
		add_child(wall)
		wall.position = pos

	if(room._connected_to[DIRECTIONS.DOWN]):
		var wall = ROOMS.DOOR_DOWN.instance()
		add_child(wall)
		wall.position = pos
	else:
		var wall = ROOMS.WALL_DOWN.instance()
		add_child(wall)
		wall.position = pos

	if(room._connected_to[DIRECTIONS.LEFT]):
		var wall = ROOMS.DOOR_LEFT.instance()
		add_child(wall)
		wall.position = pos
	else:
		var wall = ROOMS.WALL_LEFT.instance()
		add_child(wall)
		wall.position = pos

	if(room._connected_to[DIRECTIONS.RIGHT]):
		var wall = ROOMS.DOOR_RIGHT.instance()
		add_child(wall)
		wall.position = pos
	else:
		var wall = ROOMS.WALL_RIGHT.instance()
		add_child(wall)
		wall.position = pos
		
	# Draws Labels for Room types
	var label = Label.new()
	label.text = SEGMENTS.keys()[room._type]
	add_child(label)
	label.rect_position = pos 
	label.rect_scale = Vector2(2, 2)
	label.rect_size = Vector2(WIDTH/2, HEIGHT/2)
	label.valign = Label.VALIGN_CENTER
	label.align = Label.ALIGN_CENTER

# just returns a random item in an array
func choose(options: Array, print_choice: bool = false):
	var value = randi()%len(options)
	if(print_choice): print(value)
	return options[value]


func generate_segments() -> Segment:
	var options = []
	
	# I made functions to recreate patterns that would be reusable
	# i.e segments that are connected to two segments with keys
	# and a locked segment connected to another locked segment
	# These are like categories with variety within them, randomly picking a variation when the function is called
	# Whichever variation picked by function, Their purpose to the structure of the dungeon is the same 

	# The fact that the function is the same to the structure to the dungeon means that I had to copy paste segments to add even some slight variation in some cases
	# I've indented to be slightly more readable
	
	# Will add more as well
	
	options.append(Segment.new().add_segments(
		[regular_segment().add_to_end(
			two_extra_keys().add_to_end(
				dungeon_lock().add_to_end(
						boss_door()
						))),
		 lock().add_to_end(lock()).add_to_end(
			dungeon_item().add_to_end(
				dungeon_lock().add_to_end([
					two_extra_keys(),
					lock().add_to_end(lock()).add_to_end(
						boss_key()
					)
				])
			)
		)]))
	options.append(Segment.new().add_segments(
		[regular_segment().add_to_end([
			two_extra_keys().add_to_end(
				dungeon_lock().add_to_end(
					boss_door()
				)
			),
			lock().add_to_end(lock()).add_to_end(
				dungeon_item().add_to_end(
					dungeon_lock().add_to_end([
						two_extra_keys(),
						lock().add_to_end(lock()).add_to_end(boss_key())
					])
				)
			)
			])
		]))
	# These are linear with less linear variations
	options.append(Segment.new().add_segments([
		key(),
		lock().add_to_end([
			key(),
			lock().add_to_end([
				key(),
				lock().add_to_end(
					dungeon_item()
				),
				dungeon_lock().add_to_end(
					boss_key()),
				boss_door()
			])
		]),
	]))
	
	options.append(Segment.new().add_segments([
		key().add_to_end(
			dungeon_lock().add_to_end(
				boss_key()
			)
		),
		regular_segment().add_to_end([
			two_extra_keys().add_to_end(
				boss_door()
			),
			lock().add_to_end(
				lock().add_to_end(
					dungeon_item()
				)
			)
		])
	]))
	
	# Hella backtracking, might be unfun. But I had fun planning this
	options.append(Segment.new().add_segments([
		# Dungeon lock to boss key
		key().add_to_end([
			dungeon_lock().add_to_end(
				regular_segment().add_to_end(
					boss_key()
				)
			)
		]),
		# Segment with boss door
		lock().add_to_end([
			regular_segment().add_to_end(
				two_extra_keys()
			),
			lock().add_to_end(lock()).add_to_end(
				boss_door()
			)
		]),
		# Segment with Dungeon Item
		lock().add_to_end([
			lock().add_to_end([
				dungeon_item(),
				key(),
				key()
			])
		])
	]))
	# Slightly less backtracking
	options.append(Segment.new().add_segments([
		# Dungeon lock to boss key
		key().add_to_end([
			dungeon_lock().add_to_end(
				regular_segment().add_to_end(
					boss_key()
				)
			)
		]),
		# Segment with boss door
		lock().add_to_end([
			regular_segment().add_to_end(
				two_extra_keys()
			),
			lock().add_to_end(lock()).add_to_end(
				boss_door()
			),
			# Segment with Dungeon Item
			lock().add_to_end([
				lock().add_to_end([
					dungeon_item(),
					key(),
					key()
				])
			]),
		])
	]))
	
	# Slightly less Backtracking, 2nd variation
	# Hella backtracking, might be unfun. But I had fun planning this
	options.append(Segment.new().add_segments([
		# Dungeon lock to boss key
		key().add_to_end([
			dungeon_lock().add_to_end(
				regular_segment().add_to_end(
					boss_key()
				)
			)
		]),
		# Segment with boss door
		lock().add_to_end([
			regular_segment().add_to_end(
				two_extra_keys()
			),
			lock().add_to_end(lock()).add_to_end(
				boss_door()
			)
		]),
		# Segment with Dungeon Item
		lock().add_to_end([
			lock().add_to_end([
				dungeon_item(),
				key(),
				key()
			])
		]),
	]))
	# Slightly less backtracking
	options.append(Segment.new().add_segments([
		# Dungeon lock to boss key
		key().add_to_end([
			dungeon_lock().add_to_end(
				regular_segment().add_to_end(
					boss_key()
				)
			)
		]),
		# Segment with boss door
		lock().add_to_end([
			regular_segment().add_to_end(
				two_extra_keys()
			),
			lock().add_to_end(lock()).add_to_end(
				boss_door()
			),
			# Segment with Dungeon Item
			lock().add_to_end([
				lock().add_to_end([
					dungeon_item(),
					key(),
					key()
				])
			]),
		])
	]))	
	
	# The most linear variation there is
	options.append(Segment.new().add_segments([
		regular_segment().add_to_end([
			key(),
			lock().add_to_end([
				dungeon_item().add_to_end(
					dungeon_lock().add_to_end(
						boss_key().add_to_end(
							regular_segment().add_to_end(
								boss_door()
							)
						)
					)
				)
			])
		])
	]))
		# This is so unbelievably hard to read, but if I try making it any more readable makes it infinitely longer (if i were to use variables)
	
	return choose(options, true)

# These are used to add variety but currently only reduce the repeated use of Segment.new(ROOMS.___) 

func key() -> Segment:
	var options = []
	
	options.append(
		regular_segment().set_start().add_to_end([
			regular_segment(),
			regular_segment().add_to_end(
				Segment.new(SEGMENTS.KEY).set_end()
			)
		])
	)
	
	options.append(
		regular_segment().add_to_end(Segment.new(SEGMENTS.KEY).set_start().set_end())
	)
	
	options.append(
		regular_segment().set_start().add_to_end(
			Segment.new(SEGMENTS.KEY).set_end()
		)
	)
	
	return choose(options)

func lock() -> Segment:
	var options = []
	options.append(
		regular_segment().set_start().add_to_end(Segment.new(SEGMENTS.LOCK).set_end())
	)
	
	options.append(
		regular_segment().add_to_end(Segment.new(SEGMENTS.LOCK).set_end())
	)
	
	return choose(options)

func key_and_lock() -> Segment:
	var options = []
	options.append(
		regular_segment().set_start().add_segments([
			key(),
			lock().set_end()
		])
	)
	
	options.append(
		regular_segment().set_start().add_segments([
			key(),
			regular_segment().add_to_end(lock())
		])
	)
	
	return choose(options)

func boss_key() -> Segment:
	var options = []
	options.append(Segment.new(SEGMENTS.BOSS_KEY).set_start().set_end())
	options.append(
		regular_segment().set_start().add_to_end([
			regular_segment().add_to_end(two_extra_keys()),
			lock().add_to_end(lock()).add_to_end(Segment.new(SEGMENTS.BOSS_KEY).set_end())
		]))
	options.append(regular_segment().set_start().add_to_end(Segment.new(SEGMENTS.BOSS_KEY).set_end()))
	return choose(options)

func two_extra_keys() -> Segment:
	var options = []
	options.append(
		regular_segment().set_start().add_segments([
			Segment.new(SEGMENTS.KEY),
			Segment.new(SEGMENTS.KEY).set_end()
		]))
		
	options.append(Segment.new(SEGMENTS.KEY).set_start().add_segment(Segment.new(SEGMENTS.KEY).set_end()))
	
	return choose(options)

func boss_door() -> Segment:
	var options = []
	options.append(Segment.new(SEGMENTS.BOSS_DOOR).set_start().set_end())
	return choose(options)

# Mini boss unimplemented, is not used
func miniboss() -> Segment:
	var options = []
	options.append(regular_segment().set_start().add_to_end(Segment.new(SEGMENTS.MINIBOSS)).set_end())
	options.append(regular_segment().set_start().add_to_end([
		regular_segment().add_to_end(key()),
		regular_segment().add_to_end(lock()),
		Segment.new(SEGMENTS.MINIBOSS).set_end()
	]))
	return choose(options)

func dungeon_lock() -> Segment:
	var options = []
	options.append(regular_segment().set_start().add_segment(Segment.new(SEGMENTS.DUNGEON_LOCK).set_end()))
	return choose(options)

func dungeon_item() -> Segment:
	var options = []
	options.append(Segment.new(SEGMENTS.DUNGEON_ITEM).set_start().set_end())
	options.append(regular_segment().set_start().add_to_end([
		regular_segment().add_to_end(key()),
		regular_segment().add_to_end(lock()),
		Segment.new(SEGMENTS.DUNGEON_ITEM).set_end()
	]))
	options.append(regular_segment().set_start().add_to_end([
		regular_segment().add_to_end(key()),
		regular_segment().add_to_end(lock()),
		regular_segment().add_to_end(Segment.new(SEGMENTS.DUNGEON_ITEM).set_end())
	]))
	return choose(options)

func regular_segment() -> Segment:
	var options = [SEGMENTS.COMBAT]
	return Segment.new(choose(options)).set_start().set_end()


