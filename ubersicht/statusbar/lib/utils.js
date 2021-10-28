import { React, run } from "uebersicht";

const { useState, useEffect } = React;

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

export const useUpdate = (ms = 1000) => {
  const [_, forceRender] = useState({});

  useEffect(() => {
    const timer = setInterval(() => forceRender({}), ms);
    return () => clearInterval(timer);
  }, []);
};
