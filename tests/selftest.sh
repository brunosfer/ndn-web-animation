#!/bin/bash
#
# NDN Strategy Lab self-test
#
# Copyright 2026 Bruno Fernandes <bruno.fernandes@tum.de>
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0. See LICENSE and NOTICE.
#
# Loads web/index.html#selftest in headless Chrome or Chromium, which runs every
# profile with and without NLSR and prints the measurements as JSON, then prints
# one summary line per run. Usage: tests/selftest.sh [output.json]

set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:-}"
browser="$(command -v google-chrome || command -v chromium || command -v chromium-browser || true)"
if [ -z "$browser" ]; then
  echo "No Chrome or Chromium found." >&2
  exit 1
fi

dom="$(mktemp)"
trap 'rm -f "$dom"' EXIT
timeout 300 "$browser" --headless=new --disable-gpu --no-sandbox --virtual-time-budget=1000 \
  --dump-dom "file://$repo/web/index.html#selftest" > "$dom" 2>/dev/null

python3 - "$dom" "$out" <<'EOF'
import html, json, re, sys

page = open(sys.argv[1]).read()
match = re.search(r'<pre id="selftest">(.*?)</pre>', page, re.S)
if not match:
    sys.exit("The page produced no self-test output.")
data = json.loads(html.unescape(match.group(1)))
if sys.argv[2]:
    with open(sys.argv[2], "w") as f:
        json.dump(data, f, indent=1)

for profile, runs in data.items():
    for variant in ("without", "with"):
        for m in runs[variant]:
            if m["app"] == "transfer":
                detail = "goodput c1 {:.2f} c2 {:.2f} Mbit/s, timeouts {}".format(m["goodput"][0], m["goodput"][1], m["timeouts"])
            else:
                detail = "delivered {}/{} (cache {}), lost {}, retransmissions {}".format(
                    m["prod"] + m["cache"], m["total"], m["cache"], m["lost"], m["retx"])
            print("{:15} {:14} {:7} {}, frames {} + {} NLSR, duplicates {}".format(
                profile, m["strategy"], m["routing"], detail, m["dataFrames"], m["nlsrFrames"], m["dupI"]))
EOF
