import { run } from "uebersicht";
import { BaseBlock } from "../components/BaseBlock.jsx";
import { Icon } from "../components/Icon.jsx";
import { useProcess, useUpdate } from "../utils/hooks";

export const Volume = () => {
  const volume = (
    useProcess("osascript -e 'output volume of (get volume settings)'") || ""
  ).trim();

  const muted =
    useProcess(
      "osascript -e 'set ovol to output muted of (get volume settings)'"
    )?.trim() === "true";

  useUpdate(2000);

  const toggleMute = () => {
    if (muted) {
      run('osascript -e "set volume without output muted"');
    } else {
      run('osascript -e "set volume with output muted"');
    }
  };

  return (
    <BaseBlock hoverable onClick={toggleMute}>
      <Icon name={muted ? "volume-3" : "volume"} size={17} />
      {volume}
    </BaseBlock>
  );
};
