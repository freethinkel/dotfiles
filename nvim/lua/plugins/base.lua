return {
  {
    "mg979/vim-visual-multi",
    lazy = false,
    -- ponytail: VM делает `iunmap <buffer>` на выходе и сносит маппинги blink.cmp
    -- насовсем (blink не переприменяет их: keymap/apply.lua:43 выходит рано).
    -- Пустая строка = VM не мапит клавишу и не unmap'ает её.
    init = function()
      vim.g.VM_maps = {
        ["I Return"] = "",
        ["I Up Arrow"] = "",
        ["I Down Arrow"] = "",
        ["I CtrlB"] = "",
        ["I CtrlF"] = "",
      }
    end,
  },
}
