const nordColors = {
  primary: "rgba(255, 172, 18, 1)",

  red: "#D08770",
  green: "#A3BE8C",
  yellow: "#EBCB8B",
  blue: "#88C0D0",
  purple: "#B48EAD",
  mint: "#8FBCBB",

  background: "#434c5e",
  white: "#fff",
};

const tokyoNightColors = {
  primary: "red",

  red: "#ff7a93",
  green: "#b9f27c",
  yellow: "#ff9e64",
  blue: "#7da6ff",
  purple: "#bb9af7",
  mint: "#0db9d7",

  background: "#1a1b26",
  white: "#a9b1d6",
};

export const colors = tokyoNightColors;

export const vars = {
  radius: "6px",
};

export const hexToRgba = (hex, opacity) => {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  const rgb = result
    ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16),
      }
    : null;

  return `rgba(${[rgb.r, rgb.g, rgb.b].join(",")}, ${opacity || "1"})`;
};
