Implemented second task: Jest configuration.

- Created `jest.config.js` using `@swc/jest` transform, `node` test environment, and `testMatch` scoped to `**/tests/unit/**/*.test.ts` to avoid picking up Playwright `.spec.ts` files.
- Added `"test:unit": "jest"` script to `package.json`.
- Created `tests/unit/setup.test.ts` with a single `expect(1 + 1).toBe(2)` assertion.
- `package.json` uses `"type": "commonjs"` so `jest.config.js` (CommonJS format with `module.exports`) is correct.
- Validation command: `npx jest`
- If `@swc/jest` transform fails to handle `.ts`, ensure `@swc/core` is present (it is in devDependencies). If `testMatch` is too narrow, widen it. Watch for any module resolution issues due to NodeNext in tsconfig vs Jest's own transform.
