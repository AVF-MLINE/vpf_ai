# VPF AI MVP

Rails-ready каркас для оценки группы риска по ИИ для проекта ВПФ.

Внутри:
- `lib/` — чистая Ruby-библиотека без внешних gem-зависимостей.
- `config/factor_schemas.yml` — схема факторов, whitelist полей, enum-коды и few-shot примеры.
- `templates/rails/` — готовые шаблоны миграции, модели, джоба, сервиса и presenter для Rails-приложения.
- `bin/evaluate_historical_cases` — офлайн-оценка исторического датасета.
- `test/` — minitest на ядро библиотеки.

## Что уже реализовано
- Загрузка и валидация схем для `ВБО`, `ВБЛ`, `НСТ`, `ХОБЛ`.
- Обезличенный whitelist-only extraction из входного hash.
- Нормализация enum/int/float значений по mapping-таблице.
- Компактная кодировка payload для экономии токенов.
- HTTP-клиент к `Yandex AI Studio Classifier API`.
- Retry логика для сетевых и 5xx ошибок.
- Результаты в формате `completed / error / insufficient_data`.
- Подсчёт пилотных метрик: coverage, exact match, one-step error rate, confusion matrix, latency, cost per 1000.

## Входной контракт
Библиотека ожидает на вход обычный Ruby hash, где ключи соответствуют `source_path` из [`config/factor_schemas.yml`](/Users/andreyf/Documents/VPF_AI/config/factor_schemas.yml).

Минимальный пример для `ХОБЛ`:

```ruby
input = {
  "worker" => { "contact_years" => 14, "age" => 52, "sex" => "m" },
  "work_conditions" => { "harm_class" => "3.2" },
  "anamnesis_respiratories" => { "smoke_idx" => 1, "crises_by_year" => 1 },
  "index_mmrcs" => { "degree" => 1, "cat_points" => 1 },
  "external_breathings" => { "spirometry" => 1, "spirometry_dynamics" => 0.5 }
}

result = VpfAi::Assessor.new.assess(:hobl, input)
result.status   # => "completed" / "error" / "insufficient_data"
result.ai_group # => "I".."IV" or nil
```

## Внедрение в Rails
1. Скопировать `lib/` и `config/factor_schemas.yml` в Rails-проект.
2. Скопировать нужные файлы из [`templates/rails/`](/Users/andreyf/Documents/VPF_AI/templates/rails).
3. Подключить concern `AiRisk::ConclusionSource` к модели заключения.
4. Реализовать метод `to_ai_risk_inputs` и замаппить поля приложения на contract из схем.
5. Прописать `YANDEX_AI_API_KEY` или `YANDEX_AI_IAM_TOKEN`, а также `YANDEX_AI_FOLDER_ID`.
6. Выполнить миграцию `ai_risk_assessments`.
7. Подключить presenter или сериализатор, чтобы отдавать `ai_risk_group` и `ai_risk_status` в UI.

## Как маппить поля
Источник истины по полям находится в [`config/factor_schemas.yml`](/Users/andreyf/Documents/VPF_AI/config/factor_schemas.yml):
- `source_path` — путь к полю во входном hash из приложения.
- `normalized_key` — человекочитаемое имя признака.
- `code` — короткий код, который попадает в compact payload.
- `required` — если нет значения, результат получает `insufficient_data`.

Часть полей для ВБО/ВБЛ оставлена как расширяемые placeholders для паллестезиометрии и термометрии:
- `pallesthesiometry.upper_limbs_score`
- `pallesthesiometry.lower_limbs_score`
- `thermometry.upper_limbs_delta_c`
- `thermometry.lower_limbs_delta_c`

Если в вашем приложении эти данные называются иначе, меняйте только `source_path` в YAML.

## Ограничения текущего MVP
- Классы по плану ограничены `I-IV`, хотя в части исходных алгоритмов могут встречаться дополнительные градации. Для расширения достаточно изменить `labels` в YAML.
- Few-shot примеры заложены стартовые. Перед продом их нужно откалибровать на истории.
- Так как исходного Rails-приложения в workspace нет, слой `templates/rails/` сделан как готовый шаблон, а не как уже подключённая часть реального проекта.
- Схемы основаны на приложенных PDF там, где поля удалось прочитать напрямую; для неполностью читаемых блоков оставлены явные точки расширения в YAML.

## Офлайн-пилот
`bin/evaluate_historical_cases` принимает JSON-массив или NDJSON со строками вида:

```json
{
  "factor_code": "vbo",
  "expected_group": "III",
  "predicted_group": "II",
  "status": "completed",
  "latency_ms": 1180,
  "cost_usd": 0.011
}
```

Запуск:

```bash
ruby -Ilib bin/evaluate_historical_cases path/to/results.json
```

## Проверка
Локальный прогон тестов:

```bash
ruby -Ilib:test -e 'Dir["/Users/andreyf/Documents/VPF_AI/test/*_test.rb"].sort.each { |file| load file }'
```
