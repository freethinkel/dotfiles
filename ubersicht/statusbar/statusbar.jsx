import { styled } from "uebersicht";
import { Spaces } from "./lib/spaces.jsx";
import { Statuses } from "./lib/statuses.jsx";
import { colors } from "./lib/helpers/vars";

const BAR_HEIGHT = 40;

export const render = () => {
  return (
    <Wrapper>
      <link
        rel="stylesheet"
        href="./statusbar/lib/assets/tabler-icons.min.css"
      />
      <Spaces />
      <Statuses />
      <TopNotch />
    </Wrapper>
  );
};

const Wrapper = styled.div`
  position: fixed;
  top: 0px;
  left: 0px;
  right: 0px;
  padding: 4px 10px;
  height: ${BAR_HEIGHT}px;
  color: ${colors.white};
  display: grid;
  grid-template-columns: repeat(3, auto);
  justify-content: space-between;
  box-sizing: border-box;
`;

const TopNotch = styled.div`
  position: fixed;
  pointer-events: none;
  background: #000;
  top: 0;
  left: 0;
  width: 100%;
  height: ${BAR_HEIGHT}px;
  z-index: -1;
`;
