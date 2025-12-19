#!/bin/bash

set -e

LCOV_INFO="coverage/lcov.info"
HTML_REPORT="coverage/html"

rm -rf coverage
mkdir -p coverage

echo "🧪 Running tests with coverage..."
flutter test --coverage packages/offline_first_sync_drift

if [ ! -f "$LCOV_INFO" ]; then
    echo "❌ No coverage file found"
    exit 1
fi

echo "🧮 Calculating coverage percentage..."

total_lines=$(grep -o "LF:[0-9]*" "$LCOV_INFO" | cut -d: -f2 | awk '{s+=$1} END {print s}')
covered_lines=$(grep -o "LH:[0-9]*" "$LCOV_INFO" | cut -d: -f2 | awk '{s+=$1} END {print s}')

if [ -z "$total_lines" ] || [ "$total_lines" -eq 0 ]; then
    percent=0
else
    percent=$(awk "BEGIN {printf \"%.1f\", $covered_lines * 100 / $total_lines}")
fi

echo "📈 Total Coverage: $percent% ($covered_lines/$total_lines lines)"

echo "📝 Updating README.md..."

if (( $(echo "$percent < 50" | bc -l) )); then
  color="red"
elif (( $(echo "$percent < 80" | bc -l) )); then
  color="yellow"
else
  color="brightgreen"
fi

new_badge="![coverage](https://img.shields.io/badge/coverage-${percent}%25-${color})"

if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|^!\[coverage\].*|$new_badge|" README.md
    sed -i '' "s|^!\[coverage\].*|$new_badge|" README.ru.md
else
    sed -i "s|^!\[coverage\].*|$new_badge|" README.md
    sed -i "s|^!\[coverage\].*|$new_badge|" README.ru.md
fi

echo "✅ README.md and README.ru.md updated with coverage: $percent%"

if ! command -v genhtml &> /dev/null; then
    echo "⚠️  'genhtml' is not installed. Skipping HTML report generation."
    echo "👉 Install it using: brew install lcov"
else
    echo "📊 Generating HTML report..."
    genhtml "$LCOV_INFO" -o "$HTML_REPORT" --ignore-errors empty
    echo "🎉 Report generated at $HTML_REPORT/index.html"
    open "$HTML_REPORT/index.html"
fi
