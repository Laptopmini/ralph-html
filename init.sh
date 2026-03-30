#!/bin/bash
set -euo pipefail

if ! command -v npm &> /dev/null; then
    echo "Error: NPM is not installed."
    exit 1
fi

if [ -f package.json ]; then
    echo "Error: package.json already exists. Exiting..."
    exit 1
fi

# Initialize the npm project
npm init -y && \
npm install -D @playwright/test jest @types/jest @biomejs/biome typescript ts-node @swc/jest @swc/core && \
npm pkg set scripts.test="jest && playwright test" \
            scripts.backpressure="sh .github/scripts/backpressure.sh" \
            scripts.ralph="sh .github/scripts/ralph.sh" \
            scripts.lint="biome lint --write ." \
            scripts.format="biome format --write ." \
            engines.node=">=24.14.1" \
            engines.npm=">=11.11.0"

# Install the playwright dependencies
npx playwright install chromium

# Move the init PRD to the root
mv .prds/init.md PRD.md

# Execute initial ralph loop
sh .github/scripts/ralph.sh

echo "🚀 Done!"

# Self destruct
rm -- "${BASH_SOURCE[0]:-$0}"
