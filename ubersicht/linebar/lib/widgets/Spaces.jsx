import { styled, run } from 'uebersicht';
import { useProcess } from '../utils/hooks';
import { YABAI } from '../utils/vars';
import { BaseBlock } from '../components/BaseBlock.jsx';
import { WindowTitle } from './WindowTitle.jsx';

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
					<Space
						onClick={() => setSpace(space)}
						key={space.index}
						hoverable
						accent={active.index === space.index}
					>
						{space.index}: {space.label}
					</Space>
				))}
			</SpacesInner>

			<WindowTitle />
		</Wrapper>
	);
};

const Wrapper = styled.div`
	display: flex;
	height: 100%;
	gap: 4px;
`;

const SpacesInner = styled.div`
	display: flex;
	gap: 4px;
`;

const Space = styled(BaseBlock)`
	text-transform: uppercase;
	border: none;
	margin: 0;
	font-weight: bold;
	transition: 0.2s;
	cursor: pointer;
`.withComponent('button');
