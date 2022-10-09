import { styled, run, React } from "uebersicht";
import { colors, hexToRgba, vars } from "./helpers/vars";
import { useProcess, useUpdate } from "./helpers/utils";
import { yabaiBin, jqBin } from "./helpers/bins";

export const Spaces = () => {
  const spaces = JSON.parse(
    useProcess(`${yabaiBin} -m query --spaces`) || "[]"
  ).sort((a, b) => a.index - b.index);

  const active = parseInt(
    useProcess(`${yabaiBin} -m query --spaces --space | ${jqBin} '.index'`)
  );

  useUpdate(500);

  return (
    <Wrapper>
      {spaces.map((space, i) => (
        <Space
          key={space.index}
          active={space.index === active}
          onClick={() => run(`${yabaiBin} -m space --focus ${i + 1}`)}
        >
          {space.index}: {space.label}
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
  height: 100%;
  min-width: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: "JetBrainsMono Nerd Font", serif;
  color: ${({ active }) => (active ? colors.background : colors.white)};
  background: ${({ active }) => (active ? colors.purple : "transparent")};
  transition: 0.3s;
  margin-right: 2px;
  &:hover {
    background: ${hexToRgba(colors.purple, "0.4")};
  }
`;

const Wrapper = styled.div`
  display: flex;
  background: ${colors.background};
  overflow: hidden;
  border-radius: ${vars.radius};
`;
