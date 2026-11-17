# 뉴욕 AI 워크숍 사전 설치 — Claude 가 읽고 따라 하는 문서 (윈도우)

> **사람이 읽는 부분**
> 아래 0번까지 직접 끝낸 뒤, Claude 앱의 대화창에 이렇게 한 줄만 보내세요.
>
> `이 문서를 읽고 처음부터 끝까지 순서대로 해 줘: https://raw.githubusercontent.com/yoonjechoi/nyc-ai-workshop-setup/main/CLAUDE-WIN.md`
>
> Claude 가 멈추고 「사람 차례」라고 말하면 그때만 손을 쓰면 됩니다. 대화 아래에 주황색 **「Needs your input」** 이 보이면, 그 창의 **Allow for this session** 을 눌러 주세요.
> 화면이 어두워지며 **「이 앱이 디바이스를 변경하도록 허용하시겠어요?」** 창이 뜨면, 이름이 Claude Setup · Git for Windows · Microsoft Visual C++ · Aside Installer 일 때만 **예(Yes)** 를 누릅니다. 이 창은 윈도우 보안 때문에 Claude 가 대신 누를 수 없습니다. 창이 안 보이고 화면 아래 작업 표시줄에 **방패 아이콘**만 깜빡이면 그 아이콘을 눌러서 예를 누릅니다.

## 0. 사람이 먼저 할 일 (약 10분, Claude 가 아직 못 하는 부분)
1. 엣지(Edge)에서 claude.ai/download 를 열고 쿠키 창은 **Reject**, **Download for Windows** 를 누릅니다.
2. 다운로드 목록에서 `Claude Setup.exe` 를 엽니다. 「예」 창(Claude Setup · Anthropic, PBC)이 뜨면 **예**.
3. Claude 창이 안 보이면 화면 아래 작업 표시줄의 **Claude 아이콘**을 누릅니다(엣지 뒤에 열릴 수 있음). 쿠키 **Reject** → Get started → **Continue with Google** 로 로그인합니다(Pro 이상). 로봇 확인이 나오면 직접 풉니다.
4. Claude 창 **왼쪽 아래 내 이름 → Settings**(Ctrl+,) → 검색칸에 `bypass` → **Allow bypass permissions mode** 를 켭니다.
5. 같은 검색칸에 `computer` → **Enable computer use** → Turn on. (윈도우는 다른 권한 창이 없습니다.)
6. 왼쪽 위 `</>`(Code) → Choose folder → Open folder… → 내 이름 폴더 안에 `workspace` → 그 안에 `nyc-ai-workshop` 를 만들어 고르고 **Select Folder**(창이 몇 초 늦게 뜰 수 있음) → **Trust workspace** → 입력칸 아래 모드를 **Bypass permissions** 로 바꿉니다.
7. 이 대화에 위의 한 줄을 보냅니다.

---

## Claude 에게 (여기부터는 Claude 가 따르는 지시)

너는 뉴욕 AI 워크숍 수강생의 윈도우 PC 에서 사전 설치를 돕는다. 수강생은 컴퓨터를 잘 모른다.

### 지킬 것
- 처음부터 끝까지 **한국어로, 쉽고 짧게** 말한다. 1분마다 하는 진행 알림도 한국어로 한다.
- 사람 차례(아래 **⏸ 사람 차례**)에서는 무엇을 어디서 누르는지 한두 줄로 말하고, 사람이 「했어」라고 할 때까지 기다린다.
- 비밀번호 · 인증 코드(문자 · 메일 · 인증 앱) · 캡차 · 결제 · 윈도우 「예」(UAC) 창은 **사람이 한다**. 너는 넣거나 누르지 않는다(「예」 창은 윈도우 보안 화면이라 computer use 로도 눌리지 않는다).
- 생년월일은 **이 대화 안에서만** 쓰고 파일에 적지 않는다.
- 토큰과 API 키는 채팅에 쓰지 않는다. 클립보드나 파일로만 옮긴다.
- 터미널 명령은 사람에게 넘기지 말고 **네가 직접 실행**한다(PowerShell. claude 는 `%USERPROFILE%\.local\bin\claude.exe`).
- 가입 · 로그인 웹 화면은 처음부터 Aside MCP(`aside repl`)로 다룬다. 로그인 주소는 엣지가 아니라 Aside 탭에서 연다.
- Aside 로 안 되는 화면이 나오면 그때만 computer use(전체 화면 제어)로 누른다: Aside 앱 설정 창, Aside 밖에 뜨는 창, 눌러도 반응이 없는 단추. 누른 뒤에는 다시 Aside MCP 로 돌아간다.
- 로그인 주소가 Aside 가 아닌 다른 브라우저(엣지 등)로 열리면, 그 창의 주소창을 computer use 로 복사해 Aside 에 새 탭으로 열고 Aside MCP 로 이어서 한다.
- 「이 링크를 열 앱을 고르세요」 창이 뜨면 **Aside → 한 번만(Just once)** 을 고른다. 「항상」은 고르지 않는다(기본 브라우저는 바꾸지 않는다).
- 각 단계가 끝나면 ✅ 한 줄로 알리고 다음 단계로 간다.

### 1단계 설치 (약 17분)
1. 시작하기 전에 사람에게 말한다: 「설치 중에 화면이 어두워지며 '예' 창이 세 번 뜹니다(Git for Windows, Microsoft Visual C++, Aside Installer). 모두 예를 눌러 주세요. Visual C++ 창은 앞에 안 뜨고 작업 표시줄에 방패 아이콘만 깜빡일 수 있어요. 그러면 그 아이콘을 눌러 주세요.」
2. `https://raw.githubusercontent.com/yoonjechoi/nyc-ai-workshop-setup/main/install-win.ps1` 를 지금 폴더에 받는다(`Invoke-WebRequest -UseBasicParsing … -OutFile install-win.ps1`). 그다음 `powershell -ExecutionPolicy Bypass -File install-win.ps1` 를 백그라운드로 실행하고, 1분마다 몇 번째 단계인지 한국어 한 줄로 알린다.
3. 용량이나 윈도우 버전 때문에 멈추면 안내를 쉬운 말로 전하고, 사람이 「비웠어」라고 할 때까지 기다린다.
4. 한 단계가 3분 넘게 멈추면 숨은 「예」 창일 수 있다. 사람에게 「작업 표시줄에 깜빡이는 방패 아이콘이 있으면 눌러서 예를 눌러 주세요」라고 말한다. Aside 창이 깜빡이는 것은 「예」 창이 아니다(뒤에서 로그인한다).
5. ❌ 가 나오면 `%USERPROFILE%\nyc-install.log` 를 읽고 원인을 쉬운 말로 알린 뒤, 같은 명령 끝에 `-Only <번호>` 를 붙여 그 단계만 다시 돌린다. 「예」 창에서 아니요를 눌러 ❌ 가 난 것이면 「이번엔 예를 눌러 주세요」라고 말하고 다시 돌린다. 소스 빌드는 하지 않는다.
6. Aside 설치 뒤 Aside 창이 저절로 열리는 것은 정상이다. 캡컷과 Qwen3-TTS 는 원래 오래 걸린다.
7. 끝나면 점검 표를 그대로 보여 준다. 빈 공간이 15GB 보다 적었으면 Qwen3-TTS 만 ⏸ 인 것이 정상이다.

새로 깐 도구는 이 대화의 PATH 에 아직 없을 수 있다. 그래서 이 대화에서 PowerShell 명령을 더 돌릴 때는 앞에 `$env:Path = [Environment]::GetEnvironmentVariable('Path','User') + ';' + [Environment]::GetEnvironmentVariable('Path','Machine') + ";$HOME\.local\bin;$HOME\.bun\bin;$env:APPDATA\npm;$HOME\.aside-cli\current";` 를 붙인다.

**⏸ 사람 차례 — Aside 로그인 (약 3분)** 아래 내용을 그대로 안내하고 「했어」를 기다린다.
- 설치 때 열린 Aside 창(작업 표시줄에서 깜빡이면 눌러서 열기, 없으면 시작 메뉴에서 `Aside`) → **Sign in with Google** 로 로그인한다. 이어지는 첫 안내 화면에서는 이렇게 고른다.
  - 다른 브라우저에서 가져오기: **Cancel**
  - 볼트 비밀번호를 정하고, **복구 암호는 종이에 적는다**(Claude 에게 주지 않기)
  - Choose your AI subscription: **Claude → Connect → Authorize** (꼭 하기). Claude 로그인 창에서는 **Claude 앱과 같은 Pro 이상 구글 계정**을 고른다(다른 계정이면 「Pro, Max 또는 Ultra 가 필요합니다」로 연결이 안 된다). 로봇 확인(그림 맞추기)이 나오면 직접 푼다.
  - Let your agents browse: **Skip**
  - Get started. 그다음 윈도우 「기본 앱」 설정 화면이 열리면 **아무것도 바꾸지 말고 닫는다**.
- 「Windows 보안 경고 … 방화벽이 일부 기능을 차단했습니다」가 뜨면 **허용**(「예」 창이 한 번 더 뜰 수 있음).
- 캡컷: 시작 메뉴에서 **CapCut** 을 한 번 열어 처음 뜨는 약관 창을 넘긴 뒤 닫는다.
- Aside 창은 최소화(─)해 둔다.

**⏸ 사람 차례 — Claude 앱 다시 켜고 새 대화 열기 (1단계의 마지막)** 윈도우 Claude 앱은 처음 켜질 때의 설정으로 계속 돌아서, 설치 중에 깐 도구(uvx · bun 등)를 앱을 다시 켜야 찾는다(일레븐랩스 · 텔레그램 연결에 필요). 또 이 대화는 설치 전에 시작해서 방금 깐 Aside MCP 도구가 안 보인다. 그래서 2단계는 앱을 다시 켠 뒤 새 대화에서 한다. 사람에게 이렇게 안내하고 이 대화는 여기서 마친다.
「Claude 앱을 완전히 껐다 켜 주세요. 화면 오른쪽 아래 **^** → Claude 아이콘을 **오른쪽 클릭 → Exit**(창의 X 로는 안 꺼집니다) → 시작 메뉴에서 **Claude** 를 다시 엽니다. 새 대화(New) 화면에서 폴더가 nyc-ai-workshop, 모드가 Bypass permissions 인지 보고, 아래 한 줄을 보내 주세요.」
`이 문서의 2단계부터 끝까지 해 줘: https://raw.githubusercontent.com/yoonjechoi/nyc-ai-workshop-setup/main/CLAUDE-WIN.md`

### 2단계 가입 · 로그인 · 연결 (약 15분, 새 대화에서)
먼저 이 대화에 `mcp__aside__` 로 시작하는 도구(`aside repl` 등)가 있는지 본다. 없으면 앱을 다시 켜지 않았거나 설치하던 대화일 수 있으니, 사람에게 Claude 앱을 Exit 로 껐다 켜고 새 대화에서 위 한 줄을 다시 보내 달라고 한다. 새 PowerShell 명령에도 1단계의 `$env:Path = …;` 를 붙인다.
시작할 때 **생년월일을 한 번만** 묻고, 가입 화면에서 생년월일이나 나이를 물으면 그 값을 넣는다. 수강생은 만 18세 이상이니 나이 때문에 멈추지 않는다.
1. **Aside 연결 확인:** Aside → Settings → Models 에 Claude 가 있는지 본다. 없으면 + Connect → Claude → Connect → Authorize 를 누른다.
2. **가입:** Aside 에 로그인된 Gmail 로 한다. 약관은 수강생이 읽고 동의한 것으로 보고, 결제와 유료 요금제는 하지 않는다.
   GitHub · Supabase · Vercel 은 가입하지 않는다(CLI 는 설치 스크립트가 깔아 둔다. 수업에서 필요하면 그때 한다).
   힉스필드 MCP(`https://mcp.higgsfield.ai/mcp`)는 사전 설치에서 연결하지 않는다. 로그인 창이 기본 브라우저(엣지)로 열려 다른 구글 계정과 연결될 수 있어서, 수업에서 강사와 같이 계정을 확인하며 연결한다. 사전 설치에서는 `higgsfield auth login`(CLI)까지만 한다.
   1. Aside 새 탭에 한꺼번에 연다: 힉스필드 · 일레븐랩스 · 미드저니 · Suno · 캡컷(모두 구글로)
3. **로그인**(각각 한 번만 시도한다. 주소는 Aside 에서 열고 허용 단추를 누른다)
   - git 이름 · 이메일: `git config --global user.name` / `user.email` 이 비어 있으면 Aside 에 로그인된 구글 계정의 이름과 Gmail 로 넣는다. `gh auth login` 은 하지 않는다.
   - claude 터미널판 로그인
   - 힉스필드: `higgsfield auth login`. 힉스필드 스킬(`%USERPROFILE%\.claude\skills\higgsfield-*`)은 이 CLI 를 쓴다.
   - 일레븐랩스: Aside 에서 elevenlabs.io(무료 계정) → API Keys → 새 키 만들기. 키 값은 채팅 · 화면 캡처에 남기지 말고 복사(클립보드)만 한 뒤 PowerShell 에서 `claude mcp add elevenlabs -s user -e "ELEVENLABS_API_KEY=$(Get-Clipboard)" -- uvx elevenlabs-mcp` 로 등록하고 `Set-Clipboard -Value ' '` 로 클립보드를 비운다.
4. 비밀번호 · 인증 코드 · 캡차 · 결제 화면이 나온 탭은 그대로 두고 다음으로 넘어간다. 인증 앱 코드(6자리)를 묻는 사이트(일레븐랩스 등)도 여기에 해당한다.

**⏸ 사람 차례 — Allow 창** 처음 다른 앱을 쓸 때 대화 안에 「Allow Claude to use 앱이름?」 이, 화면 전체를 쓸 때 「Take over the screen?」 이 뜬다(윈도우는 이 창이 화면을 쓸 때마다 다시 뜰 수 있다). 사람에게 「대화 아래 주황색 'Needs your input' 이 보이면 **Allow for this session** 을 눌러 주세요」라고 미리 말해 둔다.

**표 보여 주기:** `powershell -ExecutionPolicy Bypass -File install-win.ps1 -Check` 결과 표를 보여 준다. 사이트마다 ✅ / ⏸ 로 사람이 할 일(어느 탭에서 무엇을)도 표로 보여 준다.

**⏸ 사람 차례 — 안 된 부분 대화하며 되는 만큼 해결하기** ⏸ 가 있으면 사람에게 이렇게 말한다. 「한 번에 다 안 끝나도 괜찮아요. 막힌 화면이 있으면 지금 보이는 것을 저에게 말해 주세요. 되는 만큼 같이 해 봐요.」
- 할 일을 **한 번에 하나씩**, Aside 의 어느 탭에서 무엇을 누르고 넣을지 쉽게 말한다. 「다 했어」가 오면 확인한 뒤 다음 것으로 간다. 사람이 물으면 답한다.
- 이미 2단계 인증을 켠 구글 계정의 본인 확인(휴대폰 「예」), 캡차 · 미드저니 보안 확인, 메일 · 문자 · 인증 앱 코드가 여기에 해당한다.
- 인증 앱 코드를 넣었는데 「An unknown error occurred」가 나오면 코드 시간이 지난 것이니 새 코드로 다시 넣으라고 한다.
- Aside 가 로그아웃되어 탭이 닫혔으면 Aside 에 구글로 다시 로그인하게 하고 이어서 한다.
- 다 못 끝내면 남은 것을 목록으로 남긴다(수업에서 같이 한다).

**⏸ 사람 차례 — 휴대폰 (2단계가 도는 동안 해도 된다)** 아래 내용을 안내한다.
- 휴대폰에 Claude 앱을 깔고 같은 구글 계정으로 로그인한다.
- 휴대폰에 Telegram 을 깔고 전화번호로 가입한다(문자 코드는 사람이 넣는다). 휴대폰에서 먼저 가입해야 3단계에서 노트북 텔레그램을 연결할 수 있다.

### 3단계 텔레그램 (약 10분)
**⏸ 사람 차례 — 노트북 텔레그램 로그인 (약 2분)** 아래 내용을 안내하고 「했어」를 기다린다.
- 휴대폰 텔레그램은 2단계 휴대폰 차례에서 이미 가입해 두었어야 한다. 안 했으면 먼저 하게 한다.
- 시작 메뉴에서 `Telegram`(설치 스크립트가 깔아 둠)을 열고 **Start Messaging** → QR 코드가 뜬다. 전화번호 화면이 나오면 「Quick log in using QR code」.
- 휴대폰 텔레그램 설정 → 기기 → **기기 추가**(영어 화면은 Link Desktop Device) 로 그 QR 을 스캔한다.

그다음 아래 순서로 진행한다. 시작하기 전에 두 가지를 사람에게 말한다.
- 「곧 Allow 창이 2번 뜹니다(텔레그램 사용, 화면 전체 제어). Allow for this session 을 눌러 주세요.」
- 「도는 동안 휴대폰으로 BotFather 와 대화하지 마세요.」

1. Claude Code 공식 텔레그램 플러그인(claude-plugins-official 의 `telegram`)을 설치한다. 플러그인 서버는 bun 으로 돈다(`%USERPROFILE%\.bun\bin`, 설치 스크립트가 깔아 둠).
2. Telegram 앱을 computer use 로 열고 BotFather 에게 `/newbot` 을 보낸다.
   - 이름은 「NYC Workshop 봇」, 아이디는 `nyc_ws_` 로 시작해 `_bot` 으로 끝나며 겹치지 않는 것으로 한다.
   - 다른 대화방은 열지 않는다.
3. 봇 토큰은 채팅에 쓰지 말고 클립보드로만 옮겨서, 플러그인 안내대로 저장한다. 저장한 뒤 클립보드를 비운다.
4. 텔레그램이 연결된 새 Claude Code 대화를 이 Claude 앱 안의 터미널 탭(이름 「텔레그램 Claude」)에 띄운다.
   - `/mcp` 에서 telegram 이 실패로 나오면 Reconnect 한다(처음에 자주 실패한다).
5. 페어링: Telegram 앱에서 새 봇 대화만 열어 「안녕」 을 보낸다. 봇이 준 코드로 pair 한 뒤 「허용된 사람만」 으로 잠근다.
6. 봇 대화에 「시험 메시지 보내 줘」 를 보내 답장이 오는지 확인한다.
7. 마지막에 이렇게 안내한다. 「노트북을 끄거나 덮거나 '텔레그램 Claude' 탭을 닫으면 텔레그램 연결이 끊깁니다. 다시 쓰려면 새 대화에 '텔레그램 연결된 대화 다시 띄워 줘'라고 보내세요.」

### 끝
마지막으로 한 화면에 요약한다.
- 설치 표, 가입 · 로그인 · 연결 표, 텔레그램 결과
- 아직 사람이 할 일(⏸)이 있으면 그 목록

모든 줄이 ✅ 면 「사전 설치 끝! 수업 날 노트북만 가져오세요」라고 말한다.
