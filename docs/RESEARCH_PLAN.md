# FantaProbeQuest research plan

## Goal

Determine how completely World of Warcraft: Forever exposes old quest-chain structure through native client APIs, especially:

- whether `C_QuestLine.GetQuestLineInfo(questID)` returns data for old Vanilla-era quests;
- whether `C_QuestLine.GetQuestLineQuests(questLineID)` returns the full chain;
- whether the returned quest IDs are in actual story order;
- how optional quests, alternate variants and branches are represented;
- whether cross-zone quest chains stay in one quest line;
- whether completion state is sufficient to calculate "current step / total steps" without an external database.

## Existing Redridge character baseline

Source: manual screenshot before FantaProbeQuest was installed, followed by a live SavedVariables capture on Forever `1.60.1.70205`.

Character:

- Human Priest;
- screenshot baseline level: 21;
- realm: Classic Beta PvP 2;
- this is the existing higher-level character;
- the clean Human test will be performed on a different PvE realm.

The live client resolved the Redridge quests from the screenshot to:

| Quest ID | Quest |
| ---: | --- |
| 91 | Закон Соломона |
| 115 | Темная магия |
| 126 | Вой в холмах |
| 128 | Награда за головы орков Черной горы |
| 95999 | РАЗЫСКИВАЕТСЯ: Испепелитель Гар'им |
| 19 | Тарил'зун |
| 180 | РАЗЫСКИВАЕТСЯ: лейтенант Фангор |

### First live result

For all seven Redridge quests above, the first probe capture received no usable `C_QuestLine.GetQuestLineInfo()` result. The saved quest-line snapshot contained only the current map context.

This is not evidence that `C_QuestLine` is broken globally. In the same session, quest `92749` (**План с динамитом**) returned:

- questLineID: `6026`;
- quest-line name: **Ядовитая почва**;
- eleven returned member quest IDs.

The same returned line also showed duplicate quest titles/alternate entries and completion state that was not strictly monotonic around the currently active quest. Therefore:

1. old Vanilla-era quests cannot currently be assumed to have native quest-line metadata;
2. the raw array index from `GetQuestLineQuests()` cannot automatically be presented as "step X of Y";
3. branch/variant handling must be researched before a player-facing progress number is designed.

### Observational fallback

The first capture also proved that FantaProbeQuest can reconstruct real quest transitions from events even when `C_QuestLine` provides no chain metadata.

Example observed in the first session:

- quest `298`, **Отчет о ходе раскопок**, was turned in;
- quest `301`, **Отчет в Стальгорн**, was immediately shown and accepted from the same NPC.

Version `0.2.0` records such same-NPC immediate transitions explicitly as `FOLLOWUP_CANDIDATE`.

This fallback can build empirical chain relationships while the player quests, but by itself it cannot reveal unseen future steps before they are encountered.

## FantaProbeQuest 0.2.0 changes

- no longer stores objective text/counts in normal quest snapshots;
- suppresses the duplicate full-journal diff that could occur before the initial session snapshot;
- does not create repeated full quest-line snapshots just because another member title finished loading;
- records available quest lines returned for the current map;
- records zone/map changes and player level-up events;
- records strong same-NPC follow-up candidates after turn-in;
- avoids a large live API rescan during `PLAYER_LOGOUT`.

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
