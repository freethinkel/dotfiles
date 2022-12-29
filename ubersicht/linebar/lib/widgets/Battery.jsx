import { Icon } from "../components/Icon.jsx";
import { BaseBlock } from "../components/BaseBlock.jsx";
import { useProcess, useUpdate } from "../utils/hooks";

const getBatteryIcon = (value, isCharging) => {
  let icon = "";

  if (value < 25) {
    icon = "battery-1";
  } else if (+value < 50) {
    icon = "battery-2";
  } else if (+value < 75) {
    icon = "battery-3";
  } else {
    icon = "battery-4";
  }

  if (isCharging) {
    icon = "battery-charging";
  }

  return icon;
};

export const Battery = () => {
  const [value] = useProcess(
    "pmset -g batt | egrep '([0-9]+%).*' -o --colour=auto | cut -f1 -d';'",
    (value) => parseInt(value || "0")
  );
  const [isCharging] = useProcess(
    "pmset -g batt | grep -c 'AC'",
    (value) => parseInt(value) > 0
  );
  const icon = getBatteryIcon(value, isCharging);

  useUpdate(30000);

  return (
    <BaseBlock>
      <Icon size={22} name={icon} />
      {value}%
    </BaseBlock>
  );
};
