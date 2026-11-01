extends SceneTree
## Builds Ultimate Sudoku puzzles into res://puzzles/ultimate.json (kept puzzles stay).
## Ultimate 6 / 3 / 2: put the variant id first, e.g. `-- ultimate_6 part hard 1 5 5` → res://puzzles/ultimate_6.json,
## ultimate_6_examples.json, parts ultimate_6_<level>_t<first>-<last>.json, ids pack-ultimate_6-<level>-<type>-<n>.
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
##     godot --headless -s tools/build_ultimate.gd -- smoke
##         → quick check before a CI build: SMOKE types at hard and master must each build a unique puzzle, else
##           exit code 1 (the workflow then starts no build jobs). A part job also gives up (exit code 1) once
##           every type of its range has failed in a row, instead of burning its whole time limit.
##     godot --headless -s tools/build_ultimate.gd -- merge
##         → every ultimate_*.json part into res://puzzles/ultimate.json (the old pack is replaced)

var variant := "ultimate"   # any of Ultimate.VARIANTS (first argument; default the 9-rule Ultimate)
var PATH := "res://puzzles/ultimate.json"
var EXAMPLES := "res://puzzles/ultimate_examples.json"
const TEST := [[1, "beginner"], [2, "easy"], [3, "medium"], [4, "hard"], [5, "expert"]]
const SMOKE := [1, 34, 67, 100]   # types the smoke check builds (first, last and two between)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1 and Ultimate.is_ultimate(args[0]):
		variant = args[0]
		args = args.slice(1)
	PATH = "res://puzzles/%s.json" % variant
	EXAMPLES = "res://puzzles/%s_examples.json" % variant
	if args.size() >= 1 and args[0] == "examples":
		_all_examples()
		quit()
		return
	if args.size() >= 1 and args[0] == "smoke":
		quit(0 if _smoke() else 1)
		return
	if args.size() >= 5 and args[0] == "part":
		var ok := _part(args[1], int(args[2]), int(args[3]), int(args[4]), int(args[5]) if args.size() >= 6 else 2, int(args[6]) if args.size() >= 7 else 0)
		quit(0 if ok else 1)
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
				ex.id = "example-%s-%03d" % [variant, int(job[0])]
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
	for t in range(1, Ultimate.types(variant).size() + 1):
		if examples.has(str(t)):
			continue
		var ex := _build(t, "easy", 900000)
		if ex == null:
			print("type %d example: FAILED" % t)
			continue
		ex.id = "example-%s-%03d" % [variant, t]
		examples[str(t)] = ex.to_dict()
		_write_examples(examples)


const PARTS := "res://puzzles/_parts/"


## `per` puzzles of every type from `first` to `last` at one level. Puzzle n of a type uses its own seeds
## (seed base 7000 + n * 20000) and gets the id pack-<variant>-<level>-<type>-<n>. A puzzle whose 30 seeds all fail
## gets more tries with fresh seeds (+ r * 1,000,000 for r = first_round .. first_round + rounds - 1); top-up runs start
## at a later round so they never repeat seeds an earlier run already tried.
func _part(level: String, first: int, last: int, per: int, rounds := 2, first_round := 0) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PARTS))
	var path := PARTS + "%s_%s_t%03d-%03d.json" % [variant, level, first, last]
	var list: Array = _read(path).get("puzzles", [])
	var have := {}
	for d in list:
		have[str(d.id)] = true
	var t0 := Time.get_ticks_msec()
	var fails := 0   # failures in a row
	for n in per:   # one round over all types, then the next: a job cut short still covers every type
		for t in range(first, last + 1):
			var id := "pack-%s-%s-%03d-%d" % [variant, level, t, n]
			if have.has(id):
				continue
			var p: Puzzle = null
			for r in range(first_round, first_round + rounds):
				p = _build(t, level, 7000 + n * 20000 + r * 1000000)
				if p:
					break
			if p == null:
				print("type %d %s #%d: FAILED" % [t, level, n])
				fails += 1
				if fails >= last - first + 1:   # every type of the range failed in a row: something is broken
					FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify({"puzzles": list}))
					print("GIVING UP %s: %d failures in a row, %d puzzles kept" % [path.get_file(), fails, list.size()])
					return false
				continue
			fails = 0
			p.id = id
			list.append(p.to_dict())
			FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify({"puzzles": list}))
			print("PART %s: %d puzzles (%ds)" % [path.get_file(), list.size(), (Time.get_ticks_msec() - t0) / 1000])
	FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify({"puzzles": list}))
	print("DONE %s: %d puzzles" % [path.get_file(), list.size()])
	return true


## The SMOKE types at hard and master (the slowest levels); false if any fails or isn't unique (_build checks).
func _smoke() -> bool:
	var ok := true
	var t0 := Time.get_ticks_msec()
	for level in ["hard", "master"]:
		for t in SMOKE:
			if _build(t, level) == null:
				print("SMOKE %s type %d %s: FAILED" % [variant, t, level])
				ok = false
	print("SMOKE %s: %s (%ds)" % [variant, "OK" if ok else "FAILED", (Time.get_ticks_msec() - t0) / 1000])
	return ok


func _merge() -> void:
	var list: Array = []
	var seen := {}
	var mine := RegEx.create_from_string("^%s_(%s)_t.*[.]json$" % [variant, "|".join(Generator.LEVELS)])   # not ultimate_6_… for ultimate
	for fn in DirAccess.get_files_at(PARTS):
		if mine.search(fn):
			for d in _read(PARTS + fn).get("puzzles", []):
				if not seen.has(str(d.id)):
					seen[str(d.id)] = true
					list.append(Puzzle.from_dict(d).to_dict())   # back to whole numbers (JSON reads them as floats)
	if list.is_empty():
		push_error("no %s parts in %s" % [variant, PARTS])
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
		var p := Generator.make(variant, level, seed_base + type * 100 + k)
		if p == null:
			continue
		var s := Solver.new(p)
		if s.count_solutions(p.givens, 2, 0) != 1:
			print("  type %d %s seed %d: not unique, retry" % [type, level, k])
			continue
		p.id = "pack-%s-%s-%03d" % [variant, level, type]
		print("type %d %s: %d givens, %.1f s, tries %d | %s" % [type, level, p.given_count(), (Time.get_ticks_msec() - t0) / 1000.0, k + 1, ", ".join(p.rules)])
		print("    cages %d thermos %d arrows %d lines %d edges %d outer %d sums %d parity %d marks %d quads %d clones %d areas %d" % [
			p.cages.size(), p.thermos.size(), p.arrows.size(), p.lines.size(), p.edges.size(), p.outer.size(), p.sums.size(),
			p.parity.size(), p.marks.size(), p.quads.size(), p.clones.size(), p.areas.size()])
		Generator.ult_type = 0
		return p
	Generator.ult_type = 0
	return null
