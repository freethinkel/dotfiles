import { React, run } from "uebersicht";

const { useEffect, useState } = React;

export const useProcess = (command) => {
  const [result, setResult] = useState(null);

  useEffect(() => {
    (async () => {
      const res = await run(command);
      setResult(res);
    })();
  });

  return result;
};

export const useBluetoothDevices = () => {
  try {
    const result = useProcess(
      "system_profiler SPBluetoothDataType -json 2>/dev/null"
    );
    const info = JSON.parse(result);

    const connected = (
      info?.SPBluetoothDataType[0]?.device_connected || []
    ).reduce((acc, curr) => {
      acc = { ...acc, ...curr };
      return acc;
    }, {});

    return connected;
  } catch (err) {
    console.log(err);
    return null;
  }
};

export const useUpdate = (ms) => {
  const [, setState] = useState({});

  useEffect(() => {
    const time = setInterval(() => {
      setState({});
    }, ms);

    return () => {
      clearInterval(time);
    };
  }, []);
};
