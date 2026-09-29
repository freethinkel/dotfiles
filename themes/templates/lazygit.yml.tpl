gui:
  theme:
    activeBorderColor: ['{{ accent }}', bold]
    inactiveBorderColor: ['{{ color8 }}']
    searchingActiveBorderColor: ['{{ color3 }}', bold]
    optionsTextColor: ['{{ color4 }}']
    selectedLineBgColor: ['{{ selection_background }}']
    inactiveViewSelectedLineBgColor: ['{{ selection_background }}']
    cherryPickedCommitFgColor: ['{{ accent }}']
    cherryPickedCommitBgColor: ['{{ selection_background }}']
    markedBaseCommitFgColor: ['{{ color4 }}']
    markedBaseCommitBgColor: ['{{ color3 }}']
    unstagedChangesColor: ['{{ color1 }}']
    defaultFgColor: ['{{ foreground }}']
git:
  pagers:
    - colorArg: always
      pager: delta --{{ mode }} --paging=never
