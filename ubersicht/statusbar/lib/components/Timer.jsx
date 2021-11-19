import { styled, React } from "uebersicht";
import { colors, hexToRgba } from "../colors";
import { useUpdate } from "../utils";

export const Time = () => {
  const now = new Date();
  const value = [now.getHours(), now.getMinutes()].map((v) =>
    v.toString().padStart(2, "0")
  );

  useUpdate(5000);

  return (
    <TimeInner>
      <span className="ti ti-clock" />
      <span>{value.join(":")}</span>
    </TimeInner>
  );
};

const TimeInner = styled.button`
  outline: none;
  border: none;
  display: flex;
  background: transparent;
  color: ${colors.white};
  font-family: "JetBrainsMono Nerd Font";
  align-items: center;
  gap: 3px;
  font-size: 12px;
  padding: 0 8px;
  height: 24px;
  top: 0;
  margin: 0;
  font-weight: bold;
  color: ${colors.mint};
  background: ${hexToRgba(colors.mint, 0.12)};
  & .ti {
    margin-top: -2px;
    font-weight: bold;
    font-size: 16px;
  }
`;
