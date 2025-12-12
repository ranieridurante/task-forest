import globals from 'globals'
import pluginJs from '@eslint/js'
import tseslint from 'typescript-eslint'
import pluginReact from 'eslint-plugin-react'
import stylistic from '@stylistic/eslint-plugin'

export default [
  { files: ['**/*.{js,mjs,cjs,ts,jsx,tsx}'] },
  { languageOptions: { globals: globals.browser } },
  pluginJs.configs.recommended,
  stylistic.configs['recommended-flat'],
  ...tseslint.configs.recommended,
  pluginReact.configs.flat.recommended,
  {
    rules: {
      '@typescript-eslint/no-explicit-any': ['warn'], // https://typescript-eslint.io/rules/no-explicit-any/
      '@typescript-eslint/consistent-type-imports': 'error', // https://typescript-eslint.io/rules/consistent-type-imports
      '@typescript-eslint/no-unused-vars': ['error', { // https://typescript-eslint.io/rules/no-unused-vars
        caughtErrors: 'none'
      }],
      'func-style': [ // https://eslint.org/docs/latest/rules/func-style
        'error',
        'expression',
        { allowArrowFunctions: true },
      ],
      'no-plusplus': ['error'],
      '@stylistic/comma-dangle': ['error', 'only-multiline'], // https://eslint.style/rules/default/comma-dangle
      '@stylistic/space-before-function-paren': ['error', 'always'], // https://eslint.style/rules/default/space-before-function-paren
      '@stylistic/quote-props': ['error', 'as-needed'], // https://eslint.style/rules/default/quote-props
      '@stylistic/brace-style': ['error', '1tbs'], // https://eslint.style/rules/default/brace-style
      '@stylistic/operator-linebreak': ['error', 'after'], // https://eslint.style/rules/default/operator-linebreak
      '@stylistic/arrow-parens': ['error', 'always'], // https://eslint.style/rules/default/arrow-parens
      '@stylistic/jsx-first-prop-new-line': ['error', 'multiline'], // https://eslint.style/rules/default/jsx-first-prop-new-line
      '@stylistic/jsx-max-props-per-line': ['error', { maximum: 1, when: 'always' }], // https://eslint.style/rules/default/jsx-max-props-per-line
    },
  },
]
