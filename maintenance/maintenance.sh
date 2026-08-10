#!/bin/bash
# opencode-maintenance: ежедневная профилактика накопительных эффектов.
# 1) Удаляет старые неактивные сессии (порог RETENTION_DAYS) + их события — «короткая память»: скорость важнее архива.
# 2) Удаляет события-сироты (event-sourcing лог удалённых сессий — главный раздуватель БД).
# 3) Валит WAL обратно в базу (checkpoint TRUNCATE).
# 4) Если opencode полностью закрыт — полный VACUUM (сжатие файла).
# 5) Обрезает активный лог до разумного размера.
# Настройка: сколько дней хранить неактивные сессии (0 = удалять всё старше суток).
RETENTION_DAYS=3
RET_MS=$((RETENTION_DAYS * 86400000))
set -u
DB=~/.local/share/opencode/opencode.db
LOG=~/.local/share/opencode/log/opencode.log
LOGMAX=52428800  # 50 МБ

cd ~/.local/share/opencode

# Определяем, закрыт ли opencode полностью (desktop + CLI)
OPENCODE_RUNNING=false
if pgrep -x "opencode" > /dev/null 2>&1 || pgrep -f "OpenCode Helper" > /dev/null 2>&1 || pgrep -f "OpenCode.app" > /dev/null 2>&1; then
  OPENCODE_RUNNING=true
fi

if [ ! -f "$DB" ]; then
  echo "$(date '+%F %T') нет базы, выход" >> maintenance.log
  exit 0
fi

SQL="PRAGMA busy_timeout=300000; PRAGMA foreign_keys=ON;
DELETE FROM part WHERE message_id NOT IN (SELECT id FROM message WHERE session_id IN (SELECT id FROM session WHERE time_updated >= (unixepoch()*1000 - RET_MS)));
DELETE FROM message WHERE session_id NOT IN (SELECT id FROM session WHERE time_updated >= (unixepoch()*1000 - RET_MS));
DELETE FROM event WHERE aggregate_id NOT IN (SELECT id FROM session WHERE time_updated >= (unixepoch()*1000 - RET_MS));
DELETE FROM event_sequence WHERE aggregate_id NOT IN (SELECT id FROM session WHERE time_updated >= (unixepoch()*1000 - RET_MS));
DELETE FROM session WHERE time_updated < (unixepoch()*1000 - RET_MS);
PRAGMA wal_checkpoint(TRUNCATE);"
if [ "$OPENCODE_RUNNING" = false ]; then
  SQL="$SQL VACUUM;"
fi

echo "$(date '+%F %T') opencode_running=$OPENCODE_RUNNING, начинаю очистку" >> maintenance.log
sqlite3 "$DB" "$SQL" >> maintenance.log 2>&1

# Ротация лога (если вырос — обрезаем, безопасно для открытого дескриптора)
if [ -f "$LOG" ]; then
  sz=$(stat -f%z "$LOG" 2>/dev/null || echo 0)
  if [ "$sz" -gt "$LOGMAX" ]; then
    : > "$LOG"
    echo "$(date '+%F %T') лог обрезан ($sz байт)" >> maintenance.log
  fi
fi

echo "$(date '+%F %T') готово" >> maintenance.log