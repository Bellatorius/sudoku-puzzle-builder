class_name Ultimate
extends RefCounted
## Ultimate Sudoku: 100 types, each type mixing its own 9 rules (Puzzle.rules); Ultimate 6 / 3 / 2 (TYPES_6 …)
## are lighter versions with 6, 3 or 2 of those rules.
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


## Lighter Ultimate variants: 6, 3 or 2 rules per type, each type a subset of the 9-rule type with the same
## number (so every set is known to allow a grid). Ultimate 6 = shape, one line, a dot or sign, outside clues,
## cell marks, one global rule; Ultimate 3 / 2 = every mix of 3 / 2 of those six kinds in turn (never two
## global rules, so each type has clues). Written once by a script; edit by hand to change a type.
const TYPES_6 := [
	["clone", "double_arrow", "ratio_dots", "frame", "friendly", "anti_diagonal"],   # 1
	["parity_regions", "palindrome", "sum_product_dots", "xsum", "pulse", "diagonal"],   # 2
	["killer", "parity_lines", "kropki", "skyscraper", "index", "king"],   # 3
	["clone", "ratio_lines", "greater_than", "little_killer", "prime_composite", "queen"],   # 4
	["killer", "entropic", "couples", "numbered_rooms", "divisibility", "jigsaw"],   # 5
	["parity_regions", "product_lines", "xv", "battlefield", "vertex", "universal"],   # 6
	["killer", "renban", "ratio_dots", "missing_digit", "min_max", "girandola"],   # 7
	["parity_regions", "slow_thermo", "difference_dots", "sandwich", "slingshot", "dutch_flatmates"],   # 8
	["clone", "pill_arrow", "ratio_dots", "missing_digit", "axia", "queen"],   # 9
	["killer", "zipper", "xv", "frame", "quadruple", "asterisk"],   # 10
	["parity_regions", "modular", "greater_than", "xsum", "even_odd", "knight"],   # 11
	["clone", "renban", "couples", "numbered_rooms", "forbidden_digit", "diagonal"],   # 12
	["parity_regions", "dutch_whispers", "ratio_dots", "skyscraper", "even_odd", "diagonal"],   # 13
	["clone", "german_whispers", "difference_dots", "little_killer", "axia", "queen"],   # 14
	["killer", "lockout", "sum_product_dots", "sandwich", "fortress", "knight"],   # 15
	["clone", "pill_arrow", "xv", "battlefield", "vertex", "knight"],   # 16
	["killer", "zipper", "greater_than", "numbered_rooms", "prime_composite", "universal"],   # 17
	["parity_regions", "modular", "couples", "little_killer", "slingshot", "anti_diagonal"],   # 18
	["killer", "region_sum", "sum_product_dots", "sandwich", "quadruple", "windoku"],   # 19
	["parity_regions", "ten_lines", "ratio_dots", "frame", "pulse", "diagonal"],   # 20
	["clone", "ratio_lines", "difference_dots", "xsum", "divisibility", "knight"],   # 21
	["killer", "slow_thermo", "couples", "missing_digit", "min_max", "anti_diagonal"],   # 22
	["clone", "product_lines", "greater_than", "battlefield", "friendly", "universal"],   # 23
	["parity_regions", "modular", "xv", "skyscraper", "index", "anti_diagonal"],   # 24
	["killer", "between", "ratio_dots", "frame", "fortress", "diagonal"],   # 25
	["parity_regions", "zipper", "difference_dots", "missing_digit", "forbidden_digit", "diagonal"],   # 26
	["clone", "renban", "kropki", "xsum", "divisibility", "jigsaw"],   # 27
	["parity_regions", "arrow", "greater_than", "little_killer", "pulse", "dutch_flatmates"],   # 28
	["killer", "lockout", "couples", "numbered_rooms", "quadruple", "universal"],   # 29
	["clone", "dutch_whispers", "xv", "sandwich", "vertex", "non_consecutive"],   # 30
	["parity_regions", "palindrome", "difference_dots", "battlefield", "axia", "anti_diagonal"],   # 31
	["clone", "difference_lines", "kropki", "skyscraper", "friendly", "knight"],   # 32
	["killer", "pill_arrow", "sum_product_dots", "skyscraper", "min_max", "girandola"],   # 33
	["parity_regions", "product_lines", "greater_than", "little_killer", "even_odd", "argyle"],   # 34
	["clone", "double_arrow", "couples", "missing_digit", "index", "jigsaw"],   # 35
	["killer", "palindrome", "xv", "sandwich", "fortress", "windoku"],   # 36
	["parity_regions", "lockout", "ratio_dots", "battlefield", "slingshot", "knight"],   # 37
	["clone", "difference_lines", "sum_product_dots", "numbered_rooms", "forbidden_digit", "universal"],   # 38
	["killer", "pill_arrow", "difference_dots", "xsum", "prime_composite", "king"],   # 39
	["clone", "zipper", "couples", "frame", "divisibility", "dutch_flatmates"],   # 40
	["killer", "ten_lines", "xv", "battlefield", "quadruple", "jigsaw"],   # 41
	["parity_regions", "region_sum", "greater_than", "little_killer", "vertex", "universal"],   # 42
	["killer", "thermo", "ratio_dots", "sandwich", "slingshot", "center_dot"],   # 43
	["clone", "parity_lines", "difference_dots", "numbered_rooms", "axia", "universal"],   # 44
	["parity_regions", "product_lines", "kropki", "xsum", "prime_composite", "queen"],   # 45
	["killer", "modular", "couples", "frame", "even_odd", "girandola"],   # 46
	["parity_regions", "pill_arrow", "xv", "skyscraper", "pulse", "anti_diagonal"],   # 47
	["clone", "difference_lines", "greater_than", "missing_digit", "friendly", "dutch_flatmates"],   # 48
	["parity_regions", "ten_lines", "difference_dots", "sandwich", "forbidden_digit", "anti_diagonal"],   # 49
	["killer", "ratio_lines", "ratio_dots", "battlefield", "min_max", "jigsaw"],   # 50
	["clone", "bishop", "kropki", "skyscraper", "index", "queen"],   # 51
	["parity_regions", "german_whispers", "greater_than", "xsum", "even_odd", "argyle"],   # 52
	["clone", "zipper", "couples", "missing_digit", "prime_composite", "diagonal"],   # 53
	["killer", "parity_lines", "xv", "little_killer", "fortress", "asterisk"],   # 54
	["clone", "arrow", "ratio_dots", "frame", "slingshot", "universal"],   # 55
	["parity_regions", "ratio_lines", "sum_product_dots", "numbered_rooms", "friendly", "non_consecutive"],   # 56
	["killer", "thermo", "kropki", "numbered_rooms", "vertex", "center_dot"],   # 57
	["clone", "parity_lines", "xv", "skyscraper", "divisibility", "king"],   # 58
	["parity_regions", "product_lines", "greater_than", "little_killer", "quadruple", "anti_diagonal"],   # 59
	["killer", "renban", "couples", "battlefield", "min_max", "knight"],   # 60
	["parity_regions", "lockout", "difference_dots", "sandwich", "pulse", "dutch_flatmates"],   # 61
	["clone", "german_whispers", "sum_product_dots", "xsum", "axia", "universal"],   # 62
	["killer", "slow_thermo", "ratio_dots", "missing_digit", "forbidden_digit", "jigsaw"],   # 63
	["clone", "zipper", "greater_than", "frame", "index", "king"],   # 64
	["killer", "double_arrow", "xv", "xsum", "fortress", "anti_diagonal"],   # 65
	["parity_regions", "ten_lines", "couples", "little_killer", "pulse", "diagonal"],   # 66
	["parity_regions", "nabner", "ratio_dots", "skyscraper", "index", "universal"],   # 67
	["killer", "double_arrow", "sum_product_dots", "battlefield", "slingshot", "asterisk"],   # 68
	["clone", "renban", "difference_dots", "missing_digit", "vertex", "king"],   # 69
	["parity_regions", "ratio_lines", "greater_than", "sandwich", "divisibility", "dutch_flatmates"],   # 70
	["clone", "thermo", "xv", "numbered_rooms", "quadruple", "diagonal"],   # 71
	["killer", "entropic", "couples", "frame", "axia", "girandola"],   # 72
	["killer", "german_whispers", "kropki", "skyscraper", "friendly", "knight"],   # 73
	["parity_regions", "lockout", "ratio_dots", "missing_digit", "even_odd", "diagonal"],   # 74
	["clone", "region_sum", "difference_dots", "little_killer", "forbidden_digit", "jigsaw"],   # 75
	["clone", "between", "couples", "sandwich", "prime_composite", "king"],   # 76
	["killer", "palindrome", "xv", "frame", "min_max", "jigsaw"],   # 77
	["parity_regions", "lockout", "greater_than", "battlefield", "pulse", "anti_diagonal"],   # 78
	["clone", "palindrome", "difference_dots", "xsum", "slingshot", "universal"],   # 79
	["killer", "slow_thermo", "ratio_dots", "numbered_rooms", "fortress", "center_dot"],   # 80
	["parity_regions", "modular", "difference_dots", "missing_digit", "divisibility", "anti_diagonal"],   # 81
	["parity_regions", "product_lines", "xv", "battlefield", "forbidden_digit", "knight"],   # 82
	["clone", "renban", "greater_than", "numbered_rooms", "friendly", "knight"],   # 83
	["killer", "thermo", "couples", "sandwich", "quadruple", "windoku"],   # 84
	["clone", "region_sum", "kropki", "frame", "prime_composite", "anti_diagonal"],   # 85
	["killer", "difference_lines", "difference_dots", "skyscraper", "vertex", "argyle"],   # 86
	["parity_regions", "german_whispers", "ratio_dots", "little_killer", "axia", "jigsaw"],   # 87
	["parity_regions", "dutch_whispers", "greater_than", "xsum", "index", "non_consecutive"],   # 88
	["killer", "between", "couples", "missing_digit", "min_max", "universal"],   # 89
	["clone", "difference_lines", "xv", "skyscraper", "even_odd", "king"],   # 90
	["killer", "product_lines", "ratio_dots", "xsum", "fortress", "center_dot"],   # 91
	["clone", "region_sum", "kropki", "sandwich", "prime_composite", "dutch_flatmates"],   # 92
	["parity_regions", "zipper", "kropki", "frame", "axia", "jigsaw"],   # 93
	["parity_regions", "renban", "xv", "numbered_rooms", "even_odd", "anti_diagonal"],   # 94
	["clone", "arrow", "couples", "little_killer", "divisibility", "diagonal"],   # 95
	["killer", "palindrome", "greater_than", "battlefield", "pulse", "asterisk"],   # 96
	["clone", "modular", "ratio_dots", "sandwich", "quadruple", "argyle"],   # 97
	["killer", "ratio_lines", "difference_dots", "skyscraper", "slingshot", "queen"],   # 98
	["parity_regions", "slow_thermo", "kropki", "little_killer", "vertex", "jigsaw"],   # 99
	["clone", "parity_lines", "xv", "missing_digit", "forbidden_digit", "diagonal"],   # 100
]
const TYPES_3 := [
	["clone", "double_arrow", "ratio_dots"],   # 1
	["parity_regions", "palindrome", "xsum"],   # 2
	["killer", "parity_lines", "index"],   # 3
	["clone", "ratio_lines", "queen"],   # 4
	["killer", "couples", "numbered_rooms"],   # 5
	["parity_regions", "xv", "vertex"],   # 6
	["killer", "ratio_dots", "girandola"],   # 7
	["parity_regions", "sandwich", "slingshot"],   # 8
	["clone", "missing_digit", "queen"],   # 9
	["killer", "quadruple", "anti_diagonal"],   # 10
	["modular", "sum_product_dots", "xsum"],   # 11
	["bishop", "kropki", "forbidden_digit"],   # 12
	["between", "greater_than", "non_consecutive"],   # 13
	["german_whispers", "little_killer", "axia"],   # 14
	["lockout", "sandwich", "center_dot"],   # 15
	["parity_lines", "vertex", "knight"],   # 16
	["kropki", "numbered_rooms", "prime_composite"],   # 17
	["couples", "little_killer", "anti_diagonal"],   # 18
	["sum_product_dots", "quadruple", "windoku"],   # 19
	["frame", "pulse", "diagonal"],   # 20
	["clone", "ratio_lines", "difference_dots"],   # 21
	["killer", "slow_thermo", "missing_digit"],   # 22
	["clone", "product_lines", "friendly"],   # 23
	["parity_regions", "modular", "king"],   # 24
	["killer", "xv", "frame"],   # 25
	["parity_regions", "couples", "forbidden_digit"],   # 26
	["clone", "kropki", "anti_diagonal"],   # 27
	["parity_regions", "little_killer", "pulse"],   # 28
	["killer", "numbered_rooms", "universal"],   # 29
	["clone", "vertex", "non_consecutive"],   # 30
	["palindrome", "difference_dots", "battlefield"],   # 31
	["nabner", "kropki", "friendly"],   # 32
	["parity_lines", "xv", "girandola"],   # 33
	["product_lines", "little_killer", "even_odd"],   # 34
	["double_arrow", "missing_digit", "queen"],   # 35
	["bishop", "fortress", "king"],   # 36
	["ratio_dots", "battlefield", "slingshot"],   # 37
	["couples", "numbered_rooms", "non_consecutive"],   # 38
	["difference_dots", "prime_composite", "windoku"],   # 39
	["frame", "divisibility", "dutch_flatmates"],   # 40
	["killer", "ten_lines", "xv"],   # 41
	["parity_regions", "region_sum", "little_killer"],   # 42
	["killer", "thermo", "slingshot"],   # 43
	["clone", "parity_lines", "universal"],   # 44
	["parity_regions", "couples", "xsum"],   # 45
	["killer", "couples", "even_odd"],   # 46
	["parity_regions", "ratio_dots", "jigsaw"],   # 47
	["clone", "missing_digit", "friendly"],   # 48
	["parity_regions", "sandwich", "universal"],   # 49
	["killer", "min_max", "asterisk"],   # 50
	["bishop", "kropki", "skyscraper"],   # 51
	["slow_thermo", "sum_product_dots", "even_odd"],   # 52
	["entropic", "couples", "diagonal"],   # 53
	["parity_lines", "little_killer", "fortress"],   # 54
	["arrow", "frame", "universal"],   # 55
	["difference_lines", "friendly", "non_consecutive"],   # 56
	["kropki", "numbered_rooms", "vertex"],   # 57
	["xv", "skyscraper", "jigsaw"],   # 58
	["difference_dots", "quadruple", "knight"],   # 59
	["battlefield", "min_max", "asterisk"],   # 60
	["parity_regions", "lockout", "difference_dots"],   # 61
	["clone", "german_whispers", "xsum"],   # 62
	["killer", "slow_thermo", "forbidden_digit"],   # 63
	["clone", "zipper", "king"],   # 64
	["killer", "xv", "xsum"],   # 65
	["parity_regions", "couples", "pulse"],   # 66
	["parity_regions", "ratio_dots", "universal"],   # 67
	["killer", "battlefield", "slingshot"],   # 68
	["clone", "missing_digit", "king"],   # 69
	["parity_regions", "divisibility", "knight"],   # 70
	["thermo", "ratio_dots", "numbered_rooms"],   # 71
	["dutch_whispers", "sum_product_dots", "axia"],   # 72
	["zipper", "xv", "asterisk"],   # 73
	["lockout", "missing_digit", "even_odd"],   # 74
	["region_sum", "little_killer", "king"],   # 75
	["slow_thermo", "prime_composite", "king"],   # 76
	["kropki", "frame", "min_max"],   # 77
	["greater_than", "battlefield", "anti_diagonal"],   # 78
	["difference_dots", "slingshot", "universal"],   # 79
	["numbered_rooms", "fortress", "center_dot"],   # 80
	["parity_regions", "modular", "difference_dots"],   # 81
	["parity_regions", "product_lines", "battlefield"],   # 82
	["clone", "renban", "friendly"],   # 83
	["killer", "thermo", "diagonal"],   # 84
	["clone", "greater_than", "frame"],   # 85
	["killer", "couples", "vertex"],   # 86
	["parity_regions", "ratio_dots", "queen"],   # 87
	["parity_regions", "xsum", "index"],   # 88
	["killer", "missing_digit", "universal"],   # 89
	["clone", "even_odd", "king"],   # 90
	["product_lines", "ratio_dots", "xsum"],   # 91
	["bishop", "kropki", "prime_composite"],   # 92
	["german_whispers", "xv", "jigsaw"],   # 93
	["renban", "numbered_rooms", "even_odd"],   # 94
	["arrow", "little_killer", "king"],   # 95
	["entropic", "pulse", "universal"],   # 96
	["ratio_dots", "sandwich", "quadruple"],   # 97
	["greater_than", "skyscraper", "girandola"],   # 98
	["kropki", "vertex", "king"],   # 99
	["missing_digit", "forbidden_digit", "diagonal"],   # 100
]
const TYPES_2 := [
	["clone", "double_arrow"],   # 1
	["parity_regions", "greater_than"],   # 2
	["killer", "skyscraper"],   # 3
	["clone", "prime_composite"],   # 4
	["killer", "jigsaw"],   # 5
	["product_lines", "xv"],   # 6
	["renban", "missing_digit"],   # 7
	["german_whispers", "slingshot"],   # 8
	["ten_lines", "argyle"],   # 9
	["xv", "frame"],   # 10
	["sum_product_dots", "even_odd"],   # 11
	["couples", "diagonal"],   # 12
	["skyscraper", "even_odd"],   # 13
	["little_killer", "queen"],   # 14
	["fortress", "center_dot"],   # 15
	["clone", "pill_arrow"],   # 16
	["killer", "greater_than"],   # 17
	["parity_regions", "little_killer"],   # 18
	["killer", "quadruple"],   # 19
	["parity_regions", "diagonal"],   # 20
	["arrow", "xv"],   # 21
	["slow_thermo", "missing_digit"],   # 22
	["product_lines", "friendly"],   # 23
	["thermo", "anti_diagonal"],   # 24
	["ratio_dots", "frame"],   # 25
	["couples", "forbidden_digit"],   # 26
	["kropki", "anti_diagonal"],   # 27
	["little_killer", "pulse"],   # 28
	["numbered_rooms", "universal"],   # 29
	["vertex", "non_consecutive"],   # 30
	["parity_regions", "palindrome"],   # 31
	["clone", "kropki"],   # 32
	["xv", "non_consecutive"],   # 33
	["parity_regions", "even_odd"],   # 34
	["clone", "jigsaw"],   # 35
	["bishop", "kropki"],   # 36
	["german_whispers", "battlefield"],   # 37
	["difference_lines", "forbidden_digit"],   # 38
	["pill_arrow", "windoku"],   # 39
	["couples", "frame"],   # 40
	["sum_product_dots", "quadruple"],   # 41
	["greater_than", "universal"],   # 42
	["sandwich", "slingshot"],   # 43
	["numbered_rooms", "knight"],   # 44
	["prime_composite", "diagonal"],   # 45
	["killer", "modular"],   # 46
	["parity_regions", "ratio_dots"],   # 47
	["clone", "missing_digit"],   # 48
	["parity_regions", "forbidden_digit"],   # 49
	["killer", "asterisk"],   # 50
	["between", "kropki"],   # 51
	["slow_thermo", "xsum"],   # 52
	["entropic", "prime_composite"],   # 53
	["parity_lines", "asterisk"],   # 54
	["clone", "slingshot"],   # 55
	["greater_than", "friendly"],   # 56
	["kropki", "diagonal"],   # 57
	["skyscraper", "divisibility"],   # 58
	["little_killer", "anti_diagonal"],   # 59
	["min_max", "knight"],   # 60
	["parity_regions", "lockout"],   # 61
	["clone", "couples"],   # 62
	["killer", "missing_digit"],   # 63
	["clone", "index"],   # 64
	["killer", "anti_diagonal"],   # 65
	["ten_lines", "couples"],   # 66
	["nabner", "skyscraper"],   # 67
	["difference_lines", "slingshot"],   # 68
	["arrow", "non_consecutive"],   # 69
	["greater_than", "sandwich"],   # 70
	["ratio_dots", "quadruple"],   # 71
	["couples", "girandola"],   # 72
	["skyscraper", "friendly"],   # 73
	["missing_digit", "diagonal"],   # 74
	["forbidden_digit", "king"],   # 75
	["clone", "between"],   # 76
	["killer", "xv"],   # 77
	["parity_regions", "battlefield"],   # 78
	["xsum", "slingshot"],   # 79
	["killer", "center_dot"],   # 80
	["pill_arrow", "couples"],   # 81
	["product_lines", "battlefield"],   # 82
	["renban", "friendly"],   # 83
	["entropic", "windoku"],   # 84
	["kropki", "frame"],   # 85
	["couples", "vertex"],   # 86
	["ratio_dots", "queen"],   # 87
	["xsum", "index"],   # 88
	["missing_digit", "universal"],   # 89
	["even_odd", "king"],   # 90
	["killer", "product_lines"],   # 91
	["kropki", "prime_composite"],   # 92
	["parity_regions", "frame"],   # 93
	["numbered_rooms", "even_odd"],   # 94
	["clone", "diagonal"],   # 95
	["entropic", "ratio_dots"],   # 96
	["lockout", "sandwich"],   # 97
	["ratio_lines", "slingshot"],   # 98
	["slow_thermo", "king"],   # 99
	["xv", "missing_digit"],   # 100
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
	return Lang.t("%s: %s") % [Lang.t(info.get("name", r.capitalize())), Lang.t(short)]


static func rules_intro(pz: Puzzle) -> String:
	return Lang.t("%s rules apply, plus these %d rules at once:") % [Lang.t("Jigsaw Sudoku" if pz.has_rule("jigsaw") else "Normal Sudoku"), pz.rules.size()]


const RULES_NOTE := "Clues are only where shown: a missing dot, sign or line says nothing."


## The Ultimate variants: id -> rules per type.
const VARIANTS := ["ultimate", "ultimate_6", "ultimate_3", "ultimate_2"]


static func is_ultimate(id: String) -> bool:
	return id in VARIANTS


## The types of an Ultimate variant (the 9-rule TYPES for "ultimate" and anything unknown).
static func types(variant: String) -> Array:
	match variant:
		"ultimate_6": return TYPES_6
		"ultimate_3": return TYPES_3
		"ultimate_2": return TYPES_2
	return TYPES


## The Ultimate variant whose types have this many rules.
static func variant_for(count: int) -> String:
	return "ultimate" if count >= 9 else "ultimate_%d" % count


static func rules_of(type: int, variant := "ultimate") -> Array:
	var list := types(variant)
	return list[clampi(type, 1, list.size()) - 1].duplicate()


## True if both lists hold the same rules (in any order).
static func same_rules(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for r in a:
		if not b.has(r):
			return false
	return true


## The type number of a rule list in the variant with that many rules, 0 if it isn't one of its types.
static func type_of(rules: Array) -> int:
	var list := types(variant_for(rules.size()))
	for i in list.size():
		if same_rules(list[i], rules):
			return i + 1
	return 0


## The rules card: normal Sudoku plus each of the puzzle's rules, one line each.
static func rules_text(pz: Puzzle) -> String:
	var lines: Array = [rules_intro(pz)]
	for r in pz.rules:
		lines.append("•  " + rule_line(r))
	lines.append(Lang.t(RULES_NOTE))
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
