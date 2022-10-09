import { BaseBlock } from "../components/BaseBlock.jsx";
import { Icon } from "../components/Icon.jsx";
import { useBluetoothDevices, useUpdate } from "../utils/hooks";

export const Airpods = () => {
  const info = getAirpodsInfo();
  useUpdate(2000);

  if (!info) {
    return null;
  }

  const [_name, params] = info;
  const caseP = parseInt(params.device_batteryLevelCase) || 0;
  const left = parseInt(params.device_batteryLevelLeft) || 0;
  const right = parseInt(params.device_batteryLevelRight) || 0;

  return (
    <BaseBlock>
      <Icon name="headphones" />
      C:{caseP}% | L:{left}% | R:{right}%
    </BaseBlock>
  );
};

const getAirpodsInfo = () => {
  const info = useBluetoothDevices();

  const airpods = Object.entries(info).find(
    ([key]) => key.toLowerCase().indexOf("airpods") >= 0
  );

  return airpods;
};
