# 上傳公鑰
function Add-SSHKeyToServer {
    [CmdletBinding(DefaultParameterSetName = "PubKeyPath")]
    param (
        [Parameter(Position=0, ParameterSetName="", Mandatory)]
        [string] $User,
        [Parameter(Position=1, ParameterSetName="", Mandatory)]
        [string] $HostName,
        [Parameter(Position=2, ParameterSetName="PubKeyPath")]
        [string] $PubKeyPath,
        [Parameter(ParameterSetName="PubKeyContent")]
        [string] $PubKeyContent
    )
    
    # 新增金鑰
    if (!$PubKeyPath -and !$PubKeyContent) {
        $prvKey = "$env:USERPROFILE\.ssh\id_ed25519"
        if (!(Test-Path $prvKey -PathType Leaf)) { ssh-keygen -t ed25519 -f $prvKey }
        $PubKeyPath = "$prvKey.pub"
    }
    
    # 處理路徑
    if ($PubKeyPath) {
        [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
        $PubKeyPath = [IO.Path]::GetFullPath($PubKeyPath)
        if (!(Test-Path -PathType:Leaf $PubKeyPath)) { Write-Error "Error:: Path `"$PubKeyPath`" does not exist" -ErrorAction:Stop }
        $PubKeyContent = Get-Content $PubKeyPath
    }
    
    # 上傳公鑰
    if ($PubKeyContent) {
        # 檢索用字串
        $SearchContent = ($PubKeyContent -split " ")[1]
        if ($SearchContent.Length -ge 254) { $SearchContent = (($SearchContent)).Substring($SearchContent.Length - 254) }
        $SearchContent = [regex]::Escape($SearchContent)
        
        # 上傳公鑰
        ssh $User@$HostName "whoami /groups | findstr /C:S-1-5-32-544 >nul && ((findstr """$SearchContent""" C:\ProgramData\ssh\administrators_authorized_keys >nul || (echo $PubKeyContent>>C:\ProgramData\ssh\administrators_authorized_keys)) && (icacls.exe C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant Administrators:F /grant SYSTEM:F >nul)) || ((if not exist .ssh mkdir .ssh) && (findstr """$SearchContent""" .ssh\authorized_keys >nul || (echo $PubKeyContent>>.ssh\authorized_keys)))"
        Write-Host "$PubKeyContent" -ForegroundColor DarkGray
        
        # 成功信息
        ssh -o BatchMode=yes $User@$HostName "echo Upload successful. Now connected to $User@$HostName"
    }
}
# Add-SSHKeyToServer sftp 192.168.3.123 $env:USERPROFILE\.ssh\id_ed25519.pub
# Add-SSHKeyToServer administrator 192.168.3.123 $env:USERPROFILE\.ssh\id_ed25519.pub
# Add-SSHKeyToServer administrator 192.168.3.123 $env:USERPROFILE\.ssh\id_rsa.pub
# Add-SSHKeyToServer sftp 192.168.3.123 $env:USERPROFILE\.ssh\id_rsa.pub
# Add-SSHKeyToServer sftp 192.168.3.123 -PubKeyContent (Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub)
# Add-SSHKeyToServer sftp 192.168.3.123
