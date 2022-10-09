import { BaseBlock } from "../components/BaseBlock.jsx";
import { useUpdate } from "../utils/hooks.js";

const getTime = () => {
  const date = new Date();
  const h = date.getHours().toString().padStart(2, "0");
  const m = date.getMinutes().toString().padStart(2, "0");

  return `${h}:${m}`;
};

const getDate = () => {
  const date = new Date();
  const d = date.getDate().toString().padStart(2, "0");
  const m = Intl.DateTimeFormat("ru-RU", { month: "short" }).format(date);

  return `${d} ${m}`;
};

export const DateTime = () => {
  const time = getTime();
  const date = getDate();

  useUpdate("20000");

  return (
    <BaseBlock>
      {date} {time}
    </BaseBlock>
  );
};
