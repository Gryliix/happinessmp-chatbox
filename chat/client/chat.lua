--[[
    ============================================================
      CHAT
    ============================================================
      Opens the chat with the keys from the config, sends what
      the player types, shows the messages.

      File     : client/chat.lua
      Author   : Grylix
      Site     : https://grylix.dev
      GitHub   : https://github.com/Gryliix
      Version  : 1.0 (16/11/2026)
      For      : HappinessMP
    ============================================================

      From your other client scripts:
        Exports.chat:AddMessage("text")                     -- a line only this player sees
        Events.Call("chatbox:setLocked", { "my_menu", true })  -- hides the chat and blocks it
        Events.Call("chatbox:setLocked", { "my_menu", false }) -- gives it back
        Events.Call("chatbox:setLanguage", { "fr" })           -- changes the language
        Events.Subscribe("chatbox:visibilityChanged", function(open) end) -- input opened or closed
      Commands ("/something") are sent to your scripts with the "chatCommand" event.
]]

local cfg = ChatConfig
local language = cfg.Language
local webui = nil
local pageReady = false
local inputOpen = false
local locks = {}
local pending = {}

-- Text for the page. Accented letters are written as é so they always arrive intact.
local function jsonString(s)
    s = tostring(s)
    local out = {}
    local i = 1
    while i <= #s do
        local c = s:byte(i)
        if c < 0x80 then
            if c == 34 or c == 92 then
                table.insert(out, "\\" .. string.char(c))
            elseif c < 0x20 then
                table.insert(out, string.format("\\u%04x", c))
            else
                table.insert(out, string.char(c))
            end
            i = i + 1
        elseif c < 0xE0 then
            table.insert(out, string.format("\\u%04x", (c % 0x20) * 0x40 + (s:byte(i + 1) % 0x40)))
            i = i + 2
        elseif c < 0xF0 then
            table.insert(out, string.format("\\u%04x", (c % 0x10) * 0x1000 + (s:byte(i + 1) % 0x40) * 0x40 + (s:byte(i + 2) % 0x40)))
            i = i + 3
        else
            table.insert(out, "?") -- emoji: not supported
            i = i + 4
        end
    end
    return '"' .. table.concat(out) .. '"'
end

local function localPed()
    return Game.GetPlayerChar(Game.GetPlayerId())
end

local function pushConfig()
    if not pageReady then return end
    local t = cfg.Texts[language] or cfg.Texts.en
    local json = string.format(
        '{"position":%s,"offsetX":%s,"offsetY":%s,"width":%s,"lines":%s,"fade":%s,"accent":%s,"channel":%s,"placeholder":%s,"maxLength":%s}',
        jsonString(cfg.Position), tonumber(cfg.OffsetX), tonumber(cfg.OffsetY), tonumber(cfg.Width),
        tonumber(cfg.Lines), tonumber(cfg.FadeDelay), jsonString(cfg.AccentColor),
        jsonString(t.channel), jsonString(t.placeholder), tonumber(cfg.MaxLength))
    WebUI.CallEvent(webui, "chatbox:config", { json })
end

local function addLine(kind, a, b, c)
    if not pageReady then
        table.insert(pending, { kind, a, b, c })
        return
    end
    WebUI.CallEvent(webui, "chatbox:add", { kind, a or "", b or "", c or "" })
end

-- IsCharDead is unreliable in multiplayer, so check how long the player has been dead instead.
local function isDead()
    local ok, deadFor = pcall(Game.HowLongHasNetworkPlayerBeenDeadFor, Game.GetPlayerId())
    return ok and type(deadFor) == "number" and deadFor > 0
end

local function isLocked()
    return next(locks) ~= nil
end

local function applyHidden()
    if pageReady then WebUI.CallEvent(webui, "chatbox:setHidden", { isLocked() }) end
end

-- No chat when: locked, dead, pause menu, or another page has focus.
local function canOpen()
    if not pageReady or isLocked() or isDead() or Game.IsPauseMenuActive() then return false end
    local okE, alive = pcall(Game.DoesCharExist, localPed())
    if not (okE and alive) then return false end
    local okF, focus = pcall(WebUI.GetFocus)
    if okF and focus and focus ~= -1 and focus ~= webui then return false end
    return true
end

local function openInput()
    inputOpen = true
    WebUI.CallEvent(webui, "chatbox:showInput", {})
    WebUI.SetFocus(webui)
    -- Other scripts read the raw keyboard: this tells them the player is typing.
    Events.Call("chatbox:visibilityChanged", { true })
end

local function closeInput()
    if not inputOpen then return end
    inputOpen = false
    WebUI.CallEvent(webui, "chatbox:hideInput", {})
    local okF, focus = pcall(WebUI.GetFocus)
    if okF and focus == webui then WebUI.SetFocus(-1) end
    Events.Call("chatbox:visibilityChanged", { false })
end

Events.Subscribe("chatbox:ready", function()
    pageReady = true
    pushConfig()
    for _, m in ipairs(pending) do addLine(m[1], m[2], m[3], m[4]) end
    pending = {}
    applyHidden()
end, true)

Events.Subscribe("chatbox:submit", function(text)
    closeInput()
    if not text or text == "" then return end
    if text:sub(1, 1) == "/" then
        Events.Call("chatCommand", { text })
    else
        Events.CallRemote("chatbox:send", { text })
    end
end, true)

Events.Subscribe("chatbox:cancel", function()
    closeInput()
end, true)

-- A player message from the server.
Events.Subscribe("chatbox:message", function(name, color, text)
    addLine("player", name, color, text)
end, true)

-- A line from your own scripts (Exports.chat:SendMessage / BroadcastMessage).
Events.Subscribe("chatbox:system", function(text)
    addLine("system", text)
end, true)

Events.Subscribe("chatbox:notice", function(code)
    local t = cfg.Texts[language] or cfg.Texts.en
    if t[code] then addLine("notice", t[code]) end
end, true)

function AddMessage(text)
    addLine("system", tostring(text))
end

Events.Subscribe("chatbox:setLocked", function(name, locked)
    locks[tostring(name)] = locked and true or nil
    if isLocked() then closeInput() end
    applyHidden()
end)

Events.Subscribe("chatbox:setLanguage", function(lang)
    if cfg.Texts[lang] then
        language = lang
        pushConfig()
    end
end)

Events.Subscribe("scriptInit", function()
    webui = WebUI.Create("resource://" .. Resource.GetCurrentName() .. "/UI/chat.html", 1920, 1080, true)

    Thread.Create(function()
        while true do
            if inputOpen then
                if not canOpen() then closeInput() end
            elseif canOpen() then
                for _, key in ipairs(cfg.OpenKeys) do
                    if Game.GetAsciiJustPressed(key) then
                        openInput()
                        break
                    end
                end
            end
            Thread.Pause(0)
        end
    end)
end)

Events.Subscribe("resourceStop", function(resourceName)
    if resourceName ~= Resource.GetCurrentName() or not inputOpen then return end
    local okF, focus = pcall(WebUI.GetFocus)
    if okF and focus == webui then WebUI.SetFocus(-1) end
end)
