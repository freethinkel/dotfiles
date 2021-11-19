import { styled } from "uebersicht";
import { useProcess, useUpdate } from "../utils";
import { colors, hexToRgba } from "../colors";

export const Battery = () => {
  const value = parseInt(
    useProcess(
      "pmset -g batt | egrep '([0-9]+%).*' -o --colour=auto | cut -f1 -d';'"
    ) || ""
  );
  const isCharging = parseInt(useProcess("pmset -g batt | grep -c 'AC'")) > 0;

  useUpdate(2000);

  let icon = "";
  if (+value < 25) {
    icon = "ti-battery-1";
  } else if (+value < 50) {
    icon = "ti-battery-2";
  } else if (+value < 75) {
    icon = "ti-battery-3";
  } else {
    icon = "ti-battery-4";
  }

  if (isCharging) {
    icon = "ti-battery-charging";
  }
  return (
    <BatteryInner className="battery">
      <span className={"ti " + icon}></span>
      <span>{value}%</span>
    </BatteryInner>
  );
};

const BatteryInner = styled.div`
  display: flex;
  align-items: center;
  border: none;
  background: ${hexToRgba(colors.green)};
  color: ${colors.background};
  cursor: pointer;
  gap: 2px;
  padding: 0 8px;
  font-size: 12px;
  font-weight: bold;
  & .ti {
    font-size: 22px;
    font-weight: 100;
  }
`;
