import { BaseBlock } from "../components/BaseBlock.jsx";
import { Icon } from "../components/Icon.jsx";
import { useProcess, useUpdate } from "../utils/hooks";

const layoutMap = {
  ABC: "EN",
  RussianWin: "RU",
};

export const KeyboardLayout = () => {
  const str =
    useProcess(
      "defaults read ~/Library/Preferences/com.apple.HIToolbox.plist | grep AppleCurrentKeyboardLayoutInputSourceID"
    ) || "";
  useUpdate(1000);

  const layout = str
    .replace("AppleCurrentKeyboardLayoutInputSourceID =", "")
    .replace(/"/gim, "")
    .replace(";", "")
    .replace("com.apple.keylayout.", "")
    .trim();

  return (
    <BaseBlock>
      <Icon name="keyboard" />
      {layoutMap[layout] || layout}
    </BaseBlock>
  );
};
