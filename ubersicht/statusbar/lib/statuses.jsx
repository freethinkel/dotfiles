import { styled, run, React } from "uebersicht";
import { colors } from "./colors";
import { Volume } from "./components/Volume.jsx";
import { Battery } from "./components/Battery.jsx";
import { Wifi } from "./components/Wifi.jsx";
import { DateItem } from "./components/Date.jsx";

export const Statuses = ({ statuses }) => {
  return (
    <Wrapper>
      <Volume />
      <Battery />
      <Wifi />
      <DateItem />
    </Wrapper>
  );
};

const HardInfo = ({ statuses }) => {
  return (
    <Expanded>
      <Memory value={statuses.memory} />
      <Cpu value={statuses.cpu} />
      <Disk value={statuses.disk} />
    </Expanded>
  );
};

const Memory = ({ value }) => {
  return (
    <ItemWrapper onClick={() => run("~/projects/dev/dotfiles/bin/purge.sh")}>
      <span className="ti ti-container" />
      <span>{value}Mb</span>
    </ItemWrapper>
  );
};

const Disk = ({ value }) => {
  return (
    <ItemWrapper>
      <span className="ti ti-chart-pie" />
      <span>{value}%</span>
    </ItemWrapper>
  );
};

const Cpu = ({ value }) => {
  return (
    <ItemWrapper className="cpu">
      <span className="ti ti-activity" />
      <span>{value}%</span>
    </ItemWrapper>
  );
};

const Wrapper = styled.div`
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  font-family: "JetBrainsMono Nerd Font";
  padding-right: 8px;
  & .ti {
    margin-top: -2px;
    font-size: 18px;
  }
`;

const ItemWrapper = styled.button`
  display: flex;
  align-items: center;
  border: none;
  background: transparent;
  color: ${colors.white};
  cursor: pointer;
  padding: 0;
  font-size: 12px;
`;

const Expanded = styled.div`
  overflow: hidden;
  width: 22px;
  display: flex;
  transition: 0.3s;
  &:hover {
    width: 230px;
  }
`;
