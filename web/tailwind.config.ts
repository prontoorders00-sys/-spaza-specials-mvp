import type { Config } from "tailwindcss";

export default {
  content: [
    "./src/app/**/*.{ts,tsx,js,jsx}",
    "./src/components/**/*.{ts,tsx,js,jsx}"
  ],
  theme: {
    extend: {
      colors: {
        ink: "#14110F",
        panel: "#1C1916",
        line: "#2E2822",
        cream: "#F5EEE3",
        dim: "#8A7F6F",
        orange: "#E85D2F",
        orangeDeep: "#C44220",
        ochre: "#E8A33C",
        grass: "#3F7A4E",
        grassLight: "#7EC48D",
        alert: "#C4503A"
      },
      fontFamily: {
        display: ["Archivo Black", "sans-serif"],
        body: ["Inter Tight", "sans-serif"],
        mono: ["JetBrains Mono", "ui-monospace", "monospace"]
      }
    }
  },
  plugins: []
} as Config;
