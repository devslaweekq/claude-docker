# Changelog

## [1.2.12] - 2026-06-22

### Fixed

### Cyrillic (non-ASCII) text copy from terminal
Copying Russian or any non-ASCII text from the cladock terminal produced garbled
characters (`ÑÐµÐ¿ÐµÑÑ` instead of `теперь`) while English copied correctly.
Native `claude` was not affected.

Root cause: `menu.sh` used `\033c` (RIS — Reset to Initial State) to clear the
screen between menu transitions. RIS is a full terminal reset that reverts the
character-set tables in some terminals (notably xterm and derivatives). After the
reset the terminal fell back to Latin-1 mode for clipboard operations, so copying
multi-byte UTF-8 sequences stored the raw bytes in the clipboard which the paste
target then decoded as Latin-1.

Fix: replaced `\033c` with `\033[3J\033[2J\033[H` — clears the visible screen
and the scrollback buffer without touching character-set or encoding state, so the
terminal stays in UTF-8 mode throughout the entire session.
