[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="The name for your new SSH key pair.")]
    [string]$KeyName,

    [Parameter(Mandatory=$true, HelpMessage="The username on the remote server.")]
    [string]$RemoteUser,

    [Parameter(Mandatory=$true, HelpMessage="The IP address or hostname of the remote server.")]
    [string]$RemoteIP,

    [Parameter(Mandatory=$true, HelpMessage="A short name for your SSH config entry.")]
    [string]$QuickName
)

# --- Setup Paths ---
$dotSshPath = Join-Path $HOME ".ssh"
$privateKey = Join-Path $dotSshPath $KeyName
$publicKey  = "$privateKey.pub"
$configFile = Join-Path $dotSshPath "config"

# 1. Ensure local .ssh directory exists
if (-not (Test-Path $dotSshPath)) {
    New-Item -ItemType Directory -Path $dotSshPath | Out-Null
}

# 2. Generate the Key Pair
if (-not (Test-Path $privateKey)) {
    Write-Host "Generating 4096-bit RSA key: $KeyName..." -ForegroundColor Cyan
    ssh-keygen -t rsa -b 4096 -f $privateKey -N '""' 
} else {
    Write-Host "Key '$KeyName' already exists. Skipping generation." -ForegroundColor Yellow
}

# 3. Transfer Public Key to Remote Server
Write-Host "Transferring public key to $RemoteIP..." -ForegroundColor Cyan
$pubKeyContent = Get-Content $publicKey -Raw
$remoteCommand = "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$pubKeyContent' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# This will prompt for your remote password
ssh "${RemoteUser}@${RemoteIP}" $remoteCommand

# 4. Create/Update SSH Config Entry
# Note: ssh-config requires forward slashes for paths even on Windows
$configEntry = @"

Host $QuickName
    HostName $RemoteIP
    User $RemoteUser
    IdentityFile $($privateKey -replace '\\', '/')
"@

Write-Host "Adding entry to $configFile..." -ForegroundColor Cyan
Add-Content -Path $configFile -Value $configEntry

Write-Host "Setup complete! Connect with: ssh $QuickName" -ForegroundColor Green
