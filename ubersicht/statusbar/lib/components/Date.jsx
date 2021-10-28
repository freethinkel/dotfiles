import { styled } from "uebersicht";
import { useUpdate } from "../utils";

export const Date = () => {
  const now = new Date();
  const weekMap = ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"];

  useUpdate(60 * 60 * 1000);

  const day = now.getDate().toString().padStart(2, "0");
  const week = weekMap[now.getDay()];
  const month = [];

  return (
    <DateInner>
      <span className="ti ti-calendar"></span>
      <span>
        {week} {day} {month}
      </span>
    </DateInner>
  );
};

const DateInner = styled.div`
  display: flex;
`;
