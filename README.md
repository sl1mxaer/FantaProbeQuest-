# FantaProbeQuest

A silent diagnostic addon for **World of Warcraft: Forever** that records quest and quest-line behavior while the player quests normally.

The addon exists to research whether Forever's native quest APIs provide enough information to build a separate player-facing addon that can show progress through quest chains without an external quest database.

## Scope

FantaProbeQuest records only quest-related state:

- current quest log on session start/end;
- quest offers shown by NPC gossip;
- legacy quest greeting offers;
- quest detail opened before acceptance;
- quest accepted / turned in / removed / autocomplete events;
- quest progress/completion interaction states;
- quest-line updates;
- `C_QuestLine.GetQuestLineInfo()` results;
- `C_QuestLine.GetQuestLineQuests()` ordering;
- completion state for every returned quest-line member;
- quest titles as they become available from the client.

It intentionally does **not** record combat, targets, health, power, auras, spellcasts, combat log data, or per-kill objective progress.

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

## Current target

- World of Warcraft: Forever
- Interface: `16001`
- Initial research build: `0.1.0`

See `docs/RESEARCH_PLAN.md` for the current test plan.
