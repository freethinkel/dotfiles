export const colors = {
  primary: "rgba(255, 172, 18, 1)",

  red: "#fb4934",
  green: "#b8bb26",
  yellow: "#fabd2f",
  blue: "#83a598",
  purple: "#fb4934",
  mint: "#8ec07c",

  background: "#302d41",
  white: "#fff",
};

export const vars = {
  radius: '6px'
}

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
