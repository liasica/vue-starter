#!/usr/bin/env bash

set -euo pipefail

project_name="${1:-}"
style_solution="${2:-}"
working_directory="$(pwd)"
marker_file="$(mktemp -t vue-starter-install.XXXXXX)"

cleanup() {
  if [[ -w /dev/tty ]]; then
    printf '\033[?25h' > /dev/tty
  fi

  rm -f "$marker_file"
}

trap cleanup EXIT

normalize_style_solution() {
  local normalized_value

  normalized_value="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"

  case "$normalized_value" in
    '')
      printf '\n'
      ;;
    unocss|uno)
      printf 'unocss\n'
      ;;
    tailwind|tailwindcss)
      printf 'tailwind\n'
      ;;
    *)
      printf 'unsupported\n'
      ;;
  esac
}

select_style_solution() {
  local prompt selected_index key escape_sequence line_count
  local selected_label first_marker second_marker
  local -a option_labels option_values

  if [[ ! -r /dev/tty || ! -w /dev/tty ]]; then
    echo 'Interactive style selection requires a terminal. Pass the style as the second argument: unocss or tailwind.' >&2
    return 1
  fi

  prompt='Use CSS solution?'
  option_labels=('UnoCSS' 'Tailwind CSS')
  option_values=('unocss' 'tailwind')
  selected_index=0
  line_count=5

  while true; do
    printf '\033[?25l' > /dev/tty

    if (( selected_index == 0 )); then
      first_marker='●'
      second_marker='○'
    else
      first_marker='○'
      second_marker='●'
    fi

    printf '┌  Vue Starter\n' > /dev/tty
    printf '│\n' > /dev/tty
    printf '◆  %s\n' "$prompt" > /dev/tty
    printf '│  %s %s / %s %s\n' \
      "$first_marker" "${option_labels[0]}" \
      "$second_marker" "${option_labels[1]}" > /dev/tty
    printf '└\n' > /dev/tty

    IFS= read -rsn1 key < /dev/tty || true

    case "$key" in
      '')
        printf '\033[%dA' "$line_count" > /dev/tty
        printf '\033[J' > /dev/tty
        selected_label="${option_labels[$selected_index]}"
        printf '◇  %s\n' "$prompt" > /dev/tty
        printf '│  %s\n' "$selected_label" > /dev/tty
        printf '\033[?25h' > /dev/tty
        printf '%s\n' "${option_values[$selected_index]}"
        return 0
        ;;
      $'\x1b')
        IFS= read -rsn2 -t 1 escape_sequence < /dev/tty || escape_sequence=''
        case "$escape_sequence" in
          '[A'|'[D')
            selected_index=$(( (selected_index + ${#option_labels[@]} - 1) % ${#option_labels[@]} ))
            ;;
          '[B'|'[C')
            selected_index=$(( (selected_index + 1) % ${#option_labels[@]} ))
            ;;
        esac
        ;;
      'h'|'H')
        selected_index=$(( (selected_index + ${#option_labels[@]} - 1) % ${#option_labels[@]} ))
        ;;
      'l'|'L')
        selected_index=$(( (selected_index + 1) % ${#option_labels[@]} ))
        ;;
      'k'|'K')
        selected_index=$(( (selected_index + ${#option_labels[@]} - 1) % ${#option_labels[@]} ))
        ;;
      'j'|'J')
        selected_index=$(( (selected_index + 1) % ${#option_labels[@]} ))
        ;;
      ' '|$'\t')
        selected_index=$(( (selected_index + 1) % ${#option_labels[@]} ))
        ;;
      '1')
        selected_index=0
        ;;
      '2')
        selected_index=1
        ;;
    esac

    printf '\033[%dA' "$line_count" > /dev/tty
    printf '\033[J' > /dev/tty
  done
}

resolve_project_directory() {
  local package_file package_mtime latest_mtime project_directory

  if [[ -n "$project_name" ]]; then
    printf '%s\n' "$working_directory/$project_name"
    return 0
  fi

  project_directory=''
  latest_mtime=0

  while IFS= read -r -d '' package_file; do
    package_mtime=$(stat -f '%m' "$package_file")

    if (( package_mtime > latest_mtime )); then
      latest_mtime=$package_mtime
      project_directory="$(dirname "$package_file")"
    fi
  done < <(find "$working_directory" -type f -name package.json -newer "$marker_file" -not -path '*/node_modules/*' -print0)

  if [[ -z "$project_directory" ]]; then
    echo 'Unable to determine the created Vue project directory.' >&2
    return 1
  fi

  printf '%s\n' "$project_directory"
}

install_dependencies() {
  local selected_style
  local -a common_packages selected_style_packages

  selected_style="$1"
  common_packages=(
    @stylistic/eslint-plugin
    @vitejs/plugin-vue
    @vue/eslint-config-typescript
    @vue/tsconfig
    eslint
    eslint-plugin-oxlint
    eslint-plugin-vue
    oxlint
    sass
    stylelint
    @stylistic/stylelint-plugin
    stylelint-config-recess-order
    stylelint-config-recommended
    stylelint-config-recommended-scss
    stylelint-config-recommended-vue
    stylelint-config-standard
    stylelint-config-standard-scss
    stylelint-order
    stylelint-scss
    stylelint-stylus
    typescript
    vite
    vite-plugin-vue-devtools
    vue-eslint-parser
    vue-tsc
  )

  case "$selected_style" in
    unocss)
      selected_style_packages=(
        @unocss/eslint-config
        @unocss/inspector
        @unocss/postcss
        @unocss/preset-mini
        @unocss/reset
        unocss
      )
      ;;
    tailwind)
      selected_style_packages=(
        @tailwindcss/vite
        tailwindcss
      )
      ;;
    *)
      echo "Unsupported style solution: $selected_style" >&2
      return 1
      ;;
  esac

  pnpm install -D "${common_packages[@]}" "${selected_style_packages[@]}"
}

write_vite_config() {
  local selected_style style_import style_plugin

  selected_style="$1"

  case "$selected_style" in
    unocss)
      style_import="import UnoCSS from 'unocss/vite'"
      style_plugin='      UnoCSS(),'
      ;;
    tailwind)
      style_import="import tailwindcss from '@tailwindcss/vite'"
      style_plugin='      tailwindcss(),'
      ;;
    *)
      echo "Unsupported style solution: $selected_style" >&2
      return 1
      ;;
  esac

  tee vite.config.ts <<EOF
import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'
$style_import

// https://vite.dev/config/
export default defineConfig(() => {
  return {
    plugins: [
      vue(),
      vueDevTools(),
$style_plugin
    ],
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url)),
      },
    },
  }
})
EOF
}

write_stylelint_ignore() {
  tee .stylelintignore <<EOF
dist
node_modules
EOF
}

write_eslint_config() {
  local selected_style style_import style_config

  selected_style="$1"
  style_import=''
  style_config=''

  case "$selected_style" in
    unocss)
      style_import="import unocss from '@unocss/eslint-config/flat'"
      style_config='  unocss,'
      ;;
    tailwind)
      ;;
    *)
      echo "Unsupported style solution: $selected_style" >&2
      return 1
      ;;
  esac

  tee eslint.config.ts <<EOF
import { globalIgnores } from 'eslint/config'
import { defineConfigWithVueTs, vueTsConfigs } from '@vue/eslint-config-typescript'
import pluginVue from 'eslint-plugin-vue'
import pluginOxlint from 'eslint-plugin-oxlint'
$style_import
import stylistic from '@stylistic/eslint-plugin'

const INLINE_ELEMENTS = [
  'a',
  'abbr',
  'audio',
  'b',
  'bdi',
  'bdo',
  'canvas',
  'cite',
  'code',
  'data',
  'del',
  'dfn',
  'em',
  'i',
  'iframe',
  'ins',
  'kbd',
  'label',
  'map',
  'mark',
  'noscript',
  'object',
  'output',
  'picture',
  'q',
  'ruby',
  's',
  'samp',
  'small',
  'span',
  'strong',
  'sub',
  'sup',
  'svg',
  'time',
  'u',
  'var',
  'video',
  'button',
]

// To allow more languages other than `ts` in `.vue` files, uncomment the following lines:
// import { configureVueProject } from '@vue/eslint-config-typescript'
// configureVueProject({ scriptLangs: ['ts', 'tsx'] })
// More info at https://github.com/vuejs/eslint-config-typescript/#advanced-setup

export default defineConfigWithVueTs(
  {
    name: 'app/files-to-lint',
    files: ['**/*.{ts,mts,tsx,vue}'],
  },

  globalIgnores(['**/dist/**', '**/dist-ssr/**', '**/coverage/**', '**/extension/**']),

  pluginVue.configs['flat/essential'],
  vueTsConfigs.recommended,
  ...pluginOxlint.configs['flat/recommended'],

$style_config
  {
    linterOptions: {
      reportUnusedDisableDirectives: 'off',
    },
    ignores: ['src/wailsjs'],
    plugins: {
      '@stylistic': stylistic,
    },
    rules: {
      // stylistic 规则列表
      // https://eslint.style/rules
      '@stylistic/space-infix-ops': ['error'],
      '@stylistic/eol-last': ['error', 'always'],
      '@stylistic/spaced-comment': ['error', 'always'],
      '@stylistic/lines-around-comment': ['error', {
        beforeBlockComment: true,
      }],
      '@stylistic/no-multiple-empty-lines': ['error', { max: 1, maxEOF: 0 }],
      '@stylistic/object-curly-spacing': ['error', 'always'],
      '@stylistic/no-trailing-spaces': ['error', { ignoreComments: true }],
      '@stylistic/comma-spacing': ['error', { before: false, after: true }],
      '@stylistic/comma-style': ['error', 'last'],
      '@stylistic/quote-props': ['error', 'as-needed'],
      '@stylistic/indent': ['error', 2],
      '@stylistic/space-in-parens': ['error', 'never'],
      '@stylistic/no-extra-semi': 'error',
      '@stylistic/no-multi-spaces': 'error',
      '@stylistic/array-bracket-spacing': ['error', 'never'],
      semi: ['error', 'never'],
      quotes: ['error', 'single'],
      indent: ['error', 2, { SwitchCase: 1 }],
      'no-unused-vars': 'off',
      '@typescript-eslint/no-unused-vars': ['error'],
      'no-shadow': 'off',
      'arrow-parens': ['error', 'as-needed'],
      'no-confusing-arrow': ['error', { allowParens: true, onlyOneSimpleParam: true }],
      // eslint-plugin-vue 规则列表
      // https://eslint.vuejs.org/rules/
      '@stylistic/comma-dangle': [
        'error',
        {
          arrays: 'always-multiline',
          objects: 'always-multiline',
          imports: 'always-multiline',
          exports: 'always-multiline',
          functions: 'always-multiline',
        },
      ],
      'vue/no-unused-components': 0,
      'vue/html-closing-bracket-spacing': 'error',
      'vue/html-indent': ['error', 2],
      'vue/script-indent': ['error', 2, { switchCase: 1 }],
      'vue/mustache-interpolation-spacing': [2, 'always'],
      'vue/max-len': [
        'error',
        {
          code: 200,
          template: 200,
          tabWidth: 2,
          comments: 400,
          // ignorePattern: INLINE_ELEMENTS,
          ignoreHTMLAttributeValues: false,
          ignoreHTMLTextContents: true,
          ignoreComments: true,
          ignoreStrings: true,
          ignoreTrailingComments: true,
          ignoreUrls: true,
          ignoreTemplateLiterals: true,
          ignoreRegExpLiterals: true,
        },
      ],
      'vue/singleline-html-element-content-newline': [
        'error',
        {
          ignoreWhenNoAttributes: false,
          ignoreWhenEmpty: true,
          ignores: [...INLINE_ELEMENTS],
        },
      ],
      'vue/max-attributes-per-line': [
        'error',
        {
          singleline: 3,
        // multiline: {
        //     max: 3,
        //     allowFirstLine: true,
        // },
        },
      ],
      'vue/first-attribute-linebreak': ['error', {
        singleline: 'beside',
        multiline: 'below',
      }],
      'vue/html-closing-bracket-newline': ['error', {
        singleline: 'never',
        multiline: 'always',
        selfClosingTag: {
          singleline: 'never',
          multiline: 'always',
        },
      },
      ],
      'vue/multiline-html-element-content-newline': ['error', {
        ignoreWhenEmpty: true,
        ignores: ['pre', 'textarea', ...INLINE_ELEMENTS],
        allowEmptyLines: false,
      }],
      'vue/no-v-html': 0,
      'vue/require-prop-types': 0,
      'vue/prop-name-casing': 0,
      'vue/multi-word-component-names': 0,
      'vue/block-tag-newline': ['error', {
        singleline: 'always',
        multiline: 'always',
        maxEmptyLines: 0,
      }],
      // 'import/no-extraneous-dependencies': [
      //   'error',
      //   {
      //     devDependencies: true,
      //     optionalDependencies: true,
      //     peerDependencies: true,
      //     bundledDependencies: true,
      //   },
      // ],
    },
  },
)
EOF
}

write_stylelint_config() {
  tee stylelint.config.js <<EOF
/** @type {import('stylelint').Config} */
export default {
  plugins: [
    'stylelint-order',
    '@stylistic/stylelint-plugin',
  ],
  overrides: [
    {
      files: ['**/*.scss'],
      customSyntax: 'postcss-scss',
    },
  ],
  extends: [
    'stylelint-config-standard',
    'stylelint-config-standard-scss',
    'stylelint-config-recommended',
    'stylelint-config-recommended-scss',
    'stylelint-config-recommended-vue/scss',
  ],
  rules: {
    'block-no-empty': true,
    'property-no-unknown': [
      true,
      {
        ignoreProperties: [
          '/d/',
        ],
      },
    ],
    'at-rule-no-unknown': null,
    'selector-pseudo-element-no-unknown': [
      true,
      {
        ignorePseudoElements: [
          'deep',
        ],
      },
    ],
    'selector-pseudo-class-no-unknown': [
      true,
      {
        ignorePseudoClasses: [
          'global',
          'deep',
        ],
      },
    ],
    'scss/dollar-variable-pattern': [
      /^[\s\S]/, { ignore: 'global' },
    ],
    'scss/no-global-function-names': null,

    // stylistic rules from @stylistic/stylelint-plugin
    // https://github.com/stylelint-stylistic/stylelint-stylistic/blob/main/docs/user-guide/rules.md
    '@stylistic/indentation': 2,
    '@stylistic/max-empty-lines': 1,
    '@stylistic/no-empty-first-line': true,
    '@stylistic/no-eol-whitespace': true,
    '@stylistic/no-missing-end-of-source-newline': true,
    '@stylistic/declaration-block-semicolon-space-before': 'never',
  },
}
EOF
}

write_style_files() {
  local selected_style

  selected_style="$1"

  case "$selected_style" in
    unocss)
      tee uno.config.ts <<EOF
import { defineConfig, presetAttributify, presetWind3 } from 'unocss'

export default defineConfig({
  presets: [
    presetAttributify({ /* preset options */}),
    presetWind3(),
    // ...custom presets
  ],
  rules: [
    ['grid-cols-config', { 'grid-template-columns': '1fr min-content 1fr' }],
  ],
})
EOF
      ;;
    tailwind)
      mkdir -p src/assets

      tee src/assets/main.css <<EOF
@import "tailwindcss";

@utility grid-cols-config {
  grid-template-columns: 1fr min-content 1fr;
}
EOF
      ;;
    *)
      echo "Unsupported style solution: $selected_style" >&2
      return 1
      ;;
  esac
}

style_solution="$(normalize_style_solution "$style_solution")"

if [[ "$style_solution" == 'unsupported' ]]; then
  echo 'Unsupported style solution. Use unocss or tailwind.' >&2
  exit 1
fi

if [[ -r /dev/tty ]]; then
  pnpm create vue@latest ${project_name:+"$project_name"} < /dev/tty
else
  pnpm create vue@latest ${project_name:+"$project_name"}
fi

project_directory="$(resolve_project_directory)"

if [[ -z "$style_solution" ]]; then
  style_solution="$(select_style_solution)"
fi

cd "$project_directory"

install_dependencies "$style_solution"
write_vite_config "$style_solution"
write_stylelint_ignore
write_eslint_config "$style_solution"
write_stylelint_config
write_style_files "$style_solution"
