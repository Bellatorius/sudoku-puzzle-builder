extends SceneTree
## Builds packs for the GridShapes variants (other grid sizes, multi-grid, non-square) into
## res://puzzles/shapes/<variant>.json. See scripts/core/grid_shapes.gd for the shapes and the puzzle format.
##
##     godot --headless -s tools/build_shapes.gd -- test
##         every shape's cells / units / digits, and that each solver finds a full solution
##     godot --headless -s tools/build_shapes.gd -- bench <variant> [levels...]
##         builds one puzzle per level (default all) and prints the time and given count
##     godot --headless -s tools/build_shapes.gd -- smoke [variants...]
##         one medium puzzle per variant (default all), fully checked; prints "SMOKE_OK <v>" or
##         "SMOKE_FAIL <v> <why>" per variant; exit code 1 when none passed
##     godot --headless -s tools/build_shapes.gd -- part <variant> <level> <shard> <count> [round]
##         → res://puzzles/_parts/shape_<variant>_<level>_s<shard>.json, saved after every puzzle; a rerun keeps
##           what is there (so a job stopped by the time limit can be continued; `round` changes the seeds for
##           top-ups). Every puzzle is fully checked (ShapeGen.verify) before it is kept. Gives up (exit 1) after
##           GIVE_UP failures in a row. Prints "DONE <variant> <level> <shard> <built>/<count>".
##     godot --headless -s tools/build_shapes.gd -- merge
##         → every shape_*.json part into res://puzzles/shapes/<variant>.json (packs are replaced; duplicates dropped)
##     godot --headless -s tools/build_shapes.gd -- check [variants...]
##         re-checks every puzzle of the merged packs; exit code 1 if any is wrong

const PARTS := "res://puzzles/_parts/"
const OUT := "res://puzzles/shapes/"
const GIVE_UP := 8          # failed tries in a row
const GIVE_UP_DUPS := 300    # duplicates in a row (small shapes run out of new puzzles)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var cmd: String = args[0] if args.size() > 0 else "test"
	var rest: Array = Array(args.slice(1))
	var code := 0
	match cmd:
		"test": code = _test()
		"bench": _bench(rest[0], rest.slice(1) if rest.size() > 1 else ShapeGen.LEVELS)
		"smoke": code = _smoke(rest if not rest.is_empty() else GridShapes.VARIANTS)
		"part": code = _part(rest[0], rest[1], int(rest[2]), int(rest[3]), int(rest[4]) if rest.size() > 4 else 0)
		"merge": _merge()
		"check": code = _check(rest if not rest.is_empty() else GridShapes.VARIANTS)
		_: print("unknown command " + cmd)
	quit(code)


func _test() -> int:
	var bad := 0
	for v in GridShapes.VARIANTS:
		var sh := GridShapes.shape(v)
		var cover := {}
		var fulls := 0
		for u in sh.units:
			if u.size() == sh.n:
				fulls += 1
			if u.size() > sh.n:
				print("  %s: a unit of %d cells for %d digits" % [v, u.size(), sh.n])
				bad += 1
			for c in u:
				cover[c] = true
		var nosym := 0
		for s in sh.sym:
			if s < 0:
				nosym += 1
		var rng := RandomNumberGenerator.new()
		rng.seed = 1
		var t := Time.get_ticks_msec()
		var sol := ShapeSolver.new(sh).fill(rng)
		print("%-15s n=%-2d cells=%-4d units=%-4d full=%-4d uncovered=%d nosym=%d  solution: %s (%d ms)" % [v, sh.n, sh.cells,
			sh.units.size(), fulls, sh.cells - cover.size(), nosym, "yes" if not sol.is_empty() else "NO", Time.get_ticks_msec() - t])
		if sol.is_empty():
			bad += 1
	if true:
		var sh := GridShapes.shape("triangular")
		var sizes: Array = []
		for i in 9:
			sizes.append(sh.units[i].size())
		print("triangular regions: ", sizes)
	print("TEST %s" % ("OK" if bad == 0 else "FAILED %d" % bad))
	return 0 if bad == 0 else 1


func _bench(v: String, levels: Array) -> void:
	for lv in levels:
		var t := Time.get_ticks_msec()
		var p := ShapeGen.make(v, lv, hash(v + lv))
		var ms := Time.get_ticks_msec() - t
		if p.is_empty():
			print("%s %s: FAILED (%d ms)" % [v, lv, ms])
			continue
		var t2 := Time.get_ticks_msec()
		var why := ShapeGen.verify(p)
		var given := 0
		for ch in p.givens:
			if ch != "0":
				given += 1
		print("%s %s: %d / %d given, build %d ms, check %d ms %s" % [v, lv, given, p.givens.length(), ms,
			Time.get_ticks_msec() - t2, "OK" if why == "" else "BAD: " + why])


func _smoke(vs: Array) -> int:
	var ok := 0
	for v in vs:
		if not GridShapes.is_shape(v):
			print("SMOKE_FAIL %s unknown variant" % v)
			continue
		var p := ShapeGen.make(v, "medium", hash("smoke" + v))
		var why := "no solution found" if p.is_empty() else ShapeGen.verify(p)
		if why == "":
			ok += 1
			print("SMOKE_OK %s" % v)
		else:
			print("SMOKE_FAIL %s %s" % [v, why.replace(" ", "_")])
	return 0 if ok > 0 else 1


func _part_path(v: String, lv: String, shard: int) -> String:
	return PARTS + "shape_%s_%s_s%d.json" % [v, lv, shard]


func _read_list(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d.get("puzzles", []) if d is Dictionary else []


func _write_list(path: String, list: Array, head := "") -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var lines: Array = []
	for p in list:
		lines.append(JSON.stringify(p))
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{" + head + "\"puzzles\": [\n" + ",\n".join(lines) + "\n]}\n")
	f.close()


func _part(v: String, lv: String, shard: int, count: int, round: int) -> int:
	if not GridShapes.is_shape(v) or not lv in ShapeGen.LEVELS:
		print("bad variant / level")
		return 1
	var path := _part_path(v, lv, shard)
	var list := _read_list(path)
	var seen := {}
	for p in list:
		seen[p.givens] = true
	var fails := 0
	var dups := 0
	var k := 0
	while list.size() < count:
		var seed := hash("%s|%s|%d|%d|%d" % [v, lv, shard, round, k])
		k += 1
		var id := "pack-%s-%s-s%d-%03d" % [v, lv, shard, list.size() + 1]
		var t := Time.get_ticks_msec()
		var p := ShapeGen.make(v, lv, seed, id)
		var why := "no solution found" if p.is_empty() else ShapeGen.verify(p)
		if why == "" and seen.has(p.givens):
			why = "duplicate"
		if why == "duplicate":
			dups += 1
			if dups >= GIVE_UP_DUPS:
				print("GAVE_UP %s %s %d %d/%d (only duplicates left)" % [v, lv, shard, list.size(), count])
				return 1
			continue
		if why != "":
			fails += 1
			print("%s %s s%d: try %d failed (%s)" % [v, lv, shard, k, why])
			if fails >= GIVE_UP:
				print("GAVE_UP %s %s %d %d/%d" % [v, lv, shard, list.size(), count])
				return 1
			continue
		fails = 0
		dups = 0
		seen[p.givens] = true
		list.append(p)
		_write_list(path, list)
		print("%s %s s%d: %d/%d (%d ms)" % [v, lv, shard, list.size(), count, Time.get_ticks_msec() - t])
	print("DONE %s %s %d %d/%d" % [v, lv, shard, list.size(), count])
	return 0


func _merge() -> void:
	var by: Dictionary = {}
	for fn in DirAccess.get_files_at(PARTS):
		if not fn.begins_with("shape_") or not fn.ends_with(".json"):
			continue
		for p in _read_list(PARTS + fn):
			if not by.has(p.variant):
				by[p.variant] = {}
			by[p.variant][p.givens] = p   # same givens twice: one kept
	for v in by:
		var list: Array = by[v].values()
		list.sort_custom(func(a, b):
			var la := ShapeGen.LEVELS.find(a.difficulty)
			var lb := ShapeGen.LEVELS.find(b.difficulty)
			return la < lb or (la == lb and a.id < b.id))
		var counts := {}
		for p in list:
			counts[p.difficulty] = counts.get(p.difficulty, 0) + 1
		_write_list(OUT + v + ".json", list, "\"variant\": \"%s\", \"version\": 1, " % v)
		print("puzzles/shapes/%s.json: %d puzzles %s" % [v, list.size(), counts])


func _check(vs: Array) -> int:
	var bad := 0
	for v in vs:
		var list := _read_list(OUT + v + ".json")
		var seen := {}
		var wrong := 0
		for p in list:
			var why := ShapeGen.verify(p)
			if why == "" and seen.has(p.givens):
				why = "duplicate"
			seen[p.givens] = true
			if why != "":
				wrong += 1
				print("  %s %s: %s" % [v, p.id, why])
		print("CHECK %s: %d puzzles, %d wrong" % [v, list.size(), wrong])
		bad += wrong
	return 0 if bad == 0 else 1
