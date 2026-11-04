#!/bin/bash
# ════════════════════════════════════════════════════════════════════════════
# Claude Code — Status Line with real-time usage tracking
#
# Dependencies: bash, jq, curl
# License: MIT
#
# Default: main★ │ Opus 5/hi │ Ctx: 42% ▓▓▓▓░░░░░┃ │ Usage: 35% ▓▓▓░░░░░░┃ → Reset: 06:10 PM │ $0.12 1h4m
# Narrow:  main★ c42% u35%
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
TIMEZONE="${TIMEZONE:-}"                            # e.g. "America/New_York", empty = system default
REFRESH_INTERVAL="${REFRESH_INTERVAL:-300}"           # seconds between API calls (0 = every render, risks rate limiting)
SHOW_WEEKLY="${SHOW_WEEKLY:-0}"                      # set to 1 to show weekly + sonnet quotas
USAGE_FILE="${USAGE_FILE:-$HOME/.claude/usage-exact.json}"
CREDENTIALS_FILE="${CREDENTIALS_FILE:-$HOME/.claude/.credentials.json}"
SETTINGS_FILE="${SETTINGS_FILE:-$HOME/.claude/settings.json}"
BAR_WIDTH="${BAR_WIDTH:-9}"                          # cells in a meter

# Every label and timestamp below is machine-shaped English, and %p is empty in
# most non-English locales — "06:10 " would look like a truncation.
export LC_TIME=C
# LC_NUMERIC matters more than it looks: the API sends "0.1234", and under a
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
tz_date() {
    local tz="$1"; shift
    if [ -n "$tz" ]; then TZ="$tz" date "$@"; else date "$@"; fi
}

format_remaining() {
    local secs="$1"
    [ "$secs" -le 0 ] 2>/dev/null && return
    local h=$(( secs / 3600 )) m=$(( (secs % 3600) / 60 ))
    if [ $h -gt 0 ]; then echo "${h}h${m}m"
    elif [ $m -gt 0 ]; then echo "${m}m"
    else echo "<1m"
    fi
}

# Cross-platform ISO 8601 → epoch (GNU date -d || BSD date -j)
iso_to_epoch() {
    local iso="$1"
    date -d "$iso" +%s 2>/dev/null && return
    # macOS/BSD fallback: strip the offset/Z and fractional seconds, then parse the
    # core as UTC (-u). The API always sends +00:00, so the stripped wall-clock IS
    # UTC; without -u, date -j would read it as local time and skew the countdown.
    local core="${iso%[+-][0-9][0-9]:*}"  # strip +HH:MM / -HH:MM suffix
    core="${core%Z}"                       # strip trailing Z
    core="${core%%.*}"                     # strip .fractional
    date -juf "%Y-%m-%dT%H:%M:%S" "$core" +%s 2>/dev/null
}

file_mtime() {
    if stat --version &>/dev/null; then
        stat -c %Y "$1" 2>/dev/null || echo 0
    else
        stat -f %m "$1" 2>/dev/null || echo 0
    fi
}

cache_age_sec() {
    [ ! -f "$USAGE_FILE" ] && echo 999999 && return
    local age=$(( $(date +%s) - $(file_mtime "$USAGE_FILE") ))
    [ "$age" -lt 0 ] && age=0
    echo "$age"
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

# reset_clock <reset_epoch> [time_fmt] → "06:10 PM", empty when unset or past.
# The reset is shown as a clock time rather than a countdown: "06:10 PM" answers
# "can I finish this before it rolls over" without arithmetic, and it does not
# go stale between renders. Needs NOW set by the caller. Called once per render,
# never inside the layout loop — it forks `date`.
reset_clock() {
    local reset="$1" fmt="${2:-%I:%M %p}"
    [ -n "$reset" ] && [ "$reset" -gt "$NOW" ] 2>/dev/null || return 0
    # GNU date -d @epoch || BSD date -r epoch
    tz_date "${TIMEZONE}" -d "@$reset" +"$fmt" 2>/dev/null \
        || tz_date "${TIMEZONE}" -r "$reset" +"$fmt" 2>/dev/null
}

# quota_seg <prefix> <percent> <bar_width> [suffix] →
#   "Usage: 63% ▓▓▓▓▓▓░░░┃ → Reset: 06:10 PM", coloured by level. The prefix is
# taken verbatim ("Usage: ", "Use ", "u") so each layout can spend as many cells
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
# every field. US is non-whitespace so read preserves empty fields (absent
# rate_limits). rate_limits.* is native since Claude Code 2.1.x (Pro/Max) —
# preferred over the API call when present.
IFS=$'\x1f' read -r J_MODEL_DISPLAY J_MODEL_RAW J_CTX_PCT J_CTX_SIZE J_COST J_DURATION J_CWD \
    J_RL_5H_PCT J_RL_5H_RESET J_RL_7D_PCT J_RL_7D_RESET \
    < <(echo "$JSON" | jq -r '[
        (if .model | type == "object" then .model.display_name // "" else "" end),
        (if .model | type == "string" then .model else "" end),
        (.context_window.used_percentage // 0 | tostring | split(".")[0]),
        (.context_window.context_window_size // 0),
        (.cost.total_cost_usd // ""),
        (.cost.total_duration_ms // ""),
        (.workspace.current_dir // ""),
        (.rate_limits.five_hour.used_percentage // ""),
        (.rate_limits.five_hour.resets_at // ""),
        (.rate_limits.seven_day.used_percentage // ""),
        (.rate_limits.seven_day.resets_at // "")
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

# ── Refresh usage via Anthropic OAuth API ────────────────────────────────────
refresh_usage_api() {
    [ ! -f "$CREDENTIALS_FILE" ] && return 1
    local token
    token=$(jq -r '.claudeAiOauth.accessToken // empty' "$CREDENTIALS_FILE" 2>/dev/null)
    [ -z "$token" ] && return 1
    local resp
    resp=$(curl -s --max-time 3 \
        "https://api.anthropic.com/api/oauth/usage" \
        -H "Authorization: Bearer $token" \
        -H "anthropic-beta: oauth-2025-04-20" \
        -H "Content-Type: application/json" 2>/dev/null)
    echo "$resp" | jq -e '.five_hour.utilization' >/dev/null 2>&1 || return 1
    local tmp
    tmp=$(mktemp "${USAGE_FILE}.XXXXXX") || return 1
    if echo "$resp" | jq '{
        timestamp: (now | todate),
        source: "api",
        metrics: {
            session: {
                percent_used: .five_hour.utilization,
                percent_remaining: (100 - .five_hour.utilization),
                resets_at: .five_hour.resets_at
            },
            week_all: {
                percent_used: .seven_day.utilization,
                percent_remaining: (100 - .seven_day.utilization),
                resets_at: .seven_day.resets_at
            },
            week_sonnet: (if .seven_day_sonnet then {
                percent_used: .seven_day_sonnet.utilization,
                percent_remaining: (100 - .seven_day_sonnet.utilization),
                resets_at: .seven_day_sonnet.resets_at
            } else null end)
        }
    }' > "$tmp"; then
        mv "$tmp" "$USAGE_FILE"
    else
        rm -f "$tmp"; return 1
    fi
}

# Native stdin rate_limits (Pro/Max, CC ≥2.1.x) cover session + weekly-all. The
# API is only needed for the Sonnet quota (SHOW_WEEKLY) or as a fallback when the
# stdin field is absent — so most renders make no network call at all.
HAVE_STDIN_SESSION=0
[ -n "$J_RL_5H_PCT" ] && [ "$J_RL_5H_PCT" != "null" ] && HAVE_STDIN_SESSION=1
NEED_API=1
[ "$HAVE_STDIN_SESSION" = 1 ] && [ "$SHOW_WEEKLY" != "1" ] && NEED_API=0

[[ "$REFRESH_INTERVAL" =~ ^[0-9]+$ ]] || REFRESH_INTERVAL=300

# Lock outside world-writable /tmp to avoid a symlink/clobber on shared hosts.
LOCK_FILE="${XDG_RUNTIME_DIR:-$HOME/.claude}/statusline-refresh.lock"
if [ "$NEED_API" = 1 ] && [ "$(cache_age_sec)" -gt "$REFRESH_INTERVAL" ]; then
    # 2>/dev/null: if the lock dir is missing, skip the refresh quietly (no stderr noise)
    ( flock -n 9 || exit 0; refresh_usage_api ) 9>"$LOCK_FILE" 2>/dev/null
fi

# ── Resolve usage metrics: native stdin (preferred) → API cache (fallback) ────
NOW=$(date +%s)

SESS_PCT="" SESS_EPOCH="" SESS_FROM_CACHE=0
WEEK_PCT="" WEEK_EPOCH="" SONNET_PCT=""

# Leave the epoch empty when no reset is sent — num("") is "0", which the
# past-window rule would read as a past reset and wrongly zero the live percentage.
if [ "$HAVE_STDIN_SESSION" = 1 ]; then
    SESS_PCT="$J_RL_5H_PCT"
    [ -n "$J_RL_5H_RESET" ] && [ "$J_RL_5H_RESET" != "null" ] && SESS_EPOCH="$(num "$J_RL_5H_RESET")"
fi
if [ "$SHOW_WEEKLY" = "1" ] && [ -n "$J_RL_7D_PCT" ] && [ "$J_RL_7D_PCT" != "null" ]; then
    WEEK_PCT="$J_RL_7D_PCT"
    [ -n "$J_RL_7D_RESET" ] && [ "$J_RL_7D_RESET" != "null" ] && WEEK_EPOCH="$(num "$J_RL_7D_RESET")"
fi

# Cache only fills metrics stdin didn't provide. resets_at parsed as ISO 8601
# (API format); the Sonnet weekly quota is API-only (absent from stdin).
if [ -f "$USAGE_FILE" ]; then
    IFS=$'\x1f' read -r CACHE_SOURCE U_SESS_PCT U_SESS_RESETS U_WEEK_PCT U_WEEK_RESETS U_SONNET_PCT \
        < <(jq -r '[
            (.source // "legacy"),
            (.metrics.session.percent_used     // ""),
            (.metrics.session.resets_at        // ""),
            (.metrics.week_all.percent_used    // ""),
            (.metrics.week_all.resets_at       // ""),
            (.metrics.week_sonnet.percent_used // "")
        ] | join("\u001f")' "$USAGE_FILE" 2>/dev/null)

    if [ -z "$SESS_PCT" ] && [ -n "$U_SESS_PCT" ] && [ "$U_SESS_PCT" != "null" ]; then
        SESS_PCT="$U_SESS_PCT"; SESS_FROM_CACHE=1
        [ "$CACHE_SOURCE" = "api" ] && [ -n "$U_SESS_RESETS" ] && SESS_EPOCH="$(iso_to_epoch "$U_SESS_RESETS")"
    fi
    if [ "$SHOW_WEEKLY" = "1" ]; then
        if [ -z "$WEEK_PCT" ] && [ -n "$U_WEEK_PCT" ] && [ "$U_WEEK_PCT" != "null" ]; then
            WEEK_PCT="$U_WEEK_PCT"
            [ "$CACHE_SOURCE" = "api" ] && [ -n "$U_WEEK_RESETS" ] && WEEK_EPOCH="$(iso_to_epoch "$U_WEEK_RESETS")"
        fi
        [ -n "$U_SONNET_PCT" ] && [ "$U_SONNET_PCT" != "null" ] && SONNET_PCT="$U_SONNET_PCT"
    fi
fi

# ── Resolve the numbers once ─────────────────────────────────────────────────
# A reset moment already behind us means the window rolled over → back to 0%.
[ -n "$SESS_EPOCH" ] && [ "$SESS_EPOCH" -le "$NOW" ] 2>/dev/null && SESS_PCT=0
[ -n "$WEEK_EPOCH" ] && [ "$WEEK_EPOCH" -le "$NOW" ] 2>/dev/null && WEEK_PCT=0
SESS_RESET_TXT="$(reset_clock "$SESS_EPOCH")"
# The weekly reset is days out, so its clock carries the weekday too.
WEEK_RESET_TXT="$(reset_clock "$WEEK_EPOCH" "%a %I:%M %p")"

HAVE_SESS=0; [ -n "$SESS_PCT" ]   && [ "$SESS_PCT" != "null" ]   && HAVE_SESS=1
HAVE_WEEK=0; [ -n "$WEEK_PCT" ]   && [ "$WEEK_PCT" != "null" ]   && HAVE_WEEK=1
HAVE_SNT=0;  [ -n "$SONNET_PCT" ] && [ "$SONNET_PCT" != "null" ] && HAVE_SNT=1

# ── Stale indicator — the usage segment goes dim and picks up a trailing "~".
# Only when the session number came from the cache: stdin rate_limits are always
# fresh, so cache age says nothing about them.
IS_STALE=0
if [ "$SESS_FROM_CACHE" = 1 ] && [ -f "$USAGE_FILE" ] && [ "$REFRESH_INTERVAL" -gt 0 ] 2>/dev/null; then
    [ "$(cache_age_sec)" -gt $(( REFRESH_INTERVAL * 3 )) ] && IS_STALE=1   # 3 missed refresh windows
fi

# ── Assemble ─────────────────────────────────────────────────────────────────
# Five layouts, roomiest first. Each step gives up whatever is the least
# informative thing still on the line — the weekly quota, then the meters (the
# colour already carries the level), then the reset clock, then the cost, then
# the model — down to branch and the two percentages, which is what this line
# exists for. render_at sets LINE; the loop below keeps the first that fits.
#
#  0  main★ │ Opus 5/hi │ Ctx: 42% ▓▓▓▓░░░░░┃ │ Usage: 35% ▓▓▓░░░░░░┃ → Reset: 06:10 PM │ $0.12 1h4m
#  1  main★ │ Opus 5/hi │ Ctx: 42% ▓▓▓░░░┃ │ Usage: 35% ▓▓░░░░┃ → 06:10 PM │ $0.12 1h4m
#  2  main★ │ Opus 5 │ Ctx: 42% │ Usage: 35% → 06:10 PM │ $0.12
#  3  main★ │ Opus 5 │ Ctx 42% │ Use 35%
#  4  main★ c42% u35%
render_at() {
    local d="$1" bar_w branch_max reset_pfx b usage_seg parts=() part
    case "$d" in
        0) bar_w=$BAR_WIDTH; branch_max=30; reset_pfx="→ Reset: " ;;
        1) bar_w=6;          branch_max=24; reset_pfx="→ " ;;
        2) bar_w=0;          branch_max=18; reset_pfx="→ " ;;
        3) bar_w=0;          branch_max=14; reset_pfx="" ;;
        *) bar_w=0;          branch_max=10; reset_pfx="" ;;
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
        if [ "$HAVE_SESS" = 1 ]; then quota_seg "u" "$SESS_PCT" 0; LINE+=" ${QSEG}"; fi
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

    if [ "$HAVE_SESS" = 1 ]; then
        if [ "$d" -le 2 ]; then
            quota_seg "Usage: " "$SESS_PCT" "$bar_w" \
                "${SESS_RESET_TXT:+${reset_pfx}${SESS_RESET_TXT}}"
        else
            quota_seg "Use " "$SESS_PCT" "$bar_w"
        fi
        usage_seg="$QSEG"
        if [ "$IS_STALE" = 1 ]; then
            # Dim before the level colour: SGR 2 and SGR 3x combine, so the
            # segment keeps saying which level it is while reading as "not current".
            usage_seg="${C_DIM}${usage_seg%"$C_RESET"} ~${C_RESET}"
        fi
        parts+=("$usage_seg")
    fi

    if [ "$d" = 0 ] && [ "$SHOW_WEEKLY" = "1" ]; then
        local week_seg=""
        if [ "$HAVE_WEEK" = 1 ]; then
            quota_seg "Week: " "$WEEK_PCT" "$bar_w" \
                "${WEEK_RESET_TXT:+${reset_pfx}${WEEK_RESET_TXT}}"
            week_seg="$QSEG"
        fi
        if [ "$HAVE_SNT" = 1 ]; then
            local snt; snt="$(num "$SONNET_PCT")"; make_bar "$snt" 0
            [ -n "$week_seg" ] && week_seg+=" ${C_DIM}·${C_RESET} "
            week_seg+="${BAR_COLOR}Snt: ${snt}%${C_RESET}"
        fi
        [ -n "$week_seg" ] && parts+=("$week_seg")
    fi

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
