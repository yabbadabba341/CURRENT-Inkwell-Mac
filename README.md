INGENIUM  |  Copyright (c) 2026 Yannie D. Forest. All rights reserved.
NO LICENCE IS GRANTED. No copying, adaptation, redistribution, reverse
engineering or commercial use without the author's written permission.
See LICENCE.txt. Every distributed copy carries a build marker.
--------------------------------------------------------------------------

# Ingenium for macOS — standalone app

Two ways in. The first needs nothing at all.

---

## 1. Just open it

Double-click **ingenium.html**.

That single file is the entire application, and it carries its engine inside
it. It opens in your browser and runs your GGUF models completely offline: no
account, no connection, nothing uploaded, nothing installed. Go to the Models
page, add a .gguf file, and press Load. If you never do anything else in this
folder, you still have the whole of Ingenium. (See ENGINE.txt for what was
fixed in the engine.)

## 2. Build it as a proper Mac app

This gives you **Ingenium.app**: its own window, its own Dock icon in the
Ingenium's amethyst seal, no browser around it. You build it once on a Mac that
has Python 3; the finished app then runs on any Mac with nothing installed.

The app carries its **own engine** (llama.cpp, compiled on your Mac for your
Mac's processor) and two **built-in models** (LFM2.5 1.2B Instruct, quick,
and Qwen3.5 2B, which thinks before it answers), so it is useful the moment it
opens. More models install from the Models page with one click, and a model
in another form (safetensors, PyTorch, MLX) converts to GGUF there too. The native engine runs models many times faster than the
engine inside the page, and it opens model files of any size. On an Intel Mac
it uses the processor only (its graphics chip is not used).

1. Nothing to install first: the script checks for Apple's free command line
   tools, which bring Python 3 and the compiler, and if they are missing,
   macOS offers to install them (then run the script again). A Python from
   <https://www.python.org/downloads/> works too.
2. Double-click **Build Mac App.command**.
3. Watch the window: every step prints as it works — checking Python,
   downloading the tools once, compiling the engine once (about 5 to 15
   minutes; it needs Apple's free command line tools, and if they are
   missing the script asks macOS to install them), downloading the built-in
   models once (about 2 GB together), assembling the app, and testing that the
   app's engine answers and that the second model thinks. Nothing sits silently; a line always tells you what is
   happening.
4. When it finishes, **Ingenium.app is on your Desktop** (and a copy beside
   the script). Drag it to Applications if you like, or leave it. It opens
   by double-clicking on this Mac with no security prompt.

The build does its real work on the Mac's own disk (a folder in
`~/Library/Caches/IngeniumBuild`), so it is just as fast run from a USB
stick as from the Desktop, and the tools are cached there: run it again and
the downloads are skipped entirely. The build draws the app's seal itself
(`make_ingenium_icon.py`, plain Python) and assembles the icon with macOS's
own `iconutil`, so the dock icon is always in step with the app file.

### If double-clicking the builder is refused

Two different messages, two different one-minute fixes:

* **"could not be executed because you do not have appropriate access
  privileges"** — the trip to this Mac stripped the script's run permission.
  Open Terminal, type `cd` then a space, drag this folder onto the window,
  press Return, then run:
  `chmod +x "Build Mac App.command"`
  and double-click it again. (The download now carries the permission, so
  this should not happen from a fresh unzip.)
* **"Apple could not verify…"** — Gatekeeper asking for proof it cannot
  have. **MACOS_IF_BLOCKED.txt** has the three routes through.

### If the build does not finish

The script writes everything it did to **build_log.txt** in this folder and
shows you the last fifteen lines. Send that file and the cause can be
identified exactly rather than guessed at.

The build keeps its tools in `~/Library/Caches/IngeniumBuild` (a hidden
`.buildenv` there), so it cannot collide with any Python setup you already
have and so the downloads are reused next time. To reclaim that space, delete
the `IngeniumBuild` folder from `~/Library/Caches`. You can also delete this
folder's `ingenium.iconset` and `build_log.txt`; keep the icon files.

### The first time you open the app

macOS may say the app cannot be checked for malicious software. That is
Gatekeeper, and it appears for any app that has not been through Apple's paid
notarisation service. It is not a sign that anything is wrong.

Right-click **Ingenium.app**, choose **Open**, then **Open** again. You
only do this once. **MACOS_IF_BLOCKED.txt** describes the other two routes.

### Adding models in the Mac app

On the Models page, click the box that says **Drop a model file here, or
click to choose**. The Mac's own file window opens. Choose one or more
`.gguf` files. Ingenium links each file where it already is. Nothing is
copied, so even a large file is ready at once, and removing a model from
Ingenium never deletes the file itself. Leave the file where it is, because
the app reads it from there. A file dragged onto the box is copied into
Ingenium's own folder instead.

If Ollama is installed on the Mac, the same page also offers the models that
Ollama has already downloaded, linked in the same way.

**Speed-up files (Apple silicon).** On a Mac with Apple silicon, the Models
page offers **Add speed-up** for Velox (LFM2.5 1.2B Instruct) and the LFM2.5
2.6B house: their maker's small draft model (Liquid AI's DSpark, about 170 to
190 MB, checked against its SHA-256). With it the engine guesses a few words
ahead and checks them in one step on the graphics chip. In two cloud builds
of 8 October 2026, on GitHub's Apple silicon Mac, Velox wrote the same coding
answer about 37% and then about 30% faster with it (20.5 against 14.6 and
14.9 tokens a second without it; then 18.0 against 13.9 and 12.7), and the
reply was the same. The test measures without the file before and after it,
so a machine that warms up does not flatter the file.
Two earlier builds, which ran the file second, measured 46% and 66%. On an
Intel Mac, which runs models on the processor, it made replies about a third
slower, so it is not offered there. If the engine cannot use the file, it loads the model without
it. GitHub's machines are virtual, so a real Mac mini may differ.

**Train a small model from zero (R78).** The Models page has a guided lesson
that makes a tiny model of your own, with random numbers at first, and trains
it on text you give it, on this Mac, with llama.cpp's trainer (compiled from
the same llama.cpp release as the engine; it runs on the processor). Minutes
of training teach a tiny model the common words and punctuation of your
text, then short phrases; it does not hold a conversation. The models you
chat with were trained on vastly more text and computing.

Models run in the app's own engine (llama.cpp, built for this Mac), which
has no limit on the file's size: the limit is your Mac's memory. As a rough
guide (an estimate, not a measurement on your Mac), a model needs about its
file size in memory plus a little more for its Memory setting, so on a Mac with
16 GB a model file of up to about 8 to 10 GB is a sensible ceiling. The Models
page shows whether each model is likely to fit. If the engine is ever missing,
the app falls back to the slower engine inside the page (see ENGINE.txt).

## Your models on every device

A Mac mini (or any Mac running Ingenium) can lend its stronger models to your
other devices on the same Wi-Fi: a MacBook, a Windows laptop, a Fire tablet,
an iPhone or an iPad. The laptop or phone then uses, say, Qwen3.5 9B from
another room, and the replies come from the Mac mini's graphics chip.

1. On the Mac mini: Settings, **Your models on every device**, switch on
   **Share this computer's models**. It shows an address (such as
   `Mac-mini.local:17860`, and a number address beside it) and a pairing code.
2. On the other device: the same card, **Use another computer's models**.
   Enter the address and the code, and press Connect. The chat then uses the
   Mac mini's models; the source row under the chat switches back to the
   device's own.

Things to know:

* Keep Ingenium open on the Mac mini. While sharing is on, the Mac does not
  go to sleep by itself (the screen can still turn off).
* If macOS asks whether Ingenium may accept incoming network connections, or
  may find devices on your local network, choose Allow.
* One model runs at a time on the Mac mini. A device that asks for another
  model loads that one, and the Mac mini's own chat loads its model again
  when it is next used.
* Nothing leaves your home network, and only devices with the pairing code
  are answered. After eight wrong codes in ten minutes, that device waits ten
  minutes. **Make a new pairing code** shuts out every device that had the
  old one.
* If the name does not work on a device, use the number address. Your router
  may change that number now and then; giving the Mac mini a fixed address in
  the router's settings stops that.

## 3. Or let GitHub build it

The repository builds two Mac apps by itself whenever its files change, one
after the other: one for Intel Macs and one for Macs with Apple silicon (such
as a Mac mini), whose engine runs the models on the graphics chip (Metal):
`.github/workflows/build-mac.yml`. It compiles the engine (only
the first time; it is then kept in GitHub's build cache), adds the built-in
models, assembles the app, and **tests it**: the app's own engine must answer
"What is the capital of France?" before anything is published. The finished
apps appear on the repository's **Releases** page as `Ingenium-Mac-Intel.zip`
and `Ingenium-Mac-Apple-Silicon.zip`: the app alone, about 30 MB, which
downloads its two models the first time it opens (about 2 GB, once, with a
progress bar; a broken download carries on where it stopped). Each also has a
`-with-models` copy that holds everything in one 2 GB file, for a Mac without
internet. Before publishing, the build also checks the oldest macOS that each
program file inside the app needs, and it fails if any needs more than the
13.3 the release promises.

Two things to know:

* The cloud-built app needs **macOS 13.3 or newer**. On an older macOS, use
  "Build Mac App.command", which compiles the engine for your own Mac.
* This repository is private, and GitHub counts every minute on a Mac **ten
  times** against the free monthly allowance (2,000 minutes on a free
  account, at the time of writing; please check GitHub's current figures). A
  build takes roughly 5 minutes once the engine is cached, so about 50 to 60
  allowance minutes; the first build compiles the engine and took about 14
  minutes (about 140 allowance minutes).

---

## What is in this folder

| File | What it is |
| --- | --- |
| `ingenium.html` | The entire application. One file. |
| `Build Mac App.command` | Builds the standalone `.app`. Needs Python 3. |
| `app.json` | Who the app is: its name, its id and its data folder. |
| `desktop_model.json` | The built-in model: where it comes from and its checksum. |
| `tools/` | The build steps: the engine, the model, finishing the app, publishing. |
| `.github/workflows/build-mac.yml` | The cloud build (section 3). |
| `licences/`, `THIRD_PARTY_NOTICES.txt` | The licences of the engine, the model and the parts the app carries. |
| `MACOS_IF_BLOCKED.txt` | What to do when Gatekeeper stops something. |
| `ingenium_app.py` | The window the app runs in. Not run directly. |
| `ingenium.spec` | The build recipe. Not run directly. |
| `make_ingenium_icon.py` | Draws the Ingenium seal as the app icon. Plain Python. |
| `ingenium.icns`, `ingenium.png` | Ingenium seal, drawn by the step above. |

The app makes no connection by itself. It connects only when you turn a
connection on in Settings (Ollama on another computer, or a cloud provider
such as Claude). You can confirm it: open `ingenium.html`, open your browser's
network tab, reload, and watch nothing be requested. The build step is
different: it downloads its tools, the engine's source and the built-in model
once, then keeps them.

## If the app will not open, or closes at once

**You never need it.** `ingenium.html` in this folder is the whole app.
Double-click it and it runs offline, with nothing installed. The build is a
convenience only.

The things that can ever make a built app fail now speak up in a dialog and
carry on where they can:

* **No window can be drawn**, usually a Python built without the frameworks
  pywebview needs. Ingenium opens the same page in your browser instead
  and says so.
* **Anything else** writes `ingenium_crash.log` beside the app and tells
  you where it is.

## If the build script stops early

It names the cause rather than pointing at a log: a Python too new for
PyInstaller, no connection, or a certificate check on a workplace network. For
the first of those, install Python 3.12 or 3.13 alongside what you have. You
can also build with no connection at all by running, on any connected Mac,
`python3 -m pip download pyinstaller pywebview cmake setuptools wheel -d wheels` and copying the
resulting `wheels` folder next to the script.

## Moving the app

The portable Mac app is Ingenium.app from Build. It is one self-contained
bundle that carries the whole app inside, so it opens from anywhere you move
it on this Mac. The build now clears its own download quarantine, so on this
Mac it opens by double-clicking. On another Mac the first open uses
right-click then Open, because the app is not notarised by Apple. That prompt
is a security check, not a missing file. You can also skip the app and open
ingenium.html on its own, which is the whole app, offline, and needs no
folder.
