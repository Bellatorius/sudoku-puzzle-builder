class_name Ultimate
extends RefCounted
## Ultimate Sudoku: one variant, 100 types, each type mixing its own 9 rules (Puzzle.rules).
## A type = 1 shape rule, 2 line rules, 1 dot rule, 1 sign rule, 1 outside-clue rule, 1 cell-mark rule and
## 2 global rules, drawn so every rule of every slot is used about equally often (66 variants in all).
## Left out: look-alikes together (thermo + slow thermo, the arrows, the whispers), more than one rule with
## shaded regions or with extra diagonals, Kropki under Non-Consecutive, Jigsaw with box-based rules
## (Universal, Friendly), tinted shapes (Clone, Even-Odd Regions) with shaded cells or regions.
## Types 6, 16, 20, 22, 28, 41, 42, 54, 60, 75, 81, 82 and 94 later got new global rules: their pairs (e.g.
## Argyle + Anti-Knight, Anti-Diagonal + Queen, Windoku + Non-Consecutive) almost never allow a filled grid.
## The new pairs found one in at least 4 of 5 random searches of 40,000 steps (Argyle, Queen and
## Non-Consecutive clash with most other global rules; Anti-Knight rarely fits random Jigsaw regions).
## The list was drawn once with a fixed seed; edit it by hand to change a type.

## Line rules and their line code in Puzzle.lines (thermo and arrow have their own lists).
const LINE_CODES := {"german_whispers": "gw", "renban": "rb", "dutch_whispers": "dw", "palindrome": "pal",
	"between": "bt", "lockout": "lo", "zipper": "zp", "entropic": "en", "modular": "mo", "parity_lines": "pa",
	"nabner": "nb", "region_sum": "rs", "slow_thermo": "st", "double_arrow": "da", "ten_lines": "tn",
	"product_lines": "pr", "difference_lines": "df", "ratio_lines": "rt", "bishop": "bi", "pill_arrow": "pl"}
## Outside-clue rules and their code in Puzzle.outer (Little Killer uses Puzzle.sums).
const OUTER_CODES := {"sandwich": "sw", "skyscraper": "sk", "xsum": "xs", "frame": "fs", "numbered_rooms": "nr",
	"battlefield": "bf", "missing_digit": "md"}
## Rules without clues: they only change which grids are allowed (Jigsaw changes the regions).
const GLOBAL := ["diagonal", "anti_diagonal", "argyle", "king", "knight", "queen", "non_consecutive", "windoku",
	"center_dot", "asterisk", "girandola", "universal", "dutch_flatmates", "jigsaw"]

const TYPES := [
	["clone", "between", "double_arrow", "ratio_dots", "couples", "frame", "friendly", "non_consecutive", "anti_diagonal"],   # 1
	["parity_regions", "arrow", "palindrome", "sum_product_dots", "greater_than", "xsum", "pulse", "dutch_flatmates", "diagonal"],   # 2
	["killer", "parity_lines", "difference_lines", "kropki", "xv", "skyscraper", "index", "center_dot", "king"],   # 3
	["clone", "ratio_lines", "dutch_whispers", "difference_dots", "greater_than", "little_killer", "prime_composite", "universal", "queen"],   # 4
	["killer", "thermo", "entropic", "kropki", "couples", "numbered_rooms", "divisibility", "windoku", "jigsaw"],   # 5
	["parity_regions", "lockout", "product_lines", "sum_product_dots", "xv", "battlefield", "vertex", "anti_diagonal", "universal"],   # 6
	["killer", "renban", "bishop", "ratio_dots", "greater_than", "missing_digit", "min_max", "girandola", "king"],   # 7
	["parity_regions", "slow_thermo", "german_whispers", "difference_dots", "couples", "sandwich", "slingshot", "dutch_flatmates", "jigsaw"],   # 8
	["clone", "ten_lines", "pill_arrow", "ratio_dots", "xv", "missing_digit", "axia", "queen", "argyle"],   # 9
	["killer", "region_sum", "zipper", "difference_dots", "xv", "frame", "quadruple", "asterisk", "anti_diagonal"],   # 10
	["parity_regions", "modular", "nabner", "sum_product_dots", "greater_than", "xsum", "even_odd", "knight", "universal"],   # 11
	["clone", "renban", "bishop", "kropki", "couples", "numbered_rooms", "forbidden_digit", "diagonal", "dutch_flatmates"],   # 12
	["parity_regions", "between", "dutch_whispers", "ratio_dots", "greater_than", "skyscraper", "even_odd", "non_consecutive", "diagonal"],   # 13
	["clone", "double_arrow", "german_whispers", "difference_dots", "couples", "little_killer", "axia", "king", "queen"],   # 14
	["killer", "lockout", "difference_lines", "sum_product_dots", "xv", "sandwich", "fortress", "center_dot", "knight"],   # 15
	["clone", "pill_arrow", "parity_lines", "kropki", "xv", "battlefield", "vertex", "king", "knight"],   # 16
	["killer", "entropic", "zipper", "kropki", "greater_than", "numbered_rooms", "prime_composite", "girandola", "universal"],   # 17
	["parity_regions", "thermo", "modular", "difference_dots", "couples", "little_killer", "slingshot", "non_consecutive", "anti_diagonal"],   # 18
	["killer", "region_sum", "product_lines", "sum_product_dots", "greater_than", "sandwich", "quadruple", "windoku", "queen"],   # 19
	["parity_regions", "ten_lines", "nabner", "ratio_dots", "couples", "frame", "pulse", "diagonal", "king"],   # 20
	["clone", "arrow", "ratio_lines", "difference_dots", "xv", "xsum", "divisibility", "knight", "jigsaw"],   # 21
	["killer", "palindrome", "slow_thermo", "ratio_dots", "couples", "missing_digit", "min_max", "anti_diagonal", "windoku"],   # 22
	["clone", "product_lines", "german_whispers", "kropki", "greater_than", "battlefield", "friendly", "universal", "king"],   # 23
	["parity_regions", "modular", "thermo", "sum_product_dots", "xv", "skyscraper", "index", "anti_diagonal", "king"],   # 24
	["killer", "double_arrow", "between", "ratio_dots", "xv", "frame", "fortress", "asterisk", "diagonal"],   # 25
	["parity_regions", "entropic", "zipper", "difference_dots", "couples", "missing_digit", "forbidden_digit", "queen", "diagonal"],   # 26
	["clone", "renban", "slow_thermo", "kropki", "greater_than", "xsum", "divisibility", "anti_diagonal", "jigsaw"],   # 27
	["parity_regions", "arrow", "bishop", "sum_product_dots", "greater_than", "little_killer", "pulse", "knight", "dutch_flatmates"],   # 28
	["killer", "ratio_lines", "lockout", "sum_product_dots", "couples", "numbered_rooms", "quadruple", "center_dot", "universal"],   # 29
	["clone", "ten_lines", "dutch_whispers", "ratio_dots", "xv", "sandwich", "vertex", "dutch_flatmates", "non_consecutive"],   # 30
	["parity_regions", "palindrome", "region_sum", "difference_dots", "greater_than", "battlefield", "axia", "anti_diagonal", "dutch_flatmates"],   # 31
	["clone", "difference_lines", "nabner", "kropki", "couples", "skyscraper", "friendly", "knight", "diagonal"],   # 32
	["killer", "parity_lines", "pill_arrow", "sum_product_dots", "xv", "skyscraper", "min_max", "girandola", "non_consecutive"],   # 33
	["parity_regions", "nabner", "product_lines", "ratio_dots", "greater_than", "little_killer", "even_odd", "argyle", "universal"],   # 34
	["clone", "double_arrow", "modular", "difference_dots", "couples", "missing_digit", "index", "jigsaw", "queen"],   # 35
	["killer", "palindrome", "bishop", "kropki", "xv", "sandwich", "fortress", "windoku", "king"],   # 36
	["parity_regions", "german_whispers", "lockout", "ratio_dots", "greater_than", "battlefield", "slingshot", "jigsaw", "knight"],   # 37
	["clone", "entropic", "difference_lines", "sum_product_dots", "couples", "numbered_rooms", "forbidden_digit", "non_consecutive", "universal"],   # 38
	["killer", "pill_arrow", "dutch_whispers", "difference_dots", "xv", "xsum", "prime_composite", "windoku", "king"],   # 39
	["clone", "zipper", "arrow", "kropki", "couples", "frame", "divisibility", "diagonal", "dutch_flatmates"],   # 40
	["killer", "between", "ten_lines", "sum_product_dots", "xv", "battlefield", "quadruple", "asterisk", "jigsaw"],   # 41
	["parity_regions", "slow_thermo", "region_sum", "kropki", "greater_than", "little_killer", "vertex", "knight", "universal"],   # 42
	["killer", "thermo", "ratio_lines", "ratio_dots", "greater_than", "sandwich", "slingshot", "center_dot", "argyle"],   # 43
	["clone", "parity_lines", "renban", "difference_dots", "xv", "numbered_rooms", "axia", "universal", "knight"],   # 44
	["parity_regions", "lockout", "product_lines", "kropki", "couples", "xsum", "prime_composite", "queen", "diagonal"],   # 45
	["killer", "thermo", "modular", "sum_product_dots", "couples", "frame", "even_odd", "girandola", "king"],   # 46
	["parity_regions", "pill_arrow", "nabner", "ratio_dots", "xv", "skyscraper", "pulse", "anti_diagonal", "jigsaw"],   # 47
	["clone", "difference_lines", "double_arrow", "difference_dots", "greater_than", "missing_digit", "friendly", "dutch_flatmates", "non_consecutive"],   # 48
	["parity_regions", "region_sum", "ten_lines", "difference_dots", "couples", "sandwich", "forbidden_digit", "universal", "anti_diagonal"],   # 49
	["killer", "renban", "ratio_lines", "ratio_dots", "greater_than", "battlefield", "min_max", "asterisk", "jigsaw"],   # 50
	["clone", "bishop", "between", "kropki", "xv", "skyscraper", "index", "dutch_flatmates", "queen"],   # 51
	["parity_regions", "german_whispers", "slow_thermo", "sum_product_dots", "greater_than", "xsum", "even_odd", "king", "argyle"],   # 52
	["clone", "entropic", "zipper", "kropki", "couples", "missing_digit", "prime_composite", "knight", "diagonal"],   # 53
	["killer", "palindrome", "parity_lines", "difference_dots", "xv", "little_killer", "fortress", "anti_diagonal", "asterisk"],   # 54
	["clone", "arrow", "dutch_whispers", "ratio_dots", "couples", "frame", "slingshot", "universal", "queen"],   # 55
	["parity_regions", "ratio_lines", "difference_lines", "sum_product_dots", "greater_than", "numbered_rooms", "friendly", "non_consecutive", "dutch_flatmates"],   # 56
	["killer", "region_sum", "thermo", "kropki", "xv", "numbered_rooms", "vertex", "center_dot", "diagonal"],   # 57
	["clone", "palindrome", "parity_lines", "sum_product_dots", "xv", "skyscraper", "divisibility", "king", "jigsaw"],   # 58
	["parity_regions", "product_lines", "dutch_whispers", "difference_dots", "greater_than", "little_killer", "quadruple", "anti_diagonal", "knight"],   # 59
	["killer", "renban", "entropic", "ratio_dots", "couples", "battlefield", "min_max", "knight", "asterisk"],   # 60
	["parity_regions", "arrow", "lockout", "difference_dots", "greater_than", "sandwich", "pulse", "non_consecutive", "dutch_flatmates"],   # 61
	["clone", "bishop", "german_whispers", "sum_product_dots", "couples", "xsum", "axia", "argyle", "universal"],   # 62
	["killer", "slow_thermo", "between", "ratio_dots", "xv", "missing_digit", "forbidden_digit", "windoku", "jigsaw"],   # 63
	["clone", "zipper", "nabner", "kropki", "greater_than", "frame", "index", "queen", "king"],   # 64
	["killer", "modular", "double_arrow", "difference_dots", "xv", "xsum", "fortress", "center_dot", "anti_diagonal"],   # 65
	["parity_regions", "pill_arrow", "ten_lines", "kropki", "couples", "little_killer", "pulse", "knight", "diagonal"],   # 66
	["parity_regions", "nabner", "pill_arrow", "ratio_dots", "greater_than", "skyscraper", "index", "universal", "argyle"],   # 67
	["killer", "double_arrow", "difference_lines", "sum_product_dots", "xv", "battlefield", "slingshot", "asterisk", "jigsaw"],   # 68
	["clone", "arrow", "renban", "difference_dots", "couples", "missing_digit", "vertex", "king", "non_consecutive"],   # 69
	["parity_regions", "modular", "ratio_lines", "kropki", "greater_than", "sandwich", "divisibility", "dutch_flatmates", "knight"],   # 70
	["clone", "thermo", "bishop", "ratio_dots", "xv", "numbered_rooms", "quadruple", "diagonal", "queen"],   # 71
	["killer", "entropic", "dutch_whispers", "sum_product_dots", "couples", "frame", "axia", "girandola", "anti_diagonal"],   # 72
	["killer", "zipper", "german_whispers", "kropki", "xv", "skyscraper", "friendly", "asterisk", "knight"],   # 73
	["parity_regions", "ten_lines", "lockout", "ratio_dots", "couples", "missing_digit", "even_odd", "universal", "diagonal"],   # 74
	["clone", "region_sum", "product_lines", "difference_dots", "greater_than", "little_killer", "forbidden_digit", "king", "jigsaw"],   # 75
	["clone", "between", "slow_thermo", "sum_product_dots", "couples", "sandwich", "prime_composite", "queen", "king"],   # 76
	["killer", "parity_lines", "palindrome", "kropki", "xv", "frame", "min_max", "girandola", "jigsaw"],   # 77
	["parity_regions", "ratio_lines", "lockout", "sum_product_dots", "greater_than", "battlefield", "pulse", "dutch_flatmates", "anti_diagonal"],   # 78
	["clone", "palindrome", "arrow", "difference_dots", "greater_than", "xsum", "slingshot", "universal", "non_consecutive"],   # 79
	["killer", "slow_thermo", "bishop", "ratio_dots", "xv", "numbered_rooms", "fortress", "center_dot", "dutch_flatmates"],   # 80
	["parity_regions", "pill_arrow", "modular", "difference_dots", "couples", "missing_digit", "divisibility", "anti_diagonal", "universal"],   # 81
	["parity_regions", "ten_lines", "product_lines", "ratio_dots", "xv", "battlefield", "forbidden_digit", "knight", "dutch_flatmates"],   # 82
	["clone", "renban", "between", "sum_product_dots", "greater_than", "numbered_rooms", "friendly", "knight", "king"],   # 83
	["killer", "thermo", "entropic", "kropki", "couples", "sandwich", "quadruple", "windoku", "diagonal"],   # 84
	["clone", "nabner", "region_sum", "kropki", "greater_than", "frame", "prime_composite", "dutch_flatmates", "anti_diagonal"],   # 85
	["killer", "zipper", "difference_lines", "difference_dots", "couples", "skyscraper", "vertex", "girandola", "argyle"],   # 86
	["parity_regions", "german_whispers", "double_arrow", "ratio_dots", "xv", "little_killer", "axia", "queen", "jigsaw"],   # 87
	["parity_regions", "dutch_whispers", "pill_arrow", "sum_product_dots", "greater_than", "xsum", "index", "knight", "non_consecutive"],   # 88
	["killer", "parity_lines", "between", "sum_product_dots", "couples", "missing_digit", "min_max", "windoku", "universal"],   # 89
	["clone", "thermo", "difference_lines", "difference_dots", "xv", "skyscraper", "even_odd", "diagonal", "king"],   # 90
	["killer", "product_lines", "ten_lines", "ratio_dots", "greater_than", "xsum", "fortress", "center_dot", "non_consecutive"],   # 91
	["clone", "region_sum", "bishop", "kropki", "couples", "sandwich", "prime_composite", "dutch_flatmates", "queen"],   # 92
	["parity_regions", "german_whispers", "zipper", "kropki", "xv", "frame", "axia", "jigsaw", "anti_diagonal"],   # 93
	["parity_regions", "dutch_whispers", "renban", "sum_product_dots", "xv", "numbered_rooms", "even_odd", "anti_diagonal", "jigsaw"],   # 94
	["clone", "arrow", "nabner", "difference_dots", "couples", "little_killer", "divisibility", "diagonal", "king"],   # 95
	["killer", "palindrome", "entropic", "ratio_dots", "greater_than", "battlefield", "pulse", "asterisk", "universal"],   # 96
	["clone", "lockout", "modular", "ratio_dots", "couples", "sandwich", "quadruple", "dutch_flatmates", "argyle"],   # 97
	["killer", "double_arrow", "ratio_lines", "difference_dots", "greater_than", "skyscraper", "slingshot", "girandola", "queen"],   # 98
	["parity_regions", "slow_thermo", "difference_lines", "kropki", "xv", "little_killer", "vertex", "king", "jigsaw"],   # 99
	["clone", "parity_lines", "ratio_lines", "sum_product_dots", "xv", "missing_digit", "forbidden_digit", "knight", "diagonal"],   # 100
]


## The two line rules of a puzzle are always drawn in these two colours (blue, orange), whatever colour the
## rule has on its own, so two kinds of line never look alike. The rules card shows the same colours.
const LINE_PAIR := [Color(0.24, 0.55, 0.98, 0.8), Color(0.97, 0.50, 0.12, 0.8)]


## Line code of a line rule as the board knows it ("th" thermo, "ar" arrow), "" for other rules.
static func line_code(r: String) -> String:
	if r == "thermo": return "th"
	if r == "arrow": return "ar"
	return LINE_CODES.get(r, "")


## Line code -> colour for this puzzle's line rules (empty for other puzzles).
static func line_colors(pz: Puzzle) -> Dictionary:
	var out := {}
	for r in pz.rules:
		var code := line_code(r)
		if code != "" and out.size() < LINE_PAIR.size():
			out[code] = LINE_PAIR[out.size()]
	return out


## "Rule name: what it says" for the rules card (colour words dropped: the key beside it shows the colour).
static func rule_line(r: String) -> String:
	var info := Variants.get_info(r)
	var short := str(info.get("short", ""))
	for w in [" an orange line", " a green line"]:
		short = short.replace(w, " this line")
	return "%s: %s" % [info.get("name", r.capitalize()), short]


static func rules_intro(pz: Puzzle) -> String:
	return "%s rules apply, plus these %d rules at once:" % ["Jigsaw Sudoku" if pz.has_rule("jigsaw") else "Normal Sudoku", pz.rules.size()]


const RULES_NOTE := "Clues are only where shown: a missing dot, sign or line says nothing."


static func rules_of(type: int) -> Array:
	return TYPES[clampi(type, 1, TYPES.size()) - 1].duplicate()


## True if both lists hold the same rules (in any order).
static func same_rules(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for r in a:
		if not b.has(r):
			return false
	return true


## The type number of a rule list, 0 if it isn't one of TYPES.
static func type_of(rules: Array) -> int:
	for i in TYPES.size():
		if same_rules(TYPES[i], rules):
			return i + 1
	return 0


## The rules card: normal Sudoku plus each of the puzzle's rules, one line each.
static func rules_text(pz: Puzzle) -> String:
	var lines: Array = [rules_intro(pz)]
	for r in pz.rules:
		lines.append("•  " + rule_line(r))
	lines.append(RULES_NOTE)
	return "\n".join(lines)


## Whether an edge / cell mark code belongs to rule r.
static func _edge_of(r: String, code: String) -> bool:
	match r:
		"kropki": return code in ["w", "b"]
		"xv": return code in ["x", "v"]
		"greater_than": return code in [">", "<"]
		"couples": return code in ["s", "d"]
		"difference_dots": return code.length() > 1 and code[0] == "-"
		"ratio_dots": return code.length() > 1 and code[0] == "/"
		"sum_product_dots": return code.length() > 1 and code[0] in ["+", "*"]
	return false


static func _mark_of(r: String, code: String) -> bool:
	match r:
		"fortress": return code == "fo"
		"min_max": return code in ["mn", "mx"]
		"prime_composite": return code in ["pm", "cm"]
		"axia": return code == "ax"
		"friendly": return code == "fr"
		"pulse": return code == "pu"
		"index": return code.begins_with("i")
		"divisibility": return code in ["d2", "d3", "d4"]
		"forbidden_digit": return code.length() == 2 and code[0] == "x"
	return false


## The same solved grid with only rule r's clues (variant r), for the example notes of one rule.
static func only(pz: Puzzle, r: String) -> Puzzle:
	var p := Puzzle.new()
	p.variant = r
	p.solution = pz.solution
	p.givens = pz.solution
	p.regions = pz.regions
	match r:
		"killer": p.cages = pz.cages
		"clone": p.clones = pz.clones
		"parity_regions": p.areas = pz.areas
		"thermo": p.thermos = pz.thermos
		"arrow": p.arrows = pz.arrows
		"little_killer": p.sums = pz.sums
		"even_odd": p.parity = pz.parity
		"quadruple": p.quads = pz.quads
		"vertex": p.vertices = pz.vertices
		"slingshot": p.slings = pz.slings
		"diagonal": p.diagonals = true
	if LINE_CODES.has(r):
		p.lines = pz.lines.filter(func(ln): return ln.t == LINE_CODES[r])
	if OUTER_CODES.has(r):
		p.outer = pz.outer.filter(func(o): return o.t == OUTER_CODES[r])
	for k in pz.edges:
		if _edge_of(r, pz.edges[k]):
			p.edges[k] = pz.edges[k]
	for k in pz.marks:
		if _mark_of(r, pz.marks[k]):
			p.marks[k] = pz.marks[k]
	return p
