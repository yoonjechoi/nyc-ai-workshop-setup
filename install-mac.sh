#!/bin/bash
# 뉴욕 AI 워크숍 — 맥 사전 설치 스크립트 v2 (2026-11-16)
#
# 쓰는 법:  bash install-mac.sh            (전부)
#           bash install-mac.sh --only 8    (8번만 다시)
#           bash install-mac.sh --list      (단계 목록만 보기)
#           bash install-mac.sh --check     (설치 · 로그인 상태 점검 표만. 아무것도 설치하지 않음)
#
# v2 에서 바뀐 것: --check 추가 · 14 힉스필드 스킬 · 15 작업 폴더 CLAUDE.md(Claude 에게 주는 규칙)
#                  · 16 qwen-tts-demo 바로가기와 앱용 PATH · 안내 시간 「약 5분」 · 2번 표에 ffmpeg 버전
#
# 지키는 것
# - Homebrew · 맥 개발자 도구(Xcode Command Line Tools)를 쓰지 않는다. 소스 빌드를 하지 않는다.
# - 관리자 비밀번호를 묻지 않는다(sudo 없음).
# - 이미 깔린 것은 건너뛴다. 몇 번을 다시 돌려도 안전하다.
# - 로그인 · 가입은 하지 않는다. 설치만 한다.
# - 맥에 원래 있는 /usr/bin/git · /usr/bin/python3 는 「개발자 도구 설치」 창만 띄우는 껍데기라 부르지 않는다.
#
# 남기는 것: 화면에는 단계마다 ✅ · ⏭ · ❌, 끝에 점검 표.
#            자세한 기록 = ~/nyc-install.log , 점검 표 = ~/nyc-install-result.txt

export LC_ALL=en_US.UTF-8 2>/dev/null || true

WORKDIR="${NYC_WORKDIR:-$HOME/workspace/nyc-ai-workshop}"
LOG="$HOME/nyc-install.log"
RESULT="$HOME/nyc-install-result.txt"
CACHE="$HOME/.cache/nyc-install"     # 받은 설치 파일 임시 보관(끝나면 지움)
MIN_FREE_GB="${NYC_MIN_FREE_GB:-10}"  # 이보다 적으면 시작하지 않는다
TTS_FREE_GB="${NYC_TTS_FREE_GB:-15}"  # 이보다 적으면 Qwen3-TTS 를 건너뛴다
MIN_MACOS_MAJOR=13                    # Claude Code 터미널판이 macOS 13 이상

ONLY=""
case "${1:-}" in
  --only) ONLY="${2:-}";;
  --list) LIST=1;;
  --check) CHECK=1;;
esac

mkdir -p "$CACHE" "$WORKDIR"
: >>"$LOG"
T0=$(date +%s)

# ───────────────────────── 화면 출력 도우미 ─────────────────────────
ROWS=()          # "번호|이름|결과|버전|초"
FAILED=0
say()  { printf '%s\n' "$*"; printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" >>"$LOG"; }
logc() { printf '\n$ %s\n' "$*" >>"$LOG"; "$@" >>"$LOG" 2>&1; }     # 명령 출력은 로그로만
logsh(){ printf '\n$ %s\n' "$1" >>"$LOG"; bash -c "$1" >>"$LOG" 2>&1; }
secs() { local s=$1; if [ "$s" -ge 60 ]; then printf '%d분 %d초' $((s/60)) $((s%60)); else printf '%d초' "$s"; fi; }
row()  { ROWS+=("$1|$2|$3|$4|$5"); }
free_gb() { df -k "$HOME" | awk 'NR==2{printf "%d", $4/1024/1024}'; }

ok()   { say "   ✅ $2  $3  ($(secs "$4"))"; row "$CUR_N" "$CUR_NAME" "✅" "$3" "$4"; }
skip() { say "   ⏭  이미 있음  $2"; row "$CUR_N" "$CUR_NAME" "⏭ 이미 있음" "$2" 0; }
bad()  { say "   ❌ 실패: $2"; say "      → 자세한 기록: $LOG (맨 아래)"; tail -n 12 "$LOG" | sed 's/^/      | /'; row "$CUR_N" "$CUR_NAME" "❌" "$2" "${3:-0}"; FAILED=$((FAILED+1)); }
pass() { say "   ⏸  건너뜀: $2"; row "$CUR_N" "$CUR_NAME" "⏸ 건너뜀" "$2" 0; }
begin(){ CUR_N=$1; CUR_NAME=$2; STEP_T=$(date +%s); say ""; say "▶ $1. $2"; }
took() { echo $(( $(date +%s) - STEP_T )); }
want() { [ -z "$ONLY" ] || [ "$ONLY" = "$1" ]; }

# 진짜 프로그램인지(맥 기본 껍데기가 아닌지) 본다. 껍데기를 실행하면 개발자 도구 창이 뜨므로 실행하지 않고 판단한다.
# PATH 에 없어도 다른 방법(Homebrew · nvm · volta 등)으로 깐 흔한 자리를 찾아, 겹쳐 깔지 않는다.
ALT_FOUND=()   # "명령|폴더"
alt_dir() {
  local c=$1 d
  for d in /opt/homebrew/bin /usr/local/bin "$HOME/.volta/bin" "$HOME/.bun/bin" "$HOME/.local/bin" "$HOME/.pixi/bin" "$HOME/.npm-global/bin" "$HOME"/.nvm/versions/node/*/bin; do
    [ -x "$d/$c" ] && { echo "$d"; return 0; }
  done
  return 1
}
has() {
  local p d; p=$(command -v "$1" 2>/dev/null)
  if [ -z "$p" ]; then
    d=$(alt_dir "$1") || return 1
    PATH="$d:$PATH"; export PATH
    case " ${ALT_FOUND[*]} " in *" $1|$d "*) ;; *) ALT_FOUND+=("$1|$d");; esac
    return 0
  fi
  case "$p" in
    /usr/bin/git|/usr/bin/python3|/usr/bin/pip3|/usr/bin/make|/usr/bin/clang|/usr/bin/gcc|/usr/bin/cc)
      xcode-select -p >/dev/null 2>&1 || return 1;;
  esac
  return 0
}
alt_note() { local e; for e in "${ALT_FOUND[@]}"; do [ "${e%%|*}" = "$1" ] && { echo " ⚠️ PATH 밖(${e#*|})"; return; }; done; }
ver() { "$@" 2>/dev/null | head -n1 | grep -oE '[0-9]+(\.[0-9]+)+' | head -n1; }

# ───────────────────────── PATH ─────────────────────────
PATH_DIRS=("$HOME/.pixi/bin" "$HOME/.npm-global/bin" "$HOME/.bun/bin" "$HOME/.local/bin")
for d in "${PATH_DIRS[@]}"; do case ":$PATH:" in *":$d:"*) ;; *) PATH="$d:$PATH";; esac; done
export PATH

write_path_block() {
  local f block
  block='# >>> nyc-ai-workshop >>>
export PATH="$HOME/.pixi/bin:$HOME/.npm-global/bin:$HOME/.bun/bin:$HOME/.local/bin:$PATH"
# <<< nyc-ai-workshop <<<'
  for f in "$HOME/.zshenv" "$HOME/.zprofile" "$HOME/.bash_profile"; do
    touch "$f"
    grep -q '>>> nyc-ai-workshop >>>' "$f" 2>/dev/null || printf '\n%s\n' "$block" >>"$f"
  done
}

# ───────────────────────── 공식 주소 찾기 ─────────────────────────
ARCH=$(uname -m)   # arm64 | x86_64
url_claude_app() {
  curl -fsSL https://downloads.claude.ai/releases/darwin/universal/RELEASES.json \
    | tr ',' '\n' | grep -oE 'https://downloads\.claude\.ai/releases/darwin/universal/[^"]*\.zip' | tail -n1
}
url_aside_app() {
  local a=arm64; [ "$ARCH" = x86_64 ] && a=x64
  { curl -fsSL https://aside.com/download; curl -fsSL https://ptqgesmtzwdmeiknncqc.supabase.co/functions/v1/omaha/version_info.json; } 2>/dev/null \
    | sed 's#\\/#/#g' | grep -oE "https://releases\.aside\.com/dev-updater/Aside-[0-9.]+-$a\.dmg" | head -n1
}
url_telegram_app() { echo "https://telegram.org/dl/macos"; }
url_capcut_app() {
  # 캡컷 공식 업데이트 주소가 알려 주는 「정식판」 전체 설치 파일(베타는 받지 않는다)
  local r
  for r in GB US SG; do
    curl -fsSL "https://editor-api-sg.capcutapi.com/service/settings/v3/?aid=359289&device_platform=mac&channel=capcutpc_0&version_code=1&os_version=26.4&region=$r&traffic_type=release" 2>/dev/null \
      | sed 's#\\/#/#g' | grep -oE '"lastest_stable_url" *: *"https://[^"]*capcutstatic\.com/[^"]*\.dmg"' \
      | grep -oE 'https://[^"]*\.dmg' | grep -vi beta | head -n1 | grep . && return 0
  done
  return 1
}

# ───────────────────────── 앱 받기(뒤에서 미리) ─────────────────────────
# 큰 파일(캡컷 1.4GB 등)을 다른 설치가 도는 동안 미리 받는다.
APPS=("Claude|Claude.app|url_claude_app|zip" "Aside|Aside.app|url_aside_app|dmg" "Telegram|Telegram.app|url_telegram_app|dmg" "CapCut|CapCut.app|url_capcut_app|dmg")
app_installed() { [ -d "/Applications/$1" ] || [ -d "$HOME/Applications/$1" ]; }

prefetch_apps() {
  local e key app fn ext url
  for e in "${APPS[@]}"; do
    IFS='|' read -r key app fn ext <<<"$e"
    app_installed "$app" && continue
    [ -s "$CACHE/$key.$ext" ] && [ ! -e "$CACHE/$key.part" ] && continue
    url=$($fn 2>/dev/null)
    if [ -z "$url" ]; then echo "noaddr" >"$CACHE/$key.err"; continue; fi
    echo "$url" >"$CACHE/$key.url"
    touch "$CACHE/$key.part"
    if curl -fL --retry 3 --retry-delay 2 -C - -o "$CACHE/$key.$ext.tmp" "$url" >>"$CACHE/$key.dl.log" 2>&1; then
      mv "$CACHE/$key.$ext.tmp" "$CACHE/$key.$ext"
    else
      echo "download" >"$CACHE/$key.err"
    fi
    rm -f "$CACHE/$key.part"
  done
}

install_app() {   # key app ext
  local key=$1 app=$2 ext=$3 f="$CACHE/$1.$3" dest=/Applications mnt src waited=0 team
  [ -w /Applications ] || dest="$HOME/Applications"
  mkdir -p "$dest"
  # 미리 받기가 아직 돌고 있으면 기다린다
  # 미리 받기가 이 파일을 아직 받는 중이거나 아직 차례가 안 왔으면 기다린다(같은 파일을 두 번 받지 않게)
  while [ -e "$CACHE/$key.part" ] || { [ -n "${PREFETCH_PID:-}" ] && kill -0 "$PREFETCH_PID" 2>/dev/null && [ ! -s "$f" ] && [ ! -e "$CACHE/$key.err" ]; }; do
    [ $((waited % 30)) -eq 0 ] && say "   … $key 설치 파일 받는 중 ($(du -sh "$f.tmp" 2>/dev/null | cut -f1) 받음)" >&2
    sleep 5; waited=$((waited+5))
  done
  if [ ! -s "$f" ]; then
    # 뒤에서 못 받았으면 지금 한 번 더 받는다
    rm -f "$CACHE/$key.err"; local fn; for e in "${APPS[@]}"; do IFS='|' read -r k a fn x <<<"$e"; [ "$k" = "$key" ] && break; done
    local url; url=$($fn 2>/dev/null)
    [ -z "$url" ] && { echo "공식 설치 파일 주소를 찾지 못함"; return 1; }
    logc curl -fL --retry 3 -o "$f" "$url" || { echo "설치 파일 받기 실패"; return 1; }
  fi
  if [ "$ext" = zip ]; then
    logc ditto -x -k "$f" "$dest/" || { echo "압축 풀기 실패"; return 1; }
  else
    mnt=$(mktemp -d "$CACHE/mnt.XXXX")
    yes | hdiutil attach -nobrowse -noautoopen -noverify -mountpoint "$mnt" "$f" >>"$LOG" 2>&1 || { echo "설치 파일 열기 실패"; return 1; }
    src=$(find "$mnt" -maxdepth 2 -name "*.app" -type d | head -n1)
    [ -z "$src" ] && { hdiutil detach -quiet "$mnt"; echo "설치 파일 안에 앱이 없음"; return 1; }
    rm -rf "$dest/$app.tmp"
    logc ditto "$src" "$dest/$app" || { hdiutil detach -quiet "$mnt"; echo "응용 프로그램 폴더로 복사 실패"; return 1; }
    hdiutil detach -quiet "$mnt" || hdiutil detach -force -quiet "$mnt"
    rmdir "$mnt" 2>/dev/null
  fi
  [ -d "$dest/$app" ] || { echo "앱이 안 보임"; return 1; }
  team=$(codesign -dv --verbose=2 "$dest/$app" 2>&1 | sed -n 's/^TeamIdentifier=//p')
  [ -n "$team" ] && [ "$team" != "not set" ] || { echo "서명 없음 — 공식 앱이 아닐 수 있어 지움"; rm -rf "$dest/$app"; return 1; }
  echo "서명=$team" >>"$LOG"
  rm -f "$f"
  return 0
}
app_ver() { defaults read "$1/Contents/Info" CFBundleShortVersionString 2>/dev/null; }
app_path() { [ -d "/Applications/$1" ] && echo "/Applications/$1" || echo "$HOME/Applications/$1"; }

# ───────────────────────── 단계 ─────────────────────────
STEPS=(
  "1|pixi(미리 만든 프로그램 받는 도구)"
  "2|Git · GitHub CLI · ffmpeg · Node.js · Python"
  "3|Aside CLI"
  "4|Vercel CLI"
  "5|힉스필드 CLI"
  "6|Bun"
  "7|Claude Code 터미널판"
  "8|Aside 를 Claude 에 연결(MCP)"
  "9|Claude 앱"
  "10|Aside 앱"
  "11|텔레그램 앱"
  "12|캡컷 앱"
  "13|Qwen3-TTS(목소리 만들기)"
  "14|힉스필드 스킬(Claude 가 쓰는 힉스필드 기능 묶음)"
  "15|작업 폴더 규칙(CLAUDE.md)"
  "16|바로가기 · 앱에서도 새 도구가 보이게"
)
if [ "${LIST:-0}" = 1 ]; then for s in "${STEPS[@]}"; do echo "${s%%|*}. ${s#*|}"; done; exit 0; fi

# ───────────────────────── --check : 점검 표만 ─────────────────────────
# 명령마다 시간 제한(멈춰 있는 로그인 확인이 있어도 끝까지 간다). perl 은 맥 기본(진짜 프로그램).
tlimit() { local s=$1; shift; perl -e 'alarm shift; exec @ARGV' "$s" "$@"; }
mask() { sed -E 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+/<메일>/g'; }
if [ "${CHECK:-0}" = 1 ]; then
  C=(); cadd(){ C+=("$1|$2|$3"); }
  st() { [ "$1" = "-" ] && echo "❌" || echo "✅"; }
  for t in "git --version" "gh --version" "node --version" "python3 --version" "bun --version" "vercel --version" "higgsfield --version" "claude --version" "aside --version" "uv --version"; do
    set -- $t
    if has "$1"; then x=$(ver "$@"); x="${x:-있음}$(alt_note "$1")"; else x="-"; fi
    cadd "$1" "$(st "$x")" "$x"
  done
  x=$(has ffmpeg && ffmpeg -version 2>/dev/null | head -n1 | awk '{print $3}' || echo -); cadd ffmpeg "$(st "$x")" "$x"
  V="$WORKDIR/.venv-qwen-tts"
  if [ -x "$V/bin/qwen-tts-demo" ] && tlimit 90 "$V/bin/qwen-tts-demo" --help >/dev/null 2>&1; then cadd "Qwen3-TTS" "✅" "qwen-tts-demo --help 됨"; elif [ ! -x "$V/bin/python" ]; then cadd "Qwen3-TTS" "❌" "안 깔림(빈 공간 15GB 넘게 만든 뒤 bash install-mac.sh --only 13)"; else cadd "Qwen3-TTS" "❌" "qwen-tts-demo 가 안 됨 → bash install-mac.sh --only 13"; fi
  for a in Claude Aside Telegram CapCut; do
    if app_installed "$a.app"; then cadd "$a 앱" "✅" "$(app_ver "$(app_path "$a.app")")"; else cadd "$a 앱" "❌" "없음"; fi
  done
  [ -d "$HOME/.claude/skills/higgsfield-generate" ] && cadd "힉스필드 스킬" "✅" "$(ls -d "$HOME"/.claude/skills/higgsfield-* 2>/dev/null | wc -l | tr -d ' ')개" || cadd "힉스필드 스킬" "❌" "없음"
  L=(); ladd(){ L+=("$1|$2|$3"); }
  # vercel whoami 는 로그아웃이어도 종료 코드 0 → 글자로 판단
  if has vercel; then x=$(tlimit 25 vercel whoami 2>&1 | grep -v '^Vercel CLI' | tail -n1 | mask)
    case "$x" in ""|*[Ll]ogged\ out*|*[Ll]og\ in*|*[Nn]o\ existing*|*[Ee]rror*|*credentials*) ladd Vercel "❌" "로그인 안 됨 → vercel login";; *) ladd Vercel "✅" "$x";; esac
  else ladd Vercel "-" "vercel 없음"; fi
  if has gh; then if tlimit 20 gh auth status >/dev/null 2>&1; then ladd GitHub "✅" "$(tlimit 20 gh api user --jq .login 2>/dev/null)"; else ladd GitHub "❌" "로그인 안 됨 → gh auth login"; fi; else ladd GitHub "-" "gh 없음"; fi
  if has git; then gn=$(git config --global user.name 2>/dev/null); ge=$(git config --global user.email 2>/dev/null)
    [ -n "$gn" ] && [ -n "$ge" ] && ladd "git 이름 · 메일" "✅" "$gn · $(echo "$ge" | mask)" || ladd "git 이름 · 메일" "❌" "git config --global user.name / user.email"
  fi
  # 힉스필드: 상태 명령이 있으면 그걸, 없으면 토큰을 받을 수 있는지만(토큰 값은 버린다)
  if has higgsfield; then x=$(tlimit 25 higgsfield account status 2>/dev/null | head -n1 | mask)
    case "$x" in *credit*|*plan*) ladd 힉스필드 "✅" "$x";;
      *) if tlimit 25 higgsfield auth token >/dev/null 2>&1; then ladd 힉스필드 "✅" "로그인됨"; else ladd 힉스필드 "❌" "로그인 안 됨 → higgsfield auth login"; fi;; esac
  else ladd 힉스필드 "-" "higgsfield 없음"; fi
  if has claude; then if tlimit 20 claude auth status 2>/dev/null | grep -q '"loggedIn": *true'; then ladd "Claude Code 터미널판" "✅" "$(tlimit 20 claude auth status 2>/dev/null | grep -o '"subscriptionType": *"[a-z]*"' | grep -o '"[a-z]*"$' | tr -d '"')"; else ladd "Claude Code 터미널판" "❌" "로그인 안 됨 → claude 실행 후 /login"; fi; else ladd "Claude Code 터미널판" "-" "claude 없음"; fi
  # Aside: 로그인하면 프로필 이름이 내 이름(「홍길동」 · 「홍길동 (Work)」)으로 바뀐다. 로그인 전에는 「Work」 같은 기본 이름.
  #        로그인 상태 명령이 따로 없어 이걸로 본다.
  if has aside; then x=$(tlimit 20 aside host profiles 2>/dev/null | awk -F'\t' 'NR>1 && $3=="connected" && $2 !~ /^(Work|Personal|Default|Profile[ 0-9]*)$/{n++} END{print n+0}')
    [ "${x:-0}" -gt 0 ] && ladd "Aside 로그인" "✅" "로그인된 프로필 ${x}개" || ladd "Aside 로그인" "❌" "Aside 앱에서 Sign in with Google(앱이 꺼져 있으면 켜고 다시 확인)"
  else ladd "Aside 로그인" "-" "aside 없음"; fi
  if has claude; then
    tlimit 20 claude mcp get aside >/dev/null 2>&1 && ladd "Aside MCP" "✅" "Claude 에 연결됨" || ladd "Aside MCP" "❌" "bash install-mac.sh --only 8"
    tlimit 20 claude mcp get elevenlabs >/dev/null 2>&1 && ladd "ElevenLabs MCP" "✅" "Claude 에 연결됨" || ladd "ElevenLabs MCP" "❌" "연결 안 됨 → 문장 ② 의 일레븐랩스 줄을 다시"
  fi
  {
    echo ""
    echo "════════════════ 설치 · 로그인 점검 ($(date '+%m-%d %H:%M')) ════════════════"
    echo "| 설치 | 결과 | 버전 · 메모 |"; echo "|---|---|---|"
    for r in "${C[@]}"; do IFS='|' read -r a b c <<<"$r"; echo "| $a | $b | $c |"; done
    echo ""
    echo "| 로그인 · 연결 | 결과 | 계정 · 메모 |"; echo "|---|---|---|"
    for r in "${L[@]}"; do IFS='|' read -r a b c <<<"$r"; echo "| $a | $b | $c |"; done
    echo ""
    echo "남은 용량: $(free_gb)GB"
  } | tee "$HOME/nyc-check-result.txt"
  exit 0
fi

say "════════════════════════════════════════"
say " 뉴욕 AI 워크숍 설치를 시작합니다 ($(date '+%H:%M'))"
say " 비밀번호를 묻지 않습니다. 약 5분 걸립니다(인터넷이 느리면 더)."
say "════════════════════════════════════════"

# ── 0. 먼저 확인: macOS 버전 · 남은 용량 · 인터넷
begin 0 "먼저 확인(맥 버전 · 남은 용량 · 인터넷)"
MACOS=$(sw_vers -productVersion); MAJOR=${MACOS%%.*}
FREE0=$(free_gb)
say "   맥 버전 macOS $MACOS ($ARCH) · 남은 용량 ${FREE0}GB"
if [ "$MAJOR" -lt "$MIN_MACOS_MAJOR" ]; then
  say ""
  say "   ❌ 맥 버전이 너무 낮습니다(macOS $MACOS). macOS $MIN_MACOS_MAJOR 이상이 필요합니다."
  say "      사과 메뉴 → 시스템 설정 → 일반 → 소프트웨어 업데이트 에서 맥을 업데이트한 뒤 다시 실행해 주세요."
  say "      업데이트가 안 나오는 오래된 맥이면 강사에게 알려 주세요."
  exit 2
fi
# 아직 없는 것만 세어 필요한 용량을 어림한다(nyc-vm-s1 실측: 전부 새로 깔면 약 8GB)
NEED_MB=0
{ has git && has gh && has ffmpeg && has node && has python3; } || NEED_MB=$((NEED_MB+1200))
{ has aside && has vercel && has higgsfield && has bun && has claude; } || NEED_MB=$((NEED_MB+500))
app_installed Claude.app   || NEED_MB=$((NEED_MB+700))
app_installed Aside.app    || NEED_MB=$((NEED_MB+600))
app_installed Telegram.app || NEED_MB=$((NEED_MB+400))
app_installed CapCut.app   || NEED_MB=$((NEED_MB+3700))   # 받는 파일 1.4GB + 앱 2.2GB
TTS_DONE=0; [ -x "$WORKDIR/.venv-qwen-tts/bin/qwen-tts-demo" ] && TTS_DONE=1
NEED_GB=$(( (NEED_MB + 1023) / 1024 + 2 ))   # 여유 2GB
[ "$NEED_MB" -eq 0 ] && NEED_GB=0
[ "$NEED_GB" -gt 0 ] && [ "$NEED_GB" -lt "$MIN_FREE_GB" ] && NEED_GB=$MIN_FREE_GB
if [ "$NEED_MB" -gt 0 ] && [ "$FREE0" -lt "$NEED_GB" ]; then
  MIN_FREE_GB=$NEED_GB
  say ""
  say "   ❌ 남은 용량이 ${FREE0}GB 라 설치를 시작하지 않습니다. 적어도 ${MIN_FREE_GB}GB(넉넉히 15GB)가 비어 있어야 합니다."
  say "      이렇게 비울 수 있습니다:"
  say "      1) 다운로드 폴더 — Finder → 다운로드 → 다 쓴 설치 파일(.dmg · .zip · .pkg)을 휴지통으로"
  say "      2) 안 쓰는 앱 — Finder → 응용 프로그램 → 안 쓰는 앱을 휴지통으로"
  say "      3) 휴지통 비우기 — 독(Dock) 맨 오른쪽 휴지통을 오른쪽 클릭 → 휴지통 비우기"
  say "      4) 큰 파일 찾기 — 사과 메뉴 → 시스템 설정 → 일반 → 저장 공간"
  say "      비운 뒤 다시 실행하면 이어서 합니다."
  exit 2
fi
if ! curl -fsSI --max-time 15 https://pixi.sh/install.sh >/dev/null 2>&1; then
  say "   ❌ 인터넷에 연결되지 않았습니다. 와이파이를 확인하고 다시 실행해 주세요."; exit 2
fi
TTS_OK=1; [ $TTS_DONE = 0 ] && [ "$FREE0" -lt "$TTS_FREE_GB" ] && TTS_OK=0
[ $TTS_OK = 0 ] && say "   ⚠️  남은 용량이 ${TTS_FREE_GB}GB 보다 적어 Qwen3-TTS(13번)는 이번에 건너뜁니다."
say "   ✅ 시작합니다"

write_path_block   # 새 터미널 · Claude 앱에서도 새 도구가 보이게(~/.zshenv · ~/.zprofile · ~/.bash_profile)
[ -z "$ONLY" ] && { prefetch_apps & PREFETCH_PID=$!; }

# ── 1. pixi
if want 1; then begin 1 "pixi(미리 만든 프로그램 받는 도구)"
  if [ -x "$HOME/.pixi/bin/pixi" ]; then skip x "$(ver "$HOME/.pixi/bin/pixi" --version)"
  else
    logsh 'curl -fsSL https://pixi.sh/install.sh | PIXI_NO_PATH_UPDATE=1 bash'
    if [ -x "$HOME/.pixi/bin/pixi" ]; then ok x "pixi" "$(ver pixi --version)" "$(took)"; else bad x "pixi 설치 안 됨" "$(took)"; fi
  fi
fi

# ── 2. Git · gh · ffmpeg · Node.js · Python (pixi 로 한 번에)
if want 2; then begin 2 "Git · GitHub CLI · ffmpeg · Node.js · Python"
  NEED=()
  has git    || NEED+=(git)
  has gh     || NEED+=(gh)
  has ffmpeg || NEED+=(ffmpeg)
  has node   || NEED+=(nodejs)
  has python3 || NEED+=(python)
  if [ ${#NEED[@]} -eq 0 ]; then skip x "모두 있음"
  elif [ ! -x "$HOME/.pixi/bin/pixi" ]; then bad x "pixi 가 없어 못 함(1번 먼저)"
  else
    say "   받는 것: ${NEED[*]}  (미리 만든 것만 받습니다)"
    logc "$HOME/.pixi/bin/pixi" global install "${NEED[@]}"
    MISS=(); for c in git gh ffmpeg node python3; do has "$c" || MISS+=("$c"); done
    if [ ${#MISS[@]} -eq 0 ]; then ok x "" "git $(ver git --version) · gh $(ver gh --version) · ffmpeg $(ffmpeg -version 2>/dev/null | head -n1 | awk '{print $3}') · node $(ver node --version) · python $(ver python3 --version)" "$(took)"; else bad x "안 깔린 것: ${MISS[*]}" "$(took)"; fi
  fi
  # 버전 줄은 표에서 따로 보여 준다
  # uv(파이썬 도구 실행기)는 Qwen3-TTS 와 ElevenLabs MCP(uvx) 가 같이 쓴다. Qwen 을 건너뛰어도 깔리게 여기서 넣는다.
  if ! has uv; then
    logsh 'curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh'
    has uv && say "   + uv $(ver uv --version)" || { say "   ⚠️ uv 설치 실패(13번 · 일레븐랩스 MCP 에 필요)"; }
  fi
fi

on_path() { case ":$PATH:" in *":$1:"*) return 0;; esac; return 1; }
# npm 이 전역 설치를 비밀번호 없이 할 수 있게 자리를 잡는다
npm_ready() {
  has npm || return 1
  local pfx; pfx=$(npm config get prefix 2>/dev/null)
  if [ ! -w "$pfx" ] || ! on_path "$pfx/bin"; then
    mkdir -p "$HOME/.npm-global"
    npm config set prefix "$HOME/.npm-global" >>"$LOG" 2>&1
  fi
  return 0
}

# ── 3. Aside CLI
if want 3; then begin 3 "Aside CLI"
  if has aside; then skip x "$(ver aside --version)"
  else
    logsh 'curl -fsSL https://releases.aside.com/install.sh | bash'
    if has aside; then ok x "" "$(ver aside --version)" "$(took)"; else bad x "aside 명령이 안 보임" "$(took)"; fi
  fi
fi

# ── 4. Vercel CLI
if want 4; then begin 4 "Vercel CLI"
  if has vercel; then skip x "$(ver vercel --version)"
  elif ! npm_ready; then pass x "Node.js 가 없어서(2번 먼저)"
  else
    logc npm install -g vercel
    if has vercel; then ok x "" "$(ver vercel --version)" "$(took)"; else bad x "vercel 명령이 안 보임" "$(took)"; fi
  fi
fi

# ── 5. 힉스필드 CLI (higgsfield.ai/cli 안내: npm). 설치 후 공식 GitHub 릴리스에서 미리 만든 파일을 받는다
if want 5; then begin 5 "힉스필드 CLI"
  if has higgsfield; then skip x "$(ver higgsfield --version)"
  elif ! npm_ready; then pass x "Node.js 가 없어서(2번 먼저)"
  else
    logc npm install -g @higgsfield/cli --allow-scripts=@higgsfield/cli || logc npm install -g @higgsfield/cli
    if has higgsfield && higgsfield --version >/dev/null 2>&1; then ok x "" "$(ver higgsfield --version)" "$(took)"
    else
      # 설치 후 받기(postinstall)가 막혔으면 한 번 더 돌린다
      d="$(npm root -g)/@higgsfield/cli"; [ -f "$d/package.json" ] && (cd "$d" && logc npm run postinstall)
      if has higgsfield && higgsfield --version >/dev/null 2>&1; then ok x "" "$(ver higgsfield --version)" "$(took)"; else bad x "higgsfield 명령이 안 됨" "$(took)"; fi
    fi
  fi
fi

# ── 6. Bun
if want 6; then begin 6 "Bun"
  if has bun; then skip x "$(ver bun --version)"
  else
    logsh 'curl -fsSL https://bun.sh/install | bash'
    if has bun; then ok x "" "$(ver bun --version)" "$(took)"; else bad x "bun 명령이 안 보임" "$(took)"; fi
  fi
fi

# ── 7. Claude Code 터미널판
if want 7; then begin 7 "Claude Code 터미널판"
  if has claude; then skip x "$(ver claude --version)"
  else
    logsh 'curl -fsSL https://claude.ai/install.sh | bash'
    if has claude; then ok x "" "$(ver claude --version)" "$(took)"; else bad x "claude 명령이 안 보임" "$(took)"; fi
  fi
fi

# ── 8. Aside MCP 연결 (Claude 앱 · 터미널판이 같이 쓰는 사용자 설정)
if want 8; then begin 8 "Aside 를 Claude 에 연결(MCP)"
  if ! has claude || ! has aside; then pass x "claude · aside 명령이 둘 다 있어야 함"
  elif claude mcp get aside >/dev/null 2>&1; then skip x "연결돼 있음"
  else
    logc claude mcp add --scope user aside -- "$(command -v aside)" mcp
    if claude mcp get aside >/dev/null 2>&1; then ok x "" "연결함" "$(took)"; else bad x "연결 안 됨" "$(took)"; fi
  fi
fi

# ── 9~12. 앱
n=9
for e in "${APPS[@]}"; do
  IFS='|' read -r key app fn ext <<<"$e"
  if want $n; then
    case $key in Claude) nm="Claude 앱";; Aside) nm="Aside 앱";; Telegram) nm="텔레그램 앱";; CapCut) nm="캡컷 앱";; esac
    begin $n "$nm"
    if app_installed "$app"; then skip x "$(app_ver "$(app_path "$app")")"
    else
      [ "$key" = CapCut ] && say "   캡컷은 파일이 커서(1.4GB) 몇 분 걸립니다."
      FREE_NOW=$(free_gb)
      if [ "$FREE_NOW" -lt 4 ]; then bad x "남은 용량 ${FREE_NOW}GB — 4GB 이상 비워야 함"
      elif msg=$(install_app "$key" "$app" "$ext"); then ok x "" "$(app_ver "$(app_path "$app")")" "$(took)"
      else bad x "${msg:-설치 실패}" "$(took)"; fi
    fi
  fi
  n=$((n+1))
done

# ── 13. Qwen3-TTS (작업 폴더 안 Python 3.12 전용 환경, 미리 만든 파일만, 모델은 안 받음)
if want 13; then begin 13 "Qwen3-TTS(목소리 만들기)"
  VENV="$WORKDIR/.venv-qwen-tts"
  if [ -x "$VENV/bin/qwen-tts-demo" ] && "$VENV/bin/qwen-tts-demo" --help >/dev/null 2>&1; then skip x "$("$VENV/bin/python" -c 'import importlib.metadata as m;print(m.version("qwen-tts"))' 2>/dev/null)"
  elif [ $TTS_OK = 0 ] && [ "$ONLY" != 13 ]; then pass x "용량이 모자라 뺌(시작할 때 ${FREE0}GB, ${TTS_FREE_GB}GB 필요)"
  else
    has uv || logsh 'curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh'
    has sox || { [ -x "$HOME/.pixi/bin/pixi" ] && logc "$HOME/.pixi/bin/pixi" global install sox; }
    if ! has uv; then bad x "uv 설치 실패" "$(took)"
    else
      [ -x "$VENV/bin/python" ] || logc uv venv --python 3.12 "$VENV"
      logc uv pip install --python "$VENV/bin/python" --only-binary :all: qwen-tts
      if "$VENV/bin/qwen-tts-demo" --help >/dev/null 2>&1; then
        ok x "" "$("$VENV/bin/python" -c 'import importlib.metadata as m;print(m.version("qwen-tts"))' 2>/dev/null) (Python $("$VENV/bin/python" -c 'import platform;print(platform.python_version())'))" "$(took)"
      else bad x "qwen-tts-demo --help 가 안 됨" "$(took)"; fi
    fi
  fi
fi

# ── 14. 힉스필드 스킬 (로그인 없이 설치 가능. Claude 가 힉스필드를 쓸 때 읽는 기능 묶음)
if want 14; then begin 14 "힉스필드 스킬(Claude 가 쓰는 힉스필드 기능 묶음)"
  if [ -d "$HOME/.claude/skills/higgsfield-generate" ]; then skip x "$(ls -d "$HOME"/.claude/skills/higgsfield-* 2>/dev/null | wc -l | tr -d ' ')개"
  elif ! has npx; then pass x "Node.js 가 없어서(2번 먼저)"
  else
    (cd "$HOME" && logc npx -y skills add higgsfield-ai/skills -g -a claude-code -s '*' -y)
    if [ -d "$HOME/.claude/skills/higgsfield-generate" ]; then ok x "" "$(ls -d "$HOME"/.claude/skills/higgsfield-* 2>/dev/null | wc -l | tr -d ' ')개" "$(took)"; else bad x "스킬 폴더가 안 보임" "$(took)"; fi
  fi
fi

# ── 15. 작업 폴더 규칙(CLAUDE.md) — 이 폴더에서 일하는 Claude 가 매번 읽는다. 생년월일 같은 개인정보는 적지 않는다.
if want 15; then begin 15 "작업 폴더 규칙(CLAUDE.md)"
  CM="$WORKDIR/CLAUDE.md"
  if grep -q '>>> nyc-ai-workshop 규칙 >>>' "$CM" 2>/dev/null; then skip x "규칙 있음"
  else
    cat >>"$CM" <<'RULES'

<!-- >>> nyc-ai-workshop 규칙 >>> (설치 스크립트가 넣음. 이 사이는 다시 돌리면 그대로 둔다) -->
# 뉴욕 AI 워크숍 작업 폴더 규칙
- 사용자는 컴퓨터 초보다. 처음부터 끝까지 한국어로, 쉬운 말로, 짧게 알려 준다.
- 웹 화면은 Aside(MCP)로 한다. 로그인 주소(vercel login · higgsfield auth login · gh auth login · claude 로그인 등)는 Safari 가 아니라 Aside 에서 연다.
- 자동 클릭이 막힌 단추(GitHub Authorize, Vercel Allow Access 같은 것)와 Aside 밖에 뜬 창은 computer use 전체 화면 제어로 마우스를 움직여 직접 누른다.
- 비밀번호 · 인증 코드 · 캡차 · 결제 화면은 손대지 않는다. 그 탭은 그대로 두고 다음으로 넘어간 뒤, 마지막에 「어느 탭에서 무엇을」 한 줄로 알려 준다.
- vercel login 같은 로그인은 한 번만 시도한다(여러 번 하면 메일 인증 코드를 요구한다).
- 맥 개발자 도구 · Homebrew · 관리자 비밀번호(sudo) · 소스 빌드를 쓰지 않는다. /usr/bin/git · /usr/bin/python3 는 부르지 않는다(개발자 도구 설치 창이 뜬다).
- 생년월일 · 비밀번호 · API 키 같은 개인정보는 파일이나 채팅에 적지 않는다. 생년월일은 대화 안에서만 쓴다.
- 설치 · 로그인 상태가 궁금하면 bash install-mac.sh --check 를 돌린다.
<!-- <<< nyc-ai-workshop 규칙 <<< -->
RULES
    grep -q '>>> nyc-ai-workshop 규칙 >>>' "$CM" && ok x "" "$CM" "$(took)" || bad x "CLAUDE.md 를 못 씀" "$(took)"
  fi
fi

# ── 16. 바로가기 · 앱에서도 새 도구가 보이게
#  - qwen-tts-demo 를 가상환경을 켜지 않아도 쓰게 ~/.local/bin 에 바로가기
#  - 독 · Spotlight 로 연 앱도 pixi 의 git · python 을 먼저 보게(로그인할 때마다 적용, 비밀번호 없음)
if want 16; then begin 16 "바로가기 · 앱에서도 새 도구가 보이게"
  mkdir -p "$HOME/.local/bin"
  V="$WORKDIR/.venv-qwen-tts/bin/qwen-tts-demo"
  [ -x "$V" ] && ln -sf "$V" "$HOME/.local/bin/qwen-tts-demo"
  # pixi 것이 먼저, 그다음 원래 쓰던 Homebrew(있으면) · 시스템 순서
  GP="$HOME/.pixi/bin:$HOME/.npm-global/bin:$HOME/.bun/bin:$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  LA="$HOME/Library/LaunchAgents/com.nyc-ai-workshop.path.plist"
  mkdir -p "$HOME/Library/LaunchAgents"
  cat >"$LA" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.nyc-ai-workshop.path</string>
  <key>ProgramArguments</key><array><string>/bin/launchctl</string><string>setenv</string><string>PATH</string><string>$GP</string></array>
  <key>RunAtLoad</key><true/>
</dict></plist>
PLIST
  logc /bin/launchctl setenv PATH "$GP"
  M=""; [ -L "$HOME/.local/bin/qwen-tts-demo" ] && M="qwen-tts-demo 바로가기 · "
  [ -f "$LA" ] && ok x "" "${M}앱 PATH 설정" "$(took)" || bad x "설정 파일을 못 씀" "$(took)"
fi

[ -n "${PREFETCH_PID:-}" ] && wait "$PREFETCH_PID" 2>/dev/null
rm -rf "$CACHE"/*.tmp "$CACHE"/mnt.* 2>/dev/null
[ "$FAILED" -eq 0 ] && rm -rf "$CACHE" 2>/dev/null   # 받은 설치 파일 정리(용량)

# 다른 방법으로 깔려 있던 도구(PATH 밖)는 새로 깔지 않고, 그 폴더를 PATH 에 더해 다음부터 보이게 한다
if [ ${#ALT_FOUND[@]} -gt 0 ]; then
  ADD=""; for e in "${ALT_FOUND[@]}"; do d="${e#*|}"; case ":$ADD:" in *":$d:"*) ;; *) ADD="${ADD:+$ADD:}$d";; esac; done
  for f in "$HOME/.zshenv" "$HOME/.zprofile" "$HOME/.bash_profile"; do
    grep -q '>>> nyc-ai-workshop-found >>>' "$f" 2>/dev/null || printf '\n# >>> nyc-ai-workshop-found >>>\nexport PATH="$PATH:%s"\n# <<< nyc-ai-workshop-found <<<\n' "$ADD" >>"$f"
  done
  say ""; say "   ⚠️  PATH 밖에 이미 깔려 있던 것을 그대로 씁니다: $(for e in "${ALT_FOUND[@]}"; do printf '%s ' "${e%%|*}"; done)"
fi

# ───────────────────────── 점검 표 ─────────────────────────
v() { has "$1" && ver "$@" || echo "-"; }
{
  echo ""
  echo "════════════════ 설치 점검 표 ($(date '+%H:%M'), 전체 $(secs $(( $(date +%s) - T0 )))) ════════════════"
  echo "| 번호 | 항목 | 결과 | 버전 · 메모 | 걸린 시간 |"
  echo "|---|---|---|---|---|"
  for r in "${ROWS[@]}"; do
    IFS='|' read -r a b c d e <<<"$r"
    [ "$a" = 0 ] && continue
    echo "| $a | $b | $c | $d | $( [ "$e" = 0 ] && echo - || secs "$e") |"
  done
  echo ""
  echo "지금 쓸 수 있는 명령(버전):"
  echo "  git $(v git --version) · gh $(v gh --version) · ffmpeg $(has ffmpeg && ffmpeg -version 2>/dev/null | head -n1 | awk '{print $3}' || echo -) · node $(v node --version) · python3 $(v python3 --version)"
  echo "  aside $(v aside --version) · vercel $(v vercel --version) · higgsfield $(v higgsfield --version) · bun $(v bun --version) · claude $(v claude --version)"
  echo "  남은 용량: 시작 ${FREE0}GB → 지금 $(free_gb)GB"
  echo ""
  if [ "$FAILED" -eq 0 ]; then
    echo "✅ 설치가 끝났습니다."
  else
    echo "❌ 실패 ${FAILED}개. 자세한 기록: $LOG"
    echo "   고친 뒤 실패한 번호만 다시:  bash $0 --only <번호>"
  fi
  echo "다음: Claude 앱을 완전히 끄고(Claude 메뉴 → Quit) 다시 켠 뒤, 왼쪽 목록에서 같은 대화로 돌아오세요. 그래야 새로 깐 도구들이 보입니다."
  echo "설치 · 로그인 상태는 언제든:  bash install-mac.sh --check"
  app_installed CapCut.app && echo "캡컷은 응용 프로그램 폴더에서 직접 한 번 열어 보세요(처음 열 때 약관 동의 창이 나옵니다)."
} | tee "$RESULT" | tee -a "$LOG"

[ "$FAILED" -eq 0 ] && exit 0 || exit 1
