const nord = {
  text: "#ECEFF4",
  background: "#4C566A",
  accent: "#88C0D0",
};

const catpuccin = {
  text: "#CDD6F4",
  background: "#1E1E2E",
  accent: "#F38BA8",
};

const mountain = {
  text: "#f0f0f0",
  background: "#0f0f0f",
  accent: "#8aac8b",
}

const tokyoNight = {
  text: "#a9b1d6",
  background: "#1a1b26",
  accent: "#73daca",
}

export const toOpacity = (color, opacity = 1) => {
  const hexAlpha = Math.floor(opacity * 255).toString(16)

  return color + hexAlpha;
}


// primary:
//   foreground: '0xa9b1d6'
//   background: '0x1a1b26'
// normal:
//   black: '0x414868'
//   red: '0xf7768e'
//   green: '0x73daca'
//   yellow: '0xe0af68'
//   blue: '0x7aa2f7'
//   magenta: '0xbb9af7'
//   cyan: '0x7dcfff'
//   white: '0xc0caf5'
// bright:
//   black: '0x414868'
//   red: '0xf7768e'
//   green: '0x73daca'
//   yellow: '0xe0af68'
//   blue: '0x7aa2f7'
//   magenta: '0xbb9af7'
//   cyan: '0x7dcfff'
//   white: '0xc0caf5'

export const theme = tokyoNight;
