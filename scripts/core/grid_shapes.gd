class_name GridShapes
extends RefCounted
## Grids that aren't one 9x9 / 6x6 square: other sizes, several overlapping 9x9 grids and non-square shapes.
## Not playable yet: only the generator (ShapeGen) and solver (ShapeSolver) exist, used by tools/build_shapes.gd
## to build packs into res://puzzles/shapes/<variant>.json. The board and screens come later.
##
## Every shape is the same thing underneath: `cells` cells holding digits 1..n, and `units`, lists of cells
## whose digits must all differ (a unit of exactly n cells holds every digit once). So one solver handles them all.
##
## shape(variant, regions) → {
##   id, n (digits 1..n), cells (count),
##   units: Array[PackedInt32Array],
##   pos:   PackedVector2Array, each cell's centre (drawing units: a square cell is 1 x 1),
##   polys: Array, per cell an Array of PackedVector2Array outlines (a cube edge cell shows on two faces),
##   grids: Array[PackedInt32Array], for multi-grid shapes each 9x9 grid's 81 cells in reading order,
##   sym:   PackedInt32Array, the cell mirrored / turned 180° onto each cell (-1 = none), used to remove
##          givens in matching pairs,
##   locked: PackedInt32Array, jigsaw_samurai: 1 = cell of a box shared by two grids (stays a 3x3 region) }
## Cell order is fixed by the variant (and is what the pack strings follow).
##
## Pack puzzle format: {"id", "variant", "difficulty", "givens", "solution"} with one character per cell:
## "0" = empty, "1"-"9", then "A" = 10 ... "G" = 16; jigsaw_samurai adds "regions": one 81-character string per
## grid (region id 0-8 per cell, reading order).
##
## Design choices (Claude's, not checked with the user yet):
##   tiny 4x4 (2x2 boxes), giant_12 (3x4 boxes, digits 1-12), giant_16 (4x4 boxes, 1-16).
##   Multi-grid: classic 9x9 grids placed on a canvas (offsets in cells, always multiples of 3 so boxes line up);
##   cells where grids overlap belong to both. twin = 2 grids sharing a corner box, dual = 2 sharing 2 boxes,
##   triple = 3 in a diagonal chain, gattai = Gattai-3 (a V of 3), quad = a ring of 4 (each shares a corner box
##   with two others), windmill = 4 grids round a centre grid each sharing 2 boxes with it, flower = 4 grids
##   each shifted 3 cells from a centre grid (sharing 6 boxes), samurai = Gattai-5, samurai_x = samurai with
##   both diagonals in every grid, jigsaw_samurai = samurai with jigsaw regions (shared boxes stay square),
##   six_grid = a zigzag of 6 grids, decathlon = a pyramid of 10 grids (4 / 3 / 2 / 1).
##   circular: 6 rings x 9 sectors, digits 1-9; each ring and each block of 3 sectors x 3 rings holds 1-9,
##   no digit repeats along a spoke.
##   hexagonal: 7 "flowers" of 7 hex cells (49 cells), digits 1-7; each flower holds 1-7, no digit repeats along
##   a straight run of cells (a run of 7 holds 1-7).
##   triangular: a triangle of 81 small triangles, digits 1-9; each of its 9 triangles of 9 holds 1-9; no digit
##   repeats along a straight line of upward triangles (the three edges, 9 long, hold 1-9) or of downward ones.
##   cube: the three faces of a 9x9x9 cube seen from a corner (217 cells; edge cells belong to two faces, the
##   corner to three); each face's rows, columns and 3x3 boxes hold 1-9.

const VARIANTS := ["tiny", "giant_12", "giant_16", "twin", "dual", "triple", "gattai", "quad", "windmill", "flower",
	"samurai", "samurai_x", "jigsaw_samurai", "six_grid", "decathlon", "circular", "hexagonal", "triangular", "cube"]

const NAMES := {
	"tiny": "Tiny 4x4", "giant_12": "Giant 12x12", "giant_16": "Giant 16x16", "twin": "Twin", "dual": "Dual",
	"triple": "Triple", "gattai": "Gattai-3", "quad": "Quad", "windmill": "Windmill", "flower": "Flower",
	"samurai": "Samurai", "samurai_x": "Samurai X", "jigsaw_samurai": "Jigsaw Samurai", "six_grid": "Six-Grid",
	"decathlon": "Decathlon", "circular": "Circular", "hexagonal": "Hexagonal", "triangular": "Triangular",
	"cube": "3D Cube",
}

## top-left corner of each 9x9 grid, in cells
const GRIDS := {
	"twin": [[0, 0], [6, 6]],
	"dual": [[0, 0], [6, 3]],
	"triple": [[0, 0], [6, 6], [12, 12]],
	"gattai": [[0, 0], [6, 6], [12, 0]],
	"quad": [[0, 6], [6, 0], [12, 6], [6, 12]],
	"windmill": [[3, 0], [12, 3], [9, 12], [0, 9], [6, 6]],
	"flower": [[3, 3], [3, 0], [6, 3], [3, 6], [0, 3]],
	"samurai": [[0, 0], [12, 0], [6, 6], [0, 12], [12, 12]],
	"samurai_x": [[0, 0], [12, 0], [6, 6], [0, 12], [12, 12]],
	"jigsaw_samurai": [[0, 0], [12, 0], [6, 6], [0, 12], [12, 12]],
	"six_grid": [[0, 0], [6, 6], [12, 0], [18, 6], [24, 0], [30, 6]],
	"decathlon": [[18, 0], [12, 6], [24, 6], [6, 12], [18, 12], [30, 12], [0, 18], [12, 18], [24, 18], [36, 18]],
}

const DIGITS := "0123456789ABCDEFG"


static func is_shape(variant: String) -> bool:
	return variant in VARIANTS


static func to_text(vals: PackedInt32Array) -> String:
	var s := ""
	for v in vals:
		s += DIGITS[v]
	return s


static func from_text(s: String) -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(s.length())
	for i in s.length():
		out[i] = DIGITS.find(s[i])
	return out


static func shape(variant: String, regions: Array = []) -> Dictionary:
	var sh: Dictionary
	match variant:
		"tiny": sh = _square([[0, 0]], 4, 2, 2)
		"giant_12": sh = _square([[0, 0]], 12, 3, 4)
		"giant_16": sh = _square([[0, 0]], 16, 4, 4)
		"circular": sh = _circular()
		"hexagonal": sh = _hexagonal()
		"triangular": sh = _triangular()
		"cube": sh = _cube()
		_:
			if not GRIDS.has(variant):
				push_error("unknown shape variant " + variant)
				return {}
			sh = _square(GRIDS[variant], 9, 3, 3, variant == "samurai_x", regions, variant == "jigsaw_samurai")
	sh.id = variant
	sh.cells = sh.pos.size()
	sh.units = _dedupe(sh.units)
	sh.sym = _symmetry(sh.pos)
	return sh


## One or more n x n grids (boxes br rows x bc columns) at the given offsets; overlapping cells are shared.
static func _square(offsets: Array, n: int, br: int, bc: int, diag := false, regions: Array = [], jigsaw := false) -> Dictionary:
	var keys := {}
	for o in offsets:
		for r in n:
			for c in n:
				keys[Vector2i(o[0] + c, o[1] + r)] = true
	var order: Array = keys.keys()
	order.sort_custom(func(a: Vector2i, b: Vector2i): return a.y < b.y or (a.y == b.y and a.x < b.x))
	var index := {}
	var pos := PackedVector2Array()
	var polys: Array = []
	for i in order.size():
		var k: Vector2i = order[i]
		index[k] = i
		pos.append(Vector2(k.x + 0.5, k.y + 0.5))
		polys.append([PackedVector2Array([Vector2(k.x, k.y), Vector2(k.x + 1, k.y), Vector2(k.x + 1, k.y + 1), Vector2(k.x, k.y + 1)])])
	var units: Array = []
	var grids: Array = []
	var cover := {}   # cell → number of grids it belongs to
	for o in offsets:
		var g := PackedInt32Array()
		for r in n:
			for c in n:
				var i: int = index[Vector2i(o[0] + c, o[1] + r)]
				g.append(i)
				cover[i] = cover.get(i, 0) + 1
		grids.append(g)
	var locked := PackedInt32Array()
	locked.resize(order.size())
	for i in order.size():
		locked[i] = 1 if cover[i] > 1 else 0
	for gi in grids.size():
		var g: PackedInt32Array = grids[gi]
		for r in n:
			var row := PackedInt32Array()
			var col := PackedInt32Array()
			for c in n:
				row.append(g[r * n + c])
				col.append(g[c * n + r])
			units.append(row)
			units.append(col)
		var reg: String = regions[gi] if gi < regions.size() else ""
		var boxes: Array = []
		for b in n:
			boxes.append(PackedInt32Array())
		for r in n:
			for c in n:
				var b: int = (r / br) * (n / bc) + c / bc
				if reg != "":
					b = int(reg[r * n + c])
				boxes[b].append(g[r * n + c])
		units.append_array(boxes)
		if diag:
			var d1 := PackedInt32Array()
			var d2 := PackedInt32Array()
			for k in n:
				d1.append(g[k * n + k])
				d2.append(g[k * n + n - 1 - k])
			units.append(d1)
			units.append(d2)
	var out := {"n": n, "units": units, "pos": pos, "polys": polys, "grids": grids}
	if jigsaw:
		out.locked = locked
	return out


## jigsaw_samurai: random jigsaw regions, one 81-char string per grid. Boxes shared by two grids stay square.
static func random_regions(variant: String, rng: RandomNumberGenerator) -> Array:
	var base := shape(variant)
	var locked: PackedInt32Array = base.locked
	var out: Array = []
	for g in base.grids:
		var lk := PackedInt32Array()
		for i in 81:
			lk.append(locked[g[i]])
		out.append(_jigsaw(lk, rng))
	return out


static func _jigsaw(locked: PackedInt32Array, rng: RandomNumberGenerator) -> String:
	var reg := PackedInt32Array()
	for i in 81:
		reg.append((i / 27) * 3 + (i % 9) / 3)
	var swaps := 0
	var tries := 0
	while swaps < 60 and tries < 20000:
		tries += 1
		var a := rng.randi() % 81
		if locked[a]:
			continue
		var nb: Array = []
		for d in [-9, 9, -1, 1]:
			var b: int = a + d
			if b < 0 or b >= 81 or (abs(d) == 1 and b / 9 != a / 9):
				continue
			if not locked[b] and reg[b] != reg[a]:
				nb.append(b)
		if nb.is_empty():
			continue
		# a moves into the neighbouring region rb, and a cell of rb that touches ra (somewhere else) moves into ra, so
		# both keep 9 cells. (A swap of two touching cells across a straight border always cut a region in two, so
		# the first version never changed anything: 2026-11-23.)
		var ra := reg[a]
		var rb := reg[nb[rng.randi() % nb.size()]]
		var give: Array = []
		for c in 81:
			if reg[c] != rb or locked[c] or c == a:
				continue
			for d2 in [-9, 9, -1, 1]:
				var e: int = c + d2
				if e >= 0 and e < 81 and not (abs(d2) == 1 and e / 9 != c / 9) and reg[e] == ra and e != a:
					give.append(c)
					break
		if give.is_empty():
			continue
		var b2: int = give[rng.randi() % give.size()]
		reg[a] = rb
		reg[b2] = ra
		if _connected(reg, ra) and _connected(reg, rb):
			swaps += 1
		else:
			reg[a] = ra
			reg[b2] = rb
	var s := ""
	for v in reg:
		s += str(v)
	return s


static func _connected(reg: PackedInt32Array, r: int) -> bool:
	var cells: Array = []
	for i in 81:
		if reg[i] == r:
			cells.append(i)
	var seen := {cells[0]: true}
	var stack: Array = [cells[0]]
	while not stack.is_empty():
		var a: int = stack.pop_back()
		for d in [-9, 9, -1, 1]:
			var b: int = a + d
			if b < 0 or b >= 81 or (abs(d) == 1 and b / 9 != a / 9):
				continue
			if reg[b] == r and not seen.has(b):
				seen[b] = true
				stack.append(b)
	return seen.size() == cells.size()


const C_RINGS := 6
const C_SECTORS := 9

static func _circular() -> Dictionary:
	var pos := PackedVector2Array()
	var polys: Array = []
	var units: Array = []
	for r in C_RINGS:
		for s in C_SECTORS:
			var r0 := 2.0 + r
			var a0 := TAU * s / C_SECTORS - PI / 2
			var a1 := TAU * (s + 1) / C_SECTORS - PI / 2
			var am := (a0 + a1) / 2
			pos.append(Vector2(cos(am), sin(am)) * (r0 + 0.5))
			var p := PackedVector2Array()
			for k in 7:
				var a: float = lerp(a0, a1, k / 6.0)
				p.append(Vector2(cos(a), sin(a)) * r0)
			for k in 7:
				var a: float = lerp(a1, a0, k / 6.0)
				p.append(Vector2(cos(a), sin(a)) * (r0 + 1))
			polys.append([p])
	for r in C_RINGS:
		var ring := PackedInt32Array()
		for s in C_SECTORS:
			ring.append(r * C_SECTORS + s)
		units.append(ring)
	for h in C_RINGS / 3:
		for g in C_SECTORS / 3:
			var block := PackedInt32Array()
			for r in range(h * 3, h * 3 + 3):
				for s in range(g * 3, g * 3 + 3):
					block.append(r * C_SECTORS + s)
			units.append(block)
	for s in C_SECTORS:
		var spoke := PackedInt32Array()
		for r in C_RINGS:
			spoke.append(r * C_SECTORS + s)
		units.append(spoke)
	return {"n": 9, "units": units, "pos": pos, "polys": polys, "grids": []}


const HEX_DIRS := [Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)]

static func _hexagonal() -> Dictionary:
	var centres: Array = [Vector2i(0, 0)]
	var v := Vector2i(2, 1)
	for k in 6:
		centres.append(v)
		v = Vector2i(-v.y, v.x + v.y)   # turn 60°
	var flowers: Array = []
	var keys: Array = []
	for c in centres:
		var f: Array = [c]
		for d in HEX_DIRS:
			f.append(c + d)
		flowers.append(f)
		keys.append_array(f)
	keys.sort_custom(func(a: Vector2i, b: Vector2i): return a.y < b.y or (a.y == b.y and a.x < b.x))
	var index := {}
	var pos := PackedVector2Array()
	var polys: Array = []
	for i in keys.size():
		var k: Vector2i = keys[i]
		index[k] = i
		var p := Vector2(sqrt(3.0) * (k.x + k.y / 2.0), 1.5 * k.y) / sqrt(3.0)   # neighbours 1 apart
		pos.append(p)
		var hexp := PackedVector2Array()
		for j in 6:
			var a := PI / 6 + PI / 3 * j
			hexp.append(p + Vector2(cos(a), sin(a)) / sqrt(3.0))
		polys.append([hexp])
	var units: Array = []
	for f in flowers:
		var u := PackedInt32Array()
		for k in f:
			u.append(index[k])
		units.append(u)
	# straight runs in the three directions
	for d in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, -1)]:
		for k in keys:
			if index.has(k - d):
				continue   # not the start of a run
			var run := PackedInt32Array()
			var c: Vector2i = k
			while index.has(c):
				run.append(index[c])
				c += d
			if run.size() >= 2:
				units.append(run)
	return {"n": 7, "units": units, "pos": pos, "polys": polys, "grids": []}


static func _triangular() -> Dictionary:
	var h := sqrt(3.0) / 2
	var pos := PackedVector2Array()
	var polys: Array = []
	var index := {}   # Vector2i(row, j) → cell
	for r in 9:
		for j in 2 * r + 1:
			var x := (j - r) * 0.5
			var y := r * h
			var p: PackedVector2Array
			if j % 2 == 0:   # pointing up
				p = PackedVector2Array([Vector2(x, y), Vector2(x + 0.5, y + h), Vector2(x - 0.5, y + h)])
			else:
				p = PackedVector2Array([Vector2(x - 0.5, y), Vector2(x + 0.5, y), Vector2(x, y + h)])
			index[Vector2i(r, j)] = pos.size()
			pos.append((p[0] + p[1] + p[2]) / 3.0)
			polys.append([p])
	var units: Array = []
	# 9 regions: the triangles of side 3 (row band R, place J, J even = up)
	for R in 3:
		for J in 2 * R + 1:
			var u := PackedInt32Array()
			for r in range(3 * R, 3 * R + 3):
				for j in 2 * r + 1:
					if _in_region(r, j, R, J):
						u.append(index[Vector2i(r, j)])
			units.append(u)
	# lines of upward triangles (r, 2a) and of downward ones (r, 2b + 1), in the three directions
	for up in [true, false]:
		var lines := {}
		for r in 9:
			var cnt := r + 1 if up else r
			for a in cnt:
				var cell: int = index[Vector2i(r, 2 * a + (0 if up else 1))]
				for key in ["r%d" % r, "a%d" % a, "d%d" % (r - a)]:
					if not lines.has(key):
						lines[key] = PackedInt32Array()
					lines[key].append(cell)
		for key in lines:
			if lines[key].size() >= 2:
				units.append(lines[key])
	return {"n": 9, "units": units, "pos": pos, "polys": polys, "grids": []}


## small triangle (r, j) inside region triangle (R, J) (big triangles of side 3)?
static func _in_region(r: int, j: int, R: int, J: int) -> bool:
	# barycentric-like test with the small triangle's centre in "row units"
	var lr := r - 3 * R        # 0..2 row inside the band
	# horizontal position of the small triangle's centre, in half-cells from the band's left edge at that row
	# small (r, j) centre x = (j - r) / 2; region (R, J) at row lr spans what the big triangle covers
	var x := (j - r) * 0.5
	var y := lr + (0.667 if j % 2 == 0 else 0.333)   # centre height inside the band (0 top .. 3 bottom)
	var bx := (J - R) * 1.5    # big triangle's centre x (side 3 = 1.5 per half step)
	if J % 2 == 0:   # up: apex at top, width grows downward
		return abs(x - bx) <= y * 0.5 + 0.001 and y <= 3.0
	return abs(x - bx) <= (3.0 - y) * 0.5 + 0.001


static func _cube() -> Dictionary:
	# cubies (x, y, z) in 0..8 with x, y or z = 8: faces X (x = 8, right), Y (y = 8, top), Z (z = 8, left)
	var keys: Array = []
	for y in range(8, -1, -1):
		for z in 9:
			for x in 9:
				if x == 8 or y == 8 or z == 8:
					keys.append(Vector3i(x, y, z))
	var index := {}
	var pos := PackedVector2Array()
	var polys: Array = []
	for i in keys.size():
		var k: Vector3i = keys[i]
		index[k] = i
		var stickers: Array = []
		if k.x == 8:
			stickers.append(_face_poly(Vector3(9, k.y, k.z), Vector3(0, 1, 0), Vector3(0, 0, 1)))
		if k.y == 8:
			stickers.append(_face_poly(Vector3(k.x, 9, k.z), Vector3(1, 0, 0), Vector3(0, 0, 1)))
		if k.z == 8:
			stickers.append(_face_poly(Vector3(k.x, k.y, 9), Vector3(1, 0, 0), Vector3(0, 1, 0)))
		var c := Vector2.ZERO
		for s in stickers:
			c += (s[0] + s[1] + s[2] + s[3]) / 4.0
		pos.append(c / stickers.size())
		polys.append(stickers)
	var units: Array = []
	for face in 3:
		var at := func(u: int, v: int) -> int:
			match face:
				0: return index[Vector3i(8, u, v)]
				1: return index[Vector3i(u, 8, v)]
			return index[Vector3i(u, v, 8)]
		for a in 9:
			var l1 := PackedInt32Array()
			var l2 := PackedInt32Array()
			for b in 9:
				l1.append(at.call(a, b))
				l2.append(at.call(b, a))
			units.append(l1)
			units.append(l2)
		for b in 9:
			var box := PackedInt32Array()
			for k in 9:
				box.append(at.call((b / 3) * 3 + k / 3, (b % 3) * 3 + k % 3))
			units.append(box)
	return {"n": 9, "units": units, "pos": pos, "polys": polys, "grids": []}


static func _iso(p: Vector3) -> Vector2:
	return Vector2((p.x - p.z) * 0.866, (p.x + p.z) * 0.5 - p.y)


static func _face_poly(o: Vector3, a: Vector3, b: Vector3) -> PackedVector2Array:
	return PackedVector2Array([_iso(o), _iso(o + a), _iso(o + a + b), _iso(o + b)])


static func _dedupe(units: Array) -> Array:
	var seen := {}
	var out: Array = []
	for u in units:
		var s: Array = Array(u)
		s.sort()
		var key := str(s)
		if not seen.has(key):
			seen[key] = true
			out.append(u)
	return out


## The cell each cell lands on when the shape is turned 180°, else mirrored left-right, else top-bottom.
static func _symmetry(pos: PackedVector2Array) -> PackedInt32Array:
	var lo := pos[0]
	var hi := pos[0]
	for p in pos:
		lo = lo.min(p)
		hi = hi.max(p)
	var mid := (lo + hi) / 2
	var lookup := {}
	for i in pos.size():
		lookup[Vector2i(roundi(pos[i].x * 100), roundi(pos[i].y * 100))] = i
	for f in [func(p: Vector2): return mid * 2 - p,
			func(p: Vector2): return Vector2(mid.x * 2 - p.x, p.y),
			func(p: Vector2): return Vector2(p.x, mid.y * 2 - p.y)]:
		var out := PackedInt32Array()
		var ok := true
		for p in pos:
			var q: Vector2 = f.call(p)
			var k := Vector2i(roundi(q.x * 100), roundi(q.y * 100))
			if not lookup.has(k):
				ok = false
				break
			out.append(lookup[k])
		if ok:
			return out
	var none := PackedInt32Array()
	none.resize(pos.size())
	none.fill(-1)
	return none
