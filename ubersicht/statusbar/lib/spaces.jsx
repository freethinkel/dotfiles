import { styled, run } from "uebersicht";
import { colors } from "./colors";

export const Spaces = ({ spaces, active }) => {
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
  background: ${({ active }) => (active ? colors.secondary : "transparent")};
  transition: 0.3s;
  margin-right: 2px;
  &:hover {
    background: ${colors.secondary50};
  }
`;

const Wrapper = styled.div`
  display: flex;
`;
