@(set "0=%~f0"^)#) & set "1=%*" & setlocal enabledelayedexpansion & powershell -nop -noe -c "$scr=([io.file]::ReadAllText($env:0, [Text.Encoding]::GetEncoding('Shift-JIS'))-split'\n',2)[1];iex('&{'+$scr+'}'+$env:1);$Host.SetShouldExit($LastExitCode);Exit($LastExitCode)" & exit /b !errorlevel!
[CmdletBinding(DefaultParameterSetName = "PrvKeyPath")]
    param(
        [Parameter(Position=0, ParameterSetName="", Mandatory)]
        [string] $LoginInfo,
        [Parameter(Position=1, ParameterSetName="PrvKeyPath")]
        [Parameter(Position=1, ParameterSetName="GeneratePrvKey")]
        [string] $PrvKeyPath,
        [Parameter(ParameterSetName="GeneratePrvKey")]
        [switch] $GeneratePrvKey
    ) [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))

    # InputPath Check
    if (!$PrvKeyPath) {
        $PrvKeyPath = @(
            "$env:USERPROFILE\.ssh\id_rsa",
            "$env:USERPROFILE\.ssh\id_dsa",
            "$env:USERPROFILE\.ssh\id_ecdsa",
            "$env:USERPROFILE\.ssh\id_ed25519"
        ) |Where-Object { Test-Path -PathType:Leaf $_ } |Select-Object -First 1
    }; if (!$PrvKeyPath) { $PrvKeyPath = "$env:USERPROFILE\.ssh\id_ed25519" }
    $PrvKeyPath = [IO.Path]::GetFullPath($PrvKeyPath)

    # Generating public/private ed25519 key pair
    if ($GeneratePrvKey) { ssh-keygen -t ed25519 -f $PrvKeyPath }
    
    # Check PrvKeyPath
    if (!(Test-Path -PathType:Leaf $PrvKeyPath)) { Write-Error "Error:: Path `"$PrvKeyPath`" does not exist" -ErrorAction:Stop }

    # Get the public key file generated previously on your client
    $authorizedKey = ssh-keygen -y -f $PrvKeyPath 2>&1
    if (!$? -and $authorizedKey -match "Permissions for .* are too open.") {
        icacls $PrvKeyPath /inheritance:r /remove *S-1-1-0 /grant *S-1-5-32-544:F /grant *S-1-5-18:F /grant "$($env:USERNAME):M" |Out-Null
        $authorizedKey = ssh-keygen -y -f $PrvKeyPath 2>&1
    } if (!$?) {
        Write-Host $authorizedKey -ForegroundColor Red
        Write-Error "Error:: Failed to retrieve the authorizedKey."
    }

    # Connect to your server and copy the client's public key to the server's authorized_keys.
    ssh -i "$PrvKeyPath" -o BatchMode=yes $LoginInfo "echo True" 2>&1 |Out-Null
    if (!$?) {
        Write-Host "PubKey: $authorizedKey" -ForegroundColor DarkGray
        Write-Host "From '$PrvKeyPath', preparing to uploaad the public key to the server" -ForegroundColor Yellow
        ssh $LoginInfo "(if not exist .ssh mkdir .ssh)&&(echo $authorizedKey>>.ssh\authorized_keys)"
    }

    # Test Connect
    $msg = ssh -i "$PrvKeyPath" -o BatchMode=yes $LoginInfo "echo SSH key authentication is now activated on '$LoginInfo'." 2>&1
    if ($?) { Write-Host $msg -ForegroundColor Green } else { Write-Host $msg -ForegroundColor Red }
