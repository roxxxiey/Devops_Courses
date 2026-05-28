# DevOps docker-compose project

Проект для варианта 72: два контейнера `app` и `tester`, оба собираются из локальных Dockerfile на базе `ubuntu:22.04`.

## Что реализовано

- `app` собирается из `Dockerfile_app`.
- Во время сборки `app` скачивает репозиторий `moevm/devops-examples`, применяет локальный патч `patches/app.patch` к `EXAMPLE_APP` и копирует это демонстрационное веб-приложение.
- Корневой процесс `app` после стартовой настройки SSH: `python3 main.py`.
- SSH-доступ в `app` настраивается по публичному ключу из `.env`: `APP_PUBLIC_SSH_KEY`.
- `tester` собирается из `Dockerfile_tester`.
- В `tester` во время сборки генерируется пара SSH-ключей, при запуске она копируется в `./ssh/generated`.
- Корневой процесс `tester`: `python3 -m http.server 3000`, запущенный в рабочем каталоге `/work`.
- Тесты запускаются через `docker-compose exec`.
- Логи каждого этапа тестирования пишутся в `docker-compose logs tester`, `./logs/stdout.log` и `./logs/stderr.log`.
- Для варианта 72 лимит CPU: `1 + 72 % 2 = 1`.

## Настройка

Скопируйте пример окружения:

```bash
cp .env.example .env
```

Для SSH-доступа в `app` укажите публичный ключ:

```env
APP_PUBLIC_SSH_KEY="ssh-ed25519 AAAA... user@host"
```

Основные параметры из `.env`:

- `APP_PUBLIC_PORT` - публичный порт веб-приложения на host-машине.
- `APP_SSH_PORT` - публичный SSH-порт контейнера `app`.
- `TESTER_SSH_PORT` - публичный SSH-порт контейнера `tester`.
- `CPU_LIMIT` - лимит ядер CPU для каждого контейнера.
- `PIDS_LIMIT` - лимит максимального количества процессов.

## Сборка и запуск

```bash
docker-compose build
docker-compose up -d
```

Проверка веб-приложения:

```bash
curl http://127.0.0.1:8080/health
```

Основная страница демонстрационного приложения доступна по адресу:

```bash
curl http://127.0.0.1:8080/
```

## Запуск тестов

Все тесты запускаются через `docker-compose exec` внутри контейнера `tester`:

```bash
docker-compose exec tester /project/scripts/run_checks.sh
```

Цепочка тестов:

1. `ssort --check /work/app /work/tests`
2. `pylint --rcfile=/work/pylintrc /work/app/bad_code.py`
3. `python3 /work/tests/integration/test_headers.py`

В `app/bad_code.py` специально допущены ошибки, чтобы `ssort` и `pylint` нашли нарушения по выбранным критериям задания.

Включенные критерии `pylint`:

- `unused-import`
- `unused-variable`
- `invalid-name`
- `missing-module-docstring`
- `missing-function-docstring`
- `too-many-arguments`
- `too-many-locals`
- `redefined-builtin`
- `broad-exception-caught`
- `dangerous-default-value`

## Логи

Вывод контейнера `tester`:

```bash
docker-compose logs tester
```

Файлы логов:

```bash
cat ./logs/stdout.log
cat ./logs/stderr.log
```

## SSH

Доступ в `app` по вашему приватному ключу, соответствующему `APP_PUBLIC_SSH_KEY`:

```bash
ssh -i ./path/to/private_key -p 2223 appuser@127.0.0.1
```

Доступ в `tester` по ключу, сгенерированному во время сборки образа:

```bash
ssh -i ./ssh/generated/tester_ed25519 -p 2222 tester@127.0.0.1
```

## Остановка

```bash
docker-compose down
```
