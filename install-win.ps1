# 뉴욕 AI 워크숍 — 윈도우 사전 설치 스크립트 (시험판, 2026-11-16)
#
# 쓰는 법:  powershell -ExecutionPolicy Bypass -File install-win.ps1            (전부)
#           powershell -ExecutionPolicy Bypass -File install-win.ps1 -Only 8    (8번만 다시)
#           powershell -ExecutionPolicy Bypass -File install-win.ps1 -List      (단계 목록만)
#           powershell -ExecutionPolicy Bypass -File install-win.ps1 -Check     (설치는 안 하고 버전 · 로그인 상태 점검 표만)
#
# 지키는 것
# - winget(윈도우 기본 앱 설치 관리자)으로 미리 만든 설치 파일만 쓴다. 소스 빌드를 하지 않는다.
# - 가능한 것은 「내 계정에만」 설치해 「예」 창(관리자 확인)을 줄인다. 그래도 뜨면 「예」.
# - 이미 깔린 것은 건너뛴다. 몇 번을 다시 돌려도 안전하다.
# - 로그인 · 가입은 하지 않는다. 설치만 한다.
#
# 남기는 것: 화면에는 단계마다 ✅ · ⏭ · ❌, 끝에 점검 표.
#            자세한 기록 = %USERPROFILE%\nyc-install.log , 점검 표 = %USERPROFILE%\nyc-install-result.txt

param([string]$Only = "", [switch]$List, [switch]$Check)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$WorkDir   = if ($env:NYC_WORKDIR) { $env:NYC_WORKDIR } else { Join-Path $HOME "workspace\nyc-ai-workshop" }
$Log       = Join-Path $HOME "nyc-install.log"
$Result    = Join-Path $HOME "nyc-install-result.txt"
$Cache     = Join-Path $env:TEMP "nyc-install"
$MinFreeGB = if ($env:NYC_MIN_FREE_GB) { [int]$env:NYC_MIN_FREE_GB } else { 10 }
$TtsFreeGB = if ($env:NYC_TTS_FREE_GB) { [int]$env:NYC_TTS_FREE_GB } else { 15 }
New-Item -ItemType Directory -Force -Path $WorkDir, $Cache | Out-Null
$T0 = Get-Date
$Rows = New-Object System.Collections.ArrayList
$script:Failed = 0

# ───────────────────────── 도우미 ─────────────────────────
function Say($m) { Write-Host $m; Add-Content -Path $Log -Value ("{0} {1}" -f (Get-Date -Format HH:mm:ss), $m) -Encoding UTF8 }
function LogRun([string]$cmd) {   # 명령 출력은 로그로만
  Add-Content -Path $Log -Value "`n> $cmd" -Encoding UTF8
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -Command "$cmd" 2>&1 | Out-String
  Add-Content -Path $Log -Value $out -Encoding UTF8
  return $LASTEXITCODE
}
function Secs($s) { $s = [int]$s; if ($s -ge 60) { "{0}분 {1}초" -f [math]::Floor($s/60), ($s % 60) } else { "${s}초" } }
function FreeGB { [math]::Floor((Get-PSDrive -Name ($HOME.Substring(0,1))).Free / 1GB) }
function Refresh-Path {
  $m = [Environment]::GetEnvironmentVariable("Path","Machine"); $u = [Environment]::GetEnvironmentVariable("Path","User")
  $env:Path = "$m;$u;$HOME\.bun\bin;$HOME\.local\bin;$env:APPDATA\npm;$env:LOCALAPPDATA\Aside\CLI\current;$env:LOCALAPPDATA\Microsoft\WinGet\Links;$env:LOCALAPPDATA\Microsoft\WindowsApps"
}
# 명령이 PATH 에 안 잡혀도 흔한 설치 위치를 한 번 더 찾는다(다른 방법으로 깐 것을 놓치거나 겹쳐 깔지 않게)
$ExtraDirs = @(
  "$env:ProgramFiles\Git\cmd", "$env:LOCALAPPDATA\Programs\Git\cmd", "$env:ProgramFiles\GitHub CLI",
  "$env:ProgramFiles\nodejs", "$env:LOCALAPPDATA\Volta\bin", $env:NVM_SYMLINK,
  "$env:LOCALAPPDATA\Programs\Python\Python3*", "$env:ProgramFiles\Python3*",
  "$env:APPDATA\npm", "$HOME\.bun\bin", "$HOME\.local\bin", "$env:LOCALAPPDATA\Aside\CLI\current",
  "$env:LOCALAPPDATA\Microsoft\WinGet\Links", "$HOME\scoop\shims", "$env:ProgramData\chocolatey\bin", "$HOME\.cargo\bin"
)
$script:Elsewhere = @{}
function FindElsewhere($c) {
  foreach ($d in $ExtraDirs) {
    if (-not $d) { continue }
    foreach ($dd in @(Resolve-Path $d -ErrorAction SilentlyContinue | Sort-Object Path -Descending)) {
      foreach ($ext in ".exe", ".cmd", ".bat") { $p = Join-Path $dd.Path "$c$ext"; if (Test-Path $p) { return $p } }
    }
  }
  $wp = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages"   # winget 이 받아 둔 폴더(링크가 없을 때)
  if (Test-Path $wp) { $hit = Get-ChildItem $wp -Recurse -Depth 3 -Filter "$c.exe" -ErrorAction SilentlyContinue | Select-Object -First 1; if ($hit) { return $hit.FullName } }
  return $null
}
# 진짜 명령의 경로(Microsoft Store 로 보내는 WindowsApps 가짜 python 은 뺀다). PATH 밖에서 찾으면 이번 실행에만 PATH 에 더한다
function RealCmd($c) {
  $g = Get-Command $c -All -ErrorAction SilentlyContinue | Where-Object { $_.Source -and $_.Source -notlike "*\WindowsApps\*" } | Select-Object -First 1
  if ($g) { return $g.Source }
  $p = FindElsewhere $c
  if ($p) {
    $dir = Split-Path $p; $env:Path = "$dir;$env:Path"; $script:Elsewhere[$c] = $dir
    Add-Content -Path $Log -Value "명령 $c 은(는) PATH 밖 $dir 에 있음 → 이번 실행에서만 PATH 에 더함" -Encoding UTF8
    return $p
  }
  return $null
}
function Has($c) { [bool](RealCmd $c) }
function Ver($c) {
  $flag = if ($c -eq "ffmpeg") { "-version" } else { "--version" }
  $exe = RealCmd $c; if (-not $exe) { return "" }
  try { $o = & $exe $flag 2>$null | Select-Object -First 1; if ($o -match '(\d+(\.\d+)+)') { $Matches[1] } else { "$o" } } catch { "" }
}
# 멈출 수 있는 명령(로그인 확인 등)은 시간 제한을 두고 돌린다 → @{ Code = 종료 코드(-1 = 시간 초과); Out = 출력 }
function RunTimed([string]$cmdline, [int]$sec = 25) {
  $j = Start-Job -ScriptBlock { param($l) $o = cmd /v:on /c "$l 2>&1 & echo __EXIT=!ERRORLEVEL!" | Out-String; $o } -ArgumentList $cmdline
  if (Wait-Job $j -Timeout $sec) { $o = Receive-Job $j | Out-String; Remove-Job $j -Force
    $code = if ($o -match '__EXIT=(-?\d+)') { [int]$Matches[1] } else { 1 }
    return @{ Code = $code; Out = ($o -replace '__EXIT=-?\d+', '').Trim() } }
  Stop-Job $j; Remove-Job $j -Force; return @{ Code = -1; Out = "" }
}
function Begin($n, $name) { $script:CurN = $n; $script:CurName = $name; $script:StepT = Get-Date; Say ""; Say "▶ $n. $name" }
function Took { [int]((Get-Date) - $script:StepT).TotalSeconds }
function Row($r, $v, $s) { [void]$Rows.Add([pscustomobject]@{ N = $script:CurN; Name = $script:CurName; R = $r; V = $v; S = $s }) }
function Ok($v)   { $s = Took; Say "   ✅ $v  ($(Secs $s))"; Row "✅" $v $s }
function Skip($v) { Say "   ⏭  이미 있음  $v"; Row "⏭ 이미 있음" $v 0 }
function Pass($m) { Say "   ⏸  건너뜀: $m"; Row "⏸ 건너뜀" $m 0 }
function Bad($m)  {
  $s = Took; Say "   ❌ 실패: $m"; Say "      → 자세한 기록: $Log (맨 아래)"
  Get-Content $Log -Tail 12 | ForEach-Object { Write-Host "      | $_" }
  Row "❌" $m $s; $script:Failed++
}
function Want($n) { ($Only -eq "") -or ($Only -eq "$n") }

# winget 으로 설치: 먼저 「내 계정에만」, 안 되면 그냥
function WingetInstall($id) {
  $common = "--id $id -e --source winget --silent --disable-interactivity --accept-source-agreements --accept-package-agreements"
  $rc = LogRun "winget install $common --scope user"
  if ($rc -ne 0 -and $rc -ne -1978335189) {   # -1978335189 = 이미 설치됨
    $rc = LogRun "winget install $common"
  }
  Refresh-Path
  return $rc
}
function WingetHas($id) { $o = winget list --id $id -e --accept-source-agreements 2>$null | Out-String; return ($o -match [regex]::Escape($id)) }

# ───────────────────────── 단계 ─────────────────────────
$Steps = @(
  "1|Git", "2|GitHub CLI(gh)", "3|ffmpeg", "4|Node.js LTS", "5|Python 3 · uv",
  "6|Aside CLI", "7|Vercel CLI", "8|힉스필드 CLI", "9|Bun", "10|Claude Code 터미널판",
  "11|Aside 를 Claude 에 연결(MCP)", "12|Claude 앱", "13|Aside 앱", "14|텔레그램 앱", "15|캡컷 앱",
  "16|Qwen3-TTS(목소리 만들기)"
)
if ($List) { $Steps | ForEach-Object { $a = $_.Split('|'); "$($a[0]). $($a[1])" }; exit 0 }

function AppInstalled($pattern) {
  $keys = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
  $hit = Get-ItemProperty $keys -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like $pattern } | Select-Object -First 1
  if ($hit) { return ($(if ($hit.DisplayVersion) { $hit.DisplayVersion } else { "있음" })) }
  $pk = Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $pattern -or $_.Name -like ($pattern -replace ' ', '') } | Select-Object -First 1
  if ($pk) { return $pk.Version }
  return $null
}

# ── -Check: 설치는 안 하고 지금 상태만 표로(버전 · 어디 있는지 · 로그인)
if ($Check) {
  Refresh-Path
  $L = @("", "════════════════ 점검 표 (설치는 안 함, $(Get-Date -Format 'MM-dd HH:mm')) ════════════════", "| 무엇 | 상태 | 버전 · 계정 | 메모 |", "|---|---|---|---|")
  foreach ($c in "git", "gh", "ffmpeg", "node", "python", "uv", "aside", "vercel", "higgsfield", "bun", "claude") {
    $p = RealCmd $c
    if ($p) { $m = if ($script:Elsewhere[$c]) { "⚠️ PATH 밖에 있음: $($script:Elsewhere[$c])" } else { "" }; $L += "| $c | ✅ 있음 | $(Ver $c) | $m |" }
    else { $L += "| $c | ❌ 없음 | - | 설치: -Only 로 그 단계 |" }
  }
  foreach ($a in @(@("Claude 앱","Claude*"), @("Aside 앱","Aside*"), @("텔레그램 앱","Telegram*"), @("캡컷 앱","CapCut*"))) {
    $v = AppInstalled $a[1]; $L += $(if ($v) { "| $($a[0]) | ✅ 있음 | $v | |" } else { "| $($a[0]) | ❌ 없음 | - | |" })
  }
  $demo = Join-Path $WorkDir ".venv-qwen-tts\Scripts\qwen-tts-demo.exe"
  $L += $(if (Test-Path $demo) { "| Qwen3-TTS | ✅ 있음 | | $WorkDir\.venv-qwen-tts |" } else { "| Qwen3-TTS | ⏸ 없음 | - | 빈 공간을 15GB 넘게 만든 뒤 -Only 16 |" })
  # 연결 · 로그인
  if (Has claude) {
    $r = RunTimed "claude mcp get aside"; $L += $(if ($r.Code -eq 0) { "| Aside MCP | ✅ 연결됨 | | |" } else { "| Aside MCP | ❌ 연결 안 됨 | | -Only 11 |" })
    $r = RunTimed "claude mcp get elevenlabs"; $L += $(if ($r.Code -eq 0) { "| ElevenLabs | ✅ MCP 로 연결됨 | | |" } else { "| ElevenLabs | ⏸ MCP 없음 | | Claude 설정 → Connectors 의 ElevenLabs 로 연결(터미널에서는 확인 못 함) |" })
    $r = RunTimed "claude auth status"
    $L += $(if ($r.Out -match '"loggedIn"\s*:\s*true') { "| Claude Code 로그인 | ✅ 됨 | | |" } else { "| Claude Code 로그인 | ⏸ 안 됨 | | claude 를 열어 /login |" })
  }
  if (Has gh) {
    $r = RunTimed "gh auth status"
    $acct = if ($r.Out -match 'account (\S+)') { $Matches[1] } else { "" }
    $L += $(if ($r.Code -eq 0 -and $r.Out -notmatch '(?i)not logged') { "| GitHub(gh) 로그인 | ✅ 됨 | $acct | |" } else { "| GitHub(gh) 로그인 | ⏸ 안 됨 | | gh auth login |" })
  }
  if (Has git) {
    $gn = (& (RealCmd git) config --global user.name 2>$null); $ge = (& (RealCmd git) config --global user.email 2>$null)
    $L += $(if ($gn -and $ge) { "| git 이름 · 이메일 | ✅ 있음 | $gn | |" } else { "| git 이름 · 이메일 | ⏸ 없음 | | git config --global user.name / user.email |" })
  }
  if (Has vercel) {
    $r = RunTimed "vercel whoami"
    $who = ($r.Out -split "`n" | Where-Object { $_ -match '^\s*[A-Za-z0-9][\w.-]*\s*$' } | Select-Object -Last 1)
    $L += $(if ($r.Code -eq 0 -and $r.Out -notmatch '(?i)logged out|no existing credentials|not logged') { "| Vercel 로그인 | ✅ 됨 | $(if ($who) { $who.Trim() }) | |" } elseif ($r.Code -eq -1) { "| Vercel 로그인 | ? 확인 못 함 | | 시간 초과 |" } else { "| Vercel 로그인 | ⏸ 안 됨 | | vercel login |" })
  }
  if (Has higgsfield) {
    # 로그인 상태 명령이 없어 「토큰이 있나」만 본다. 토큰 값은 화면 · 기록 어디에도 남기지 않는다
    $r = RunTimed "higgsfield auth token"
    $has = ($r.Code -eq 0) -and ($r.Out.Length -ge 20) -and ($r.Out -notmatch '(?i)error|not (logged|authenticated)|login')
    $r = $null
    $L += $(if ($has) { "| 힉스필드 로그인 | ✅ 됨 | | |" } else { "| 힉스필드 | ⏸ 터미널 로그인 안 함 | | Claude 설정 → Connectors 의 Higgsfield 로 연결(터미널에서는 확인 못 함) |" })
  }
  $L += ""
  $L += "✅ 있음 · 됨 / ⏸ 사람이 할 일 남음 / ❌ 없음. 설치가 빠진 것은  powershell -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Only <번호>"
  $L | ForEach-Object { Write-Host $_ }
  $L | Set-Content -Path (Join-Path $HOME "nyc-check.txt") -Encoding UTF8
  exit 0
}

Say "════════════════════════════════════════"
Say " 뉴욕 AI 워크숍 설치를 시작합니다 ($(Get-Date -Format HH:mm))"
Say " 「이 앱이 디바이스를 변경하도록 허용하시겠어요?」 창이 뜨면 「예」를 눌러 주세요."
Say " 15~20분쯤 걸립니다."
Say "════════════════════════════════════════"

# ── 0. 먼저 확인
Begin 0 "먼저 확인(윈도우 버전 · 남은 용량 · 인터넷 · winget)"
$build = [Environment]::OSVersion.Version.Build
$Free0 = FreeGB
Say "   윈도우 빌드 $build · 남은 용량 ${Free0}GB"
if ($build -lt 17763) {
  Say "   ❌ 윈도우가 너무 오래됐습니다. 윈도우 10(1809) 이상이 필요합니다. 설정 → Windows 업데이트 후 다시 실행해 주세요."; exit 2
}
if ($Free0 -lt $MinFreeGB) {
  Say ""
  Say "   ❌ 남은 용량이 ${Free0}GB 라 설치를 시작하지 않습니다. 적어도 ${MinFreeGB}GB(넉넉히 15GB)가 비어 있어야 합니다."
  Say "      이렇게 비울 수 있습니다:"
  Say "      1) 다운로드 폴더 — 파일 탐색기 → 다운로드 → 다 쓴 설치 파일(.exe · .msi · .zip)을 지우기"
  Say "      2) 안 쓰는 앱 — 시작 → 설정 → 앱 → 설치된 앱 → 안 쓰는 앱 「제거」"
  Say "      3) 휴지통 비우기 — 바탕화면 휴지통을 오른쪽 클릭 → 휴지통 비우기"
  Say "      4) 임시 파일 — 시작 → 설정 → 시스템 → 저장소 → 임시 파일 → 파일 제거"
  Say "      비운 뒤 다시 실행하면 이어서 합니다."
  exit 2
}
try { Invoke-WebRequest -UseBasicParsing -Method Head -TimeoutSec 15 https://pixi.sh/install.ps1 | Out-Null } catch {
  Say "   ❌ 인터넷에 연결되지 않았습니다. 와이파이를 확인하고 다시 실행해 주세요."; exit 2
}
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {   # 새 계정에서는 등록이 안 돼 있을 수 있다 — 한 번 등록해 본다
  try { Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop } catch {}
  $env:Path = "$env:Path;$env:LOCALAPPDATA\Microsoft\WindowsApps"
}
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Say "   ❌ winget(앱 설치 관리자)이 없습니다. Microsoft Store 에서 「앱 설치 관리자」를 설치하거나 업데이트한 뒤 다시 실행해 주세요."; exit 2
}
# winget 목록(소스)이 비어 있으면(새 계정 · 처음 쓰는 PC, 오류 0x8a15000f) Microsoft 공식 목록을 다시 넣는다
$probe = winget search --id Git.Git -e --source winget --accept-source-agreements --disable-interactivity 2>&1 | Out-String
if ($probe -notmatch "Git\.Git") {
  Say "   winget 목록을 새로 받습니다(처음 한 번)"
  Add-Content $Log $probe -Encoding UTF8
  try { Add-AppxPackage -Path https://cdn.winget.microsoft.com/cache/source.msix -ErrorAction Stop } catch { Add-Content $Log "$_" -Encoding UTF8 }
  LogRun "winget source update --name winget" | Out-Null
  $probe = winget search --id Git.Git -e --source winget --accept-source-agreements --disable-interactivity 2>&1 | Out-String
  if ($probe -notmatch "Git\.Git") { Say "   ❌ winget 목록을 받지 못했습니다. 자세한 기록: $Log"; exit 2 }
}
$TtsOk = $Free0 -ge $TtsFreeGB
if (-not $TtsOk) { Say "   ⚠️  남은 용량이 ${TtsFreeGB}GB 보다 적어 Qwen3-TTS(16번)는 이번에 건너뜁니다." }
Say "   ✅ 시작합니다"
Refresh-Path

# ── 1~5. winget 기본 도구
$Base = @(
  @{ N=1; Cmd="git";    Id="Git.Git" },
  @{ N=2; Cmd="gh";     Id="GitHub.cli" },
  @{ N=3; Cmd="ffmpeg"; Id="Gyan.FFmpeg" },
  @{ N=4; Cmd="node";   Id="OpenJS.NodeJS.LTS" },
  @{ N=5; Cmd="python"; Id="Python.Python.3.13" }
)
foreach ($b in $Base) {
  if (-not (Want $b.N)) { continue }
  Begin $b.N ($Steps[$b.N-1].Split('|')[1])
  # 윈도우의 python 은 Microsoft Store 로 보내는 가짜(WindowsApps)일 수 있다
  if (Has $b.Cmd) { $w = if ($script:Elsewhere[$b.Cmd]) { " (PATH 밖: $($script:Elsewhere[$b.Cmd]))" } else { "" }; Skip "$(Ver $b.Cmd)$w"; continue }
  $rc = WingetInstall $b.Id
  if (Has $b.Cmd) {
    $v = Ver $b.Cmd
    if ($b.Cmd -eq "python") { if (Has py) { $v = "$v (py -3 $(& py -3 --version 2>$null))" } }
    Ok $v
  } else { Bad "winget $($b.Id) 설치 뒤에도 $($b.Cmd) 명령이 안 보임 (코드 $rc)" }
}

# 5번에 딸린 uv(파이썬 도구 실행기): Qwen3-TTS 를 건너뛰는 PC 에서도 ElevenLabs MCP(uvx) 가 돌게, Python 이 이미 있어도 따로 확인한다
function EnsureUv {
  if (Has uv) { return $true }
  WingetInstall "astral-sh.uv" | Out-Null
  if (-not (Has uv)) { LogRun "irm https://astral.sh/uv/install.ps1 | iex" | Out-Null; Refresh-Path }
  return (Has uv)
}
if (Want 5) {
  if (Has uv) { Say "   ⏭  uv 이미 있음  $(Ver uv)" }
  elseif (EnsureUv) { Say "   ✅ uv $(Ver uv)" }
  else { $script:CurN = 5; $script:CurName = "uv"; $script:StepT = Get-Date; Bad "uv 설치 실패 — ElevenLabs MCP 와 Qwen3-TTS 에 필요" }
}

# npm 전역 설치 자리(내 계정, 비밀번호 없이)
function NpmReady { if (-not (Has npm)) { return $false }; New-Item -ItemType Directory -Force -Path "$env:APPDATA\npm" | Out-Null; return $true }

# ── 6. Aside CLI
if (Want 6) { Begin 6 "Aside CLI"
  if (Has aside) { Skip (Ver aside) }
  else {
    # Aside 공식 설치 파일은 「파일로 받아서」 실행해야 한다(서명 확인 때문에 irm | iex 는 거절)
    $ai = Join-Path $Cache "aside-install.ps1"
    try { Invoke-WebRequest -UseBasicParsing https://releases.aside.com/install.ps1 -OutFile $ai } catch { Add-Content $Log "$_" -Encoding UTF8 }
    LogRun "& '$ai'" | Out-Null; Remove-Item $ai -ErrorAction SilentlyContinue; Refresh-Path
    if (Has aside) { Ok (Ver aside) } else { Bad "aside 명령이 안 보임" }
  }
}
# ── 7. Vercel CLI
if (Want 7) { Begin 7 "Vercel CLI"
  if (Has vercel) { Skip (Ver vercel) }
  elseif (-not (NpmReady)) { Pass "Node.js 가 없어서(4번 먼저)" }
  else { LogRun "npm install -g vercel" | Out-Null; Refresh-Path; if (Has vercel) { Ok (Ver vercel) } else { Bad "vercel 명령이 안 보임" } }
}
# ── 8. 힉스필드 CLI (higgsfield.ai/cli 안내: npm)
if (Want 8) { Begin 8 "힉스필드 CLI"
  if (Has higgsfield) { Skip (Ver higgsfield) }
  elseif (-not (NpmReady)) { Pass "Node.js 가 없어서(4번 먼저)" }
  else {
    $rc = LogRun "npm install -g @higgsfield/cli --allow-scripts=@higgsfield/cli"
    if ($rc -ne 0) { LogRun "npm install -g @higgsfield/cli" | Out-Null }
    Refresh-Path
    if ((Has higgsfield) -and (Ver higgsfield)) { Ok (Ver higgsfield) } else { Bad "higgsfield 명령이 안 됨" }
  }
}
# ── 9. Bun
if (Want 9) { Begin 9 "Bun"
  if (Has bun) { Skip (Ver bun) }
  else {
    $rc = WingetInstall "Oven-sh.Bun"
    if (-not (Has bun)) { LogRun "irm https://bun.sh/install.ps1 | iex" | Out-Null; Refresh-Path }
    if (Has bun) { Ok (Ver bun) } else { Bad "bun 명령이 안 보임" }
  }
}
# ── 10. Claude Code 터미널판
if (Want 10) { Begin 10 "Claude Code 터미널판"
  if (Has claude) { Skip (Ver claude) }
  else {
    LogRun "irm https://claude.ai/install.ps1 | iex" | Out-Null; Refresh-Path
    if (Has claude) { Ok (Ver claude) } else { Bad "claude 명령이 안 보임" }
  }
}
# ── 11. Aside MCP
if (Want 11) { Begin 11 "Aside 를 Claude 에 연결(MCP)"
  if (-not ((Has claude) -and (Has aside))) { Pass "claude · aside 명령이 둘 다 있어야 함" }
  else {
    & claude mcp get aside *> $null
    if ($LASTEXITCODE -eq 0) { Skip "연결돼 있음" }
    else {
      $asidePath = (Get-Command aside).Source
      LogRun "claude mcp add --scope user aside -- `"$asidePath`" mcp" | Out-Null
      & claude mcp get aside *> $null
      if ($LASTEXITCODE -eq 0) { Ok "연결함" } else { Bad "연결 안 됨" }
    }
  }
}

# ── 12~15. 앱 (winget 에 있으면 winget, 없으면 공식 설치 파일)
function AsideUrl {
  $a = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "x64" }
  try { $h = (Invoke-WebRequest -UseBasicParsing https://aside.com/download).Content -replace '\\/', '/' } catch { $h = "" }
  $m = [regex]::Match($h, "https://releases\.aside\.com/dev-updater/windows/[0-9.]+/AsideInstaller-[0-9.]+-win-$a\.exe")
  if ($m.Success) { return $m.Value }
  try { $j = Invoke-RestMethod https://ptqgesmtzwdmeiknncqc.supabase.co/functions/v1/omaha/version_info.json; return $j.platforms.win.architectures.$a.url } catch { return "" }
}
$Apps = @(
  @{ N=12; Name="Claude 앱";   Pattern="Claude*";     Id="Anthropic.Claude";        Url="" },
  @{ N=13; Name="Aside 앱";    Pattern="Aside*";      Id="";                        Url="aside" },
  @{ N=14; Name="텔레그램 앱"; Pattern="Telegram*";   Id="Telegram.TelegramDesktop"; Url="https://telegram.org/dl/desktop/win64" },
  @{ N=15; Name="캡컷 앱";     Pattern="CapCut*";     Id="ByteDance.CapCut";        Url="" }
)
foreach ($a in $Apps) {
  if (-not (Want $a.N)) { continue }
  Begin $a.N $a.Name
  $v = AppInstalled $a.Pattern
  if ($v) { Skip $v; continue }
  if ((FreeGB) -lt 4) { Bad "남은 용량 $(FreeGB)GB — 4GB 이상 비워야 함"; continue }
  if ($a.N -eq 15) { Say "   캡컷은 파일이 커서 몇 분 걸립니다." }
  if ($a.Id) { WingetInstall $a.Id | Out-Null }
  if (-not (AppInstalled $a.Pattern) -and $a.Url) {
    $u = if ($a.Url -eq "aside") { AsideUrl } else { $a.Url }
    if ($u) {
      # 지난번에 「아니요」 등으로 안 끝나고 남은 설치 파일이 있으면 끈다(남아 있으면 같은 파일을 다시 못 받아 ❌)
      Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -and ($_.Path -like "$Cache\*" -or (($_.ProcessName -in "mini_installer","setup") -and $_.Path -like "$env:TEMP\*")) } | Stop-Process -Force -ErrorAction SilentlyContinue
      $f = Join-Path $Cache ("{0}-{1}.exe" -f $a.N, (Get-Date -Format "HHmmss"))
      try {
        Invoke-WebRequest -UseBasicParsing -Uri $u -OutFile $f
        $sig = Get-AuthenticodeSignature $f
        Add-Content $Log "서명: $($sig.Status) $($sig.SignerCertificate.Subject)" -Encoding UTF8
        if ($sig.Status -eq "Valid") {
          $argList = if ($a.N -eq 14) { "/VERYSILENT /NORESTART /CURRENTUSER" } else { "/S" }
          # -Wait 는 설치 파일이 띄운 앱(Aside 등)이 닫힐 때까지 기다려 멈춘다 → 설치 파일 프로세스만 기다린다(최대 5분)
          $p = Start-Process -FilePath $f -ArgumentList $argList -PassThru
          if (-not $p.WaitForExit(300000)) { Add-Content $Log "설치 파일이 5분 안에 안 끝남(「예」 창에서 「아니요」를 눌렀을 수 있음)" -Encoding UTF8; Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
          Start-Sleep -Seconds 3
        } else { Add-Content $Log "서명이 올바르지 않아 실행하지 않음" -Encoding UTF8 }
      } catch { Add-Content $Log "$_" -Encoding UTF8 }
      Remove-Item $f -ErrorAction SilentlyContinue
    }
  }
  $v = AppInstalled $a.Pattern
  if ($v) { Ok $v } else { Bad "$($a.Name) 설치 확인 안 됨 — 「이 앱이 디바이스를 변경하도록 허용하시겠어요?」 창이 떴다면 「예」를 눌러야 함" }
}

# ── 16. Qwen3-TTS
if (Want 16) { Begin 16 "Qwen3-TTS(목소리 만들기)"
  $venv = Join-Path $WorkDir ".venv-qwen-tts"
  $demo = Join-Path $venv "Scripts\qwen-tts-demo.exe"
  $vpy  = Join-Path $venv "Scripts\python.exe"
  if ((Test-Path $demo) -and ((& $demo --help *>&1 | Out-String) -match "usage")) { Skip (& $vpy -c "import importlib.metadata as m;print(m.version('qwen-tts'))") }
  elseif (-not $TtsOk -and $Only -ne "16") { Pass "용량이 모자라 뺌(시작할 때 ${Free0}GB) — 빈 공간을 ${TtsFreeGB}GB 넘게 만든 뒤 -Only 16" }
  else {
    EnsureUv | Out-Null
    if (-not (Has sox)) { WingetInstall "ChrisBagwell.SoX" | Out-Null }
    if (-not (Has uv)) { Bad "uv 설치 실패" }
    else {
      if (-not (Test-Path $vpy)) { LogRun "uv venv --python 3.12 `"$venv`"" | Out-Null }
      LogRun "uv pip install --python `"$vpy`" --only-binary :all: qwen-tts" | Out-Null
      if ((Test-Path $demo) -and ((& $demo --help *>&1 | Out-String) -match "usage")) {
        Ok ("{0} (Python {1})" -f (& $vpy -c "import importlib.metadata as m;print(m.version('qwen-tts'))"), (& $vpy -c "import platform;print(platform.python_version())"))
      } else { Bad "qwen-tts-demo --help 가 안 됨" }
    }
  }
}

# ───────────────────────── 점검 표 ─────────────────────────
function V($c) { if (Has $c) { Ver $c } else { "-" } }
$total = Secs ((Get-Date) - $T0).TotalSeconds
$lines = @()
$lines += ""
$lines += "════════════════ 설치 점검 표 ($(Get-Date -Format HH:mm), 전체 $total) ════════════════"
$lines += "| 번호 | 항목 | 결과 | 버전 · 메모 | 걸린 시간 |"
$lines += "|---|---|---|---|---|"
foreach ($r in $Rows) { if ($r.N -eq 0) { continue }; $lines += "| $($r.N) | $($r.Name) | $($r.R) | $($r.V) | $(if ($r.S -eq 0) { '-' } else { Secs $r.S }) |" }
$lines += ""
$lines += "지금 쓸 수 있는 명령(버전):"
$lines += "  git $(V git) · gh $(V gh) · ffmpeg $(V ffmpeg) · node $(V node) · python $(V python) · aside $(V aside) · vercel $(V vercel) · higgsfield $(V higgsfield) · bun $(V bun) · claude $(V claude)"
$lines += "  남은 용량: 시작 ${Free0}GB → 지금 $(FreeGB)GB"
$lines += ""
if ($script:Failed -eq 0) { $lines += "✅ 설치가 끝났습니다." }
else { $lines += "❌ 실패 $($script:Failed)개. 자세한 기록: $Log"; $lines += "   고친 뒤 실패한 번호만 다시:  powershell -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Only <번호>" }
$lines += "다음: Claude 앱을 완전히 끄고(오른쪽 아래 트레이의 Claude 도 「종료」) 다시 켜 주세요. 그래야 새로 깐 도구들이 보입니다."
if (AppInstalled "CapCut*") { $lines += "캡컷은 시작 메뉴에서 직접 한 번 열어 보세요(처음 열 때 약관 동의 창이 나옵니다)." }
$lines | ForEach-Object { Write-Host $_ }
$lines | Set-Content -Path $Result -Encoding UTF8
$lines | Add-Content -Path $Log -Encoding UTF8
if ($script:Failed -eq 0) { exit 0 } else { exit 1 }
