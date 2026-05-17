/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'military-green': '#4b5320',
        'military-dark': '#1a1c1a',
        'alert-red': '#ef4444',
        'safe-green': '#22c55e',
      }
    },
  },
  plugins: [],
}
