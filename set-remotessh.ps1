#Requires -Version 5.1

<#
.SYNOPSIS
Creates an SSH configuration entry for a remote server, including key generation and public key transfer.

.DESCRIPTION
This script automates the process of setting up an SSH connection to a remote server using RSA keys. It generates a new key pair if one doesn't exist, transfers the public key to the remote server, and creates/updates an entry in the local SSH configuration file.

.PARAMETER RemoteUser
The username on the remote server. This is a mandatory parameter.

.PARAMETER RemoteIP
The IP address or hostname of the remote server. This is a mandatory parameter.

.PARAMETER QuickName
A short name for your SSH config entry.  This will be used as the alias to connect to the server. This is a mandatory parameter.

.EXAMPLE
.\MyModule.psm1 -RemoteUser myuser -RemoteIP 192.168.1.100 -QuickName myserver

Generates an SSH key and configures a connection to 192.168.1.100 as user 'myuser' with the alias 'myserver'.
#>

[CmdletBinding()]
param(

    [Parameter(Mandatory=$true, HelpMessage="The username on the remote server.")]
    [string]$RemoteUser,



    [Parameter(Mandatory=$true, HelpMessage="The IP address or hostname of the remote server.")]
    [string]$RemoteIP,



    [Parameter(Mandatory=$true, HelpMessage="A short name for your SSH config entry.")]
    [string]$QuickName
)

# --- Setup Paths ---
$dotSshPath = Join-Path $HOME ".ssh"

$privateKey = Join-Path $dotSshPath "id_rsa" # Default key name
$publicKey  = "$privateKey.pub"
$configFile = Join-Path $dotSshPath "config"

# 1. Ensure local .ssh directory exists
if (-not (Test-Path $dotSshPath)) {
    New-Item -ItemType Directory -Path $dotSshPath | Out-Null
}

# 2. Generate the Key Pair
if (-not (Test-Path $privateKey)) {

    Write-Host "Generating 4096-bit RSA key: id_rsa..." -ForegroundColor Cyan
    ssh-keygen -t rsa -b 4096 -f $privateKey -N '""' 
} else {

    Write-Host "Key 'id_rsa' already exists. Skipping generation." -ForegroundColor Yellow
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
