import { styled } from "uebersicht";
import { BAR_HEIGHT } from "../utils/vars";

export const TopNotch = styled.div`
  background: #000;
  position: fixed;
  top: 0;
  left: 0;
  pointer-events: none;
  width: 100%;
  height: ${BAR_HEIGHT}px;
  z-index: -1000;
`;
