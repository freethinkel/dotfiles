import { styled } from "uebersicht";
import { BaseBlock } from "../components/BaseBlock.jsx";
import { useProcess } from "../utils/hooks";
import { YABAI } from "../utils/vars";

export const WindowTitle = () => {
  const result = useProcess(`${YABAI} -m query --windows`);
  const windows = JSON.parse(result || "[]");
  const activeWindow = windows.find((window) => window["has-focus"]);

  if (!activeWindow) {
    return null;
  }

  return (
    <BaseBlock>
      <Inner>
        {activeWindow.app} / {activeWindow.title}
      </Inner>
    </BaseBlock>
  );
};

const Inner = styled.span`
  max-width: 200px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
`;
