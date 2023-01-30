import { styled, run } from 'uebersicht';
import { useProcess } from '../utils/hooks';
import { BaseBlock } from "../components/BaseBlock.jsx"
import { Icon } from '../components/Icon.jsx'
import { theme } from '../utils/theme';

export const Caffeinate = () => {
  const [active, setActive] = useProcess("pgrep -x 'caffeinate'", (value) => Boolean(String(value || "").trim()));

  const handleClick = async () => {
    if (active) {
      run("killall caffeinate");
    } else {
      run("caffeinate -di & disown");
    }
    setActive(!active);
  }

  return <Wrapper active={active} onClick={handleClick}>
    <Icon size={24} name="coffee" />
    {active ? "On" : "Off"}
  </Wrapper>
}


const Wrapper = styled(BaseBlock)`
  color: ${({ active }) => active ? theme.accent : theme.text};
`
