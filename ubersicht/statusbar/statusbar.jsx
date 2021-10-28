import { styled, run } from "uebersicht";
import { Spaces } from "./lib/spaces.jsx";
import { Statuses } from "./lib/statuses.jsx";
import { Center } from "./lib/center.jsx";
import { colors } from "./lib/colors";

export const refreshFrequency = false;

export const render = (props) => {
  const spaces = props.spaces || [];
  const activeSpace = props.activeSpace || 0;
  const statuses = props.statuses || {};
  return (
    <Wrapper>
      <link
        rel="stylesheet"
        href="./statusbar/lib/assets/tabler-icons.min.css"
      />
      <Spaces spaces={spaces} active={activeSpace} />
      <Center statuses={statuses} />
      <Statuses statuses={statuses} />
    </Wrapper>
  );
};

const createAction = (type) => {
  const fn = function (payload) {
    return { type, payload };
  };

  fn.type = type;

  return fn;
};

const setSpaces = createAction("setSpaces");
const setActiveSpace = createAction("setActiveSpace");
const setStatuses = createAction("setStatuses");

export const command = async (dispatch) => {
  const statuses = await Promise.all([
    run("pmset -g batt | egrep '([0-9]+%).*' -o --colour=auto | cut -f1 -d';'"),
    run("pmset -g batt | grep -c 'AC'"),
    run('date +"%H:%M:%S"'),
    run(
      '/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | sed -e "s/^ *SSID: //p" -e d'
    ),
    run("osascript -e 'output volume of (get volume settings)'"),
    run('date +"%a %d %b"'),
    run(
      'ESC=`printf "e"`; ps -A -r -o %cpu | awk \'{s+=$1} END {printf("%05.2f",s/8);}\''
    ),
    run("df -H -l | awk '{ print $5 }'"),
    run("top -l 1 | grep PhysMem: | awk '{print $2 - $6}'"),
    run("~/projects/dev/dotfiles/bin/airpods.sh"),
  ]);

  dispatch(
    setStatuses({
      battery: parseInt(statuses[0]),
      charging: parseInt(statuses[1]) === 1,
      time: statuses[2],
      wifi: statuses[3],
      volume: statuses[4],
      date: statuses[5],
      cpu: statuses[6],
      disk: statuses[7]
        .split(/\n/)
        .filter((_, i) => i > 0)
        .map((e) => parseInt(e) || 0)
        .reduce((acc, curr) => acc + curr),
      memory: statuses[8].trim(),
      airpodsConnected: parseInt(statuses[9]) === 1,
    })
  );
};

export const updateState = (action, state = {}) => {
  const handler = {
    [setSpaces.type]: () => ({ ...state, spaces: action.payload }),
    [setActiveSpace.type]: () => ({ ...state, activeSpace: action.payload }),
    [setStatuses.type]: () => ({ ...state, statuses: action.payload }),
  }[action.type];

  if (handler) {
    return handler();
  }

  return state;
};

const Wrapper = styled.div`
  position: fixed;
  top: 10px;
  left: 10px;
  right: 10px;
  color: ${colors.white};
  display: flex;
  justify-content: space-between;
  background-color: ${colors.background};
`;
