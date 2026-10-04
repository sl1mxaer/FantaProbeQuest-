# Elwynn / Stormwind quest graph — clean Human Hunter

Source: `FantaProbeQuest(2).lua`, captured on WoW Forever `1.60.1.70205`, Interface `16001`, addon `FantaProbeQuest 0.2.0`.

Character: **Пиу**, Human Hunter, Classic Beta PvE 2.

## Aggregate results

- Recorded events: **1866**.
- Unique accepted quests: **79**.
- Unique turned-in/completed quests: **77**.
- Current active quests at final checkpoint: **2**.
- Completed quests with at least one observed graph edge: **63**.
- Completed quests with no observed graph edge yet: **14**.
- Native `C_QuestLine` result for this hunter: **zero populated questLineID records** in the entire capture.
- `AVAILABLE_QUEST_LINES` events were captured, but all returned empty `lines` / `forceVisibleQuestIDs` for this hunter.

## Current journal

- `109` — **Доклад Гриану Камнегриву**
- `246` — **Подсчет врагов**

## Reconstructed observed series

Legend: `→` direct same-NPC follow-up observed; `⇒` unlocked in a before/after offer-set change; `⇢` probable link, not proven as a prerequisite by this capture.

### Northshire / Forever adventure

```text
783 Внутренняя угроза
→ 7 Нападение на лагерь кобольдов
   ├⇒ 92479 Небрежно написанное письмо
   └⇒ 15 Разведка в руднике Горного эха
       → 21 Схватка у рудника Горного эха
          ├→ 54 Донесение в Златоземье
          └⇒ 96627 В поисках приключений
              → 95998 Дикие просторы
                 ├→ 96626 Основы походной жизни: кулинария
                 └⇒ 97923 Основы походной жизни: горное дело
```

### Library / kobold research (Forever)

```text
91741 Погрызенная книга
→ 92124 Библиотечный учет
⇢ 91743 Гадкие грызуны
→ 91745 Консультант по горному делу
→ 91752 Общая картина
→ 91758 Слежка за кобольдом
→ 91772 Тсс! Идет охота на кобольдов!
→ 91775 Вернуть книги
→ 91777 Редкие книги
```

### Defias + Millie unlock cluster

```text
18 Братство воров
├→ 6 Награда за голову Гаррика Тихокрада
└⇒ 3903 Милли Осворт
    → 3904 Урожай Милли
    → 3905 Уведомление о поставке винограда
```

### Crystal Lake Forever chain

```text
99127 Путаница с сетями
→ 99128 Склизкая угроза
→ 99129 Нелюбитель мурлоков
→ 99130 Заманчивое предложение
⇒ 99131 Наживка для успеха
```

### Young lovers

```text
106 Юные влюбленные
→ 111 Разговор с бабулей
→ 107 Записка для Вильяма
→ 112 Хрустальный фукус
⇢ 114 Вылазка
```

### Lost necklace

```text
85 Потерянное ожерелье
→ 86 Пирог для Билли
→ 84 Назад к Билли
→ 87 Фикс
```

### Mines / Westbrook / Westfall breadcrumbs

```text
62 Рудник Подземных глубин
→ 76 Яшмовая шахта
   ├→ 239 Гарнизон у Западного ручья просит помощи!
   │   → 11 Награда за гноллов из стаи Речной Лапы
   └⇒ 109 Доклад Гриану Камнегриву [ACTIVE]
```

### Guard Thomas / eastern Elwynn

```text
40 Водяная нечисть
→ 35 Новые заботы
→ 37 Пропавшие стражи
→ 45 Судьба Рольфа
→ 71 Доклад для Томаса
→ 39 Донесение Томаса
→ 59 Броня из кожи и ткани
```

### Hunter taming

```text
94792 Укрощение зверя
→ 94863 Укрощение зверя
→ 94864 Укрощение зверя
→ 94793 Укрощение зверя
```

### Stormwind tailoring delivery

```text
333 Харлан нуждается в помощи
→ 334 Посылка для Турмана
```

### Elmore delivery

```text
1097 Просьба Элмора
→ 353 Посылка для Грозовой Вершины [OFFERED, NOT ACCEPTED]
```

### Kobold candles / Stormwind

```text
60 Свечи кобольдов
→ 61 Посылка в Штормград
```

### Azora tools

```text
91723 Тонкие инструменты
→ 91724 Тонкие инструменты
```

### Extortion / Manhunt

```text
123 Вымогатель
⇒ 147 Охота на человека
```

### Redridge

```text
244 Вторжение гноллов
→ 246 Подсчет врагов [ACTIVE]

98407 Демонстрация силы was also visible from the same Redridge NPC after 246 was accepted, but this capture does not prove whether 244 or 246 is its prerequisite.
```

## False-positive / ambiguous follow-up examples

- `99130 → 40` was logged as `FOLLOWUP_CANDIDATE`, but quest 40 was already available from Remy before quest 99130 was turned in. It is **not** treated as a chain edge.
- `123 → 59` was likewise logged as a candidate because the player opened quest 59 after turning in 123, but quest 59 was already available before that turn-in. The actual new offer after 123 was quest 147.
- `112 → 114` is likely real, but the player waited about 21 seconds before opening 114; FantaProbeQuest 0.2.0's 15-second candidate window missed it. This is a probe limitation, not evidence against the relation.

## Completed quests with no observed edge yet

- `33` — Волки на границе
- `99143` — Бутылки и безделушки
- `2158` — Отдых и покой
- `47` — Золотая пыль
- `332` — Реклама винного магазина
- `91733` — Ниже по течению
- `52` — Защита границы
- `91725` — Украденные предметы для наложения чар
- `83` — Красный лен
- `5545` — Тридцать три несчастья
- `91732` — Хорошая сталь
- `88` — Принцесса должна умереть!
- `46` — Награда за мурлоков
- `176` — РАЗЫСКИВАЕТСЯ: "Дробитель"

These are not necessarily standalone in game data; the capture simply did not observe a prerequisite/follow-up relation for them.

## All completed quests

| # | Quest ID | Quest | Turn-in zone | Player level |
|---:|---:|---|---|---:|
| 1 | 783 | Внутренняя угроза | Элвиннский лес | 1 |
| 2 | 33 | Волки на границе | Элвиннский лес | 2 |
| 3 | 7 | Нападение на лагерь кобольдов | Элвиннский лес | 2 |
| 4 | 91741 | Погрызенная книга | Элвиннский лес | 2 |
| 5 | 92124 | Библиотечный учет | Элвиннский лес | 3 |
| 6 | 92479 | Небрежно написанное письмо | Элвиннский лес | 3 |
| 7 | 15 | Разведка в руднике Горного эха | Элвиннский лес | 3 |
| 8 | 91743 | Гадкие грызуны | Элвиннский лес | 4 |
| 9 | 18 | Братство воров | Элвиннский лес | 4 |
| 10 | 3903 | Милли Осворт | Элвиннский лес | 4 |
| 11 | 91745 | Консультант по горному делу | Элвиннский лес | 4 |
| 12 | 91752 | Общая картина | Элвиннский лес | 5 |
| 13 | 21 | Схватка у рудника Горного эха | Элвиннский лес | 5 |
| 14 | 91758 | Слежка за кобольдом | Элвиннский лес | 5 |
| 15 | 3904 | Урожай Милли | Элвиннский лес | 5 |
| 16 | 6 | Награда за голову Гаррика Тихокрада | Элвиннский лес | 5 |
| 17 | 3905 | Уведомление о поставке винограда | Элвиннский лес | 5 |
| 18 | 96627 | В поисках приключений | Элвиннский лес | 5 |
| 19 | 95998 | Дикие просторы | Элвиннский лес | 6 |
| 20 | 99127 | Путаница с сетями | Элвиннский лес | 6 |
| 21 | 99143 | Бутылки и безделушки | Элвиннский лес | 6 |
| 22 | 99128 | Склизкая угроза | Элвиннский лес | 6 |
| 23 | 54 | Донесение в Златоземье | Элвиннский лес | 6 |
| 24 | 91772 | Тсс! Идет охота на кобольдов! | Элвиннский лес | 6 |
| 25 | 2158 | Отдых и покой | Lion's Pride Inn (Elwynn) | 6 |
| 26 | 99129 | Нелюбитель мурлоков | Элвиннский лес | 6 |
| 27 | 96626 | Основы походной жизни: кулинария | Lion's Pride Inn (Elwynn) | 6 |
| 28 | 106 | Юные влюбленные | Элвиннский лес | 7 |
| 29 | 111 | Разговор с бабулей | Элвиннский лес | 7 |
| 30 | 85 | Потерянное ожерелье | Элвиннский лес | 7 |
| 31 | 86 | Пирог для Билли | Элвиннский лес | 7 |
| 32 | 84 | Назад к Билли | Элвиннский лес | 7 |
| 33 | 87 | Фикс | Элвиннский лес | 7 |
| 34 | 47 | Золотая пыль | Элвиннский лес | 7 |
| 35 | 99130 | Заманчивое предложение | Элвиннский лес | 8 |
| 36 | 62 | Рудник Подземных глубин | Элвиннский лес | 8 |
| 37 | 40 | Водяная нечисть | Элвиннский лес | 8 |
| 38 | 91775 | Вернуть книги | Элвиннский лес | 8 |
| 39 | 60 | Свечи кобольдов | Lion's Pride Inn (Elwynn) | 8 |
| 40 | 107 | Записка для Вильяма | Lion's Pride Inn (Elwynn) | 8 |
| 41 | 99131 | Наживка для успеха | Элвиннский лес | 8 |
| 42 | 91777 | Редкие книги | Элвиннский лес | 8 |
| 43 | 76 | Яшмовая шахта | Элвиннский лес | 8 |
| 44 | 112 | Хрустальный фукус | Lion's Pride Inn (Elwynn) | 9 |
| 45 | 114 | Вылазка | Элвиннский лес | 9 |
| 46 | 239 | Гарнизон у Западного ручья просит помощи! | Элвиннский лес | 9 |
| 47 | 61 | Посылка в Штормград | Штормград | 9 |
| 48 | 333 | Харлан нуждается в помощи | Штормград | 9 |
| 49 | 332 | Реклама винного магазина | Штормград | 9 |
| 50 | 334 | Посылка для Турмана | Штормград | 9 |
| 51 | 97923 | Основы походной жизни: горное дело | Штормград | 9 |
| 52 | 1097 | Просьба Элмора | Штормград | 9 |
| 53 | 35 | Новые заботы | Элвиннский лес | 9 |
| 54 | 91733 | Ниже по течению | Элвиннский лес | 9 |
| 55 | 52 | Защита границы | Элвиннский лес | 10 |
| 56 | 37 | Пропавшие стражи | Элвиннский лес | 10 |
| 57 | 45 | Судьба Рольфа | Элвиннский лес | 10 |
| 58 | 91723 | Тонкие инструменты | Элвиннский лес | 10 |
| 59 | 91725 | Украденные предметы для наложения чар | Элвиннский лес | 10 |
| 60 | 91724 | Тонкие инструменты | Элвиннский лес | 10 |
| 61 | 71 | Доклад для Томаса | Элвиннский лес | 11 |
| 62 | 83 | Красный лен | Элвиннский лес | 11 |
| 63 | 5545 | Тридцать три несчастья | Элвиннский лес | 11 |
| 64 | 91732 | Хорошая сталь | Элвиннский лес | 11 |
| 65 | 244 | Вторжение гноллов | Красногорье | 11 |
| 66 | 39 | Донесение Томаса | Элвиннский лес | 11 |
| 67 | 123 | Вымогатель | Элвиннский лес | 11 |
| 68 | 94792 | Укрощение зверя | Элвиннский лес | 11 |
| 69 | 94863 | Укрощение зверя | Элвиннский лес | 11 |
| 70 | 88 | Принцесса должна умереть! | Элвиннский лес | 11 |
| 71 | 94864 | Укрощение зверя | Элвиннский лес | 11 |
| 72 | 94793 | Укрощение зверя | Элвиннский лес | 11 |
| 73 | 59 | Броня из кожи и ткани | Элвиннский лес | 12 |
| 74 | 46 | Награда за мурлоков | Элвиннский лес | 12 |
| 75 | 147 | Охота на человека | Элвиннский лес | 12 |
| 76 | 11 | Награда за гноллов из стаи Речной Лапы | Элвиннский лес | 12 |
| 77 | 176 | РАЗЫСКИВАЕТСЯ: "Дробитель" | Элвиннский лес | 12 |

## Architecture conclusions

1. `C_QuestLine` cannot be the sole source for old/low-level Forever quest-series progress.
2. The live event stream is sufficient to reconstruct many real graph edges, including forks and breadcrumbs.
3. `FOLLOWUP_CANDIDATE` must never be treated as proof by itself; before/after NPC offer sets are required to reject false positives.
4. Observation alone cannot tell a first-time player the unseen future length of an old chain. A static quest graph source is still required for a reliable `step X of Y` UI.
5. Quest series should be modeled as a directed graph, not a flat array.
