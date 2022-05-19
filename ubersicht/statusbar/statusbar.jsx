import { styled } from "uebersicht";
import { Spaces } from "./lib/spaces.jsx";
import { Statuses } from "./lib/statuses.jsx";
import { Center } from "./lib/center.jsx";
import { colors } from "./lib/vars";

export const refreshFrequency = false;

export const render = () => {
  return (
    <Wrapper>
      <link
        rel="stylesheet"
        href="./statusbar/lib/assets/tabler-icons.min.css"
      />
      <Spaces />
      <Center />
      <Statuses />
    </Wrapper>
  );
};

const Wrapper = styled.div`
  position: fixed;
  top: 10px;
  left: 10px;
  right: 10px;
  color: ${colors.white};
  display: flex;
  justify-content: space-between;
  /* background-color: ${colors.background}; */
`;
