extends RefCounted

# Procedural level generator.
# Every level is longer and harder, but always beatable with the player physics
# from game.gd (jump reach ~104 px = 3.2 tiles, holes are always 3 tiles).

const ROWS := 11
const GROUND_ROW := 10
const BASE_COLS := 80
const COLS_PER_LEVEL := 30
const MAX_COLS := 320
const GAP_WIDTH := 3
const BOSS_EVERY := 3
const ARENA_COLS := 18
const THEMES := ["grass", "sand", "stone", "dirt", "snow", "purple"]

static func background_for(theme: String) -> String:
	match theme:
		"sand":
			return "background_color_desert"
		"stone":
			return "background_solid_dirt"
		"dirt":
			return "background_fade_trees"
		"snow":
			return "background_solid_cloud"
		"purple":
			return "background_color_mushrooms"
		_:
			return "background_color_hills"

# Flying enemies: none before level 3, then 1 + (level - 3) / 2, max 6.
static func flyer_count(level: int) -> int:
	if level < 3:
		return 0
	return clampi(1 + int((level - 3) / 2), 1, 6)

static func generate(level: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260902 + level * 7919

	var cols: int = mini(BASE_COLS + COLS_PER_LEVEL * (level - 1), MAX_COLS)
	var is_boss: bool = (level % BOSS_EVERY) == 0
	var arena_start: int = cols
	if is_boss:
		arena_start = cols - ARENA_COLS
	var theme: String = THEMES[(level - 1) % THEMES.size()]

	# --- holes in the ground ---
	var gaps: Array = []
	var max_gaps: int = int(float(arena_start - 30) / 14.0)
	var gap_count: int = clampi(1 + level, 1, maxi(1, max_gaps))
	var cursor: int = 16
	for i in range(gap_count):
		if cursor > arena_start - 14:
			break
		gaps.append(cursor)
		cursor += GAP_WIDTH + rng.randi_range(8, 16)

	var solid: Dictionary = {}
	for col in range(cols):
		var in_gap := false
		for g in gaps:
			if col >= int(g) and col < int(g) + GAP_WIDTH:
				in_gap = true
				break
		if not in_gap:
			solid[Vector2i(col, GROUND_ROW)] = "ground"

	# --- platforms and coins ---
	var platforms: Array = []
	var coins: Array = []
	var pcol: int = 12
	for step in range(200):
		if pcol >= arena_start - 12:
			break
		var plen: int = rng.randi_range(2, 4)
		var prow: int = 9
		if rng.randf() > 0.55:
			prow = 8
		for i in range(plen):
			solid[Vector2i(pcol + i, prow)] = "platform"
		platforms.append({"col": pcol, "len": plen, "row": prow})
		coins.append(Vector2i(pcol + int(plen / 2), prow - 1))
		if prow == 9 and rng.randf() < 0.4:
			var ucol: int = pcol + plen + 1
			if ucol + 2 < arena_start - 6:
				for i in range(2):
					solid[Vector2i(ucol + i, 7)] = "platform"
				platforms.append({"col": ucol, "len": 2, "row": 7})
				coins.append(Vector2i(ucol, 6))
		pcol += plen + rng.randi_range(5, 10)

	for g in gaps:
		coins.append(Vector2i(int(g) + 1, 9))

	# --- ground segments between holes ---
	var segments: Array = []
	var seg_start: int = 0
	for g in gaps:
		segments.append({"start": seg_start, "end": int(g) - 1})
		seg_start = int(g) + GAP_WIDTH
	segments.append({"start": seg_start, "end": arena_start - 1})

	# --- ground enemies ---
	var kinds: Array = ["slime"]
	if level >= 3:
		kinds.append("snail")
	if level >= 6:
		kinds.append("spike")

	var enemies: Array = []
	for seg in segments:
		var s: int = int(seg["start"])
		var e: int = int(seg["end"])
		if e - s < 8:
			continue
		var ecol: int = maxi(s + 3, 14)
		for step in range(60):
			if ecol > e - 3:
				break
			enemies.append({
				"kind": String(kinds[rng.randi_range(0, kinds.size() - 1)]),
				"col": ecol,
				"row": 9,
				"min_col": maxi(s + 1, ecol - 4),
				"max_col": mini(e - 1, ecol + 4),
			})
			ecol += rng.randi_range(9, 16)

	for p in platforms:
		if int(p["len"]) >= 3 and rng.randf() < 0.4:
			enemies.append({
				"kind": "slime",
				"col": int(p["col"]),
				"row": int(p["row"]) - 1,
				"min_col": int(p["col"]),
				"max_col": int(p["col"]) + int(p["len"]) - 1,
			})

	# --- flying enemies (bees), from level 3, more every two levels ---
	var flyers: int = flyer_count(level)
	for i in range(flyers):
		var span: int = maxi(20, int(float(arena_start - 30) / float(maxi(1, flyers))))
		var fcol: int = 24 + i * span + rng.randi_range(0, 6)
		if fcol > arena_start - 8:
			break
		var frow: int = 6 if (i % 2) == 0 else 5
		enemies.append({
			"kind": "fly",
			"col": fcol,
			"row": frow,
			"min_col": maxi(2, fcol - 6),
			"max_col": mini(arena_start - 2, fcol + 6),
		})

	# --- hazards and springs ---
	var spikes: Array = []
	var springs: Array = []
	if level >= 3:
		for i in range(level):
			var scol: int = rng.randi_range(22, maxi(23, arena_start - 6))
			if solid.has(Vector2i(scol, GROUND_ROW)) and not solid.has(Vector2i(scol, 9)):
				spikes.append(Vector2i(scol, 9))
	if level >= 2:
		for i in range(1 + int(level / 3)):
			var bcol: int = rng.randi_range(26, maxi(27, arena_start - 8))
			if solid.has(Vector2i(bcol, GROUND_ROW)) and not solid.has(Vector2i(bcol, 9)):
				springs.append(Vector2i(bcol, 9))

	# --- booster pickups on platforms ---
	var pickup_kinds: Array = ["grow", "star", "jump", "gun"]
	var pickups: Array = []
	var wanted: int = clampi(1 + int(level / 3), 1, 4)
	var tries: int = 0
	for step in range(60):
		if pickups.size() >= wanted or platforms.is_empty():
			break
		tries += 1
		var p: Dictionary = platforms[rng.randi_range(0, platforms.size() - 1)]
		var cell := Vector2i(int(p["col"]) + int(p["len"]) - 1, int(p["row"]) - 1)
		var busy := false
		for existing in pickups:
			if Vector2i(existing["cell"]) == cell:
				busy = true
		if busy:
			continue
		pickups.append({
			"cell": cell,
			"kind": String(pickup_kinds[rng.randi_range(0, pickup_kinds.size() - 1)]),
		})

	return {
		"level": level,
		"cols": cols,
		"rows": ROWS,
		"ground_row": GROUND_ROW,
		"theme": theme,
		"background": background_for(theme),
		"solid": solid,
		"coins": coins,
		"enemies": enemies,
		"spikes": spikes,
		"springs": springs,
		"pickups": pickups,
		"start": Vector2i(3, 9),
		"finish": Vector2i(cols - 3, 9),
		"boss": is_boss,
		"boss_cell": Vector2i(cols - 9, 9),
	}
