import { BaseBlock } from "../components/BaseBlock.jsx";
import { useBluetoothDevices, useUpdate } from "../utils/hooks";

export const Keychron = () => {
  const info = useKeyboardInfo();
  useUpdate(2000);

  console.log(info);

  if (!info) {
    return null;
  }

  return <BaseBlock>K: </BaseBlock>;
};

const useKeyboardInfo = () => {
  const info = useBluetoothDevices();

  return Object.entries(info).find(
    ([key]) => key.toLowerCase().indexOf("keychron") >= 0
  );
};
