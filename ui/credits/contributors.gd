extends Label

@export var contributors_paths: String = "contributors.txt"

func _ready():
	var file = FileAccess.open("res://" + contributors_paths, FileAccess.READ)
	if not file:
		return
	
	var contributors = []
	
	var line = file.get_line()
	while line:
		if len(line) > 0 and line[0] != "#":
			contributors.append(line)
		line = file.get_line()
		
	contributors = shuffleList(contributors)
	
	self.text = ""
	for contributor in contributors:
		self.text += contributor + "\n"

func shuffleList(list):
	var shuffledList = []
	var indexList = range(list.size())
	for i in range(list.size()):
		randomize()
		var x = randi()%indexList.size()
		shuffledList.append(list[x])
		indexList.remove_at(x)
		list.remove_at(x)
	return shuffledList
