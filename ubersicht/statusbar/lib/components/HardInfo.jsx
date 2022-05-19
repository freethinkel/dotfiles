import { styled } from "uebersicht";
import { useProcess } from "../utils";

export const HardInfo = ({ statuses }) => {
  const statuses = useProcess("");
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
