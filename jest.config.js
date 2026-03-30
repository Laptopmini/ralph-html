/** @type {import('jest').Config} */
const config = {
  transform: {
    "^.+\\.(t|j)sx?$": "@swc/jest",
  },
  testEnvironment: "node",
  testMatch: ["**/tests/unit/**/*.test.ts"],
};

module.exports = config;
