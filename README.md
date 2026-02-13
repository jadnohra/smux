# smux — simple tmux

tmux is powerful but its commands are clunky. smux wraps it with a human-friendly interface.

## Install

### With Homebrew (recommended)

```bash
brew install jadnohra/tap/smux
```

### Without Homebrew

```bash
curl -sSL https://raw.githubusercontent.com/jadnohra/smux/main/install.sh | bash
```

## Usage

```
smux new name              new session with a name
smux new name user@host    new session that SSHs into host
smux ls                    list sessions
smux attach                pick a session to reattach
smux attach name           reattach to a session by name
smux kill                  pick a session to kill
smux kill-all              kill all sessions
```

## Why?

Terminal crashed? SSH dropped? No problem — your sessions are still alive.

```
$ smux ls

  [1] db-prod     —  3 windows  ○ detached  (Feb 13 10:00)
  [2] api-server  —  1 window   ○ detached  (Feb 13 09:30)
  [3] local       —  2 windows  ● attached  (Feb 12 14:00)

$ smux attach db-prod
```

## Requirements

- bash
- tmux

## Quick tmux reference

Once inside a session, everything starts with `Ctrl+B`:

| Keys | Action |
|------|--------|
| `Ctrl+B` then `d` | detach (session keeps running) |
| `Ctrl+B` then `c` | new window |
| `Ctrl+B` then `n` / `p` | next / previous window |
| `Ctrl+B` then `0-9` | jump to window |
| `Ctrl+B` then `%` | split vertically |
| `Ctrl+B` then `"` | split horizontally |
