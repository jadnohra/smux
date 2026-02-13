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
smux                    list sessions, pick one to reattach
smux new                new local session
smux new myproject      new named session
smux new user@host      new session that SSHs into host
smux kill               pick a session to kill
smux kill-all           kill all sessions
```

## Why?

Terminal crashed? SSH dropped? No problem — your sessions are still alive. Just type `smux` and pick up where you left off.

```
$ smux

  [1] db-prod     —  3 windows  ○ detached  (Feb 13 10:00)
  [2] api-server  —  1 window   ○ detached  (Feb 13 09:30)
  [3] local       —  2 windows  ● attached  (Feb 12 14:00)

Reattach to [1-3]:
```

If there's only one detached session, it reattaches immediately — no questions asked.

SSH sessions auto-name themselves from the hostname:

```
$ smux new root@db-prod.example.com
Connecting to root@db-prod.example.com as session db-prod...
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
