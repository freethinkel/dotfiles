import { styled } from "uebersicht";
import { BAR_HEIGHT } from "./lib/utils/vars";
import { TopNotch } from "./lib/components/TopNotch.jsx";
import { Spaces } from "./lib/widgets/Spaces.jsx";
import { InfoPanel } from "./lib/widgets/InfoPanel.jsx";

export const refreshFrequency = false;

export const command = `sh linebar/lib/scripts/yabai.sh`;

export const render = (props) => {
  return (
    <Container>
      <link
        rel="stylesheet"
        href="./statusbar/lib/assets/tabler-icons.min.css"
      />
      <Spaces />
      <InfoPanel />
      <TopNotch />
    </Container>
  );
};

const Container = styled.div`
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  display: grid;
  grid-template-columns: auto auto;
  justify-content: space-between;
  box-sizing: border-box;
  padding: 5px;
  height: ${BAR_HEIGHT}px;

  &,
  & * {
    font-family: "JetBrainsMono Nerd Font", sans-serif;
  }
`;
