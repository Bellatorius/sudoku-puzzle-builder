"""Checks the latest Ultimate build and tops up what is missing (run by .github/workflows/check_ultimate.yml).

A "campaign" = the latest run tagged "full" plus the top-up runs after it. When none of its runs is still
going, every job (level x type range) is checked: the newest part of that job across the campaign counts. Jobs that
failed or built fewer puzzles than asked are started again as one top-up run ("ultimate topup-N"): each resumes from
its newest part and tries fresh seeds. At most MAX_TOPUPS top-ups; after that the summary lists what is still short.
"""
import json
import os
import re
import subprocess
import sys
import tempfile

MAX_TOPUPS = 3
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


def main():
    runs = json.loads(gh("run", "list", "--workflow", WORKFLOW, "-L", "50", "--json", "databaseId,status,displayTitle,createdAt"))
    runs.sort(key=lambda r: r["createdAt"])
    full = [i for i, r in enumerate(runs) if re.search(r"\bfull\b", r["displayTitle"])]
    if not full:
        summary("No full Ultimate build yet.")
        return
    campaign = runs[full[-1]:]
    if any(r["status"] != "completed" for r in campaign):
        summary("Ultimate build still running: " + ", ".join(str(r["databaseId"]) for r in campaign if r["status"] != "completed"))
        return
    per = int(re.search(r"x(\d+)", campaign[0]["displayTitle"]).group(1))
    topups = len(campaign) - 1

    best = {}   # "level:range" -> (run id, puzzle count) from the newest run that has its part
    tmp = tempfile.mkdtemp()
    for r in campaign:
        rid = str(r["databaseId"])
        d = os.path.join(tmp, rid)
        subprocess.run(["gh", "run", "download", rid, "-D", d], capture_output=True)
        if not os.path.isdir(d):
            continue
        for art in os.listdir(d):
            m = re.match(r"ultimate_([a-z]+)_(\d+-\d+)$", art)
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
    summary("Campaign %s (+%d top-ups), %d per level wanted: %s" % (
        campaign[0]["databaseId"], topups, per * 100, ", ".join("%s %d" % (l, per_level[l]) for l in LEVELS)))
    if not short:
        summary("All full. Fetch with: python tools/fetch_builder.py " + " ".join(str(r["databaseId"]) for r in campaign))
        return
    summary("Short: " + ", ".join("%s %s (-%d)" % (l, rg, m) for l, rg, _, m in short))
    if topups >= MAX_TOPUPS:
        summary("No more top-ups (%d done). Fetch what there is with: python tools/fetch_builder.py %s" % (
            topups, " ".join(str(r["databaseId"]) for r in campaign)))
        return
    jobs = ["%s:%s:%s" % (l, rg, rid) if rid else "%s:%s" % (l, rg) for l, rg, rid, _ in short]
    n = topups + 1
    gh("workflow", "run", WORKFLOW, "-f", "jobs=" + json.dumps(jobs), "-f", "per_type=%d" % per,
       "-f", "first_round=%d" % (2 * n), "-f", "tag=topup-%d" % n)
    summary("Started topup-%d for %d jobs." % (n, len(jobs)))


if __name__ == "__main__":
    sys.exit(main())
