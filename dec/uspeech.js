/* Currah μSpeech s$ parser and SP0256-AL2 player.
 * Tables and control flow follow ParseSpeechString ($021F) and
 * ParseAllophoneGroup ($02EB) in the 2K ROM.
 */
(function () {
  "use strict";

  var CHARACTER_KEYS = [
    0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C,
    0x2D, 0x2E, 0x2F, 0x30, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x39, 0x3A,
    0x0C, 0x07, 0x00
  ];
  var MAPPED_CHARACTERS = [
    0x42, 0x5A, 0x44, 0x4E, 0x48, 0x4A, 0x4E, 0x50, 0x52, 0x58, 0x5E, 0x72,
    0x61, 0x53, 0x55, 0x4D, 0x57, 0x5F, 0x4B, 0x5B, 0x5D, 0x62, 0x7B, 0x75,
    0x89, 0x99, 0x80
  ];
  var ALLOPHONE_VALUES = [
    0x18, 0x1C, 0x08, 0x15, 0x07, 0x28, 0x24, 0x1B, 0x0C, 0x0A, 0x2A, 0x2D,
    0x10, 0x0B, 0x17, 0x09, 0x27, 0x37, 0x11, 0x0F, 0x23, 0x2E, 0x31, 0x2B,
    0x04, 0x01, 0x03, 0x14, 0x14, 0x3F, 0x29, 0x21, 0x13, 0x3D, 0x39, 0x06,
    0x3E, 0x35, 0x19, 0x3A, 0x3B, 0x2C, 0x1A, 0x33, 0x30, 0x32, 0x25, 0x1E,
    0x26, 0x35, 0x22, 0x34, 0x1F, 0x12
  ];
  var SUFFIX_KEYS = [0x32, 0x35, 0x34, 0x39, 0x28, 0x2E, 0x21, 0x25, 0x37];
  var SUFFIX_VALUES = [0x0E, 0x16, 0x0D, 0x05, 0x1D, 0x38, 0x3C, 0x2F, 0x20];
  var COMBINED_KEYS = CHARACTER_KEYS.concat(MAPPED_CHARACTERS);
  var NAME_KEYS = CHARACTER_KEYS.slice(0, 0x18);
  var HIGH_RATE = 1.18;

  var audioCtx = null;
  var pcmBuffers = null;
  var playing = [];

  function giName(id) {
    var names = window.USPEECH_PCM && window.USPEECH_PCM.names;
    return names && names[id] ? names[id] : ("#" + id);
  }

  function hexByte(value) {
    return ("0" + (value & 0xFF).toString(16)).slice(-2).toUpperCase();
  }

  function cpir(table, value) {
    var i;
    for (i = 0; i < table.length; i++) {
      if (table[i] === value) {
        return i;
      }
    }
    return -1;
  }

  function normalise(code) {
    if (code >= 0x61) {
      return { value: (code - 0x40) & 0xFF, high: false };
    }
    return { value: (code - 0x20) & 0xFF, high: true };
  }

  function suffixLookup(code) {
    var index = cpir(SUFFIX_KEYS, code);
    if (index < 0) {
      return null;
    }
    return SUFFIX_VALUES[index];
  }

  function parseGroup(text, openAt) {
    var total = 0;
    var i = openAt + 1;
    var high = false;
    var letters = "";
    var folded;
    var result;

    while (i < text.length) {
      if (text.charCodeAt(i) === 0x29) {
        result = closeGroup(text, letters, total, high);
        result.source = text.slice(openAt, i + 1);
        result.next = i + 1;
        return result;
      }
      folded = normalise(text.charCodeAt(i));
      high = folded.high;
      if (cpir(NAME_KEYS, folded.value) < 0) {
        return { error: "Invalid letter in allophone name.", at: i };
      }
      total += folded.value;
      if (total > 255) {
        return { error: "Allophone-name sum overflowed.", at: i };
      }
      letters += text.charAt(i);
      i += 1;
    }
    return { error: "Missing closing parenthesis.", at: openAt };
  }

  function closeGroup(text, letters, total, high) {
    var folded;
    var index;
    var value;
    var letter;

    if (total === 0x64 || total === 0x68 || total === 0x5C || total === 0x66) {
      letter = letters.charAt(letters.length - 1);
      folded = normalise(letter.charCodeAt(0));
      value = suffixLookup(folded.value);
      if (value === null) {
        return { error: "Unknown allophone-name suffix.", at: null };
      }
      return { value: value, high: folded.high };
    }
    if (total === 0x78) {
      if (letters.length < 2) {
        return { error: "Allophone name is too short.", at: null };
      }
      letter = letters.charAt(letters.length - 2);
      folded = normalise(letter.charCodeAt(0));
      value = suffixLookup(folded.value);
      if (value === null) {
        return { error: "Unknown allophone-name suffix.", at: null };
      }
      return { value: value, high: folded.high };
    }
    index = cpir(COMBINED_KEYS, total);
    if (index < 0) {
      return { error: "Unknown allophone name (" + letters + ").", at: null };
    }
    return { value: ALLOPHONE_VALUES[index], high: high };
  }

  function parseSpeechString(text) {
    var tokens = [];
    var i = 0;
    var ch;
    var code;
    var folded;
    var mapped;
    var group;
    var high = false;

    if (!text.length) {
      return { status: "empty", tokens: [], message: "s$ is empty." };
    }
    if (text.charAt(0) === "*" || text.charAt(0) === "?") {
      return {
        status: "skip",
        tokens: [],
        message: "A leading * or ? means this string has already been spoken."
      };
    }

    while (i < text.length) {
      ch = text.charAt(i);
      code = text.charCodeAt(i);
      folded = normalise(code);
      high = folded.high;
      if (folded.value === 0x0E) {
        tokens.push(token(ch, 0x04, high, "pause"));
        i += 1;
        continue;
      }
      if (folded.value === 0x08) {
        group = parseGroup(text, i);
        if (group.error) {
          return fail(tokens, group.error, group.at === null ? i : group.at, text);
        }
        tokens.push(token(group.source, group.value, group.high, "group"));
        i = group.next;
        continue;
      }
      mapped = cpir(CHARACTER_KEYS, folded.value);
      if (mapped < 0) {
        return fail(tokens, "Cannot map " + JSON.stringify(ch) + ".", i, text);
      }
      tokens.push(token(ch, ALLOPHONE_VALUES[mapped], high, "letter"));
      i += 1;
    }
    return {
      status: "ok",
      tokens: tokens,
      message: "Would mark s$ with * after a successful parse.",
      marked: "*" + text.slice(1)
    };
  }

  function token(source, id, high, kind) {
    return {
      source: source,
      id: id,
      high: high,
      kind: kind,
      name: giName(id),
      queued: id | (high ? 0x40 : 0)
    };
  }

  function markQuery(text, at) {
    var chars = text.split("");
    var markAt = at;
    if (!chars.length) {
      return text;
    }
    chars[0] = "?";
    if (at + 1 < chars.length) {
      markAt = at + 1;
    }
    chars[markAt] = "?";
    return chars.join("");
  }

  function fail(tokens, message, at, text) {
    return {
      status: "error",
      tokens: tokens,
      message: message,
      at: at,
      marked: markQuery(text, at)
    };
  }

  function decodeBase64(text) {
    var raw = atob(text);
    var out = new Uint8Array(raw.length);
    var i;
    for (i = 0; i < raw.length; i++) {
      out[i] = raw.charCodeAt(i);
    }
    return out;
  }

  function pcmToBuffer(ctx, bytes, rate) {
    var buffer = ctx.createBuffer(1, bytes.length, rate);
    var data = buffer.getChannelData(0);
    var i;
    for (i = 0; i < bytes.length; i++) {
      data[i] = (bytes[i] - 128) / 128;
    }
    return buffer;
  }

  function ensureAudio() {
    var spec = window.USPEECH_PCM;
    var ctx;
    var packed;
    var offset;
    var i;
    if (!spec) {
      throw new Error("Allophone samples are not loaded.");
    }
    if (!audioCtx) {
      audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    }
    if (audioCtx.state === "suspended") {
      audioCtx.resume();
    }
    if (!pcmBuffers) {
      packed = decodeBase64(spec.data);
      pcmBuffers = [];
      offset = 0;
      for (i = 0; i < spec.lengths.length; i++) {
        pcmBuffers.push(
          pcmToBuffer(
            audioCtx,
            packed.subarray(offset, offset + spec.lengths[i]),
            spec.rate
          )
        );
        offset += spec.lengths[i];
      }
    }
    return audioCtx;
  }

  function stopSpeech() {
    playing.forEach(function (source) {
      try {
        source.stop();
      } catch (ignore) {}
    });
    playing = [];
  }

  function playTokens(tokens) {
    var ctx = ensureAudio();
    var t = ctx.currentTime;
    stopSpeech();
    tokens.forEach(function (item) {
      var source = ctx.createBufferSource();
      var rate = item.high ? HIGH_RATE : 1;
      source.buffer = pcmBuffers[item.id];
      source.playbackRate.value = rate;
      source.connect(ctx.destination);
      source.start(t);
      playing.push(source);
      t += source.buffer.duration / rate;
    });
  }

  function renderTokens(result) {
    var box = document.getElementById("uspeech-tokens");
    box.innerHTML = "";
    result.tokens.forEach(function (item, index) {
      var chip = document.createElement("button");
      chip.type = "button";
      chip.className = "uspeech-token" + (item.high ? " high" : "");
      chip.textContent = item.source + " → " + item.name +
        " $" + hexByte(item.queued);
      chip.title = "Play this allophone";
      chip.addEventListener("click", function () {
        playTokens([result.tokens[index]]);
      });
      box.appendChild(chip);
    });
  }

  function setStatus(result) {
    var status = document.getElementById("uspeech-status");
    var mark = document.getElementById("uspeech-marked");
    status.className = "uspeech-status " + result.status;
    status.textContent = result.message;
    if (result.marked) {
      mark.hidden = false;
      mark.textContent = "PRINT s$ would show " + JSON.stringify(result.marked);
    } else {
      mark.hidden = true;
      mark.textContent = "";
    }
  }

  function currentText() {
    return document.getElementById("uspeech-input").value;
  }

  function preview() {
    var result = parseSpeechString(currentText());
    renderTokens(result);
    setStatus(result);
    return result;
  }

  function speak() {
    var result = preview();
    if (result.tokens.length) {
      playTokens(result.tokens);
    }
  }

  function insertExample(text) {
    var field = document.getElementById("uspeech-input");
    field.value = text;
    field.focus();
    preview();
  }

  function bind() {
    var field = document.getElementById("uspeech-input");
    if (!field) {
      return;
    }
    document.getElementById("uspeech-speak").addEventListener("click", speak);
    document.getElementById("uspeech-stop").addEventListener("click", stopSpeech);
    field.addEventListener("input", preview);
    field.addEventListener("keydown", function (event) {
      if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) {
        event.preventDefault();
        speak();
      }
    });
    Array.prototype.forEach.call(
      document.querySelectorAll("[data-uspeech]"),
      function (button) {
        button.addEventListener("click", function () {
          insertExample(button.getAttribute("data-uspeech"));
          speak();
        });
      }
    );
    preview();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", bind);
  } else {
    bind();
  }

  window.USPEECH = {
    parse: parseSpeechString,
    play: playTokens,
    stop: stopSpeech
  };
}());
