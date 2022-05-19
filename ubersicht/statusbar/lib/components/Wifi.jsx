import { styled } from "uebersicht";
import { colors } from "../vars";
import { useProcess, useUpdate } from "../utils";

export const Wifi = () => {
  const name = useProcess(
    '/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | sed -e "s/^ *SSID: //p" -e d'
  );

  useUpdate(10 * 1000);

  return (
    <WifiInner>
      <span className="ti ti-wifi"></span>
      <span>{name}</span>
    </WifiInner>
  );
};

const WifiInner = styled.div`
  font-size: 12px;
  display: flex;
  align-items: center;
  gap: 2px;
  padding: 0 8px;
  font-weight: bold;
  background: ${colors.blue};
  color: ${colors.background};
  & .ti {
    font-weight: bold;
  }
`;
