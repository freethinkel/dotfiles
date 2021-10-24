import { styled } from "uebersicht";
import { colors } from "./colors";

export const Center = ({ statuses }) => {
  return (
    <Wrapper>
      <Time value={statuses.time} />
    </Wrapper>
  );
};

const Time = ({ value }) => {
  return (
    <TimeInner>
      <span className="ti ti-clock" />
      <span>{value}</span>
    </TimeInner>
  );
};

const Wrapper = styled.div`
  position: absolute;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  justify-content: center;
  text-align: center;
`;

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
  color: ${colors.primary};
  & .ti {
    margin-top: -2px;
    font-size: 18px;
  }
`;
