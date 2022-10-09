local keymap = require('config.utils').set_keymap


-- INSERT MAP
keymap('i', 'jk', '<Esc>')
keymap('i', 'jj', '<Esc>')
keymap('i', 'kj', '<Esc>')

-- NORMAL MAP
keymap('n', '+', '<C-a>') -- increment number above cursor
keymap('n', '-', '<C-x>') -- decrement number above cursor
keymap('n', 'ss', ':split<Return>') -- Split horizontal buffer
keymap('n', 'vs', ':vsplit<Return>') -- Split vertical buffer
