import { styled, run, React } from "uebersicht";
import { colors, hexToRgba, vars } from "./vars";
import { useProcess, useUpdate } from "./utils";

export const Spaces = () => {
  const spaces = (
    useProcess(
      "/usr/local/bin/yabai -m query --spaces | /usr/local/bin/jq -r '.[].index'"
    ) || ""
  )
    .split("\n")
    .filter((space) => space);

  const active = parseInt(
    useProcess(
      "/usr/local/bin/yabai -m query --spaces --space | /usr/local/bin/jq '.index'"
    )
  );

  useUpdate(500);

  return (
    <Wrapper>
      {spaces.map((space, i) => (
        <Space
          key={space}
          active={i + 1 === active}
          onClick={() => run(`yabai -m space --focus ${i + 1}`)}
        >
          {space}
        </Space>
      ))}
    </Wrapper>
  );
};

const Space = styled.button`
  border: none;
  padding: 0 6px;
  margin: 0;
  outline: none;
  height: 24px;
  min-width: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: "JetBrainsMono Nerd Font", serif;
  color: ${colors.white};
  background: ${({ active }) => (active ? colors.mint : "transparent")};
  transition: 0.3s;
  margin-right: 2px;
  &:hover {
    background: ${hexToRgba(colors.mint, "0.5")};
  }
`;

const Wrapper = styled.div`
  display: flex;
  background: ${colors.background};
  border-radius: ${vars.radius};
`;
