import { styled, React } from "uebersicht";
import { Time } from "./components/Timer.jsx";
import {colors} from './vars'

export const Center = () => {
  return (
    <Wrapper>
      <Time />
    </Wrapper>
  );
};

const Wrapper = styled.div`
  position: absolute;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  justify-content: center;
  text-align: center;
  border-radius: 6px;
  background-color: ${colors.background};
`;
