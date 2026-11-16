/*
    ============================================================
      CHAT
    ============================================================
      Shows the messages, the input bar and the history,
      then sends what the player writes back to the game.

      File     : UI/chat.js
      Author   : Grylix
      Site     : https://grylix.dev
      GitHub   : https://github.com/Gryliix
      Version  : 1.0 (16/11/2026)
      For      : HappinessMP
    ============================================================
*/

var chat = document.getElementById("chat");
var feed = document.getElementById("feed");
var bar = document.getElementById("bar");
var input = document.getElementById("input");
var channelEl = document.getElementById("channel");

var channelText = "Global";
var fadeMs = 8000;
var open = false;
var openedAt = 0;
var typed = [];
var typedIndex = 0;
var MAX_LINES_KEPT = 100;
var MAX_HISTORY = 20;

function applyConfig(cfg) {
    var root = document.documentElement.style;
    root.setProperty("--accent", cfg.accent);
    root.setProperty("--lines", cfg.lines);

    chat.style.top = chat.style.bottom = chat.style.left = chat.style.right = "auto";
    chat.style[cfg.position.indexOf("top") === 0 ? "top" : "bottom"] = cfg.offsetY + "%";
    chat.style[cfg.position.indexOf("left") > 0 ? "left" : "right"] = cfg.offsetX + "%";
    chat.style.width = cfg.width + "px";

    channelText = cfg.channel;
    channelEl.textContent = cfg.channel;
    input.placeholder = cfg.placeholder;
    input.maxLength = cfg.maxLength;
    fadeMs = cfg.fade * 1000;
}

function scrollDown() {
    feed.scrollTop = feed.scrollHeight;
}

// Text with {RRGGBB} colour codes, built with textContent so nothing can inject HTML.
function addColoured(parent, text, baseColor) {
    var parts = text.split(/\{([0-9A-Fa-f]{6})\}/);
    var color = baseColor;
    for (var i = 0; i < parts.length; i++) {
        if (i % 2 === 1) {
            color = "#" + parts[i];
        } else if (parts[i] !== "") {
            var span = document.createElement("span");
            span.style.color = color;
            span.textContent = parts[i];
            parent.appendChild(span);
        }
    }
}

function addLine(kind, a, b, c) {
    var li = document.createElement("li");
    li.dataset.t = Date.now();

    if (kind === "player") {
        var badge = document.createElement("span");
        badge.className = "badge";
        badge.textContent = channelText;
        var name = document.createElement("span");
        name.className = "name";
        name.style.color = b;
        name.textContent = a + ": ";
        li.appendChild(badge);
        li.appendChild(name);
        addColoured(li, c, "#eeeeee");
    } else if (kind === "notice") {
        li.className = "notice";
        li.textContent = a;
    } else {
        addColoured(li, a, "#eeeeee");
    }

    feed.appendChild(li);
    while (feed.children.length > MAX_LINES_KEPT) feed.removeChild(feed.firstChild);
    scrollDown();
}

function showInput() {
    open = true;
    openedAt = Date.now();
    chat.classList.add("open");
    bar.classList.remove("hidden");
    input.value = "";
    typedIndex = typed.length;
    input.focus();
    scrollDown();
}

function hideInput() {
    open = false;
    chat.classList.remove("open");
    bar.classList.add("hidden");
    input.blur();
    scrollDown();
}

// The key that opened the chat can leak into the box as a letter: drop it.
input.addEventListener("input", function () {
    if (Date.now() - openedAt < 150) input.value = "";
});

input.addEventListener("keydown", function (e) {
    if (e.key === "Enter") {
        e.preventDefault();
        var text = input.value.trim();
        if (text) {
            typed.push(text);
            if (typed.length > MAX_HISTORY) typed.shift();
        }
        Events.Call("chatbox:submit", [text]);
    } else if (e.key === "Escape") {
        e.preventDefault();
        Events.Call("chatbox:cancel", []);
    } else if (e.key === "ArrowUp") {
        e.preventDefault();
        if (typed.length > 0) {
            typedIndex = Math.max(0, typedIndex - 1);
            input.value = typed[typedIndex];
        }
    } else if (e.key === "ArrowDown") {
        e.preventDefault();
        if (typedIndex < typed.length) typedIndex++;
        input.value = typedIndex < typed.length ? typed[typedIndex] : "";
    }
});

// Old messages fade out while the chat is closed.
setInterval(function () {
    if (fadeMs <= 0) return;
    var now = Date.now();
    for (var i = 0; i < feed.children.length; i++) {
        var li = feed.children[i];
        li.classList.toggle("old", now - li.dataset.t > fadeMs);
    }
}, 500);

Events.Subscribe("chatbox:config", function (json) {
    applyConfig(JSON.parse(json));
});
Events.Subscribe("chatbox:add", addLine);
Events.Subscribe("chatbox:showInput", showInput);
Events.Subscribe("chatbox:hideInput", hideInput);
Events.Subscribe("chatbox:setHidden", function (hidden) {
    chat.classList.toggle("hidden-all", hidden);
});

// The page is ready: the game can send the config.
Events.Call("chatbox:ready", []);
