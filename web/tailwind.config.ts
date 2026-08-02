import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        ink: '#14110F',
        panel: '#1C1916',
        line: '#2E2822',
        cream: '#F5EEE3',
        dim: '#8A7F6F',
        orange: '#E85D2F',
        'orange-dark': '#C44220',
        ochre: '#E8A33C',
        grass: '#3F7A4E',
        'grass-light': '#7EC48D',
        alert: '#C4503A',
      },
      fontFamily: {
        'display': ['Archivo Black', 'sans-serif'],
        'body': ['Inter Tight', 'sans-serif'],
        'mono': ['JetBrains Mono', 'monospace'],
      },
    },
  },
  plugins: [],
};

export default config;
