import { styled,  React } from "uebersicht";
import { colors, hexToRgba } from "../vars";
import { useProcess, useUpdate } from "../utils";

export const Volume = () => {
  const value = (
    useProcess("osascript -e 'output volume of (get volume settings)'") || ""
  ).trim();
  const isAirpods =
    parseInt(useProcess("~/projects/dev/dotfiles/bin/airpods.sh")) === 1;

  useUpdate(1000);

  const icon = isAirpods ? "ti-headphones" : "ti-volume";
  return (
    <VolumeInner>
      <span className={"ti " + icon} />
      <span>{value}%</span>
    </VolumeInner>
  );
};

const VolumeInner = styled.div`
  display: flex;
  align-items: center;
  border: none;
  background: transparent;
  color: ${colors.background};
  cursor: pointer;
  gap: 2px;
  padding: 0 8px;
  font-weight: bold;
  font-size: 12px;
  background-color: ${hexToRgba(colors.yellow)};
  & .ti {
    font-weight: bold;
  }
`;
