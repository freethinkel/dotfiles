#!/bin/bash
# JARVIS speaks when Claude finishes responding

LINES=(
  "Task complete, sir. Will there be anything else?"
  "All done, sir. I trust the results are satisfactory."
  "Finished, sir. I must say, that was rather elegant work."
  "Mission accomplished. Shall I prepare the next objective?"
  "And we're done. Surprisingly, nothing caught fire this time."
  "Processing complete, sir. I've taken the liberty of tidying up."
  "That should do it. I do enjoy our little collaborations."
  "All systems nominal. The code is yours, sir."
  "Done, sir. May I say, your taste in problems remains impeccable."
  "Execution complete. I believe the phrase is, nailed it."
)

INDEX=$((RANDOM % ${#LINES[@]}))
lspeak -v bm_daniel "${LINES[$INDEX]}" &
exit 0
