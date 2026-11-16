--[[
    ============================================================
      CHAT
    ============================================================
      File     : config.lua, every setting is here.
      Author   : Grylix
      Site     : https://grylix.dev
      GitHub   : https://github.com/Gryliix
      Version  : 1.0 (16/11/2026)
      For      : HappinessMP
    ============================================================
]]

ChatConfig = {
    Language = "en",            -- "en" or "fr"
    AccentColor = "#a78bfa",    -- colour of the Global badge and the input border

    -- Where the chat sits on the screen.
    -- Position: "top-left", "top-right", "bottom-left" or "bottom-right".
    -- OffsetX / OffsetY: distance from that corner, in % of the screen.
    Position = "top-left",
    OffsetX = 3,
    OffsetY = 3,
    Width = 380,                -- width in pixels
    Lines = 8,                  -- lines visible at once (scroll to see older ones)
    FadeDelay = 8,              -- seconds before a message fades when the chat is closed (0 = never)

    OpenKeys = { 84, 89 },      -- keys that open the chat (84 = T, 89 = Y)
    MaxLength = 200,            -- max characters per message

    -- Anti-spam: at most Messages messages every Seconds seconds.
    Flood = { Messages = 3, Seconds = 3 },
    BlockRepeat = true,         -- refuses the same message twice in a row

    -- Name colour of each rank.
    Ranks = {
        owner  = "#E24B4A",
        admin  = "#EF9F27",
        mod    = "#5DCAA5",
        player = "#E6E6E6",
    },
    DefaultRank = "player",

    -- Quick way to give a rank, by player name (anyone with this name gets it).
    -- For a real admin system, call Exports.chat:SetPlayerRank(id, "admin") from your own script.
    Staff = {
        -- ["YourName"] = "owner",
    },

    Texts = {
        en = {
            channel = "Global",
            placeholder = "Type your message",
            flood = "Slow down, wait a few seconds.",
            repeated = "You already sent that.",
        },
        fr = {
            channel = "Global",
            placeholder = "Écris ton message",
            flood = "Doucement, attends quelques secondes.",
            repeated = "Tu viens déjà d'envoyer ça.",
        },
    },
}
