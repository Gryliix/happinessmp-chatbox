--[[
    ============================================================
      CHAT
    ============================================================
      File     : config.lua, every setting is here.
      Author   : Grylix
      Site     : https://grylix.dev
      GitHub   : https://github.com/Gryliix
      Version  : 1.1 (26/11/2026)
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

    -- Quick way to give a rank. Anyone can pick any name, so the IP must match too.
    -- An entry without an ip is ignored. If your IP changes often, or for a real admin system,
    -- call Exports.chat:SetPlayerRank(id, "admin") from your own script.
    Staff = {
        -- ["YourName"] = { rank = "owner", ip = "203.0.113.10" },
    },

    -- Private messages: "/mp name message" (a player ID works too), "/r message" answers.
    PrivateCommands = { "mp", "pm" }, -- {} = private messages off
    ReplyCommand = "r",
    PrivateColor = "#f472b6",

    -- A message when a player joins or leaves.
    JoinLeave = true,

    Texts = {
        en = {
            channel = "Global",
            placeholder = "Type your message",
            flood = "Slow down, wait a few seconds.",
            repeated = "You already sent that.",
            pm_usage = "Use: /mp name message",
            pm_notfound = "Player not found.",
            pm_self = "You cannot message yourself.",
            pm_noreply = "Nobody to answer.",
            pm_from = "From",
            pm_to = "To",
            joined = "joined the server",
            left_timeout = "lost connection",
            left_quit = "left the server",
            left_kick = "was kicked",
        },
        fr = {
            channel = "Global",
            placeholder = "Écris ton message",
            flood = "Doucement, attends quelques secondes.",
            repeated = "Tu viens déjà d'envoyer ça.",
            pm_usage = "Écris : /mp pseudo message",
            pm_notfound = "Joueur introuvable.",
            pm_self = "Tu ne peux pas t'écrire à toi-même.",
            pm_noreply = "Personne à qui répondre.",
            pm_from = "De",
            pm_to = "À",
            joined = "a rejoint le serveur",
            left_timeout = "a perdu la connexion",
            left_quit = "a quitté le serveur",
            left_kick = "a été expulsé",
        },
    },
}
