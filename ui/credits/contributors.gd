extends Label

export(String) var contributors_paths = "contributors.txt"

func _ready():
	var file = File.new()
	file.open("res://"+contributors_paths, file.READ)
	
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
		indexList.remove(x)
		list.remove(x)
	return shuffledList
