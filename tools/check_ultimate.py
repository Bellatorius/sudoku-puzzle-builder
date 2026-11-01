"""Checks the latest Ultimate builds and tops up what is missing (run by .github/workflows/check_ultimate.yml).

Each Ultimate pack (VARIANTS: ultimate = 9 rules, ultimate_6 / _3 / _2) is checked on its own. Its "campaign" = the
latest run titled "<variant> full x<N>" plus that variant's top-up runs after it. When none of its runs is still
going, every job (level x type range) is checked: the newest part of that job across the campaign counts. Jobs that
failed or built fewer puzzles than asked are started again as one top-up run ("<variant> topup-N"): each resumes from
its newest part and tries fresh seeds. At most MAX_TOPUPS top-ups per campaign; after that the summary lists what is
still short. Fail checks (so no runner time is wasted): a job that was in the last top-up and gained nothing is not
tried again, and a campaign whose full run built nothing at all (e.g. the smoke check failed) gets no top-ups.
"""
import json
import os
import re
import subprocess
import sys
import tempfile

MAX_TOPUPS = 3
VARIANTS = ["ultimate", "ultimate_6", "ultimate_3", "ultimate_2"]
LEVELS = ["beginner", "easy", "medium", "hard", "expert", "master"]
RANGES = ["%d-%d" % (a, a + 4) for a in range(1, 101, 5)]
WORKFLOW = "build_ultimate.yml"


def gh(*args):
    return subprocess.run(["gh"] + list(args), check=True, capture_output=True, text=True).stdout


def summary(text):
    print(text)
    path = os.environ.get("GITHUB_STEP_SUMMARY")
    if path:
        with open(path, "a") as f:
            f.write(text + "\n")


def check(variant, runs):
    # run titles are "<variant> <tag> x<per>" (runs from before Ultimate 6 / 3 / 2 are "ultimate full x5" too)
    runs = [r for r in runs if r["displayTitle"].split(" ")[0] == variant]
    full = [i for i, r in enumerate(runs) if re.search(r"\bfull\b", r["displayTitle"])]
    if not full:
        summary("%s: no full build yet." % variant)
        return
    campaign = runs[full[-1]:]
    if any(r["status"] != "completed" for r in campaign):
        summary("%s: still running: %s" % (variant, ", ".join(str(r["databaseId"]) for r in campaign if r["status"] != "completed")))
        return
    per = int(re.search(r"x(\d+)", campaign[0]["displayTitle"]).group(1))
    topups = len(campaign) - 1
    fetch = "python tools/fetch_builder.py " + " ".join(str(r["databaseId"]) for r in campaign)

    best = {}   # "level:range" -> (run id, puzzle count) from the newest run that has its part
    before = {}  # the same, before the newest run of the campaign (to see whether its top-up gained anything)
    tmp = tempfile.mkdtemp()
    art_re = re.compile(r"%s_([a-z]+)_(\d+-\d+)$" % re.escape(variant))
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
        for rg in RANGES:
            a, b = map(int, rg.split("-"))
            want = per * (b - a + 1)
            rid, n = best.get(l + ":" + rg, ("", 0))
            per_level[l] += n
            if n < want:
                short.append((l, rg, rid, want - n))
    summary("%s: campaign %s (+%d top-ups), %d per level wanted: %s" % (
        variant, campaign[0]["databaseId"], topups, per * 100, ", ".join("%s %d" % (l, per_level[l]) for l in LEVELS)))
    if not short:
        summary("%s: all full. Fetch with: %s" % (variant, fetch))
        return
    summary("%s: short: %s" % (variant, ", ".join("%s %s (-%d)" % (l, rg, m) for l, rg, _, m in short)))
    if not any(n for _, n in best.values()):
        summary("%s: the build made no puzzles at all (smoke check or setup failed?): no top-ups. Read the run log." % variant)
        return
    if topups > 0:
        stuck = [(l, rg) for l, rg, _, _ in short if best.get(l + ":" + rg, ("", 0))[1] <= before.get(l + ":" + rg, ("", 0))[1]]
        if stuck:
            summary("%s: no progress in the last top-up, not tried again: %s" % (variant, ", ".join("%s %s" % j for j in stuck)))
        short = [j for j in short if (j[0], j[1]) not in stuck]
        if not short:
            summary("%s: nothing left worth a top-up. Fetch what there is with: %s" % (variant, fetch))
            return
    if topups >= MAX_TOPUPS:
        summary("%s: no more top-ups (%d done). Fetch what there is with: %s" % (variant, topups, fetch))
        return
    jobs = ["%s:%s:%s" % (l, rg, rid) if rid else "%s:%s" % (l, rg) for l, rg, rid, _ in short]
    n = topups + 1
    gh("workflow", "run", WORKFLOW, "-f", "variant=" + variant, "-f", "jobs=" + json.dumps(jobs),
       "-f", "per_type=%d" % per, "-f", "first_round=%d" % (2 * n), "-f", "tag=topup-%d" % n)
    summary("%s: started topup-%d for %d jobs." % (variant, n, len(jobs)))


def main():
    runs = json.loads(gh("run", "list", "--workflow", WORKFLOW, "-L", "200", "--json", "databaseId,status,displayTitle,createdAt"))
    runs.sort(key=lambda r: r["createdAt"])
    for v in VARIANTS:
        check(v, runs)


if __name__ == "__main__":
    sys.exit(main())
