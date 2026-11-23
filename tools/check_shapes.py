"""Starts, checks and tops up the GridShapes pack builds (run by .github/workflows/check_shapes.yml every 30 minutes).

For each variant in VARIANTS:
- no "<variant> full" run yet: start one (SHARDS[variant] jobs per level, 500 / shards puzzles each);
- its campaign (the latest full run + the top-ups after it) still running: report it;
- campaign finished: count every job's newest part (level x shard). Jobs that failed or built fewer puzzles than
  asked are started again as one top-up run ("<variant> topup-N"), each resuming from its newest part with fresh
  seeds. At most MAX_TOPUPS top-ups; a job that gained nothing in the last top-up isn't tried again; a campaign
  whose full run built nothing at all (the smoke check failed) gets no top-ups.

The run summary lists every variant's counts and what failed. The check run itself FAILS (red, so GitHub emails the
repo owner) whenever a variant has given up: smoke check failed, or still short after its top-ups. When every
variant is finished (full, or given up), the summary prints the fetch command and this workflow disables itself.
"""
import json
import os
import re
import subprocess
import sys
import tempfile

MAX_TOPUPS = 3
PACK = {"tiny": 100}   # puzzles per level (default 500; a 4x4 has too few different puzzles for 500)
LEVELS = ["beginner", "easy", "medium", "hard", "expert", "master"]
# jobs per level (each builds PACK / shards puzzles); more for the slow ones so no job nears the 6 h limit
SHARDS = {
    "tiny": 1, "giant_12": 1, "giant_16": 5, "twin": 1, "dual": 1, "triple": 1, "gattai": 1, "quad": 2,
    "windmill": 2, "flower": 1, "samurai": 2, "samurai_x": 2, "jigsaw_samurai": 5, "six_grid": 4,
    "decathlon": 20, "circular": 1, "hexagonal": 1, "triangular": 1, "cube": 1,
}
VARIANTS = list(SHARDS)
WORKFLOW = "build_shapes.yml"
SELF = "check_shapes.yml"


def gh(*args):
    return subprocess.run(["gh"] + list(args), check=True, capture_output=True, text=True).stdout


def summary(text):
    print(text)
    path = os.environ.get("GITHUB_STEP_SUMMARY")
    if path:
        with open(path, "a") as f:
            f.write(text + "  \n")


def pack(v):
    return PACK.get(v, 500)


def per_job(v):
    return pack(v) // SHARDS[v]


def check(variant, runs):
    """Returns "done", "failed" (given up) or "busy"."""
    runs = [r for r in runs if r["displayTitle"].split(" ")[0] == variant]
    full = [i for i, r in enumerate(runs) if re.search(r"\bfull\b", r["displayTitle"])]
    if not full:
        gh("workflow", "run", WORKFLOW, "-f", "variant=" + variant, "-f", "shards=%d" % SHARDS[variant],
           "-f", "per=%d" % per_job(variant), "-f", "tag=full")
        summary("%s: started the full build (%d jobs per level)." % (variant, SHARDS[variant]))
        return "busy"
    campaign = runs[full[-1]:]
    if any(r["status"] != "completed" for r in campaign):
        summary("%s: running: %s" % (variant, ", ".join(str(r["databaseId"]) for r in campaign if r["status"] != "completed")))
        return "busy"
    per = int(re.search(r"x(\d+)", campaign[0]["displayTitle"]).group(1))
    shards = pack(variant) // per
    topups = len(campaign) - 1

    best = {}    # "level:shard" -> (run id, count) from the newest run that has that part
    before = {}
    tmp = tempfile.mkdtemp()
    art_re = re.compile(r"%s_([a-z]+)_s(\d+)$" % re.escape(variant))
    for r in campaign:
        rid = str(r["databaseId"])
        if r is campaign[-1]:
            before = dict(best)
        d = os.path.join(tmp, rid)
        subprocess.run(["gh", "run", "download", rid, "-D", d], capture_output=True)
        if not os.path.isdir(d):
            continue
        for art in os.listdir(d):
            m = art_re.match(art)
            if not m:
                continue
            n = 0
            for fn in os.listdir(os.path.join(d, art)):
                with open(os.path.join(d, art, fn)) as f:
                    n += len(json.load(f).get("puzzles", []))
            best[m.group(1) + ":" + m.group(2)] = (rid, n)

    short = []
    per_level = {l: 0 for l in LEVELS}
    for l in LEVELS:
        for s in range(1, shards + 1):
            rid, n = best.get("%s:%d" % (l, s), ("", 0))
            per_level[l] += n
            if n < per:
                short.append((l, s, rid, per - n))
    summary("%s: campaign %s (+%d top-ups): %s" % (variant, campaign[0]["databaseId"], topups,
                                                   ", ".join("%s %d" % (l, per_level[l]) for l in LEVELS)))
    if not short:
        summary("%s: all full." % variant)
        return "done"
    summary("%s: short: %s" % (variant, ", ".join("%s s%d (-%d)" % (l, s, m) for l, s, _, m in short)))
    if not any(n for _, n in best.values()):
        summary("**%s: FAILED: the build made no puzzles (smoke check or setup failed). Read run %s.**" % (variant, campaign[0]["databaseId"]))
        return "failed"
    if topups > 0:
        stuck = [(l, s) for l, s, _, _ in short if best.get("%s:%d" % (l, s), ("", 0))[1] <= before.get("%s:%d" % (l, s), ("", 0))[1]]
        if stuck:
            summary("%s: no progress in the last top-up, not tried again: %s" % (variant, ", ".join("%s s%d" % j for j in stuck)))
        short = [j for j in short if (j[0], j[1]) not in stuck]
        if not short:
            summary("**%s: FAILED: still short and nothing left worth a top-up.**" % variant)
            return "failed"
    if topups >= MAX_TOPUPS:
        summary("**%s: FAILED: still short after %d top-ups.**" % (variant, topups))
        return "failed"
    jobs = ["%s:%d:%s" % (l, s, rid) if rid else "%s:%d" % (l, s) for l, s, rid, _ in short]
    n = topups + 1
    gh("workflow", "run", WORKFLOW, "-f", "variant=" + variant, "-f", "jobs=" + json.dumps(jobs),
       "-f", "per=%d" % per, "-f", "first_round=%d" % n, "-f", "tag=topup-%d" % n)
    summary("%s: started topup-%d for %d jobs." % (variant, n, len(jobs)))
    return "busy"


def main():
    runs = json.loads(gh("run", "list", "--workflow", WORKFLOW, "-L", "500", "--json", "databaseId,status,displayTitle,createdAt"))
    runs.sort(key=lambda r: r["createdAt"])
    states = {}
    for v in VARIANTS:
        try:
            states[v] = check(v, runs)
        except Exception as e:   # one variant's trouble must not stop the others
            summary("**%s: check error: %s**" % (v, e))
            states[v] = "busy"
    failed = [v for v, s in states.items() if s == "failed"]
    if all(s != "busy" for s in states.values()):
        campaigns = []
        for v in VARIANTS:
            mine = [r for r in runs if r["displayTitle"].split(" ")[0] == v]
            full = [i for i, r in enumerate(mine) if re.search(r"\bfull\b", r["displayTitle"])]
            campaigns += [str(r["databaseId"]) for r in mine[full[-1]:]] if full else []
        summary("ALL FINISHED. Fetch with: python tools/fetch_builder.py " + " ".join(campaigns))
        gh("workflow", "disable", SELF)
        summary("This check is now switched off (enable it again to check new builds).")
    if failed:
        summary("**Failed variants: %s**" % ", ".join(failed))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
