#!/bin/bash
# ════════════════════════════════════════════════════════════════════════════
# Claude Code — Status Line: branch, model, context, cost
#
# Dependencies: bash, jq
# License: MIT
#
# Default: main★ │ Opus 5/hi │ Ctx: 42% ▓▓▓▓░░░░░┃ │ $0.12 1h4m
# Narrow:  main★ c42%
#
# Level is carried by colour, not by an emoji dot. The dot said nothing the
# percentage next to it didn't already say, and being double-width it shifted
# the line by a different amount in every terminal font. That colour is also
# what lets the narrow layouts drop the meters without losing anything.
#
# The line measures the terminal and picks the roomiest of five layouts that
# fits (see "Assemble" at the bottom); STATUSLINE_COLS=<n> forces a width.
# ════════════════════════════════════════════════════════════════════════════

# ── Configuration (override via environment variables) ────────────────────────
SETTINGS_FILE="${SETTINGS_FILE:-$HOME/.claude/settings.json}"
BAR_WIDTH="${BAR_WIDTH:-9}"                          # cells in a meter

# LC_NUMERIC matters: the API sends "0.1234", and under a
# comma-decimal locale printf %.2f stops reading at the dot and renders "$0,00".
export LC_NUMERIC=C

# ── Colors ────────────────────────────────────────────────────────────────────
# Plain SGR, not 256-color: this line lands in whatever terminal the user is in,
# and the base eight follow its palette instead of fighting it.
C_RESET=$'\033[0m'
C_DIM=$'\033[2m'
C_ACCENT=$'\033[36m'
C_OK=$'\033[32m'
C_WARN=$'\033[33m'
C_CRIT=$'\033[31m'

# ── Helpers ───────────────────────────────────────────────────────────────────
format_remaining() {
    local secs="$1"
    [ "$secs" -le 0 ] 2>/dev/null && return
    local h=$(( secs / 3600 )) m=$(( (secs % 3600) / 60 ))
    if [ $h -gt 0 ]; then echo "${h}h${m}m"
    elif [ $m -gt 0 ]; then echo "${m}m"
    else echo "<1m"
    fi
}

# Coerce to a bare non-negative integer. Drops the decimal part then strips any
# non-digit. Critical: percentages/resets flow into $(( )), where a value like
# "x[$(cmd)]" would execute cmd via arithmetic array-subscript evaluation.
num() {
    local v="${1%%.*}"
    v="${v//[^0-9]/}"
    echo "$(( 10#${v:-0} ))"   # 10# forces base 10 — a leading zero would be read as octal
}

# make_bar <percent> [width] → sets BAR_COLOR (an SGR sequence) and BAR_STR (the
# meter, <width> cells plus an end cap so the empty tail has a visible right
# edge). Width 0 leaves BAR_STR empty — the narrow layouts keep the colour,
# which carries the level, and drop the meter, which only restates the number.
make_bar() {
    local pct; pct="$(num "$1")"
    local w="${2:-$BAR_WIDTH}"
    [ "$pct" -gt 100 ] && pct=100
    BAR_STR=""
    if [ "$w" -gt 0 ] 2>/dev/null; then
        # Round up: 1% has to light the first cell, or "just started" reads as "idle".
        local filled=$(( (pct * w + 99) / 100 ))
        [ $filled -gt "$w" ] && filled=$w
        local empty=$(( w - filled ))
        local i
        for ((i=0; i<filled; i++)); do BAR_STR+="▓"; done
        for ((i=0; i<empty;  i++)); do BAR_STR+="░"; done
        BAR_STR+="┃"
    fi
    if   [ "$pct" -lt 50 ]; then BAR_COLOR="$C_OK"
    elif [ "$pct" -lt 80 ]; then BAR_COLOR="$C_WARN"
    else                         BAR_COLOR="$C_CRIT"
    fi
}

# quota_seg <prefix> <percent> <bar_width> [suffix] →
#   "Ctx: 42% ▓▓▓▓░░░░░┃", coloured by level. The prefix is
# taken verbatim ("Ctx: ", "Ctx ", "c") so each layout can spend as many cells
# on the label as it can afford.
# It sets QSEG rather than printing: the layout loop below may build the line
# five times over, and a command substitution per segment would put twenty forks
# behind every keystroke.
quota_seg() {
    local prefix="$1" bar_w="$3" suffix="${4:-}" pct
    pct="$(num "$2")"
    make_bar "$pct" "$bar_w"
    local out="${prefix}${pct}%"
    [ -n "$BAR_STR" ] && out="${out} ${BAR_STR}"
    [ -n "$suffix" ]  && out="${out} ${suffix}"
    QSEG="${BAR_COLOR}${out}${C_RESET}"
}

# ── Fitting the line to the terminal ─────────────────────────────────────────
# Claude runs this hook with stdin on a pipe and no controlling terminal: $COLUMNS
# is unset, /dev/tty does not open, and `tput cols` answers with its 80-column
# default rather than an error. The real width belongs to the pty *claude* is
# attached to, so ask ps which one that is and stty how wide it is. 0 means "no
# idea" — the caller then renders the full line instead of compressing on a guess.
# The walk up the ancestry is deliberate: the hook's own parent is claude today,
# but a `bash -c` wrapper in between would report "?" and silently turn the whole
# thing off, so climb a few generations before giving up.
term_cols() {
    if [[ "${STATUSLINE_COLS:-}" =~ ^[0-9]+$ ]]; then echo "$STATUSLINE_COLS"; return; fi
    local pid="${PPID:-0}" dev size hop
    for hop in 1 2 3 4; do
        [ "$pid" -gt 1 ] 2>/dev/null || break
        read -r dev pid < <(ps -o tty=,ppid= -p "$pid" 2>/dev/null)
        [ -z "$dev" ] && break
        if [ "$dev" != "?" ] && [ -c "/dev/$dev" ]; then
            size=$(stty size <"/dev/$dev" 2>/dev/null) || break
            size="${size#* }"               # "rows cols" → cols
            [[ "$size" =~ ^[0-9]+$ ]] && { echo "$size"; return; }
            break
        fi
    done
    echo 0
}

# Visible width of a rendered line: characters left after the SGR sequences are
# taken out. Every escape this script emits is an SGR (CSI … m), so the strip is
# a plain loop rather than a regex — and it stays fork-free, which matters in a
# hook that runs on every keystroke. Counting characters equals counting cells
# for this charset; under a non-UTF-8 locale bash counts bytes instead, which
# only overestimates, so the line compresses a step early rather than wrapping.
vis_len() {
    local s="$1" out=""
    while [[ "$s" == *$'\033'* ]]; do
        out+="${s%%$'\033'*}"
        s="${s#*$'\033'}"; s="${s#\[}"; s="${s#*m}"
    done
    out+="$s"
    VLEN="${#out}"
}

# ── Read JSON input from stdin ────────────────────────────────────────────────
JSON=$(cat)

# ── Parse all stdin fields in a single jq call ───────────────────────────────
# Joined on US (0x1f), not "|": a "|" in a branch path or model name would shift
# every field. US is non-whitespace so read preserves empty fields.
IFS=$'\x1f' read -r J_MODEL_DISPLAY J_MODEL_RAW J_CTX_PCT J_CTX_SIZE J_COST J_DURATION J_CWD \
    < <(echo "$JSON" | jq -r '[
        (if .model | type == "object" then .model.display_name // "" else "" end),
        (if .model | type == "string" then .model else "" end),
        (.context_window.used_percentage // 0 | tostring | split(".")[0]),
        (.context_window.context_window_size // 0),
        (.cost.total_cost_usd // ""),
        (.cost.total_duration_ms // ""),
        (.workspace.current_dir // "")
    ] | join("\u001f")' 2>/dev/null)

# ── Model ─────────────────────────────────────────────────────────────────────
MODEL="$J_MODEL_DISPLAY"
MODEL=$(echo "$MODEL" | sed 's/Default (\(.*\))/\1/' | sed 's/Claude //' | sed 's/ (.*//')
[ -z "$MODEL" ] && MODEL="$J_MODEL_RAW"
case "$MODEL" in
  claude-sonnet-4-6*|Sonnet\ 4.6*) MODEL="Snt 4.6" ;;
  claude-sonnet-4-5*|Sonnet\ 4.5*) MODEL="Snt 4.5" ;;
  claude-opus-4-6*|Opus\ 4.6*)     MODEL="Opus 4.6" ;;
  claude-opus-4-5*|Opus\ 4.5*)     MODEL="Opus 4.5" ;;
  claude-haiku-4*|Haiku\ 4*)       MODEL="Haiku 4"  ;;
esac
# strip control bytes — model name comes from untrusted JSON (terminal OSC injection)
MODEL="${MODEL//[$'\x01'-$'\x1f'$'\x7f']/}"

# ── Effort level (from settings.json — not yet in stdin JSON) ────────────────
EFFORT_LABEL=""
if [ -f "$SETTINGS_FILE" ]; then
    case "$(jq -r '.effortLevel // empty' "$SETTINGS_FILE" 2>/dev/null)" in
        low)    EFFORT_LABEL="lo" ;;
        medium) EFFORT_LABEL="md" ;;
        high)   EFFORT_LABEL="hi" ;;
        max)    EFFORT_LABEL="mx" ;;
    esac
fi

# ── Context window ────────────────────────────────────────────────────────────
CTX_PERCENT="$(num "${J_CTX_PCT:-0}")"
CTX_LABEL="Ctx"
[ "$J_CTX_SIZE" -ge 900000 ] 2>/dev/null && CTX_LABEL="1M"   # ≥900k → extended 1M context

# ── Session cost + duration ───────────────────────────────────────────────────
COST_STR="" DURATION_STR=""
if [[ "$J_COST" =~ ^[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?$ ]] && [ "$J_COST" != "0" ]; then
    COST_STR=$(printf '$%.2f' "$J_COST" 2>/dev/null)
fi
if [ -n "$J_DURATION" ] && [ "$J_DURATION" != "0" ] && [ "$J_DURATION" != "null" ]; then
    DURATION_STR=$(format_remaining $(( $(num "$J_DURATION") / 1000 )))
fi

# ── Git branch ────────────────────────────────────────────────────────────────
CWD="$J_CWD"
BRANCH="" DIRTY=""
if [ -n "$CWD" ] && [ -d "$CWD" ]; then
    BRANCH=$(git -C "$CWD" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
    if [ -n "$BRANCH" ] && git -C "$CWD" --no-optional-locks diff --quiet HEAD 2>/dev/null; then
        [ -n "$(git -C "$CWD" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null)" ] && DIRTY="★"
    else
        [ -n "$BRANCH" ] && DIRTY="★"
    fi
fi
[ -z "$BRANCH" ] && BRANCH="(no git)"
[ "${#BRANCH}" -gt 30 ] && BRANCH="${BRANCH:0:27}..."

# ── Assemble ─────────────────────────────────────────────────────────────────
# Five layouts, roomiest first. Each step gives up whatever is the least
# informative thing still on the line — the duration, then the meter (the
# colour already carries the level), then the cost, then the model — down to
# branch and the context percentage. render_at sets LINE; the loop below keeps the first that fits.
#
#  0  main★ │ Opus 5/hi │ Ctx: 42% ▓▓▓▓░░░░░┃ │ $0.12 1h4m
#  1  main★ │ Opus 5/hi │ Ctx: 42% ▓▓▓░░░┃ │ $0.12 1h4m
#  2  main★ │ Opus 5 │ Ctx: 42% │ $0.12
#  3  main★ │ Opus 5 │ Ctx 42%
#  4  main★ c42%
render_at() {
    local d="$1" bar_w branch_max b parts=() part
    case "$d" in
        0) bar_w=$BAR_WIDTH; branch_max=30 ;;
        1) bar_w=6;          branch_max=24 ;;
        2) bar_w=0;          branch_max=18 ;;
        3) bar_w=0;          branch_max=14 ;;
        *) bar_w=0;          branch_max=10 ;;
    esac

    b="$BRANCH"
    [ "${#b}" -gt "$branch_max" ] && b="${b:0:$((branch_max - 1))}…"
    local branch_seg="${C_ACCENT}${b}${C_RESET}${C_WARN}${DIRTY}${C_RESET}"

    if [ "$d" -ge 4 ]; then
        # Mobile: no separators, one-letter labels. "1M" cannot shrink to its
        # first character — "142%" would read as a number, so it becomes "M".
        local ctx_short="c"; [ "$CTX_LABEL" = "1M" ] && ctx_short="M"
        quota_seg "$ctx_short" "$CTX_PERCENT" 0
        LINE="${branch_seg} ${QSEG}"
        return
    fi

    parts=("$branch_seg")
    if [ -n "$MODEL" ]; then
        if [ "$d" -le 1 ] && [ -n "$EFFORT_LABEL" ]; then
            parts+=("${C_DIM}${MODEL}/${EFFORT_LABEL}${C_RESET}")
        else
            parts+=("${C_DIM}${MODEL}${C_RESET}")
        fi
    fi

    if [ "$d" -le 2 ]; then quota_seg "${CTX_LABEL}: " "$CTX_PERCENT" "$bar_w"
    else                    quota_seg "${CTX_LABEL} "  "$CTX_PERCENT" "$bar_w"
    fi
    parts+=("$QSEG")

    if [ "$d" -le 1 ] && [ -n "$COST_STR" ] && [ -n "$DURATION_STR" ]; then
        parts+=("${C_DIM}${COST_STR} ${DURATION_STR}${C_RESET}")
    elif [ "$d" -le 2 ] && [ -n "$COST_STR" ]; then
        parts+=("${C_DIM}${COST_STR}${C_RESET}")
    fi

    LINE=""
    for part in "${parts[@]}"; do
        [ -z "$LINE" ] && LINE="$part" || LINE+=" ${C_DIM}│${C_RESET} $part"
    done
}

COLS="$(term_cols)"
# One cell of slack: a line that ends exactly on the last column is at the mercy
# of whatever the host draws after it.
[ "$COLS" -gt 1 ] 2>/dev/null && COLS=$(( COLS - 1 ))

LINE=""
for D in 0 1 2 3 4; do
    render_at "$D"
    [ "$COLS" -le 0 ] && break          # width unknown → leave the full line alone
    vis_len "$LINE"
    [ "$VLEN" -le "$COLS" ] && break
done

echo "${LINE}"
