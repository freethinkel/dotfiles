import { styled, React } from "uebersicht";
import { colors } from "../colors";
import { useUpdate } from "../utils";

export const Time = () => {
  const now = new Date();
  const value = [now.getHours(), now.getMinutes(), now.getSeconds()].map((v) =>
    v.toString().padStart(2, "0")
  );

  useUpdate(1000);

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
  font-size: "JetBrainsMono Nerd Font";
  align-items: center;
  gap: 3px;
  font-size: 12px;
  padding: 0;
  height: 24px;
  top: 0;
  margin: 0;
  font-weight: bold;
  letter-spacing: 1px;
  color: ${colors.green};
  & .ti {
    margin-top: -2px;
    font-size: 16px;
  }
`;
