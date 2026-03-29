# PRD: Project Infrastructure & Tooling Setup

## Objective

Establish and verify the baseline configuration for Jest (unit testing), 
and Playwright (E2E testing). The result should 
be a reusable project skeleton that future PRDs can build on.

## Context

- Dependencies are already installed via npm. Do not modify `package.json` 
  dependencies. Only scripts and devDependencies entries may be added.
- No application source code exists yet. Do not create anything under `src/`.

## Constraints

- Only modify configuration files and the `tests/` directory.
- All test files must pass on first execution.
- Do not install additional packages.

## Tasks

- [ ] Configure Jest. Create a `jest.config.js` for a standard Node/JS 
  environment. Add a `"test:unit"` script to `package.json` that runs Jest. 
  Create a sanity test at `tests/unit/setup.test.js` with a single passing 
  assertion (`expect(1 + 1).toBe(2)`). `[test: npx jest]`

- [ ] Configure Playwright. Create a `playwright.config.ts` set to run 
  headless Chromium, with `baseURL` set to `http://localhost:3000` as a 
  placeholder. Add a `"test:e2e"` script to `package.json` that runs 
  Playwright. Create a sanity test at `tests/e2e/setup.spec.ts` that 
  navigates to `about:blank` and asserts the page title is an empty string. `[test: npx playwright test]`

- [ ] Wire up a root test script. Add a `"test"` script to `package.json` 
  that runs `test:unit` and `test:e2e` sequentially. Verify it exits 
  cleanly.