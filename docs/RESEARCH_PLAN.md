# FantaProbeQuest research plan

## Goal

Determine how completely World of Warcraft: Forever exposes old quest-chain structure through native client APIs, especially:

- whether `C_QuestLine.GetQuestLineInfo(questID)` returns data for old Vanilla-era quests;
- whether `C_QuestLine.GetQuestLineQuests(questLineID)` returns the full chain;
- whether the returned quest IDs are in actual story order;
- how optional quests and branches are represented;
- whether cross-zone quest chains stay in one quest line;
- whether completion state is sufficient to calculate "current step / total steps" without an external database.

## Existing Redridge character baseline

Source: manual screenshot before FantaProbeQuest was installed.

Character context:

- class: Priest;
- level: 21;
- location: Redridge Mountains;
- this is the existing higher-level character;
- the new clean Human test will be performed on a different PvE realm.

Active quests visible in the screenshot:

| Display level | Quest | Visible objective |
| --- | --- | --- |
| 23+ | Закон Соломона | Подвеска Темношкуров: 1/10 |
| 23+ | Темная магия | Полуночная сфера: 0/3 |
| 25 | Вой в холмах | Лапа Изувоя: 0/1 |
| 25 | Награда за головы орков Черной горы | Воитель из клана Черной горы — убито: 0/15 |
| 25+ | РАЗЫСКИВАЕТСЯ: Испепелитель Гар'им | Сломанный посох Испепелителя Гар'има: 0/1 |
| 25+ | Тарил'зун | Голова Тарил'зуна: 0/1 |
| 26 | РАЗЫСКИВАЕТСЯ: лейтенант Фангор | Лапа Фангора: 0/1 |

Quest IDs are intentionally not guessed here. FantaProbeQuest should identify them from the live client during the initial journal snapshot.

### Particularly valuable Redridge cases

- **Вой в холмах**: likely useful for checking a conventional multi-step local chain.
- **Тарил'зун**: useful for checking a Blackrock-related continuation.
- The existing journal as a whole is useful because several chains are already partially progressed; this lets us test whether the client exposes earlier and later members even when the probe did not witness the beginning.

## Clean Human test character

Create a new Human Alliance character on the intended PvE realm and play normally.

Suggested analysis checkpoints:

1. levels 1–5: Northshire;
2. levels 5–7: early Elwynn / farms;
3. levels 7–10: eastern Elwynn;
4. Westfall;
5. Redridge.

At each checkpoint:

1. exit WoW normally so SavedVariables are written;
2. copy `FantaProbeQuest.lua` from account SavedVariables;
3. analyze the accumulated log;
4. only change the probe if the previous segment shows missing data.

## Priority chain shapes

The research should deliberately encounter several shapes:

- simple short linear chain;
- longer linear chain;
- identical quest titles with different quest IDs;
- branching / optional step;
- cross-zone chain;
- chain already partially completed before the probe was installed.

## Operating rule

The player should not type diagnostic commands or manually mark observations while leveling. The probe must collect enough context automatically to reconstruct quest progression afterward.
