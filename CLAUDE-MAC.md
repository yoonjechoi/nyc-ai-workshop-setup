# 뉴욕 AI 워크숍 사전 설치 — Claude 가 읽고 따라 하는 문서 (맥)

> **사람이 읽는 부분**
> 아래 0번까지 직접 끝낸 뒤, Claude 앱의 대화창에 이렇게 한 줄만 보내세요.
>
> `이 문서를 읽고 처음부터 끝까지 순서대로 해 줘: https://raw.githubusercontent.com/yoonjechoi/nyc-ai-workshop-setup/main/CLAUDE-MAC.md`
>
> Claude 가 멈추고 「사람 차례」라고 말하면 그때만 손을 쓰면 됩니다. 대화 아래에 주황색 **「Needs your input」** 이 보이면, 그 창의 **Allow for this session** 을 눌러 주세요.

## 0. 사람이 먼저 할 일 (약 10분, Claude 가 아직 못 하는 부분)
1. claude.ai/download 에서 Claude 앱을 설치하고, 구글 계정으로 로그인합니다(Pro 이상).
2. 설정 → Claude Code 에서 **권한 무시(bypass permissions)** 를 켭니다.
3. 설정 → **Capabilities → Computer use** 를 켭니다(Turn on).
   - 「Grant macOS permissions」 창에서 Accessibility · Screen recording 의 **Request** 를 누르고, 시스템 설정 스위치를 켠 뒤 맥 비밀번호를 넣습니다. 「Quit & Reopen」이 나오면 **Reopen** 을 누릅니다.
4. Code 탭에서 폴더 `~/workspace/nyc-ai-workshop` 를 만들어 고르고, Trust 를 누른 뒤 모드를 **Bypass permissions** 로 바꿉니다.
5. 이 대화에 위의 한 줄을 보냅니다.

---

## Claude 에게 (여기부터는 Claude 가 따르는 지시)

너는 뉴욕 AI 워크숍 수강생의 맥에서 사전 설치를 돕는다. 수강생은 컴퓨터를 잘 모른다.

### 지킬 것
- 처음부터 끝까지 **한국어로, 쉽고 짧게** 말한다.
- 사람 차례(아래 **⏸ 사람 차례**)에서는 무엇을 어디서 누르는지 한두 줄로 말하고, 사람이 「했어」라고 할 때까지 기다린다.
- 비밀번호 · 인증 코드(문자 · 메일 · 인증 앱) · 캡차 · 결제 · macOS 권한 창은 **사람이 한다**. 너는 넣거나 누르지 않는다.
- 생년월일은 **이 대화 안에서만** 쓰고 파일에 적지 않는다.
- 토큰과 API 키는 채팅에 쓰지 않는다. 클립보드나 파일로만 옮긴다.
- 터미널 명령은 사람에게 넘기지 말고 **네가 직접 실행**한다(claude 는 `~/.local/bin/claude`).
- 가입 · 로그인 웹 화면은 처음부터 Aside MCP(`aside repl`)로 다룬다. 로그인 주소는 Safari 가 아니라 Aside 탭에서 연다.
- Aside 로 안 되는 화면이 나오면 그때만 computer use(전체 화면 제어)로 누른다: Aside 앱 설정 창, Aside 밖에 뜨는 창, 눌러도 반응이 없는 단추(GitHub Authorize, Vercel Allow Access 등). 누른 뒤에는 다시 Aside MCP 로 돌아간다.
- 각 단계가 끝나면 ✅ 한 줄로 알리고 다음 단계로 간다.

### 1단계 설치 (약 5분)
1. `https://raw.githubusercontent.com/yoonjechoi/nyc-ai-workshop-setup/main/install-mac.sh` 를 지금 폴더에 받는다. 그다음 `bash install-mac.sh` 를 백그라운드로 실행하고, 1분마다 몇 번째 단계인지 한 줄로 알린다.
2. 용량이나 맥 버전 때문에 멈추면 안내를 쉬운 말로 전하고, 사람이 「비웠어」라고 할 때까지 기다린다.
3. ❌ 가 나오면 `~/nyc-install.log` 를 읽고 원인을 고친 뒤 `bash install-mac.sh --only <번호>` 로 그 단계만 다시 돌린다. Homebrew · 맥 개발자 도구 · 소스 빌드 · sudo · `/usr/bin/python3` 는 쓰지 않는다.
4. 도중에 「python3 … 개발자 도구를 설치할까요?」 창이 뜨면 사람에게 **Cancel** 을 누르라고 말한다. 눌러도 안 눌러도 설치는 끝난다.
5. 끝나면 점검 표를 그대로 보여 준다.

**Aside 띄우기 — Claude 앱은 끄지 않는다.**
- 새로 깐 도구는 이 대화의 PATH 에 아직 없을 수 있다. 그래서 이후 모든 터미널 명령 앞에 `export PATH="$HOME/.pixi/bin:$HOME/.npm-global/bin:$HOME/.bun/bin:$HOME/.local/bin:$PATH";` 를 붙인다. 사람에게 앱을 끄라고 하지 않는다.
- `open -a Aside` 로 네가 Aside 를 띄운다.

**⏸ 사람 차례 — Aside 구글 로그인 (약 1분)** Aside 창이 뜨면 「**Continue with Google** 로 로그인하고, 끝나면 '했어'라고 보내 주세요」라고 안내하고 기다린다.

**Aside 첫 안내 화면 — 네가 computer use 로 진행한다**(「했어」를 받은 뒤)
- Import from your browser: **Skip**
- 볼트(비밀번호 관리자) 비밀번호 · 복구 암호 화면이 나오면 **멈추고** 사람에게 맡긴다: 「볼트 비밀번호를 정하고 복구 암호는 종이에 적어 주세요(저에게 알려 주지 마세요). 다 하면 '했어'」
- Choose your AI subscription: **Claude → Connect → Authorize** (꼭 한다)
- Let your agents browse: **Skip**
- **Get started**
- macOS 「Allow "Aside" to find devices on local networks?」 창이 뜨면 사람에게 **Allow** 를 눌러 달라고 한다(시스템 권한 창은 사람이 누른다).

**⏸ 사람 차례 — 새 대화 열기 (1단계의 마지막)** 이 대화는 설치 전에 시작해서 방금 깐 Aside MCP 도구가 안 보인다. 새 대화는 시작할 때 도구를 다시 읽어서 보인다(앱을 끌 필요 없음, 2026-11-17 시험). 그래서 2단계는 새 대화에서 한다. 사람에게 이렇게 안내하고 이 대화는 여기서 마친다.
「Claude 앱 왼쪽 위 **New** 로 새 대화를 열어 주세요. 폴더는 nyc-ai-workshop 그대로 두고, 아래 한 줄을 보내 주세요. 앱은 끄지 마세요.」
`이 문서의 2단계부터 끝까지 해 줘: https://raw.githubusercontent.com/yoonjechoi/nyc-ai-workshop-setup/main/CLAUDE-MAC.md`

### 2단계 가입 · 로그인 · 연결 (약 15분, 새 대화에서)
먼저 이 대화에 `mcp__aside__` 로 시작하는 도구(`aside repl` 등)가 있는지 본다. 없으면 설치하던 대화일 수 있으니, 사람에게 New 로 새 대화를 열어 위 한 줄을 다시 보내 달라고 한다. 새 터미널 명령에도 1단계의 `export PATH=…;` 를 붙인다.
시작할 때 **생년월일을 한 번만** 묻고, 가입 화면에서 생년월일이나 나이를 물으면 그 값을 넣는다. 수강생은 만 18세 이상이니 나이 때문에 멈추지 않는다.
1. **Aside 연결 확인:** Aside → Settings → Models 에 Claude 가 있는지 본다. 없으면 + Connect → Claude → Connect → Authorize 를 누른다.
2. **가입:** Aside 에 로그인된 Gmail 로 한다. 약관은 수강생이 읽고 동의한 것으로 보고, 결제와 유료 요금제는 하지 않는다.
   1. Supabase(`supabase.com/dashboard/sign-up`) → Continue with GitHub. GitHub 계정이 없으면 그 화면에서 구글로 GitHub 에 가입한 뒤 Authorize 를 누른다.
   2. Vercel(`vercel.com/signup`, Hobby, Continue with Google)
   3. 나머지는 Aside 새 탭에 한꺼번에 연다: 힉스필드 · 일레븐랩스 · 미드저니 · Suno · 캡컷(모두 구글로)
3. **로그인**(각각 한 번만 시도한다. 주소는 Aside 에서 열고 허용 단추를 누른다)
   - `vercel login`
   - `gh auth login`(git 이름 · 이메일을 GitHub 계정에 맞춘다)
   - claude 터미널판 로그인
   - 힉스필드: `higgsfield auth login`. 힉스필드 스킬(~/.claude/skills/higgsfield-*)은 이 CLI 를 쓴다.
   - 일레븐랩스: Aside 에서 elevenlabs.io(무료 계정) → API Keys → 새 키 만들기. 키 값은 채팅 · 화면 캡처에 남기지 말고 복사(클립보드)만 한 뒤 `claude mcp add elevenlabs -s user -e ELEVENLABS_API_KEY="$(pbpaste)" -- uvx elevenlabs-mcp` 로 등록하고 `printf '' | pbcopy` 로 클립보드를 비운다.
4. 비밀번호 · 인증 코드 · 캡차 · 결제 화면이 나온 탭은 그대로 두고 다음으로 넘어간다.

**⏸ 사람 차례 — Allow 창** 처음 다른 앱을 쓸 때 대화 안에 「Allow Claude to use 앱이름?」 이, 화면 전체를 쓸 때 「Take over the screen?」 이 뜬다. 사람에게 「대화 아래 주황색 'Needs your input' 이 보이면 **Allow for this session** 을 눌러 주세요」라고 미리 말해 둔다.

**표 보여 주기:** `bash install-mac.sh --check` 결과 표를 보여 준다. 사이트마다 ✅ / ⏸ 로 사람이 할 일(어느 탭에서 무엇을)도 표로 보여 준다. ⏸ 가 있으면 사람이 하고 「다 했어」라고 할 때까지 기다린다. 이미 2단계 인증을 켠 계정, 캡차, Vercel 휴대폰 인증이 여기에 해당한다.

**⏸ 사람 차례 — 휴대폰 (2단계가 도는 동안 해도 된다)** 아래 내용을 안내한다.
- 휴대폰에 Claude 앱을 깔고 같은 구글 계정으로 로그인한다.
- 휴대폰에 Telegram 을 깔고 전화번호로 가입한다(문자 코드는 사람이 넣는다). 휴대폰에서 먼저 가입해야 3단계에서 노트북 텔레그램을 연결할 수 있다.
- Aside 새 탭에서 `instagram.com` 에 직접 로그인한다(없으면 건너뜀).

### 3단계 텔레그램 (약 10분)
**⏸ 사람 차례 — 노트북 텔레그램 로그인 (약 2분)** 아래 내용을 안내하고 「했어」를 기다린다.
- 휴대폰 텔레그램은 2단계 휴대폰 차례에서 이미 가입해 두었어야 한다. 안 했으면 먼저 하게 한다.
- 노트북의 Telegram 앱(설치 스크립트가 깔아 둠)을 열면 QR 코드가 뜬다.
- 휴대폰 텔레그램 설정 → 기기 → **데스크톱 기기 연결** 로 그 QR 을 스캔한다.

그다음 아래 순서로 진행한다. 시작하기 전에 두 가지를 사람에게 말한다.
- 「곧 Allow 창이 2번 뜹니다(텔레그램 사용, 화면 전체 제어). Allow for this session 을 눌러 주세요.」
- 「도는 동안 휴대폰으로 BotFather 와 대화하지 마세요.」

1. Claude Code 공식 텔레그램 플러그인(claude-plugins-official 의 `telegram`)을 설치한다.
2. Telegram 앱을 computer use 로 열고 BotFather 에게 `/newbot` 을 보낸다.
   - 이름은 「NYC Workshop 봇」, 아이디는 `nyc_ws_` 로 시작해 `_bot` 으로 끝나며 겹치지 않는 것으로 한다.
   - 다른 대화방은 열지 않는다.
3. 봇 토큰은 채팅에 쓰지 말고 클립보드로만 옮겨서, 플러그인 안내대로 저장한다. 저장한 뒤 클립보드를 비운다.
4. 텔레그램이 연결된 새 Claude Code 대화를 이 Claude 앱 안의 터미널 탭(이름 「텔레그램 Claude」)에 띄운다.
   - `/mcp` 에서 telegram 이 실패로 나오면 Reconnect 한다(처음에 자주 실패한다).
   - 탭에 직접 입력이 안 되면 작은 pty 래퍼로 띄워서 키를 보낸다.
5. 페어링: Telegram 앱에서 새 봇 대화만 열어 「안녕」 을 보낸다. 봇이 준 코드로 pair 한 뒤 「허용된 사람만」 으로 잠근다.
6. 봇 대화에 「시험 메시지 보내 줘」 를 보내 답장이 오는지 확인한다.
7. 마지막에 이렇게 안내한다. 「노트북을 끄거나 덮거나 '텔레그램 Claude' 탭을 닫으면 텔레그램 연결이 끊깁니다. 다시 쓰려면 새 대화에 '텔레그램 연결된 대화 다시 띄워 줘'라고 보내세요.」

### 끝
마지막으로 한 화면에 요약한다.
- 설치 표, 가입 · 로그인 · 연결 표, 텔레그램 결과
- 아직 사람이 할 일(⏸)이 있으면 그 목록

모든 줄이 ✅ 면 「사전 설치 끝! 수업 날 노트북만 가져오세요」라고 말한다.
