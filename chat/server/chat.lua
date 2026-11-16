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
      Version  : 1.0 (16/11/2026)
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

local function safe(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then print("[chat] error: " .. tostring(err)) end
    end
end

local function rankOf(id)
    local rank = ranks[id] or cfg.Staff[Player.GetName(id)] or cfg.DefaultRank
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

-- Player text: no colour codes (nobody can fake a system line), cut at MaxLength.
local function clean(text)
    local s = tostring(text):gsub("[{}]", ""):sub(1, cfg.MaxLength)
    -- A cut in the middle of an emoji would leave a broken character.
    while #s > 0 and not utf8.len(s) do s = s:sub(1, -2) end
    return s
end

Events.Subscribe("chatbox:send", safe(function(text)
    local id = Events.GetSource()
    local msg = clean(text)
    if msg == "" then return end

    if isFlooding(id) then
        Events.CallRemote("chatbox:notice", id, { "flood" })
        return
    end
    if cfg.BlockRepeat and lastText[id] == msg then
        Events.CallRemote("chatbox:notice", id, { "repeated" })
        return
    end
    lastText[id] = msg

    Events.BroadcastRemote("chatbox:message", { Player.GetName(id), cfg.Ranks[rankOf(id)], msg })
end), true)

Events.Subscribe("playerDisconnect", safe(function(id)
    ranks[id], recent[id], lastText[id] = nil, nil, nil
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
