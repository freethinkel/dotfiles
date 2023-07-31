import fs from "node:fs";
import path from "node:path";

const env = _parseDotenv(
  String(
    fs.readFileSync(path.join(process.env.HOME, "Developer/dev/dotfiles/.env"))
  )
);

function _parseDotenv(content) {
  const obj = {};

  content
    .trim()
    .split("\n")
    .forEach((line) => {
      const [key, value] = line.trim().split("=");
      obj[key] = value.replace(/"/gim, "");
    });

  return obj;
}
