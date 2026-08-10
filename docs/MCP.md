# MCP-серверы

## Текущий набор

| Сервер | Статус | Назначение | Путь |
|---|---|---|---|
| `sqz` | ✅ | сжатие длинных выводов | `/opt/homebrew/bin/sqz-mcp` |
| `playwright` | ✅ | браузер, скриншоты, e2e | `~/.config/opencode/node_modules/.bin/playwright-mcp` |
| `memory` | ✅ | граф знаний (пуст, по запросу) | `~/.config/opencode/node_modules/.bin/mcp-server-memory` |
| `filesystem` | ✅ | файлы вне workspace (OneDrive, Projects) | `~/.config/opencode/node_modules/.bin/mcp-server-filesystem` |
| `context7` | ✅ | доки библиотек (плагин) | — |
| `serena` | ✅ | навигация по коду (индексы по запросу) | `~/.local/bin/serena` |
| `codegraph` | ✅ | граф кода (в проектах с `.codegraph/`) | — |
| `lsp-daemon` | ✅ | диагностика кода (плагин) | — |
| `github` | ⛔ | не нужен — есть `gh` CLI | — |
| `sequential-thinking` | ⛔ | не используется | — |

## Как добавить новый сервер

1. Поставить пакет **локально** (никаких `npx -y` — медленно):
   ```bash
   cd ~/.config/opencode && npm install <пакет>
   ```
2. Прописать в `~/.config/opencode/opencode.jsonc` блок `mcp.<имя>`
   с командой на локальный бинарь из `~/.config/opencode/node_modules/.bin/`.
3. Перезапустить OpenCode (конфиг читается при старте).
4. Если сервер плагинный (context7, lsp-daemon) — регистрируется сам.

## Принципы

- **Только используемое**: лишние серверы добавляют время старта. `github`,
  `sequential-thinking` отключены намеренно.
- **Локально, без npx**: все MCP-пакеты ставятся в `~/.config/opencode/node_modules`.
- Enable/disable — флаг `"enabled"` в `opencode.jsonc`, без удаления конфига.