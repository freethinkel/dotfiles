import { styled, run } from 'uebersicht';
import { useProcess } from '../utils/hooks';
import { YABAI } from '../utils/vars';
import { WindowTitle } from './WindowTitle.jsx';
import { theme, toOpacity } from '../utils/theme';
import { Icon } from '../components/Icon.jsx'

const SPACE_ICONS = {
  'web': 'world-www',
  "code": "code-dots",
  "chat": "brand-wechat",
  "music": "music",
  "term": "3d-cube-sphere"
}

export const Spaces = () => {
  const [query] = useProcess(`${YABAI} -m query --spaces`);
  const [active, setActive] = useProcess(
    `${YABAI} -m query --spaces --space`,
    (value) => JSON.parse(value || '{}')
  );
  const spaces = JSON.parse(query || '[]');

  const setSpace = (space) => {
    setActive(JSON.stringify(space));
    run(`${YABAI} -m space --focus ${space.label}`);
  };

  return (
    <Wrapper>
      <SpacesInner>
        {spaces.map((space) => (
          <SpacItem
            onClick={() => setSpace(space)}
            key={space.index}
            data-active={active.index === space.index}
          // hoverable
          >
            <Icon size={24} name={SPACE_ICONS[space.label]} />
            {space.label}
          </SpacItem>
        ))}
      </SpacesInner>

      <WindowTitle />
    </Wrapper>
  );
};

const Wrapper = styled.div`
	display: flex;
	height: 100%;
	gap: 8px;
`;

const SpacItem = styled.button`
  background: none;
  border: none;
  cursor: pointer;
  padding: 0 3px;
  margin: 0;
  display: flex;
  align-items: center;
  color: ${theme.text};

  &:hover , &[data-active="true"] {
    color:${theme.accent};
  }

  & .icon {
    top: -2px;
  }
`

const SpacesInner = styled.div`
	display: flex;
  padding-left: 5px;
	gap: 2px;
  background-color: ${theme.background};
  border-radius: var(--border-radius);
  border: 1px solid ${toOpacity(theme.accent, 0.12)};
`;

