#!/usr/bin/env bash
# Install the QA kit into a Flutter project.
# Usage: ./scripts/install.sh <flutter_project_dir> [package_name]
set -euo pipefail
KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:?Usage: install.sh <flutter_project_dir> [package_name]}"
[ -f "$TARGET/pubspec.yaml" ] || { echo "No pubspec.yaml in $TARGET"; exit 1; }
PKG="${2:-$(grep -m1 '^name:' "$TARGET/pubspec.yaml" | awk '{print $2}')}"
echo "Installing QA kit into $TARGET (package: $PKG)"

copy_no_overwrite() {  # src_dir dest_dir
  (cd "$1" && find . -type f) | while read -r f; do
    if [ -e "$2/$f" ]; then echo "  skip (exists): $2/$f"
    else mkdir -p "$(dirname "$2/$f")"; cp "$1/$f" "$2/$f"; echo "  added: $2/$f"; fi
  done
}

for d in scripts test integration_test qa .github; do copy_no_overwrite "$KIT/$d" "$TARGET/$d"; done
copy_no_overwrite "$KIT/reference/lib" "$TARGET/lib"
for f in AGENTS.md CLAUDE.md; do [ -e "$TARGET/$f" ] || cp "$KIT/$f" "$TARGET/$f"; done

# Replace placeholder package name in Dart imports
grep -rl 'package:steelforce_app/' "$TARGET/test" "$TARGET/integration_test" "$TARGET/lib" 2>/dev/null \
  | xargs -r sed -i.bak "s#package:steelforce_app/#package:$PKG/#g"
find "$TARGET" -name '*.bak' -delete

chmod +x "$TARGET/scripts/"*.sh
grep -q '^reports/' "$TARGET/.gitignore" 2>/dev/null || printf '\nreports/\ncoverage/\n' >> "$TARGET/.gitignore"

echo; echo "Checking dev dependencies:"
for dep in flutter_bloc equatable bloc_test mocktail integration_test; do
  grep -qE "^\s+$dep:" "$TARGET/pubspec.yaml" && echo "  ok   $dep" || echo "  MISSING $dep (see README.md)"
done
echo; echo "Done. Next: cd $TARGET && ./scripts/qa_agent.sh doctor"
