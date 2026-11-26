--[[
    ============================================================
      CHAT
    ============================================================
      Receives the messages, checks them (length, spam, rank)
      and sends them to everyone.

      File     : server/chat.lua
      Author   : Grylix
      Site     : https://grylix.dev
      GitHub   : https://github.com/Gryliix
      Version  : 1.1 (26/11/2026)
      For      : HappinessMP
    ============================================================

      From your other server scripts:
        Exports.chat:SendMessage(playerId, "text")     -- one player
        Exports.chat:BroadcastMessage("text")          -- everyone
        Exports.chat:SetPlayerRank(playerId, "admin")  -- name colour (a rank from config.lua)
      Colours work inside the text: "{FF0000}red {FFFFFF}white".
]]

local cfg = ChatConfig

local ranks = {}    -- [playerId] = rank given by another script
local recent = {}   -- [playerId] = times of the last messages
local lastText = {} -- [playerId] = last message
local players = {}  -- [playerId] = name, filled when the player's script starts
local partner = {}  -- [playerId] = the player "/r" answers to
local startedAt = os.time()

local function safe(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then print("[chat] error: " .. tostring(err)) end
    end
end

local function staffRank(id)
    local entry = cfg.Staff[Player.GetName(id)]
    if type(entry) ~= "table" or not entry.ip then return nil end
    local ip = tostring(Player.GetIP(id)):gsub("^::ffff:", "")
    if ip == entry.ip then return entry.rank end
    return nil
end

local function rankOf(id)
    local rank = ranks[id] or staffRank(id) or cfg.DefaultRank
    if not cfg.Ranks[rank] then rank = cfg.DefaultRank end
    return rank
end

local function isFlooding(id)
    local now = os.time()
    local kept = {}
    for _, t in ipairs(recent[id] or {}) do
        if now - t < cfg.Flood.Seconds then table.insert(kept, t) end
    end
    recent[id] = kept
    if #kept >= cfg.Flood.Messages then return true end
    table.insert(kept, now)
    return false
end

-- Player text: no colour codes (nobody can fake a system line), cut at MaxLength characters.
local function clean(text)
    local s = tostring(text):gsub("[{}%c]", "")
    if not utf8.len(s) then return "" end
    -- Counted in characters, not bytes: an accented letter is 2 bytes.
    local cut = utf8.offset(s, cfg.MaxLength + 1)
    if cut then s = s:sub(1, cut - 1) end
    return s
end

local function notice(id, code)
    Events.CallRemote("chatbox:notice", id, { code })
end

Events.Subscribe("chatbox:send", safe(function(text)
    local id = Events.GetSource()
    local msg = clean(text)
    if msg == "" then return end

    if isFlooding(id) then return notice(id, "flood") end
    if cfg.BlockRepeat and lastText[id] == msg then return notice(id, "repeated") end
    lastText[id] = msg

    Events.BroadcastRemote("chatbox:message", { Player.GetName(id), cfg.Ranks[rankOf(id)], msg })
end), true)

-- A player ID, a full name, or the start of a name if only one player matches.
local function findPlayer(who)
    local number = math.tointeger(tonumber(who))
    if number and players[number] then return number end
    local wanted = who:lower()
    local found, count = nil, 0
    for id, name in pairs(players) do
        local lower = name:lower()
        if lower == wanted then return id end
        if lower:sub(1, #wanted) == wanted then found, count = id, count + 1 end
    end
    if count == 1 then return found end
    return nil
end

local function sendPrivate(from, to, text)
    if isFlooding(from) then return notice(from, "flood") end
    partner[from], partner[to] = to, from
    Events.CallRemote("chatbox:private", to, { "pm_from", Player.GetName(from), text })
    Events.CallRemote("chatbox:private", from, { "pm_to", Player.GetName(to), text })
end

Events.Subscribe("chatbox:private", safe(function(who, text)
    local id = Events.GetSource()
    if #cfg.PrivateCommands == 0 then return end
    local msg = clean(text)
    if msg == "" then return notice(id, "pm_usage") end
    local target = findPlayer(tostring(who))
    if not target or not Player.IsConnected(target) then return notice(id, "pm_notfound") end
    if target == id then return notice(id, "pm_self") end
    sendPrivate(id, target, msg)
end), true)

Events.Subscribe("chatbox:reply", safe(function(text)
    local id = Events.GetSource()
    if #cfg.PrivateCommands == 0 then return end
    local msg = clean(text)
    if msg == "" then return end
    local target = partner[id]
    if not target or not Player.IsConnected(target) then return notice(id, "pm_noreply") end
    sendPrivate(id, target, msg)
end), true)

Events.Subscribe("chatbox:join", safe(function()
    local id = Events.GetSource()
    if players[id] then return end
    players[id] = Player.GetName(id)
    -- Right after the resource starts, everyone already online reports in: stay quiet.
    if cfg.JoinLeave and os.time() - startedAt >= 10 then
        Events.BroadcastRemote("chatbox:presence", { "joined", players[id], cfg.Ranks[rankOf(id)] })
    end
end), true)

local LEAVE = { [0] = "left_timeout", [1] = "left_quit", [2] = "left_kick" }

Events.Subscribe("playerDisconnect", safe(function(id, name, reason)
    if cfg.JoinLeave and players[id] then
        -- The IP may be gone already, so only a rank set by a script is kept.
        local color = cfg.Ranks[ranks[id] or cfg.DefaultRank] or cfg.Ranks[cfg.DefaultRank]
        Events.BroadcastRemote("chatbox:presence", { LEAVE[reason] or "left_quit", name or players[id], color })
    end
    ranks[id], recent[id], lastText[id], players[id], partner[id] = nil, nil, nil, nil, nil
    -- The ID will be reused: nobody must answer the next player by mistake.
    for other, target in pairs(partner) do
        if target == id then partner[other] = nil end
    end
end))

function SendMessage(id, text)
    if not Player.IsConnected(id) then return end
    Events.CallRemote("chatbox:system", id, { tostring(text) })
end

function BroadcastMessage(text)
    Events.BroadcastRemote("chatbox:system", { tostring(text) })
end

function SetPlayerRank(id, rank)
    ranks[id] = rank
end
