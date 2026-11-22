class_name ShapeGen
extends RefCounted
## Builds GridShapes puzzles: a random full solution, then givens removed (in mirrored pairs) while the
## solution stays unique, until no given can go (minimal). Expert = that minimal puzzle, master = the fewest
## givens of MASTER_TRIES minimal tries; the easier levels put solution digits back (in mirrored pairs):
## ADD_BACK = the share of the cells the minimal puzzle left empty that are filled again. So givens always go
## down from beginner to master, on any shape.

const LEVELS := ["beginner", "easy", "medium", "hard", "expert", "master"]
const ADD_BACK := {"beginner": 0.45, "easy": 0.32, "medium": 0.21, "hard": 0.10, "expert": 0.0, "master": 0.0}
const MASTER_TRIES := 3
const CHECK_NODES := 4000     # search nodes per uniqueness check; a check that gives up keeps the given
const VERIFY_NODES := 400000  # the final full check; a puzzle it can't settle is thrown away


## {id, variant, difficulty, givens, solution[, regions]} or {} when no solution was found.
static func make(variant: String, level: String, seed: int, id := "") -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var regions: Array = []
	var sol := PackedInt32Array()
	var sh: Dictionary
	var solver: ShapeSolver
	for attempt in 6:
		if variant == "jigsaw_samurai":
			regions = GridShapes.random_regions(variant, rng)
		sh = GridShapes.shape(variant, regions)
		solver = ShapeSolver.new(sh)
		sol = solver.fill(rng)
		if not sol.is_empty():
			break
	if sol.is_empty():
		return {}
	var best := PackedInt32Array()
	var tries := MASTER_TRIES if level == "master" else 1
	for t in tries:
		var g := _remove(solver, sh, sol, rng)
		if best.is_empty() or _given_count(g) < _given_count(best):
			best = g
	_add_back(best, sh, sol, float(ADD_BACK[level]), rng)
	var out := {"id": id, "variant": variant, "difficulty": level,
		"givens": GridShapes.to_text(best), "solution": GridShapes.to_text(sol)}
	if not regions.is_empty():
		out.regions = regions
	return out


static func _given_count(g: PackedInt32Array) -> int:
	var k := 0
	for v in g:
		if v:
			k += 1
	return k


static func _shuffled(nc: int, rng: RandomNumberGenerator) -> Array:
	var order: Array = range(nc)
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var t = order[i]
		order[i] = order[j]
		order[j] = t
	return order


## Puts solution digits back into `share` of the empty cells (mirrored pairs together).
static func _add_back(g: PackedInt32Array, sh: Dictionary, sol: PackedInt32Array, share: float, rng: RandomNumberGenerator) -> void:
	var empty := 0
	for v in g:
		if v == 0:
			empty += 1
	var goal := int(round(empty * share))
	var sym: PackedInt32Array = sh.sym
	for c in _shuffled(sh.cells, rng):
		if goal <= 0:
			break
		if g[c] != 0:
			continue
		g[c] = sol[c]
		goal -= 1
		var m: int = sym[c]
		if m >= 0 and g[m] == 0:
			g[m] = sol[m]
			goal -= 1


## Removes givens in random order (mirrored pairs together) while the solution stays unique: a minimal puzzle.
static func _remove(solver: ShapeSolver, sh: Dictionary, sol: PackedInt32Array, rng: RandomNumberGenerator) -> PackedInt32Array:
	var g := sol.duplicate()
	var nc: int = sh.cells
	var sym: PackedInt32Array = sh.sym
	for c in _shuffled(nc, rng):
		if g[c] == 0:
			continue
		var group: Array = [c]
		var m: int = sym[c]
		if m >= 0 and m != c and g[m] != 0:
			group.append(m)
		for x in group:
			g[x] = 0
		if solver.other_exists(g, sol, group, CHECK_NODES) != 0:
			for x in group:
				g[x] = sol[x]
	return g


## Full check of a built puzzle: givens fit the solution, the solution obeys every unit, exactly one solution.
static func verify(p: Dictionary) -> String:
	var sh := GridShapes.shape(p.variant, p.get("regions", []))
	if sh.is_empty():
		return "unknown variant"
	var g := GridShapes.from_text(p.givens)
	var s := GridShapes.from_text(p.solution)
	if g.size() != sh.cells or s.size() != sh.cells:
		return "wrong length"
	for c in sh.cells:
		if s[c] < 1 or s[c] > sh.n:
			return "bad solution digit"
		if g[c] != 0 and g[c] != s[c]:
			return "given differs from the solution"
	for u in sh.units:
		var seen := 0
		for c in u:
			var b: int = 1 << (s[c] - 1)
			if seen & b:
				return "solution breaks a unit"
			seen |= b
	var k := ShapeSolver.new(sh).count(g, 2, VERIFY_NODES)
	if k != 1:
		return "check gave up" if k < 0 else "%d solutions" % k
	return ""
