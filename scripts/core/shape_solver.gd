class_name ShapeSolver
extends RefCounted
## Solver for GridShapes puzzles: cells with digits 1..n and units whose digits must all differ.
## Bitmask candidates (digit d = bit d - 1), naked singles + hidden singles (in units of exactly n cells),
## then a search on the cell with the fewest candidates.

var n := 9
var nc := 0
var full := 0
var units: Array = []
var full_units: Array = []
var peers: Array = []

var nodes := 0
var node_limit := 0
var aborted := false
var found := 0
var want := 1
var first := PackedInt32Array()
var rng: RandomNumberGenerator = null

static var _pc := PackedByteArray()   # popcount of every 16-bit mask


func _init(shape: Dictionary) -> void:
	n = shape.n
	nc = shape.cells
	full = (1 << n) - 1
	units = shape.units
	var sets: Array = []
	for i in nc:
		sets.append({})
	for u in units:
		if u.size() == n:
			full_units.append(u)
		for a in u:
			for b in u:
				if a != b:
					sets[a][b] = true
	for s in sets:
		peers.append(PackedInt32Array(s.keys()))
	if _pc.is_empty():
		_pc.resize(1 << 16)
		for m in range(1, 1 << 16):
			_pc[m] = _pc[m >> 1] + (m & 1)


## Number of solutions up to `limit` (-1 = gave up after `nlimit` search nodes; 0 = no limit).
func count(givens: PackedInt32Array, limit := 2, nlimit := 0) -> int:
	var st := _start(givens)
	if st.is_empty():
		return 0
	_reset(limit, nlimit, null)
	_search(st[0], st[1])
	return -1 if aborted else found


## A random full solution (empty when the search gave up).
func fill(r: RandomNumberGenerator, nlimit := 20000, tries := 30) -> PackedInt32Array:
	var empty := PackedInt32Array()
	empty.resize(nc)
	for t in tries:
		var st := _start(empty)
		_reset(1, nlimit, r)
		_search(st[0], st[1])
		if found > 0:
			return first
	return PackedInt32Array()


## Is there a solution other than `sol` once the cells in `removed` are emptied from a puzzle that was unique
## with them given? Any other solution must differ in one of them, so each is searched with its own digit
## forbidden. 1 = yes, 0 = no (still unique), -1 = gave up.
func other_exists(givens: PackedInt32Array, sol: PackedInt32Array, removed: Array, nlimit := 0) -> int:
	var gave_up := false
	for c in removed:
		var st := _start(givens)
		if st.is_empty():
			return 0
		var cand: PackedInt32Array = st[1]
		cand[c] &= ~(1 << (sol[c] - 1))
		_reset(1, nlimit, null)
		_search(st[0], cand)
		if found > 0:
			return 1
		if aborted:
			gave_up = true
	return -1 if gave_up else 0


func _reset(limit: int, nlimit: int, r: RandomNumberGenerator) -> void:
	nodes = 0
	node_limit = nlimit
	aborted = false
	found = 0
	want = limit
	first = PackedInt32Array()
	rng = r


## [values, candidates] with the givens placed, or [] if two givens clash.
func _start(givens: PackedInt32Array) -> Array:
	var vals := PackedInt32Array()
	vals.resize(nc)
	var cand := PackedInt32Array()
	cand.resize(nc)
	cand.fill(full)
	for c in nc:
		var d := givens[c]
		if d > 0:
			if not cand[c] & (1 << (d - 1)):
				return []
			_place(vals, cand, c, d)
	return [vals, cand]


func _place(vals: PackedInt32Array, cand: PackedInt32Array, c: int, d: int) -> void:
	vals[c] = d
	cand[c] = 0
	var b := ~(1 << (d - 1))
	for p in peers[c]:
		cand[p] &= b


static func _digit(m: int) -> int:
	var d := 1
	while not m & 1:
		m >>= 1
		d += 1
	return d


func _propagate(vals: PackedInt32Array, cand: PackedInt32Array) -> bool:
	var changed := true
	while changed:
		changed = false
		for c in nc:
			if vals[c] == 0:
				var m := cand[c]
				if m == 0:
					return false
				if m & (m - 1) == 0:
					_place(vals, cand, c, _digit(m))
					changed = true
		if changed:
			continue
		for u in full_units:
			var once := 0
			var twice := 0
			var placed := 0
			for c in u:
				var v := vals[c]
				if v:
					placed |= 1 << (v - 1)
				else:
					var m := cand[c]
					twice |= once & m
					once |= m
			if (once | placed) != full:
				return false
			var single := once & ~twice & ~placed
			if single:
				for c in u:
					if vals[c] == 0:
						var s := cand[c] & single
						if s:
							if s & (s - 1):
								return false
							_place(vals, cand, c, _digit(s))
							changed = true
	return true


func _search(vals: PackedInt32Array, cand: PackedInt32Array) -> void:
	nodes += 1
	if node_limit > 0 and nodes > node_limit:
		aborted = true
		return
	if not _propagate(vals, cand):
		return
	var best := -1
	var bc := 99
	var start := rng.randi() % nc if rng else 0
	for i in nc:
		var c := (start + i) % nc
		if vals[c] == 0:
			var k := _pc[cand[c]]
			if k < bc:
				bc = k
				best = c
				if k == 2:
					break
	if best < 0:
		found += 1
		if found == 1:
			first = vals.duplicate()
		return
	var digits: Array = []
	var m := cand[best]
	for d in range(1, n + 1):
		if m & (1 << (d - 1)):
			digits.append(d)
	if rng:
		for i in range(digits.size() - 1, 0, -1):
			var j := rng.randi() % (i + 1)
			var t = digits[i]
			digits[i] = digits[j]
			digits[j] = t
	for d in digits:
		var v2 := vals.duplicate()
		var c2 := cand.duplicate()
		_place(v2, c2, best, d)
		_search(v2, c2)
		if found >= want or aborted:
			return
