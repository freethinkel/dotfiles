#!/usr/bin/env node
const { exec } = require("child_process");

const appsToSpaces = {
  "Google Chrome": 1,
  alacritty: 2,
  iTerm2: 2,
  "Visual Studio Code": 2,
  Code: 2,
  Slack: 3,
  Telegram: 3,
};

const main = async () => {
  const spaces = await Promise.all(
    JSON.parse(await runProccess("yabai -m query --spaces")).map(
      async (space) => ({
        space,
        apps: JSON.parse(
          await runProccess(`yabai -m query --windows --space ${space.index}`)
        ),
      })
    )
  );
  const currentSpace = spaces.find((space) => space.space["has-focus"]);
  const command = spaces
    .filter((space) =>
      space.apps.some(
        (app) =>
          appsToSpaces[app.app] && space.space.index !== appsToSpaces[app.app]
      )
    )
    .map((space) => {
      return space.apps
        .filter(
          (app) =>
            appsToSpaces[app.app] && space.space.index !== appsToSpaces[app.app]
        )
        .map(
          (app) =>
            `yabai -m window --focus ${app.id} && yabai -m window --space ${
              appsToSpaces[app.app]
            }`
        )
        .join(" && ");
    })
    .join(" && ");

  if (command) {
    await runProccess(command);

    setTimeout(() => {
      runProccess(`yabai -m space --focus ${currentSpace.space.index}`);
    }, 1000);
  }
};

const runProccess = (command) =>
  new Promise((rslv, rjct) => {
    exec(command, (err, stdout, stderr) => {
      if (err) {
        rjct(err);
      } else {
        rslv(stdout || stderr);
      }
    });
  });

main();
