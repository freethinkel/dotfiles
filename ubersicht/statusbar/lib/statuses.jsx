import { styled, React } from "uebersicht";
import { colors, vars } from "./helpers/vars";
import { Volume } from "./widgets/Volume.jsx";
import { Battery } from "./widgets/Battery.jsx";
import { Wifi } from "./widgets/Wifi.jsx";
import { DateItem } from "./widgets/Date.jsx";
import { Timer } from "./widgets/Timer.jsx";

export const Statuses = () => {
  return (
    <Wrapper>
      <Volume />
      <Battery />
      <Wifi />
      <Timer />
      <DateItem />
    </Wrapper>
  );
};

const Wrapper = styled.div`
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  font-family: "JetBrainsMono Nerd Font";
  border-radius: ${vars.radius};
  background-color: ${colors.background};
  overflow: hidden;
  grid-column: 3/4;

  & .ti {
    margin-top: -2px;
    font-size: 18px;
  }
`;
