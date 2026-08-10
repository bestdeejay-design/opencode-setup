# OpenCode Setup — автонастройка рабочего места агента

Приватный репозиторий-«самонастройка»: после чистой установки opencode на любом Mac
этот репозиторий с **одной командой** восстанавливает всю рабочую конфигурацию:
профиль я (Sisyphus), MCP-серверы, скиллы, обслуживание базы, правила поведения.

Язык общения с пользователем — русский. Всё в этом README — на русском.

---

## Что восстанавливается

| Компонент | Откуда | Что именно |
|---|---|---|
| Правила и профиль агента | `config/AGENTS.md` | язык, идентичность Sisyphus, профиль пользователя, политика данных |
| Конфиг opencode | `config/opencode.jsonc` | провайдеры, плагин `oh-my-openagent@latest`, MCP-серверы |
| Агенты (Sisyphus и др.) | `config/oh-my-openagent.json` | модели и fallback для 11 агентов + категорий |
| MCP: playwright, memory, filesystem | `config/package.json` | локальные бинарники (без медленного `npx`) |
| Скиллы (28 шт) | публичный `agent-skills` | code-review, frontend-perfection, seo-toolkit и др. |
| Обслуживание базы | `maintenance/` | чистка старых чатов (3 дня), WAL, VACUUM, ротация лога — через launchd |
| Прочее | `config/tui.json`, `lsp-install-decisions.json` | TUI, решения по LSP-серверам |

---

## Установка с нуля (пошагово)

### Шаг 0. Предпосылки (один раз)
- macOS, рабочий терминал (zsh).
- Установить GitHub CLI и Node:
  ```bash
  brew install gh node
  ```

### Шаг 1. Установить opencode
Официальный способ (CLI + desktop):
```bash
curl -fsSL https://opencode.ai/install | bash
```
Desktop-приложение: <https://opencode.ai/download> (используется как основная среда).

Проверка: `opencode --version`.

### Шаг 2. Авторизация GitHub
```bash
gh auth login        # аккаунт bestdeejay-design, протокол HTTPS
gh auth status       # должно показать Logged in
```
Доступ к GitHub работает через `gh` CLI — MCP-сервер `github` не нужен.

### Шаг 3. Клонировать этот репозиторий
```bash
mkdir -p ~/Projects
git clone https://github.com/bestdeejay-design/opencode-setup ~/Projects/opencode-setup
```

### Шаг 4. Запустить установку
```bash
bash ~/Projects/opencode-setup/setup.sh
```
Что сделает скрипт (всё с бэкапами существующих файлов):
1. разложит конфиги в `~/.config/opencode/`;
2. установит MCP-пакеты (playwright, memory, filesystem) локально в `~/.config/opencode/node_modules`;
3. склонирует скиллы из `bestdeejay-design/agent-skills` (лежат в `~/.config/opencode/skills`) и поставит их зависимости;
4. скопирует сервис обслуживания базы в `~/.local/share/opencode/` и зарегистрирует в launchd;
5. покажет проверки (gh, node, MCP-бинарки).

### Шаг 5. Перезапустить OpenCode
MCP-серверы читаются при старте — после перезапуска в чате появится полный арсенал.

### Шаг 6. Проверка агентом (рекомендуется)
В новом чате opencode написать:
```
настрой всё по репозиторию opencode-setup
```
Агент сам проверит: `gh auth status`, наличие MCP-бинарков, `launchctl list | grep opencode-maintenance`,
размер базы `~/.local/share/opencode/opencode.db`, целостность (`PRAGMA quick_check`).

---

## Что получается в итоге (карта рабочего места)

- **Чаты** живут 3 дня неактивности, потом удаляются автоматически (политика
  пользователя: всё важное сохраняется в GitHub-доки, чаты — летучие).
- **База** `~/.local/share/opencode/opencode.db` чистится каждые 6 часов бодрствования
  + при логине; VACUUM выполняется, когда OpenCode закрыт. Лог работы: `~/.local/share/opencode/maintenance.log`.
- **MCP-серверы**: `sqz` (сжатие контекста), `playwright` (браузер), `memory` (граф знаний — пуст, по запросу),
  `filesystem` (файлы вне workspace: OneDrive, Projects), `context7` (доки библиотек), `serena`, `codegraph`.
- **Отключены** (по скорости): `github` (есть gh), `sequential-thinking`, `filesystem` был возвращён локально.

---

## Как обновлять

- **Скиллы**: `git -C ~/Projects/agent-skills pull` (или перезапустить `setup.sh` — он переустановит, если папки скиллов нет).
- **Конфиг**: правите файлы в `~/Projects/opencode-setup`, коммитите и пушите — репозиторий и есть источник правды:
  ```bash
  cd ~/Projects/opencode-setup && git add -A && git commit -m "feat: ..." && git push
  ```
- **Порог хранения чатов**: `RETENTION_DAYS` в `~/.local/share/opencode/maintenance.sh`.

---

## Полезные ссылки

- Документация opencode: <https://opencode.ai/docs>
- Скиллы: <https://github.com/bestdeejay-design/agent-skills>
- Плагин агентов: `oh-my-openagent@latest` (Sisyphus и команда агентов)
- Проблемы и решения: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)