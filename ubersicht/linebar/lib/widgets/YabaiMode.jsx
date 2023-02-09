import { run } from 'uebersicht'
import { BaseBlock } from '../components/BaseBlock.jsx'
import { useProcess } from '../utils/hooks.js'
import { YABAI } from '../utils/vars.js'


export const YabaiMode = () => {

  // LAYOUT="$(yabai -m query --spaces --space | jq -r '.type')"
  const [mode, setMode] = useProcess(`${YABAI} -m query --spaces --space`, (value) => {
    try {
      return JSON.parse(value).type
    } catch (err) {
      return null
    }
  })

  const handleClick = () => {
    const _mode = mode === 'bsp' ? 'stack' : 'bsp'

    run(`${YABAI} -m space --layout ${_mode}`);
    setMode(_mode)
  }

  if (!mode) {
    return null
  }

  return <BaseBlock onClick={handleClick}>{mode}</BaseBlock>
}
