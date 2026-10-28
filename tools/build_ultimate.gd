extends SceneTree
## Builds Ultimate Sudoku puzzles into res://puzzles/ultimate.json (kept puzzles stay).
##
## Test run (types 1-5, one per level beginner .. expert):
##     godot --headless -s tools/build_ultimate.gd -- test
## Solved examples for every type that has none yet:
##     godot --headless -s tools/build_ultimate.gd -- examples
## One type at one level:
##     godot --headless -s tools/build_ultimate.gd -- one <type> <level>
## Each puzzle is checked for a unique solution with no search limit. Every type built also gets a solved
## example of its own (an easy puzzle with other seeds) in res://puzzles/ultimate_examples.json.
##
## Full packs, split over CI jobs (sudoku-puzzle-builder repo, workflow build_ultimate.yml):
##     godot --headless -s tools/build_ultimate.gd -- part <level> <first type> <last type> <per type> [rounds] [first round]
##         → res://puzzles/_parts/ultimate_<level>_t<first>-<last>.json (saved after every puzzle; a rerun
##           keeps what is there, so a job stopped by the time limit can be continued)
##     godot --headless -s tools/build_ultimate.gd -- merge
##         → every ultimate_*.json part into res://puzzles/ultimate.json (the old pack is replaced)

const PATH := "res://puzzles/ultimate.json"
const EXAMPLES := "res://puzzles/ultimate_examples.json"
const TEST := [[1, "beginner"], [2, "easy"], [3, "medium"], [4, "hard"], [5, "expert"]]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1 and args[0] == "examples":
		_all_examples()
		quit()
		return
	if args.size() >= 5 and args[0] == "part":
		_part(args[1], int(args[2]), int(args[3]), int(args[4]), int(args[5]) if args.size() >= 6 else 2, int(args[6]) if args.size() >= 7 else 0)
		quit()
		return
	if args.size() >= 1 and args[0] == "merge":
		_merge()
		quit()
		return
	var jobs: Array = TEST
	if args.size() >= 3 and args[0] == "one":
		jobs = [[int(args[1]), args[2]]]
	var list := _existing()
	var examples := _read(EXAMPLES)
	for job in jobs:
		if not examples.has(str(job[0])):
			var ex := _build(int(job[0]), "easy", 900000)
			if ex:
				ex.id = "example-ultimate-%03d" % int(job[0])
				examples[str(job[0])] = ex.to_dict()
		var p := _build(int(job[0]), str(job[1]))
		if p == null:
			print("type %d %s: FAILED" % job)
			continue
		list = list.filter(func(d): return d.get("id", "") != p.id)
		list.append(p.to_dict())
	list.sort_custom(func(a, b): return Generator.LEVELS.find(a.difficulty) * 1000 + int(a.type) < Generator.LEVELS.find(b.difficulty) * 1000 + int(b.type))
	var lines: Array = []
	for d in list:
		lines.append("  " + JSON.stringify(d))
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("{\"puzzles\": [\n" + ",\n".join(lines) + "\n]}\n")
	f.close()
	print("wrote %d puzzles to %s" % [list.size(), PATH])
	_write_examples(examples)
	quit()


## Solved examples for every type that has none yet, saved after each one (safe to stop and rerun).
func _all_examples() -> void:
	var examples := _read(EXAMPLES)
	for t in range(1, Ultimate.TYPES.size() + 1):
		if examples.has(str(t)):
			continue
		var ex := _build(t, "easy", 900000)
		if ex == null:
			print("type %d example: FAILED" % t)
			continue
		ex.id = "example-ultimate-%03d" % t
		examples[str(t)] = ex.to_dict()
		_write_examples(examples)


const PARTS := "res://puzzles/_parts/"


## `per` puzzles of every type from `first` to `last` at one level. Puzzle n of a type uses its own seeds
## (seed base 7000 + n * 20000) and gets the id pack-ultimate-<level>-<type>-<n>. A puzzle whose 30 seeds all fail
## gets more tries with fresh seeds (+ r * 1,000,000 for r = first_round .. first_round + rounds - 1); top-up runs start
## at a later round so they never repeat seeds an earlier run already tried.
func _part(level: String, first: int, last: int, per: int, rounds := 2, first_round := 0) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PARTS))
	var path := PARTS + "ultimate_%s_t%03d-%03d.json" % [level, first, last]
	var list: Array = _read(path).get("puzzles", [])
	var have := {}
	for d in list:
		have[str(d.id)] = true
	var t0 := Time.get_ticks_msec()
	for n in per:   # one round over all types, then the next: a job cut short still covers every type
		for t in range(first, last + 1):
			var id := "pack-ultimate-%s-%03d-%d" % [level, t, n]
			if have.has(id):
				continue
			var p: Puzzle = null
			for r in range(first_round, first_round + rounds):
				p = _build(t, level, 7000 + n * 20000 + r * 1000000)
				if p:
					break
			if p == null:
				print("type %d %s #%d: FAILED" % [t, level, n])
				continue
			p.id = id
			list.append(p.to_dict())
			FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify({"puzzles": list}))
			print("PART %s: %d puzzles (%ds)" % [path.get_file(), list.size(), (Time.get_ticks_msec() - t0) / 1000])
	FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify({"puzzles": list}))
	print("DONE %s: %d puzzles" % [path.get_file(), list.size()])


func _merge() -> void:
	var list: Array = []
	var seen := {}
	for fn in DirAccess.get_files_at(PARTS):
		if fn.begins_with("ultimate_") and fn.ends_with(".json"):
			for d in _read(PARTS + fn).get("puzzles", []):
				if not seen.has(str(d.id)):
					seen[str(d.id)] = true
					list.append(Puzzle.from_dict(d).to_dict())   # back to whole numbers (JSON reads them as floats)
	if list.is_empty():
		push_error("no ultimate parts in " + PARTS)
		return
	list.sort_custom(func(a, b): return str(a.id) < str(b.id) if a.difficulty == b.difficulty 		else Generator.LEVELS.find(a.difficulty) < Generator.LEVELS.find(b.difficulty))
	var lines: Array = []
	for d in list:
		lines.append("  " + JSON.stringify(d))
	FileAccess.open(PATH, FileAccess.WRITE).store_string("{\"puzzles\": [\n" + ",\n".join(lines) + "\n]}\n")
	var counts := {}
	for d in list:
		counts[d.difficulty] = counts.get(d.difficulty, 0) + 1
	print("wrote %d puzzles to %s %s" % [list.size(), PATH, counts])


func _write_examples(examples: Dictionary) -> void:
	var keys: Array = examples.keys()
	keys.sort_custom(func(a, b): return int(a) < int(b))
	var ex_lines: Array = []
	for k in keys:
		ex_lines.append("  \"%s\": %s" % [k, JSON.stringify(examples[k])])
	var f := FileAccess.open(EXAMPLES, FileAccess.WRITE)
	f.store_string("{\n" + ",\n".join(ex_lines) + "\n}\n")
	f.close()
	print("wrote %d examples to %s" % [keys.size(), EXAMPLES])


func _existing() -> Array:
	return _read(PATH).get("puzzles", [])


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}


func _build(type: int, level: String, seed_base := 7000) -> Puzzle:
	Generator.ult_type = type
	var t0 := Time.get_ticks_msec()
	for k in 30:
		var p := Generator.make("ultimate", level, seed_base + type * 100 + k)
		if p == null:
			continue
		var s := Solver.new(p)
		if s.count_solutions(p.givens, 2, 0) != 1:
			print("  type %d %s seed %d: not unique, retry" % [type, level, k])
			continue
		p.id = "pack-ultimate-%s-%03d" % [level, type]
		print("type %d %s: %d givens, %.1f s, tries %d | %s" % [type, level, p.given_count(), (Time.get_ticks_msec() - t0) / 1000.0, k + 1, ", ".join(p.rules)])
		print("    cages %d thermos %d arrows %d lines %d edges %d outer %d sums %d parity %d marks %d quads %d clones %d areas %d" % [
			p.cages.size(), p.thermos.size(), p.arrows.size(), p.lines.size(), p.edges.size(), p.outer.size(), p.sums.size(),
			p.parity.size(), p.marks.size(), p.quads.size(), p.clones.size(), p.areas.size()])
		Generator.ult_type = 0
		return p
	Generator.ult_type = 0
	return null
