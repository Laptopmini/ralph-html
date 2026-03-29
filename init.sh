#!/bin/bash

# Initialize the npm project
npm init -y && \
npm install -D @playwright/test jest @biomejs/biome && \
npm pkg set scripts.test="jest && playwright test" \
            scripts.backpressure="sh .github/scripts/backpressure.sh" \
            scripts.ralph="sh .github/scripts/ralph.sh" \
            scripts.lint="biome lint --write ." \
            scripts.format="biome format --write ." \

# Move the init PRD to the root
mv .prds/init.md PRD.md

# Self destruct
npm pkg delete scripts.init || exit 1
rm --  "$( readlink -f -- "${BASH_SOURCE[0]:-$0}" 2> '/dev/null'; )"; || exit 1

# Instruct to run the first ralph loop, which should be the starting point for the project (html, react, nextjs)
echo "🚀 Run 'npm run ralph' to start the Ralph Loop."