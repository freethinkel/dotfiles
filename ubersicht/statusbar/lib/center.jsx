import { styled, React } from "uebersicht";
import { Time } from "./components/Timer.jsx";

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
`;
