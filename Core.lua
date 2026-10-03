local addonName, addon = ...

addon.name = addonName
addon.version = "0.2.0"
addon.schemaVersion = 1

local function canAccessValue(value)
    if type(issecretvalue) == "function" and issecretvalue(value) then
        if type(canaccessvalue) == "function" then
            return canaccessvalue(value)
        end
        return false
    end

    return true
end

local function canAccessTable(value)
    if type(value) ~= "table" then
        return false
    end

    if type(issecrettable) == "function" and issecrettable(value) then
        if type(canaccesstable) == "function" then
            return canaccesstable(value)
        end
        return false
    end

    return true
end

function addon.CanAccessValue(value)
    return canAccessValue(value)
end

function addon.CanAccessTable(value)
    return canAccessTable(value)
end

function addon.SafeScalar(value)
    if value == nil then
        return nil
    end

    if not canAccessValue(value) then
        return "<secret>"
    end

    local valueType = type(value)
    if valueType == "string" or valueType == "number" or valueType == "boolean" then
        return value
    end

    return nil
end

function addon.SafeCall(func, ...)
    if type(func) ~= "function" then
        return false, nil, "missing-function"
    end

    local ok, a, b, c, d, e = pcall(func, ...)
    if not ok then
        return false, nil, a
    end

    return true, a, b, c, d, e
end

function addon.GetServerTimestamp()
    if type(GetServerTime) == "function" then
        local ok, value = pcall(GetServerTime)
        if ok and canAccessValue(value) then
            return value
        end
    end

    if type(time) == "function" then
        local ok, value = pcall(time)
        if ok and canAccessValue(value) then
            return value
        end
    end

    return nil
end

function addon.GetCurrentMapID()
    if C_Map and type(C_Map.GetBestMapForUnit) == "function" then
        local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
        if ok and canAccessValue(mapID) and type(mapID) == "number" then
            return mapID
        end
    end

    return nil
end

local function safeGlobalCall(func, ...)
    if type(func) ~= "function" then
        return nil
    end

    local ok, value = pcall(func, ...)
    if ok and canAccessValue(value) then
        return value
    end

    return nil
end

function addon.GetContext()
    local context = {
        level = safeGlobalCall(UnitLevel, "player"),
        zone = safeGlobalCall(GetZoneText),
        subZone = safeGlobalCall(GetSubZoneText),
        mapID = addon.GetCurrentMapID(),
    }

    return context
end

local function getClientInfo()
    local info = {}

    if type(GetBuildInfo) == "function" then
        local ok, version, build, buildDate, interfaceVersion = pcall(GetBuildInfo)
        if ok then
            info.version = addon.SafeScalar(version)
            info.build = addon.SafeScalar(build)
            info.buildDate = addon.SafeScalar(buildDate)
            info.interface = addon.SafeScalar(interfaceVersion)
        end
    end

    info.locale = safeGlobalCall(GetLocale)
    info.projectID = addon.SafeScalar(WOW_PROJECT_ID)

    return info
end

local function getPlayerIdentity()
    local name = safeGlobalCall(UnitName, "player") or "Unknown"
    local realm = safeGlobalCall(GetRealmName) or "Unknown"

    local raceName
    local raceFile
    if type(UnitRace) == "function" then
        local ok, a, b = pcall(UnitRace, "player")
        if ok then
            raceName = addon.SafeScalar(a)
            raceFile = addon.SafeScalar(b)
        end
    end

    local className
    local classFile
    if type(UnitClass) == "function" then
        local ok, a, b = pcall(UnitClass, "player")
        if ok then
            className = addon.SafeScalar(a)
            classFile = addon.SafeScalar(b)
        end
    end

    local faction
    if type(UnitFactionGroup) == "function" then
        local ok, value = pcall(UnitFactionGroup, "player")
        if ok then
            faction = addon.SafeScalar(value)
        end
    end

    return {
        name = name,
        realm = realm,
        key = realm .. ":" .. name,
        guid = safeGlobalCall(UnitGUID, "player"),
        raceName = raceName,
        raceFile = raceFile,
        className = className,
        classFile = classFile,
        faction = faction,
    }
end

local function initializeRootDatabase()
    if type(FantaProbeQuestDB) ~= "table" then
        FantaProbeQuestDB = {}
    end

    local db = FantaProbeQuestDB
    db.schemaVersion = db.schemaVersion or addon.schemaVersion
    db.createdByVersion = db.createdByVersion or addon.version
    db.characters = db.characters or {}

    addon.db = db
end

local function initializeCharacterDatabase()
    local identity = getPlayerIdentity()
    local db = addon.db

    local character = db.characters[identity.key]
    if type(character) ~= "table" then
        character = {
            identity = {},
            sessions = {},
            events = {},
            nextSeq = 1,
        }
        db.characters[identity.key] = character
    end

    character.identity = identity
    character.identity.lastSeenLevel = safeGlobalCall(UnitLevel, "player")
    character.identity.lastSeenAt = addon.GetServerTimestamp()
    character.sessions = character.sessions or {}
    character.events = character.events or {}
    character.nextSeq = character.nextSeq or (#character.events + 1)

    local now = addon.GetServerTimestamp()
    local elapsed = type(GetTime) == "function" and GetTime() or 0
    local sessionID = tostring(now or 0) .. ":" .. tostring(math.floor((elapsed or 0) * 1000))

    local session = {
        id = sessionID,
        startedAt = now,
        addonVersion = addon.version,
        client = getClientInfo(),
        identity = identity,
    }

    character.sessions[#character.sessions + 1] = session

    addon.characterDB = character
    addon.session = session
end

function addon.AppendEvent(eventType, payload)
    local character = addon.characterDB
    local session = addon.session

    if not character or not session then
        return
    end

    local entry = {
        seq = character.nextSeq,
        event = eventType,
        sessionID = session.id,
        serverTime = addon.GetServerTimestamp(),
        elapsed = type(GetTime) == "function" and GetTime() or nil,
        context = addon.GetContext(),
    }

    character.nextSeq = character.nextSeq + 1

    if type(payload) == "table" then
        for key, value in pairs(payload) do
            entry[key] = value
        end
    end

    character.events[#character.events + 1] = entry
    character.identity.lastSeenLevel = entry.context and entry.context.level or character.identity.lastSeenLevel
    character.identity.lastSeenAt = entry.serverTime
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= addonName then
            return
        end

        initializeRootDatabase()
        self:RegisterEvent("PLAYER_LOGIN")
        return
    end

    if event == "PLAYER_LOGIN" then
        initializeCharacterDatabase()

        if type(addon.InitializeQuestCapture) == "function" then
            addon.InitializeQuestCapture()
        end

        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)
