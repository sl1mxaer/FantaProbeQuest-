# FantaProbeQuest

A silent diagnostic addon for **World of Warcraft: Forever** that records quest and quest-line behavior while the player quests normally.

The addon exists to research whether Forever's native quest APIs provide enough information to build a separate player-facing addon that can show progress through quest chains without an external quest database.

## Scope

FantaProbeQuest records only quest-related state:

- current quest log at session start;
- quest offers shown by NPC gossip;
- legacy quest greeting offers;
- quest detail opened before acceptance;
- quest accepted / turned in / removed / autocomplete events;
- quest progress/completion interaction states;
- quest-line updates;
- available quest-line data for the current map;
- `C_QuestLine.GetQuestLineInfo()` results;
- `C_QuestLine.GetQuestLineQuests()` membership and returned ordering;
- completion state for returned quest-line members;
- strong same-NPC follow-up candidates observed immediately after quest turn-in;
- quest titles as they become available from the client.

It intentionally does **not** record combat, targets, health, power, auras, spellcasts, combat-log data, or per-kill objective progress.

## No manual commands

There are no slash commands and no in-game configuration. Install the addon, enable it, and quest normally.

The addon is silent in chat.

## Saved data

All research data is stored account-wide in:

```text
WTF/Account/<ACCOUNT>/SavedVariables/FantaProbeQuest.lua
```

The database separates characters by realm and character name, so the existing Redridge test character and a new Human on another realm are kept apart.

WoW writes SavedVariables to disk on logout/reload. For analysis, exit the game normally before copying the file.

## Research status

The first live capture on Forever `1.60.1.70205` showed that native `C_QuestLine` coverage is selective:

- several old Redridge/Vanilla quests returned no quest-line metadata;
- a newer Forever quest returned a populated quest line with multiple members;
- the returned member list can include duplicate-title/alternate entries and non-monotonic completion state, so its array position must not automatically be treated as a simple story step.

Version `0.2.0` reduces duplicate logging and adds explicit observational follow-up detection for old quests that are not covered by `C_QuestLine`.

## Current target

- World of Warcraft: Forever
- Interface: `16001`
- Research build: `0.2.0`

See `docs/RESEARCH_PLAN.md` for the current test plan.
