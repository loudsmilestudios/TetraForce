extends RefCounted
class_name RenderLayers

# Keep the old actor/foreground planes. Objects on the actor plane are
# ordered by their ground position, so their tops occlude actors behind them.
# Main sprites must inherit this plane with relative Z = 0. Walkable platforms
# use relative Z = -1 so crossing them never depends on actor Y-sort order.
const ACTORS = 100
const FOREGROUND = 200
