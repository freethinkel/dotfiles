# overwrite, not append: the var is exported, nested shells would stack --color
export FZF_DEFAULT_OPTS="--color=fg:{{ foreground }},bg:-1,hl:{{ accent }},fg+:{{ foreground }},bg+:{{ selection_background }},hl+:{{ accent }},info:{{ color8 }},prompt:{{ accent }},pointer:{{ accent }},marker:{{ color2 }},spinner:{{ accent }},header:{{ color8 }},border:{{ color8 }},gutter:-1"
