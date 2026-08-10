#!/bin/bash
# ============================================================
#  opencode-setup — автораскладка рабочей конфигурации opencode
#  Запуск:  bash setup.sh   (в папке репозитория opencode-setup)
#  Идемпотентный: существующие файлы получают бэкап с датой.
# ============================================================
set -u

CONFIG="$HOME/.config/opencode"
DATA="$HOME/.local/share/opencode"
REPO="$(cd "$(dirname "$0")" && pwd)"
STAMP=$(date +%Y%m%d-%H%M%S)

backup() {
  [ -e "$1" ] && cp -R "$1" "$1.bak-$STAMP" 2>/dev/null || true
}

say()  { printf '\n\033[1;32m== %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!! %s\033[0m\n' "$*"; }

mkdir -p "$CONFIG" "$DATA" "$HOME/Projects" "$HOME/Library/LaunchAgents"

# ---------- 1. Основные конфиги ----------
say "1/5 Раскладываю конфиги в $CONFIG"
for f in AGENTS.md opencode.jsonc package.json oh-my-openagent.json tui.json lsp-install-decisions.json; do
  backup "$CONFIG/$f"
  cp "$REPO/config/$f" "$CONFIG/$f"
done

# ---------- 2. MCP-пакеты и утилиты (локально, без npx-задержек) ----------
say "2/5 Устанавливаю MCP-пакеты (playwright, memory, filesystem + утилиты)"
cd "$CONFIG" || exit 1
if command -v node >/dev/null 2>&1; then
  npm install --no-audit --no-fund
  if [ -x "$CONFIG/node_modules/.bin/playwright-mcp" ]; then
    say "    Браузеры Playwright (chromium) — только если нужен браузер"
    "$CONFIG/node_modules/.bin/playwright-mcp" --version >/dev/null 2>&1 || true
  fi
else
  warn "node не найден — пропускаю npm-установку (установите Node перед настройкой)"
fi

# ---------- 3. Скиллы из публичного репозитория agent-skills ----------
say "3/5 Скиллы: клонирую bestdeejay-design/agent-skills"
if [ ! -d "$CONFIG/skills" ] || ! ls "$CONFIG/skills"/SKILL.md >/dev/null 2>&1; then
  TMP_SK=$(mktemp -d)
  git clone --depth 1 -q https://github.com/bestdeejay-design/agent-skills "$TMP_SK" || warn "не удалось склонировать agent-skills"
  if [ -d "$TMP_SK/skills" ]; then
    backup "$CONFIG/skills"
    mkdir -p "$CONFIG/skills"
    cp -R "$TMP_SK/skills/." "$CONFIG/skills/"
    say "    Установлены скиллы: $(ls "$CONFIG/skills" | wc -l | tr -d ' ') шт"
    # зависимости скилла frontend-perfection (lighthouse и т.п.)
    if [ -f "$CONFIG/skills/frontend-perfection/scripts/package.json" ]; then
      (cd "$CONFIG/skills/frontend-perfection/scripts" && npm install --no-audit --no-fund) >/dev/null 2>&1 \
        && say "    Зависимости frontend-perfection установлены" || warn "зависимости frontend-perfection не установились"
    fi
  fi
  rm -rf "$TMP_SK"
else
  say "    Скиллы уже на месте — пропускаю"
fi

# ---------- 4. Обслуживание базы (launchd, ежедневно) ----------
say "4/5 Сервис обслуживания базы (чистка чатов, WAL, VACUUM)"
backup "$DATA/maintenance.sh"
cp "$REPO/maintenance/maintenance.sh" "$DATA/"
chmod +x "$DATA/maintenance.sh"
cp "$REPO/maintenance/com.user.opencode-maintenance.plist" "$HOME/Library/LaunchAgents/"
launchctl unload "$HOME/Library/LaunchAgents/com.user.opencode-maintenance.plist" 2>/dev/null || true
launchctl load "$HOME/Library/LaunchAgents/com.user.opencode-maintenance.plist" && \
  say "    launchd: com.user.opencode-maintenance активен"

# ---------- 5. Проверки ----------
say "5/5 Проверки"
printf '  gh CLI:      '; command -v gh >/dev/null 2>&1 && gh --version | head -1 || warn "gh не установлен: brew install gh && gh auth login"
printf '  node:        '; command -v node >/dev/null 2>&1 && node --version || warn "node не установлен"
printf '  MCP-бинарки: '; ls "$CONFIG"/node_modules/.bin/playwright-mcp "$CONFIG"/node_modules/.bin/mcp-server-memory "$CONFIG"/node_modules/.bin/mcp-server-filesystem 2>/dev/null | wc -l | tr -d ' '
echo " из 3 на месте"

printf '\n\033[1;36mГОТОВО. Дальше:\033[0m\n'
echo "  1. Перезапустить OpenCode (конфиг MCP читается при старте)."
echo "  2. Авторизация GitHub, если ещё нет:  gh auth login"
echo "  3. В новом чате сказать: «настрой всё по репозиторию opencode-setup» — агент проверит сам."
echo "  4. Логи обслуживания: $DATA/maintenance.log"