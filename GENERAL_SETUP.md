# Secure LLM Environment General Setup

## Dedicated Windows User

- Create user for the agent, I'll use user `agent`

> [!NOTE]
> As Administrator
```powershell
net user agent * /add
```

- Run powershell as `agent`, to initialize home directory

> [!NOTE]
> As your user
```powershell
runas /user:agent /savecred powershell
```

- You can use `runas /user:agent /savecred <cmd>` to run applications (e.g. llm desktop app or cli) as the dedicated user
- The agent won't have access to your home directory
- The agent won't have administrative privileges
- You can stop here, or you can keep going

## Limited Filesystem Access

- Create a local group for blocking filesystem access
- Add `agent` user to the local group

> [!NOTE]
> As Administrator
```powershell
net localgroup LLMs /add
net localgroup LLMs agent /add
```

- Deny filesystem access on drive/folder basis

> [!NOTE]
> As Administrator
```powershell
function Deny-LLMs {
    param (
        [string]$Path
    )

    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("$env:COMPUTERNAME\LLMs", "FullControl", "ContainerInherit, ObjectInherit", "None", "Deny")

    $acl = Get-Acl $Path
    $acl.SetAccessRule($rule)
    Set-Acl $Path $acl
}

Deny-LLMs D:\
Deny-LLMs G:\NoAIProjects
```

- You have now more granular control of filesystem paths `agent` has access to
- You can stop here, or you can keep going

## SSH Server

- Add OpenSSH server (will take some time)
- Configure for automatic startup

> [!NOTE]
> As Administrator
```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Set-Service -Name sshd -StartupType Automatic
```

- Configure for localhost connection to the agent account
- Configure for ssh key authentication

> [!NOTE]
> As Administrator
```powershell
Edit C:\ProgramData\ssh\sshd_config
```

sshd_config:
```
ListenAddress 127.0.0.1
AllowUsers agent
PasswordAuthentication no
```

- Run the server

> [!NOTE]
> As Administrator
```powershell
Start-Service sshd
```

## SSH Default Shell

- Set ssh default shell to `powershell`

> [!NOTE]
> As Administrator
```powershell
New-ItemProperty @{
    Path         = "HKLM:\SOFTWARE\OpenSSH"
    Name         = "DefaultShell"
    Value        = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    PropertyType = "String"
    Force        = $true
}
```

## SSH Connection

- Configure ssh-agent for automatic startup and run

> [!NOTE]
> As Administrator
```powershell
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service ssh-agent
```

- Generate ssh key pair
- Add ssh key to ssh-agent
- Copy public key to shared location

> [!NOTE]
> As your user
```powershell
ssh-keygen -f $env:USERPROFILE\.ssh\agent_ed25519
ssh-add $env:USERPROFILE\.ssh\agent_ed25519
copy $env:USERPROFILE\.ssh\agent_ed25519.pub G:\
```

- Add ssh key to `authorized_keys` on `agent` account

> [!NOTE]
> As `agent` user (`runas /user:agent /savecred powershell`)
```powershell
mkdir $env:USERPROFILE\.ssh
Get-Content G:\\agent_ed25519.pub | Out-File -Encoding ascii $env:USERPROFILE\.ssh\authorized_keys
```

- Test ssh connection

> [!NOTE]
> As your user
```powershell
ssh agent@localhost
```

- You can now run commandline applications as `agent` in a separate login session

> [!NOTE]
> As your user
```powershell
ssh -t agent@localhost -- <cmd>
```

- `-t` forces pseudo-terminal allocation, to make sure the environment is set up, e.g. `$env:PATH` is loaded
- You can stop here, or you can keep going

## WSL Setup

- Install on main account, and init with `agent` user
- Export to `agent` accessible location

> [!NOTE]
> As your user
```powershell
wsl --install Ubuntu-24.04 --name Ubuntu-agent
wsl --export Ubuntu-agent G:\Ubuntu-agent
wsl --unregister Ubuntu-agent
```

- Import on claude account

> [!NOTE]
> As `agent` user (`ssh agent@localhost`)
```powershell
wsl --import Ubuntu $env:USERPROFILE\wsl G:\Ubuntu-agent
rm G:\Ubuntu-agent
```

- Configure mirrored networking for easy MCP servers connection

> [!NOTE]
> As `agent` user (`ssh agent@localhost`)
```powershell
edit $env:USERPROFILE\.wslconfig
```

.wslconfig:
```
[wsl2]
networkingMode=mirrored
```

- You can now run commandline applications as `agent` in a WSL2 instance run in a separate login session
- This command is suitable for running in e.g. Claude Code IDE integration (just use `claude` as the `<cmd>`)

> [!NOTE]
> As your user
```powershell
ssh -t agent@localhost -- wsl --shell-type=login --cd=$Pwd.Path -- <cmd>
```

- `--shell-type=login` makes sure the environment is set up, e.g. `.bashrc` is loaded
- `--cd=$Pwd.Path` makes sure you'll end up in the current directory, otherwise `ssh` starts you in `agent` home directory

- For easier access to additional terminal windows you can add `screen` to the mix:

> [!NOTE]
> As your user
```powershell
ssh -t agent@localhost -- wsl --shell-type=login --cd=$Pwd.Path -- screen <cmd>
```

- You can stop here, or you can keep going
