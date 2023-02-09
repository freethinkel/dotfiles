import { styled } from 'uebersicht';
import { BAR_HEIGHT } from './lib/utils/vars';
import { Spaces } from './lib/widgets/Spaces.jsx';
import { InfoPanel } from './lib/widgets/InfoPanel.jsx';
import { YabaiMode } from './lib/widgets/YabaiMode.jsx'

export const refreshFrequency = false;

export const command = `sh linebar/lib/scripts/yabai.sh`;

export const render = () => {
  return (
    <Container>
      <link
        rel='stylesheet'
        href='./linebar/lib/assets/tabler-icons.min.css'
      />
      <RoundedCorner
      // style={{ borderTopLeftRadius: '18px' }}
      >
        <YabaiMode />
        <Spaces />
      </RoundedCorner>
      <div />
      <RoundedCorner
        style={{
          justifyContent: 'flex-end',
          // borderTopRightRadius: '18px' 
        }}
      >
        <InfoPanel />
      </RoundedCorner>
    </Container>
  );
};

const RoundedCorner = styled.div`
	border-radius: 5px;
	overflow: hidden;
	display: flex;
  gap: 8px;
`;

const Container = styled.div`
	position: fixed;
	top: 0;
	left: 0;
	width: 100%;
	display: grid;
	grid-template-columns: 1fr 230px 1fr;
	justify-content: space-between;
	box-sizing: border-box;
	padding: 8px;
	height: ${BAR_HEIGHT}px;
  --border-radius: 6px;

	&,
	& * {
    box-sizing: border-box;
		font-family: 'JetBrainsMono Nerd Font', sans-serif;
	}
`;
