class_name TournamentMaster

const ARENA_DATA = {
	"inn_cellar" : {
		"name" : "Jupiter Arena"
	}
}

enum MATCH_TYPE {
	ONE_VS_ONE,
	FOUR_FFA
}

var unranked_queue = {}
var active_queues = []

func reset():
	unranked_queue = {}

func _matchmaker_tick() -> void:
	if _has_no_authority_error(): return
	
	for arena in unranked_queue:
		for match_type in unranked_queue[arena]:
			var queue = unranked_queue[arena][match_type]
			match match_type:
				MATCH_TYPE.ONE_VS_ONE:
					if len(queue) >= 2:
						pass
				MATCH_TYPE.FOUR_FFA:
					if len(queue) >= 4:
						pass

func _notify_match_ready():
	if _has_no_authority_error(): return

func _add_player_to_queue(pid, arena, queue):
	if _has_no_authority_error(): return
	
	if not arena in unranked_queue:
		unranked_queue[arena] = {}
	if not queue in unranked_queue[arena]:
		unranked_queue[arena].queue = []
	if not pid in unranked_queue[arena].queue:
		unranked_queue[arena].queue.append(pid)
		network.peer_call_id(pid, self.active_queues, "append", ["%s/%s" % [arena, queue]])
	
	_matchmaker_tick()

func _remove_player_from_queue(pid, arena, queue):
	if _has_no_authority_error(): return
	
	if arena in unranked_queue:
		if queue in unranked_queue[arena]:
			unranked_queue[arena].queue.erase(pid)
			network.peer_call_id(pid, self.active_queues, "erase", ["%s/%s" % [arena, queue]])
	
	_matchmaker_tick()

func join_queue(arena, match_type):
	network.dedicated_call(self, "_add_player_to_queue", [network.pid, arena, match_type])

func leave_queue(arena, match_type):
	network.dedicated_call(self, "_remove_player_from_queue", [network.pid, arena, match_type])

func _has_no_authority_error() -> bool:
	if network.pid != 1:
		printerr("Cannot interact with tournament backend as client!")
		return true
	return false
