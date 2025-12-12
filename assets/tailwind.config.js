// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

import { nextui } from '@nextui-org/react'
import plugin from 'tailwindcss/plugin'
import fs from 'fs'
import path from 'path'

/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './js/**/*.{js,ts,jsx,tsx}',
    '../lib/task_forest_web.ex',
    '../lib/task_forest_web/**/*.*ex',
    './node_modules/@nextui-org/theme/dist/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        brand: '#D9318B',
        transparent: 'transparent',
        current: 'currentColor',
        plombYellow: {
          100: '#FFFCEB',
          200: '#FFFBE0',
          300: '#FFF9D5',
          400: '#FFF7CA',
          500: '#FEF9C2',
          600: '#E8E0AE',
          700: '#D1C899',
          800: '#BAB085',
          900: '#A39970',
          default: '#FEF9C2',
        },
        plombDarkBrown: {
          100: '#A6696A',
          200: '#8F595C',
          300: '#79494E',
          400: '#633940',
          500: '#400704',
          600: '#330603',
          700: '#260502',
          800: '#1A0401',
          900: '#0D0201',
          default: '#400704',
        },
        plombLightBrown: {
          100: '#A67A7A',
          200: '#956A6A',
          300: '#845A5A',
          400: '#734A4A',
          500: '#5A1A1A',
          600: '#491515',
          700: '#381010',
          800: '#270B0B',
          900: '#160505',
          default: '#5A1A1A',
        },
        plombPink: {
          100: '#F2AED4',
          200: '#F09AC7',
          300: '#EE86BA',
          400: '#EC72AD',
          500: '#D9318B',
          600: '#B02770',
          700: '#872055',
          800: '#5E193A',
          900: '#350F1F',
          default: '#D9318B',
        },
        plombBlack: {
          100: '#8C898A',
          200: '#757475',
          300: '#5E5F60',
          400: '#47494B',
          500: '#221F20',
          600: '#1B1A1B',
          700: '#141415',
          800: '#0D0D0E',
          900: '#060607',
          default: '#221F20',
        },
      },
    },
  },
  darkMode: 'class',
  plugins: [
    nextui({
      addCommonColors: true,
      themes: {
        light: {
          colors: {
            background: '#FEF9C2',
            foreground: '#400704',
            primary: {
              100: '#5A1A1A',
              200: '#743030',
              300: '#8E4646',
              400: '#A85C5C',
              500: '#400704',
              600: '#320603',
              700: '#280502',
              800: '#1E0402',
              900: '#140301',
              foreground: '#FFFFFF',
              DEFAULT: '#400704',
            },
            success: {
              100: '#F9FCD2',
              200: '#F2F9A6',
              300: '#E2EE77',
              400: '#CEDE53',
              500: '#b3c922',
              600: '#97AC18',
              700: '#7C9011',
              800: '#62740A',
              900: '#4F6006',
            },
            info: {
              100: '#E0E9FF',
              200: '#C1D3FF',
              300: '#A3BBFF',
              400: '#8CA7FF',
              500: '#6687FF',
              600: '#4A66DB',
              700: '#3349B7',
              800: '#203193',
              900: '#13207A',
            },
            warning: {
              100: '#FFF4D0',
              200: '#FFE5A1',
              300: '#FFD372',
              400: '#FFC14E',
              500: '#ffa314',
              600: '#DB830E',
              700: '#B7650A',
              800: '#934B06',
              900: '#7A3903',
            },
            danger: {
              100: '#FFE5D5',
              200: '#FFC5AB',
              300: '#FF9E81',
              400: '#FF7961',
              500: '#FF3B2D',
              600: '#DB2023',
              700: '#B71626',
              800: '#930E26',
              900: '#7A0826',
            },
          },
        },
      },
    }),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) =>
      addVariant('phx-no-feedback', ['.phx-no-feedback&', '.phx-no-feedback &']),
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-click-loading', [
        '.phx-click-loading&',
        '.phx-click-loading &',
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-submit-loading', [
        '.phx-submit-loading&',
        '.phx-submit-loading &',
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-change-loading', [
        '.phx-change-loading&',
        '.phx-change-loading &',
      ]),
    ),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, '../deps/heroicons/optimized')
      let values = {}
      let icons = [
        ['', '/24/outline'],
        ['-solid', '/24/solid'],
        ['-mini', '/20/solid'],
        ['-micro', '/16/solid'],
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
          let name = path.basename(file, '.svg') + suffix
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) }
        })
      })
      matchComponents(
        {
          hero: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, '')
            let size = theme('spacing.6')
            if (name.endsWith('-mini')) {
              size = theme('spacing.5')
            } else if (name.endsWith('-micro')) {
              size = theme('spacing.4')
            }
            return {
              [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              '-webkit-mask': `var(--hero-${name})`,
              mask: `var(--hero-${name})`,
              'mask-repeat': 'no-repeat',
              'background-color': 'currentColor',
              'vertical-align': 'middle',
              display: 'inline-block',
              width: size,
              height: size,
            }
          },
        },
        { values },
      )
    }),
  ],
}
