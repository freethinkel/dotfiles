import { styled } from "uebersicht";
import { Battery } from "./Battery.jsx";
import { DateTime } from "./DateTime.jsx";
import { Volume } from "./Volume.jsx";
import { Airpods } from "./Airpods.jsx";
import { KeyboardLayout } from "./KeyboardLayout.jsx";

export const InfoPanel = () => {
  return (
    <Wrapper>
      <KeyboardLayout />
      <Airpods />
      <Volume />
      <Battery />
      <DateTime />
    </Wrapper>
  );
};

const Wrapper = styled.div`
  display: flex;
  gap: 4px;
`;
