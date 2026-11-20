#!/bin/bash
# setup.sh: يثبت Ghidra 12.2 و REA (rea-agents@6.10.1) و mingw-w64 و Wine
# ويشغّل Wine على الشاشة الافتراضية (Xvfb :99). مصمم لينتهي في أقل من 5 دقائق:
# التنزيلات الثلاثة (apt و Ghidra و npm) تعمل بالتوازي.
set -euo pipefail

# rea-agents 6.10.1 يرفض أي Ghidra أقدم من 12.2 (unsupported_version)
GHIDRA_VERSION="12.2"
GHIDRA_TAG="Ghidra_${GHIDRA_VERSION}_build"
GHIDRA_FALLBACK_ZIP="ghidra_${GHIDRA_VERSION}_PUBLIC_20261016.zip"
GHIDRA_INSTALL_DIR="/opt/ghidra"
REA_VERSION="6.10.1"
DISPLAY_NUM=":99"
LOG_DIR="${TMPDIR:-/tmp}/setup-logs"
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"

mkdir -p "$LOG_DIR"
SECONDS=0
log() { printf '[%3ds] %s\n' "$SECONDS" "$*"; }

# 1) الحزم من apt: mingw-w64 و Wine و Xvfb (و Java 21 إن لم يكن موجودا)
install_apt() {
  local pkgs=(mingw-w64 wine wine64 wine32:i386 xvfb unzip curl ca-certificates procps)
  java -version 2>&1 | grep -qE 'version "(2[1-9]|[3-9][0-9])' || pkgs+=(openjdk-21-jdk-headless)
  $SUDO dpkg --add-architecture i386 || true
  $SUDO apt-get update -qq
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq --no-install-recommends "${pkgs[@]}"
}

# 2) Ghidra 12.2 من إصدارات GitHub الرسمية (يستبدل أي إصدار آخر في /opt/ghidra)
install_ghidra() {
  if [ -x "$GHIDRA_INSTALL_DIR/support/analyzeHeadless" ] &&
     grep -q "application.version=$GHIDRA_VERSION" "$GHIDRA_INSTALL_DIR/Ghidra/application.properties"; then
    echo "Ghidra $GHIDRA_VERSION already installed"; return 0
  fi
  local api="https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/tags/$GHIDRA_TAG"
  local url
  url=$(curl -fsSL "$api" | grep -o '"browser_download_url": *"[^"]*\.zip"' | head -1 | cut -d'"' -f4) || true
  [ -n "$url" ] || url="https://github.com/NationalSecurityAgency/ghidra/releases/download/$GHIDRA_TAG/$GHIDRA_FALLBACK_ZIP"
  local tmp; tmp=$(mktemp -d)
  curl -fL --retry 3 -o "$tmp/ghidra.zip" "$url"
  unzip -q "$tmp/ghidra.zip" -d "$tmp"
  $SUDO rm -rf "$GHIDRA_INSTALL_DIR"
  $SUDO mv "$tmp"/ghidra_"${GHIDRA_VERSION}"_PUBLIC "$GHIDRA_INSTALL_DIR"
  rm -rf "$tmp"
}

# 3) REA بالإصدار المحدد
install_rea() {
  $SUDO npm install -g --no-fund --no-audit "rea-agents@$REA_VERSION"
}

log "بدء التثبيت بالتوازي (السجلات في $LOG_DIR)"
install_apt    >"$LOG_DIR/apt.log"    2>&1 & pid_apt=$!
install_ghidra >"$LOG_DIR/ghidra.log" 2>&1 & pid_ghidra=$!
install_rea    >"$LOG_DIR/rea.log"    2>&1 & pid_rea=$!

fail=0
for job in apt:$pid_apt ghidra:$pid_ghidra rea:$pid_rea; do
  name=${job%%:*}
  if wait "${job#*:}"; then log "تم: $name"
  else log "فشل: $name (انظر $LOG_DIR/$name.log)"; tail -5 "$LOG_DIR/$name.log"; fail=1; fi
done
[ "$fail" -eq 0 ] || exit 1

# 4) الشاشة الافتراضية و Wine عليها
export DISPLAY="$DISPLAY_NUM"
if ! xdpyinfo >/dev/null 2>&1 && ! pgrep -f "Xvfb $DISPLAY_NUM" >/dev/null; then
  nohup Xvfb "$DISPLAY_NUM" -screen 0 1280x1024x24 -nolisten tcp >"$LOG_DIR/xvfb.log" 2>&1 &
  for _ in $(seq 1 50); do [ -e "/tmp/.X11-unix/X${DISPLAY_NUM#:}" ] && break; sleep 0.1; done
fi
log "Xvfb يعمل على $DISPLAY"
# Wine 9 من Ubuntu يتعطل (free(): invalid pointer) إن لم يوجد /run/user/<uid>
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
$SUDO mkdir -p "$XDG_RUNTIME_DIR" && $SUDO chown "$(id -u):$(id -g)" "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
export WINEDEBUG=-all WINEDLLOVERRIDES="mscoree,mshtml="
timeout 120 wineboot --init >"$LOG_DIR/wineboot.log" 2>&1
# wineserver -w ينتظر خروج كل برامج Wine؛ المهلة تمنع التعليق إن كان برنامج مفتوحا
timeout 30 wineserver -w || true
log "Wine جاهز على $DISPLAY"

# 5) فحص سريع
log "Ghidra: $(grep application.version= "$GHIDRA_INSTALL_DIR/Ghidra/application.properties")"
log "REA: $(rea --version 2>/dev/null | head -1)"
log "mingw-w64: $(x86_64-w64-mingw32-gcc --version | head -1)"
log "Wine: $(wine --version)"
printf '#include <stdio.h>\nint main(void){puts("hello from mingw+wine");return 0;}\n' >"$LOG_DIR/hello.c"
x86_64-w64-mingw32-gcc -o "$LOG_DIR/hello.exe" "$LOG_DIR/hello.c"
log "تشغيل exe عبر Wine: $(wine "$LOG_DIR/hello.exe" 2>/dev/null | tr -d '\r')"

log "انتهى في ${SECONDS} ثانية"
[ "$SECONDS" -lt 300 ] || log "تحذير: تجاوز 5 دقائق"
