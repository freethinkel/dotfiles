import { styled } from "uebersicht";
import { BAR_HEIGHT } from "./lib/utils/vars";
import { Spaces } from "./lib/widgets/Spaces.jsx";
import { InfoPanel } from "./lib/widgets/InfoPanel.jsx";

export const refreshFrequency = false;

export const command = `sh linebar/lib/scripts/yabai.sh`;

export const render = () => {
  return (
    <Container onClick={console.log}>
      <link
        rel="stylesheet"
        href="./statusbar/lib/assets/tabler-icons.min.css"
      />
      <RoundedCorner style={{ borderTopLeftRadius: "18px" }}>
        <Spaces />
      </RoundedCorner>
      <div></div>
      <RoundedCorner
        style={{ justifyContent: "flex-end", borderTopRightRadius: "18px" }}
      >
        <InfoPanel />
      </RoundedCorner>
    </Container>
  );
};

const RoundedCorner = styled.div`
  background: rgba(0, 0, 0, 0.12);
  backdrop-filter: blur(10px);
  --webkit-backdrop-filter: blur(10px);
  border-radius: 5px;
  overflow: hidden;
  display: flex;
`;

const Container = styled.div`
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  display: grid;
  grid-template-columns: 1fr 230px 1fr;
  justify-content: space-between;
  box-sizing: border-box;
  padding: 5px;
  height: ${BAR_HEIGHT}px;

  &,
  & * {
    font-family: "JetBrainsMono Nerd Font", sans-serif;
  }
`;
