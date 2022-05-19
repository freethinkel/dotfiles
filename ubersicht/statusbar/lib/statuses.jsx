import { styled, React } from "uebersicht";
import { colors, vars } from "./vars";
import { Volume } from "./components/Volume.jsx";
import { Battery } from "./components/Battery.jsx";
import { Wifi } from "./components/Wifi.jsx";
import { DateItem } from "./components/Date.jsx";

export const Statuses = () => {
  return (
    <Wrapper>
      <Volume />
      <Battery />
      <Wifi />
      <DateItem />
    </Wrapper>
  );
};

const Wrapper = styled.div`
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  font-family: "JetBrainsMono Nerd Font";
  /* padding: 0 8px; */
  border-radius: ${vars.radius};
  background-color: ${colors.background};
  overflow: hidden;
  & .ti {
    margin-top: -2px;
    font-size: 18px;
  }
`;
