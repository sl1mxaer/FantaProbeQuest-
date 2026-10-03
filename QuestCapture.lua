local addonName, addon = ...

local eventFrame = CreateFrame("Frame")
local pendingQuestLoads = {}
local seenQuestIDs = {}
local lastJournalState = {}
local lastLineSignatures = {}
local currentInteractionQuestID
local initialSnapshotRecorded = false
local lastGossipSignature
local lastGossipTime = 0

local function safeScalar(value)
    return addon.SafeScalar(value)
end

local function getNPC()
    local npc = {}

    if type(UnitName) == "function" then
        local ok, value = pcall(UnitName, "npc")
        if ok then
            npc.name = safeScalar(value)
        end
    end

    if type(UnitGUID) == "function" then
        local ok, value = pcall(UnitGUID, "npc")
        if ok then
            npc.guid = safeScalar(value)
        end
    end

    if npc.name == nil and npc.guid == nil then
        return nil
    end

    return npc
end

local function requestQuestTitle(questID)
    if type(questID) ~= "number" then
        return nil
    end

    if C_QuestLog and type(C_QuestLog.GetTitleForQuestID) == "function" then
        local ok, title = pcall(C_QuestLog.GetTitleForQuestID, questID)
        if ok and addon.CanAccessValue(title) and title then
            return title
        end
    end

    if not pendingQuestLoads[questID] and C_QuestLog and type(C_QuestLog.RequestLoadQuestByID) == "function" then
        pendingQuestLoads[questID] = true
        pcall(C_QuestLog.RequestLoadQuestByID, questID)
    end

    return nil
end

local function safeQuestBool(func, questID)
    if type(func) ~= "function" then
        return nil
    end

    local ok, value = pcall(func, questID)
    if ok and addon.CanAccessValue(value) then
        return value
    end

    return nil
end

local function getLogIndex(questID)
    if not C_QuestLog or type(C_QuestLog.GetLogIndexForQuestID) ~= "function" then
        return nil
    end

    local ok, value = pcall(C_QuestLog.GetLogIndexForQuestID, questID)
    if ok and addon.CanAccessValue(value) then
        return value
    end

    return nil
end

local function copyQuestInfo(info)
    if type(info) ~= "table" or not addon.CanAccessTable(info) then
        return nil
    end

    return {
        title = safeScalar(info.title),
        questLogIndex = safeScalar(info.questLogIndex),
        questID = safeScalar(info.questID),
        level = safeScalar(info.level),
        difficultyLevel = safeScalar(info.difficultyLevel),
        suggestedGroup = safeScalar(info.suggestedGroup),
        frequency = safeScalar(info.frequency),
        isStory = safeScalar(info.isStory),
        isTask = safeScalar(info.isTask),
        isBounty = safeScalar(info.isBounty),
        isHidden = safeScalar(info.isHidden),
        isAutoComplete = safeScalar(info.isAutoComplete),
        questClassification = safeScalar(info.questClassification),
    }
end

local function getQuestInfoFromLog(questID)
    local questLogIndex = getLogIndex(questID)
    if not questLogIndex or not C_QuestLog or type(C_QuestLog.GetInfo) ~= "function" then
        return nil
    end

    local ok, info = pcall(C_QuestLog.GetInfo, questLogIndex)
    if not ok then
        return nil
    end

    return copyQuestInfo(info)
end

local function getObjectives(questID)
    if not C_QuestLog or type(C_QuestLog.GetQuestObjectives) ~= "function" then
        return nil
    end

    local ok, objectives = pcall(C_QuestLog.GetQuestObjectives, questID)
    if not ok or type(objectives) ~= "table" or not addon.CanAccessTable(objectives) then
        return nil
    end

    local result = {}
    for index, objective in ipairs(objectives) do
        if type(objective) == "table" and addon.CanAccessTable(objective) then
            result[#result + 1] = {
                index = index,
                text = safeScalar(objective.text),
                type = safeScalar(objective.type),
                finished = safeScalar(objective.finished),
                numFulfilled = safeScalar(objective.numFulfilled),
                numRequired = safeScalar(objective.numRequired),
                objectiveType = safeScalar(objective.objectiveType),
            }
        end
    end

    return result
end

local function copyQuestLineInfo(info)
    if type(info) ~= "table" or not addon.CanAccessTable(info) then
        return nil
    end

    return {
        questLineName = safeScalar(info.questLineName),
        questName = safeScalar(info.questName),
        questLineID = safeScalar(info.questLineID),
        questID = safeScalar(info.questID),
        x = safeScalar(info.x),
        y = safeScalar(info.y),
        isHidden = safeScalar(info.isHidden),
        isLegendary = safeScalar(info.isLegendary),
        isLocalStory = safeScalar(info.isLocalStory),
        isDaily = safeScalar(info.isDaily),
        isCampaign = safeScalar(info.isCampaign),
        isImportant = safeScalar(info.isImportant),
        isAccountCompleted = safeScalar(info.isAccountCompleted),
        isCombatAllyQuest = safeScalar(info.isCombatAllyQuest),
        isMeta = safeScalar(info.isMeta),
        inProgress = safeScalar(info.inProgress),
        isQuestStart = safeScalar(info.isQuestStart),
        floorLocation = safeScalar(info.floorLocation),
        startMapID = safeScalar(info.startMapID),
    }
end

local function buildLineMember(questID, index)
    return {
        index = index,
        questID = questID,
        title = requestQuestTitle(questID),
        inLog = getLogIndex(questID) ~= nil,
        completed = C_QuestLog and safeQuestBool(C_QuestLog.IsQuestFlaggedCompleted, questID) or nil,
        completedOnAccount = C_QuestLog and safeQuestBool(C_QuestLog.IsQuestFlaggedCompletedOnAccount, questID) or nil,
    }
end

local function getQuestLineInfo(questID, mapID)
    if not C_QuestLine or type(C_QuestLine.GetQuestLineInfo) ~= "function" then
        return nil, "missing-api"
    end

    local ok, info = pcall(C_QuestLine.GetQuestLineInfo, questID, mapID, false)
    if not ok then
        return nil, info
    end

    return copyQuestLineInfo(info), nil
end

local function buildQuestLineSnapshot(questID)
    if not C_QuestLine then
        return nil
    end

    local mapID = addon.GetCurrentMapID()
    local mapInfo
    local mapError

    if mapID then
        mapInfo, mapError = getQuestLineInfo(questID, mapID)
    end

    local globalInfo
    local globalError
    globalInfo, globalError = getQuestLineInfo(questID, nil)

    local selectedInfo = mapInfo or globalInfo
    local result = {
        currentMapID = mapID,
        mapInfo = mapInfo,
        globalInfo = globalInfo,
        mapLookupError = safeScalar(mapError),
        globalLookupError = safeScalar(globalError),
        selectedSource = mapInfo and "map" or (globalInfo and "global" or nil),
    }

    if not selectedInfo or type(selectedInfo.questLineID) ~= "number" then
        return result
    end

    result.questLineID = selectedInfo.questLineID
    result.questLineName = selectedInfo.questLineName

    if type(C_QuestLine.GetQuestLineQuests) == "function" then
        local ok, questIDs = pcall(C_QuestLine.GetQuestLineQuests, selectedInfo.questLineID)
        if ok and type(questIDs) == "table" and addon.CanAccessTable(questIDs) then
            result.members = {}

            for index, memberQuestID in ipairs(questIDs) do
                if addon.CanAccessValue(memberQuestID) and type(memberQuestID) == "number" then
                    result.members[#result.members + 1] = buildLineMember(memberQuestID, index)
                end
            end
        elseif not ok then
            result.membersError = safeScalar(questIDs)
        end
    end

    if type(C_QuestLine.IsComplete) == "function" then
        local ok, value = pcall(C_QuestLine.IsComplete, selectedInfo.questLineID)
        if ok then
            result.lineComplete = safeScalar(value)
        end
    end

    return result
end

local function getQuestDifficultyLevel(questID)
    if C_QuestLog and type(C_QuestLog.GetQuestDifficultyLevel) == "function" then
        local ok, value = pcall(C_QuestLog.GetQuestDifficultyLevel, questID)
        if ok then
            return safeScalar(value)
        end
    end

    return nil
end

local function buildQuestSnapshot(questID, includeObjectives)
    if type(questID) ~= "number" then
        return nil
    end

    seenQuestIDs[questID] = true

    local inLog = getLogIndex(questID) ~= nil
    local snapshot = {
        questID = questID,
        title = requestQuestTitle(questID),
        difficultyLevel = getQuestDifficultyLevel(questID),
        inLog = inLog,
        completed = C_QuestLog and safeQuestBool(C_QuestLog.IsQuestFlaggedCompleted, questID) or nil,
        completedOnAccount = C_QuestLog and safeQuestBool(C_QuestLog.IsQuestFlaggedCompletedOnAccount, questID) or nil,
        questLogInfo = getQuestInfoFromLog(questID),
        questLine = buildQuestLineSnapshot(questID),
    }

    if C_QuestLog and type(C_QuestLog.IsComplete) == "function" then
        snapshot.readyToTurnIn = safeQuestBool(C_QuestLog.IsComplete, questID)
    end

    if includeObjectives and inLog then
        snapshot.objectives = getObjectives(questID)
    end

    return snapshot
end

local function getCurrentJournalState()
    local state = {}

    if not C_QuestLog or type(C_QuestLog.GetNumQuestLogEntries) ~= "function" or type(C_QuestLog.GetInfo) ~= "function" then
        return state
    end

    local ok, numShownEntries = pcall(C_QuestLog.GetNumQuestLogEntries)
    if not ok or type(numShownEntries) ~= "number" then
        return state
    end

    for index = 1, numShownEntries do
        local infoOK, info = pcall(C_QuestLog.GetInfo, index)
        if infoOK and type(info) == "table" and addon.CanAccessTable(info) and not info.isHeader then
            local questID = safeScalar(info.questID)
            if type(questID) == "number" then
                state[questID] = {
                    questID = questID,
                    title = safeScalar(info.title) or requestQuestTitle(questID),
                    readyToTurnIn = C_QuestLog and safeQuestBool(C_QuestLog.IsComplete, questID) or nil,
                }
            end
        end
    end

    return state
end

local function buildJournalSnapshot()
    local state = getCurrentJournalState()
    local questIDs = {}

    for questID in pairs(state) do
        questIDs[#questIDs + 1] = questID
    end

    table.sort(questIDs)

    local quests = {}
    for _, questID in ipairs(questIDs) do
        quests[#quests + 1] = buildQuestSnapshot(questID, true)
    end

    return quests
end

local function recordJournalDiff(reason)
    local current = getCurrentJournalState()
    local added = {}
    local removed = {}
    local completionChanged = {}

    for questID, info in pairs(current) do
        local previous = lastJournalState[questID]
        if not previous then
            added[#added + 1] = buildQuestSnapshot(questID, true)
        elseif previous.readyToTurnIn ~= info.readyToTurnIn then
            completionChanged[#completionChanged + 1] = {
                before = previous.readyToTurnIn,
                after = info.readyToTurnIn,
                quest = buildQuestSnapshot(questID, true),
            }
        end
    end

    for questID, info in pairs(lastJournalState) do
        if not current[questID] then
            removed[#removed + 1] = {
                questID = questID,
                title = info.title or requestQuestTitle(questID),
                completed = C_QuestLog and safeQuestBool(C_QuestLog.IsQuestFlaggedCompleted, questID) or nil,
            }
        end
    end

    if #added > 0 or #removed > 0 or #completionChanged > 0 then
        addon.AppendEvent("QUEST_LOG_DIFF", {
            reason = reason,
            added = added,
            removed = removed,
            completionChanged = completionChanged,
        })
    end

    lastJournalState = current
end

local function requestQuestLinesForCurrentMap()
    local mapID = addon.GetCurrentMapID()

    if mapID and C_QuestLine and type(C_QuestLine.RequestQuestLinesForMap) == "function" then
        pcall(C_QuestLine.RequestQuestLinesForMap, mapID)
    end
end

local function lineSignature(line)
    if type(line) ~= "table" then
        return "nil"
    end

    local parts = {
        tostring(line.questLineID or ""),
        tostring(line.questLineName or ""),
        tostring(line.selectedSource or ""),
    }

    if type(line.members) == "table" then
        for _, member in ipairs(line.members) do
            parts[#parts + 1] = table.concat({
                tostring(member.questID or ""),
                tostring(member.title or ""),
                tostring(member.inLog),
                tostring(member.completed),
                tostring(member.completedOnAccount),
            }, ":")
        end
    end

    return table.concat(parts, "|")
end

local function captureKnownQuestLineChanges(reason)
    local current = getCurrentJournalState()
    for questID in pairs(current) do
        seenQuestIDs[questID] = true
    end

    for questID in pairs(seenQuestIDs) do
        local line = buildQuestLineSnapshot(questID)
        local signature = lineSignature(line)

        if lastLineSignatures[questID] ~= signature then
            lastLineSignatures[questID] = signature
            addon.AppendEvent("QUEST_LINE_STATE", {
                reason = reason,
                questID = questID,
                title = requestQuestTitle(questID),
                questLine = line,
            })
        end
    end
end

local function recordQuestEvent(eventName, questID, extra)
    local payload = extra or {}

    if type(questID) == "number" then
        payload.quest = buildQuestSnapshot(questID, true)
    else
        payload.questID = questID
    end

    payload.npc = payload.npc or getNPC()
    addon.AppendEvent(eventName, payload)
end

local function normalizeGossipQuest(info)
    if type(info) ~= "table" or not addon.CanAccessTable(info) then
        return nil
    end

    local questID = safeScalar(info.questID)
    local result = {
        title = safeScalar(info.title),
        questLevel = safeScalar(info.questLevel),
        isTrivial = safeScalar(info.isTrivial),
        frequency = safeScalar(info.frequency),
        repeatable = safeScalar(info.repeatable),
        isComplete = safeScalar(info.isComplete),
        isLegendary = safeScalar(info.isLegendary),
        isIgnored = safeScalar(info.isIgnored),
        questID = questID,
        isImportant = safeScalar(info.isImportant),
        isMeta = safeScalar(info.isMeta),
        questInfoID = safeScalar(info.questInfoID),
    }

    if type(questID) == "number" then
        result.quest = buildQuestSnapshot(questID, false)
    end

    return result
end

local function captureGossip()
    if not C_GossipInfo then
        return
    end

    local available = {}
    local active = {}

    if type(C_GossipInfo.GetAvailableQuests) == "function" then
        local ok, values = pcall(C_GossipInfo.GetAvailableQuests)
        if ok and type(values) == "table" and addon.CanAccessTable(values) then
            for _, info in ipairs(values) do
                local normalized = normalizeGossipQuest(info)
                if normalized then
                    available[#available + 1] = normalized
                end
            end
        end
    end

    if type(C_GossipInfo.GetActiveQuests) == "function" then
        local ok, values = pcall(C_GossipInfo.GetActiveQuests)
        if ok and type(values) == "table" and addon.CanAccessTable(values) then
            for _, info in ipairs(values) do
                local normalized = normalizeGossipQuest(info)
                if normalized then
                    active[#active + 1] = normalized
                end
            end
        end
    end

    if #available == 0 and #active == 0 then
        return
    end

    local signatureParts = {}
    for _, info in ipairs(available) do
        signatureParts[#signatureParts + 1] = "A:" .. tostring(info.questID or "") .. ":" .. tostring(info.isComplete)
    end
    for _, info in ipairs(active) do
        signatureParts[#signatureParts + 1] = "C:" .. tostring(info.questID or "") .. ":" .. tostring(info.isComplete)
    end

    local npc = getNPC()
    signatureParts[#signatureParts + 1] = npc and tostring(npc.guid or npc.name or "") or ""
    local signature = table.concat(signatureParts, "|")
    local now = type(GetTime) == "function" and GetTime() or 0

    if signature == lastGossipSignature and (now - lastGossipTime) < 2 then
        return
    end

    lastGossipSignature = signature
    lastGossipTime = now

    addon.AppendEvent("GOSSIP_QUESTS", {
        npc = npc,
        available = available,
        active = active,
    })
end

local function captureLegacyGreeting()
    local available = {}
    local active = {}

    if type(GetNumAvailableQuests) == "function" then
        local ok, count = pcall(GetNumAvailableQuests)
        if ok and type(count) == "number" then
            for index = 1, count do
                local questID
                local title

                if type(GetAvailableQuestInfo) == "function" then
                    local infoOK, _, _, _, _, id = pcall(GetAvailableQuestInfo, index)
                    if infoOK then
                        questID = safeScalar(id)
                    end
                end

                if type(GetAvailableTitle) == "function" then
                    local titleOK, value = pcall(GetAvailableTitle, index)
                    if titleOK then
                        title = safeScalar(value)
                    end
                end

                local record = {
                    index = index,
                    questID = questID,
                    title = title,
                }

                if type(questID) == "number" then
                    record.quest = buildQuestSnapshot(questID, false)
                end

                available[#available + 1] = record
            end
        end
    end

    if type(GetNumActiveQuests) == "function" then
        local ok, count = pcall(GetNumActiveQuests)
        if ok and type(count) == "number" then
            for index = 1, count do
                local questID
                local title
                local isComplete

                if type(GetActiveQuestID) == "function" then
                    local idOK, value = pcall(GetActiveQuestID, index)
                    if idOK then
                        questID = safeScalar(value)
                    end
                end

                if type(GetActiveTitle) == "function" then
                    local titleOK, value, complete = pcall(GetActiveTitle, index)
                    if titleOK then
                        title = safeScalar(value)
                        isComplete = safeScalar(complete)
                    end
                end

                local record = {
                    index = index,
                    questID = questID,
                    title = title,
                    isComplete = isComplete,
                }

                if type(questID) == "number" then
                    record.quest = buildQuestSnapshot(questID, false)
                end

                active[#active + 1] = record
            end
        end
    end

    addon.AppendEvent("QUEST_GREETING_STATE", {
        npc = getNPC(),
        available = available,
        active = active,
    })
end

local function getCurrentInteractionQuestID()
    if type(GetQuestID) == "function" then
        local ok, questID = pcall(GetQuestID)
        if ok and addon.CanAccessValue(questID) and type(questID) == "number" and questID > 0 then
            return questID
        end
    end

    return currentInteractionQuestID
end

local function scheduleJournalDiff(reason)
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(0, function()
            recordJournalDiff(reason)
        end)
    else
        recordJournalDiff(reason)
    end
end

local function recordInitialSnapshot()
    if initialSnapshotRecorded then
        return
    end

    initialSnapshotRecorded = true
    requestQuestLinesForCurrentMap()

    addon.AppendEvent("SESSION_START", {
        journal = buildJournalSnapshot(),
    })

    lastJournalState = getCurrentJournalState()
    captureKnownQuestLineChanges("SESSION_START")
end

local function onQuestLineUpdate(requestRequired)
    addon.AppendEvent("QUESTLINE_UPDATE", {
        requestRequired = safeScalar(requestRequired),
    })

    if requestRequired then
        requestQuestLinesForCurrentMap()
        return
    end

    captureKnownQuestLineChanges("QUESTLINE_UPDATE")
end

local function onEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        if not initialSnapshotRecorded then
            if C_Timer and type(C_Timer.After) == "function" then
                C_Timer.After(0.5, recordInitialSnapshot)
            else
                recordInitialSnapshot()
            end
        end
        return
    end

    if event == "PLAYER_LOGOUT" then
        addon.AppendEvent("SESSION_END", {
            journal = buildJournalSnapshot(),
        })
        return
    end

    if event == "GOSSIP_SHOW" then
        requestQuestLinesForCurrentMap()
        captureGossip()
        return
    end

    if event == "QUEST_GREETING" then
        requestQuestLinesForCurrentMap()
        captureLegacyGreeting()
        return
    end

    if event == "QUEST_DETAIL" then
        local questID = getCurrentInteractionQuestID()
        currentInteractionQuestID = questID
        requestQuestLinesForCurrentMap()

        local title
        if type(GetTitleText) == "function" then
            local ok, value = pcall(GetTitleText)
            if ok then
                title = safeScalar(value)
            end
        end

        recordQuestEvent("QUEST_DETAIL", questID, {
            displayedTitle = title,
        })
        return
    end

    if event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" then
        local questID = getCurrentInteractionQuestID()
        currentInteractionQuestID = questID
        recordQuestEvent(event, questID)
        return
    end

    if event == "QUEST_FINISHED" then
        addon.AppendEvent("QUEST_FINISHED", {
            questID = currentInteractionQuestID,
            npc = getNPC(),
        })
        currentInteractionQuestID = nil
        return
    end

    if event == "QUEST_ACCEPT_CONFIRM" then
        local name, questTitle, questID = ...
        recordQuestEvent("QUEST_ACCEPT_CONFIRM", questID, {
            sender = safeScalar(name),
            sharedQuestTitle = safeScalar(questTitle),
        })
        return
    end

    if event == "QUEST_ACCEPTED" then
        local questID = ...
        currentInteractionQuestID = questID
        recordQuestEvent("QUEST_ACCEPTED", questID)
        scheduleJournalDiff("QUEST_ACCEPTED")
        return
    end

    if event == "QUEST_AUTOCOMPLETE" then
        local questID = ...
        recordQuestEvent("QUEST_AUTOCOMPLETE", questID)
        return
    end

    if event == "QUEST_TURNED_IN" then
        local questID, xpReward, moneyReward = ...
        recordQuestEvent("QUEST_TURNED_IN", questID, {
            xpReward = safeScalar(xpReward),
            moneyReward = safeScalar(moneyReward),
        })
        scheduleJournalDiff("QUEST_TURNED_IN")
        return
    end

    if event == "QUEST_REMOVED" then
        local questID, wasReplayQuest = ...
        recordQuestEvent("QUEST_REMOVED", questID, {
            wasReplayQuest = safeScalar(wasReplayQuest),
        })
        scheduleJournalDiff("QUEST_REMOVED")
        return
    end

    if event == "QUEST_DATA_LOAD_RESULT" then
        local questID, success = ...
        if pendingQuestLoads[questID] then
            pendingQuestLoads[questID] = nil
            addon.AppendEvent("QUEST_DATA_LOAD_RESULT", {
                questID = questID,
                success = safeScalar(success),
                title = requestQuestTitle(questID),
            })
            captureKnownQuestLineChanges("QUEST_DATA_LOAD_RESULT")
        end
        return
    end

    if event == "QUESTLINE_UPDATE" then
        local requestRequired = ...
        onQuestLineUpdate(requestRequired)
        return
    end

    if event == "QUEST_LOG_UPDATE" then
        recordJournalDiff("QUEST_LOG_UPDATE")
        return
    end
end

function addon.InitializeQuestCapture()
    local events = {
        "PLAYER_ENTERING_WORLD",
        "PLAYER_LOGOUT",
        "GOSSIP_SHOW",
        "QUEST_GREETING",
        "QUEST_DETAIL",
        "QUEST_PROGRESS",
        "QUEST_COMPLETE",
        "QUEST_FINISHED",
        "QUEST_ACCEPT_CONFIRM",
        "QUEST_ACCEPTED",
        "QUEST_AUTOCOMPLETE",
        "QUEST_TURNED_IN",
        "QUEST_REMOVED",
        "QUEST_DATA_LOAD_RESULT",
        "QUESTLINE_UPDATE",
        "QUEST_LOG_UPDATE",
    }

    for _, event in ipairs(events) do
        eventFrame:RegisterEvent(event)
    end

    eventFrame:SetScript("OnEvent", onEvent)
end
