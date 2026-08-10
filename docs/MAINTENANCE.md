# Обслуживание базы OpenCode

## Как устроено

`maintenance.sh` (копия лежит в `~/.local/share/opencode/`) запускается через launchd
(агент `com.user.opencode-maintenance`) в трёх случаях:
- каждые 6 часов бодрствования (`StartInterval = 21600`);
- ежедневно в 4:00 (`StartCalendarInterval` — если Mac спит, запуск откладывается);
- при каждом логине (`RunAtLoad`).

## Что делает скрипт (при каждом запуске)

1. **Удаляет старые чаты** — неактивные дольше `RETENTION_DAYS` (по умолчанию 3 дня)
   вместе со всеми сообщениями, фрагментами и событиями. Политика пользователя:
   всё важное сохранено в GitHub-доках, чаты — летучие.
2. **Удаляет события-сироты** — записи event-sourcing от уже удалённых сессий
   (главный источник раздувания базы из 6+ ГБ).
3. **Checkpoint WAL** — сливает WAL-журнал в основную базу.
4. **VACUUM** — полное физическое сжатие файла — только если OpenCode **закрыт**
   (иначе конфликт блокировок; страницы просто остаются свободными до ночи).
5. **Ротация лога** — обрезает `opencode.log` при размере больше 50 МБ.

## Настройки

| Параметр | Где | Значение |
|---|---|---|
| Срок хранения чатов | `RETENTION_DAYS` в `maintenance.sh` | 3 (0 = только сегодняшние) |
| Интервал запусков | plist: `StartInterval` | 21600 сек (6 ч) |
| Лимит лога | `LOGMAX` в `maintenance.sh` | 50 МБ |

## Ручные команды

```bash
# Посмотреть последний прогон
tail -5 ~/.local/share/opencode/maintenance.log

# Запустить чистку сейчас (если opencode открыт — VACUUM не выполнится)
bash ~/.local/share/opencode/maintenance.sh

# Перезагрузить агент launchd
launchctl unload ~/Library/LaunchAgents/com.user.opencode-maintenance.plist
launchctl load   ~/Library/LaunchAgents/com.user.opencode-maintenance.plist
```

## Аварийное сжатие базы

Если база снова раздулась (например, давно не было VACUUM при закрытом opencode):

```bash
# 1) закрыть OpenCode полностью
# 2) компакт-копия + замена
cd ~/.local/share/opencode
sqlite3 opencode.db "PRAGMA wal_checkpoint(TRUNCATE);"
mv opencode.db opencode.db.old
sqlite3 opencode.db "VACUUM INTO 'opencode.db.compact';"
mv opencode.db.compact opencode.db
rm -f opencode.db-wal opencode.db-shm
sqlite3 opencode.db "PRAGMA quick_check;"
rm opencode.db.old
```