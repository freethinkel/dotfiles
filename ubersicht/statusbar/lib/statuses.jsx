import { styled, run, React } from "uebersicht";
import { colors } from "./colors";
import { Volume } from "./components/Volume.jsx";
import { Battery } from "./components/Battery.jsx";
import { Wifi } from "./components/Wifi.jsx";

const { useState, useEffect } = React;

export const Statuses = ({ statuses }) => {
  return (
    <Wrapper>
      <Volume />
      <Wifi />
      <HardInfo statuses={statuses} />
      <Battery />
      <DateItem value={statuses.date} />
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

const DateItem = ({ value }) => {
  return (
    <ItemWrapper>
      <span className="ti ti-calendar" />
      <span>{value}</span>
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
  font-family: "JetBrainsMono Nerd Font";
  padding-right: 8px;
  & > *:not(:first-child) {
    position: relative;
    &::before {
      content: "";
      position: absolute;
      top: 4px;
      bottom: 4px;
      left: -8px;
      display: flex;
      background-color: rgba(255, 255, 255, 0.4);
      width: 2px;
    }
  }
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
  gap: 2px;
  padding: 0;
  font-size: 12px;
  & + & {
    margin-left: 16px;
  }
  &.cpu {
    min-width: 65px;
  }
  &.battery {
    & .ti {
      font-size: 22px;
    }
  }
`;

const Expanded = styled.div`
  overflow: hidden;
  width: 22px;
  display: flex;
  transition: 0.3s;
  & > *:not(:first-child) {
    position: relative;
    &::before {
      content: "";
      position: absolute;
      top: 4px;
      bottom: 4px;
      left: -8px;
      display: flex;
      background-color: rgba(255, 255, 255, 0.4);
      width: 2px;
    }
  }
  &:hover {
    width: 230px;
  }
`;
