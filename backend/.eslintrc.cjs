/** @type {import('eslint').Linter.Config} */
module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 2022,
    sourceType: 'module',
    project: './tsconfig.json',
  },
  plugins: ['@typescript-eslint', 'import'],
  ignorePatterns: ['dist', 'node_modules'],
  rules: {
    '@typescript-eslint/no-explicit-any': 'error',
    '@typescript-eslint/no-non-null-assertion': 'error',
    '@typescript-eslint/no-floating-promises': 'error',
    'import/no-cycle': 'error',
    'no-console': 'error',
    'no-restricted-syntax': [
      'error',
      {
        selector:
          'MemberExpression[object.name="process"][property.name="env"]',
        message: 'Read configuration from src/config only.',
      },
    ],
  },
  overrides: [
    {
      files: ['src/config/**/*.ts', 'scripts/**/*.ts', 'src/cli/**/*.ts'],
      rules: { 'no-restricted-syntax': 'off', 'no-console': 'off' },
    },
    {
      files: ['test/**/*.ts'],
      rules: {
        'no-restricted-syntax': 'off',
        'no-console': 'off',
        '@typescript-eslint/no-floating-promises': 'off',
      },
    },
  ],
};
