import { styled } from "uebersicht";
import { colors } from "../vars";
import { useUpdate } from "../utils";

export const DateItem = () => {
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
  align-items: center;
  gap: 2px;
  padding: 0 8px;
  font-size: 12px;
  font-weight: bold;
  color: ${colors.background};
  background: ${colors.red};
  & .ti {
    font-weight: bold;
  }
`;
