# Claude Specific Setup

## Claude Code Settings Containment

- By default, Claude has access to its `.credentials.json` and `settings.json`
- You can use configuration supplied in the `claude` folder to add some protection
- Copy the contents to `~/.claude` on WSL of your agent
- If you already have `settings.json`, you'll have to merge it with the one provided
- The configuration was designed by Claude, it seems to work, but probably is overengineered
- I expect it won't work well with built-in Claude sandbox (`/sandbox` command), but I didn't try
- For the hooks in the supplied `claude` folder to work, you'll need some perquisites:

```bash
sudo apt update
sudo apt upgrade
sudo apt install bubblewrap jq
```

## Claude Code IDE Integration

- Claude Code IDE Integration needs to be able to add a lock file to the `.claude/ide` folder
- As this folder is somewhat hard to get to (in WSL run by a separate user), there's a need for a workaround
- Create a `.claude_ide\ide` folders in a generally accessible location
- Set `.claude_ide` as the `CLAUDE_CONFIG_DIR` for your user

> [!NOTE]
> As your user
```powershell
mkdir G:\.claude_ide\ide
[System.Environment]::SetEnvironmentVariable('CLAUDE_CONFIG_DIR', 'G:\.claude_ide', 'User')
```

- In `agent` wsl make a soft link `~/.claude/ide` pointing to the ide folder

> [!NOTE]
> As `agent` in WSL
```bash
ln -s /mnt/g/.claude_ide/ide ~/.claude/ide
```

- This way IDE will know where to place the lock file, and the agent will have access to it
