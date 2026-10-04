# Northshire quest graph — live probe 2026-10-04

Test source: FantaProbeQuest 0.2.0 SavedVariables from the clean Human Hunter **Пиу** on **Classic Beta PvE 2**.

Client:

- WoW Forever 1.60.1
- build 70205
- Interface 16001
- locale ruRU

## Result summary

The clean Northshire run captured 20 distinct quest IDs and 408 events through level 5.

For this character, none of the captured Northshire quest snapshots exposed a usable native `C_QuestLine` questLineID. The graph below is therefore reconstructed from live quest events, NPC context, and before/after quest-offer sets.

Confidence labels:

- **DIRECT** — quest A was turned in and quest B immediately opened from the same NPC.
- **UNLOCK SET** — a quest was not offered immediately before A was turned in, but appeared in the same NPC's offer list immediately afterward.
- **PROBABLE** — chronology strongly suggests a link, but the log did not observe enough before/after NPC state to prove the prerequisite.
- **UNRESOLVED** — no successor relationship was observed yet.

## Reconstructed graph

### Main classic Northshire chain

```text
783  Внутренняя угроза
  ↓ DIRECT
7    Нападение на лагерь кобольдов
  ├─ UNLOCK SET → 15     Разведка в руднике Горного эха
  │                ↓ DIRECT
  │               21     Схватка у рудника Горного эха
  │                ├─ UNLOCK SET / DIRECT → 54     Донесение в Златоземье
  │                └─ UNLOCK SET          → 96627  В поисках приключений
  │
  └─ UNLOCK SET → 92479  Небрежно написанное письмо
```

Observations:

- Before quest 7 was turned in, Marshal McBride showed quest 7 as active and no available quests.
- Immediately after quest 7 was turned in, Marshal McBride offered both quest 15 and quest 92479.
- Before quest 21 was turned in at level 5, Marshal McBride had no available quests after the other active branch had been handled.
- Immediately after quest 21 was turned in, he offered both quest 54 and quest 96627.
- Quest 96627 is a Forever-added quest but still did not expose a native questLineID in this capture.

Current status at the checkpoint:

- 54 active
- 96627 active

### Brotherhood branch

```text
18  Братство воров
 ↓ DIRECT
6   Награда за голову Гаррика Тихокрада
```

Quest 3903 was also visible from Deputy Willem during the same visit after quest 18, but the probe does not prove that quest 18 unlocked it. It is therefore kept as a separate chain below.

### Millie chain

```text
3903  Милли Осворт
  ↓ DIRECT
3904  Урожай Милли
  ↓ DIRECT
3905  Уведомление о поставке винограда
```

All three transitions were observed through normal questing. Quest 3905 was turned in to Brother Neals.

### Forever / library / kobold research chain

Observed direct links:

```text
91741  Погрызенная книга
  ↓ DIRECT
92124  Библиотечный учет

91743  Гадкие грызуны
  ↓ DIRECT
91745  Консультант по горному делу
  ↓ DIRECT
91752  Общая картина
  ↓ DIRECT
91758  Слежка за кобольдом
  ↓ DIRECT
91772  Тсс! Идет охота на кобольдов!
```

Likely graph:

```text
91741 → 92124 → ? → 91743 → 91745 → 91752 → 91758 → 91772
```

The missing link between 92124 and 91743 is **PROBABLE**, not confirmed. Quest 92124 was turned in to Daniel, while quest 91743 was subsequently accepted from Brother Paxton. The probe did not capture a Brother Paxton offer-state before 92124 was completed, so it cannot prove that 92124 is the prerequisite.

Current status at the checkpoint:

- 91772 active

### Standalone / unresolved observations

```text
33     Волки на границе
92479  Небрежно написанное письмо
```

No successor was observed after quest 33.

Quest 92479 was unlocked in the same post-quest-7 offer set as quest 15 and was later turned in to Тордрин Мракоруб. No immediate successor was observed. It may be a side branch, a breadcrumb, or a prerequisite that merges into another Forever chain later; the current log is insufficient to decide.

## Important architecture findings

1. Native `C_QuestLine` cannot be assumed to cover ordinary Northshire quest chains.
2. A live observational graph can recover many real relationships without external databases.
3. Same-NPC immediate follow-ups are useful but not enough: quest 7 and quest 21 each unlocked **multiple** quests at once.
4. Therefore the probe must preserve the full before/after NPC offer set, not only the first quest the player clicks.
5. A player-facing addon cannot infer unseen future length from observation alone. To show "step X of Y" for unmarked old chains before the player has personally observed them, an additional source of chain metadata would still be required.
6. Quest ordering is a graph problem, not always a simple list problem.

## Next test segment

Continue the same Hunter naturally through:

- Goldshire and the rest of Elwynn Forest;
- Stormwind quests encountered naturally;
- every visible quest, including side quests and Forever-added quests.

Keep the three currently active quests (54, 91772, 96627) and continue normally.

The next segment should focus on:

- cross-NPC transitions;
- cross-zone / Stormwind delivery quests;
- branches that later merge;
- quests that appear because of level versus because of a prerequisite;
- any quest that finally exposes a native questLineID.
