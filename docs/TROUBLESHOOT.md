# Частые проблемы и решения

## MCP-сервер не появляется после перезапуска

- Проверьте бинарь: `ls ~/.config/opencode/node_modules/.bin/<имя>`.
- Проверьте конфиг: `node -e "JSON.parse(require('fs').readFileSync('$HOME/.config/opencode/opencode.jsonc','utf8')); console.log('ok')"`.
- Убедитесь, что OpenCode **полностью** перезапущен (Cmd+Q, не просто новое окно).
- Если сервер падает при старте — запустите его вручную:
  `echo '' | ~/.config/opencode/node_modules/.bin/mcp-server-filesystem ~/Projects`

## База раздулась / тормозит

- Причины роста: события `message.updated` пишут полный контент на каждое обновление;
  старые чаты с большими вложениями.
- Лечение: `bash ~/.local/share/opencode/maintenance.sh` (при закрытом OpenCode сделает VACUUM).
- Аварийное сжатие — см. [MAINTENANCE.md](MAINTENANCE.md), раздел «Аварийное сжатие».

## «Rate limit exceeded» / отвалы ответов

- Провайдер `opencode.ai` имеет дневные лимиты на free-модели (1000 запросов/день).
- Лечение: подождать, переключить модель в `~/.config/opencode/oh-my-openagent.json`
  (fallback-модели уже прописаны), либо использовать локальную `qwen2.5-coder:7b`
  через провайдер `ollama-lan` (192.168.180.199 — IP может меняться, поправить в `opencode.jsonc`).

## Нет доступа к GitHub

```bash
gh auth login && gh auth status
```
MCP `github` не нужен — все операции через `gh` CLI и git.

## Playwright не запускает браузер

- Не установлены браузеры: `npx playwright install chromium` (или через бинарь:
  `~/.config/opencode/node_modules/.bin/playwright-mcp --version` не возвращает ошибок).
- Либо браузер установлен, но путь не найден — перезапустить OpenCode.

## Скиллы не подхватываются

- Путь скиллов: `~/.config/opencode/skills` (источник: `bestdeejay-design/agent-skills`).
- Проверьте `ls ~/.config/opencode/skills | wc -l` — должно быть ~28.
- Если папки нет: `bash ~/Projects/opencode-setup/setup.sh` (переустановит).
- В конфиге должен быть блок `"skills": { "sources": ["~/.config/opencode/skills"] }`.

## Очистка не запускается (launchd)

```bash
launchctl list | grep opencode-maintenance   # должен быть PID
tail -50 ~/.local/share/opencode/maintenance.log
launchctl unload ~/Library/LaunchAgents/com.user.opencode-maintenance.plist
launchctl load   ~/Library/LaunchAgents/com.user.opencode-maintenance.plist
```
Если файла plist нет — он в репозитории: `maintenance/com.user.opencode-maintenance.plist`.