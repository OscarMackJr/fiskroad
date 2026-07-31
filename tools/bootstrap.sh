#!/usr/bin/env bash
# Clone (or refresh) every Fiskroad member repository into workspace/.
# workspace/ is gitignored: the member repos are never submodules or
# subtrees of Fiskroad, only neighbours in one directory.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WS="$ROOT/workspace"
mkdir -p "$WS"

# Minimal YAML read: name/url/branch triples from .repos.yml.
names=($(grep -E '^\s+- name:' "$ROOT/.repos.yml" | sed 's/.*name: *//'))
urls=($(grep -E '^\s+url:' "$ROOT/.repos.yml" | sed 's/.*url: *//' | sed 's/ *#.*//'))
branches=($(grep -E '^\s+branch:' "$ROOT/.repos.yml" | sed 's/.*branch: *//'))

for i in "${!names[@]}"; do
  name="${names[$i]}"; url="${urls[$i]}"; branch="${branches[$i]}"
  target="$WS/$name"
  if [ -d "$target/.git" ]; then
    echo "== $name: fetching"
    git -C "$target" fetch --all --prune
  else
    echo "== $name: cloning"
    git clone --branch "$branch" "$url" "$target"
  fi
done

echo
echo "Workspace ready at $WS"
echo "Member repos are independent: commit and open PRs in each one separately."
