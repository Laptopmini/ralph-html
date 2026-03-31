# ralph-node-base

A fork of [ralph-node](https://github.com/Laptopmini/ralph-node) that has been initialized by running the bootstrap PRD. Save some tokens by using this as a starting point, or just do it yourself!

- **PRDs:** [View all Product Requirements Documents](/.prds)
- **TDD:** [View all backpressure tests](/tests)
- **Ralph Loop:** [View latest Ralph execution](/.ralph.log)

Fork this repo and drop in a new `PRD.md` to start building something with the loop already bootstrapped.

For full documentation on how the Ralph Loop works and how to use these repos, see the [original ralph-node README](https://github.com/Laptopmini/ralph-node#readme).

## Changelog

- **TypeScript** — `tsconfig.json` with ES2022 target, NodeNext modules, strict mode, and `dist/` output
- **Jest** — `jest.config.js` with `@swc/jest` transform scoped to unit tests, plus a sanity test
- **Playwright** — `playwright.config.ts` targeting Chromium at `localhost:3000`, plus a sanity E2E test
- **Root test script** — `npm test` wired to run unit then E2E tests sequentially

## Stack

| Tool | Role |
|------|------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | Default AI engine |
| [OpenCode](https://opencode.ai/docs) | Alternative AI engine |
| [Jest](https://jestjs.io/) | Unit testing |
| [Playwright](https://playwright.dev/) | E2E testing |
| [Biome](https://biomejs.dev/) | Linting and formatting |

## License

Apache 2.0
