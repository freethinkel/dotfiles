import { styled, run, React } from "uebersicht";
import { colors } from "../colors";
import { useProcess, useUpdate } from "../utils";

const { useState, useEffect } = React;

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
  color: ${colors.white};
  cursor: pointer;
  gap: 2px;
  padding: 0;
  font-size: 12px;
`;
