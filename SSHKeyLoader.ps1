# 上傳公鑰
function Add-SSHKeyToServer {
    [CmdletBinding(DefaultParameterSetName = "PubKeyPath")]
    param (
        # 連接資訊
        [Parameter(Position=0, Mandatory)]
        [string] $LoginInfo,
        # 公鑰
        [Parameter(Position=1, ParameterSetName="PubKeyPath")]
        [string] $PubKeyPath,
        [Parameter(ParameterSetName="PubKeyContent")]
        [string] $PubKeyContent,
        # 連接埠
        [Parameter(ParameterSetName="")]
        [int] $Port = 22
    )
    
    # 解析 LoginInfo
    $UserName, $HostName = $LoginInfo -split '@', 2
    if (-not $UserName -or -not $HostName) {
        Write-Error "Error:: Invalid LoginInfo format. It should be in 'UserName@HostName' format." -ErrorAction:Stop
    }

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
        ssh $LoginInfo "whoami /groups | findstr /C:S-1-5-32-544 >nul && ((findstr """$SearchContent""" C:\ProgramData\ssh\administrators_authorized_keys >nul || (echo $PubKeyContent>>C:\ProgramData\ssh\administrators_authorized_keys)) && (icacls.exe C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant Administrators:F /grant SYSTEM:F >nul)) || ((if not exist .ssh mkdir .ssh) && (findstr """$SearchContent""" .ssh\authorized_keys >nul || (echo $PubKeyContent>>.ssh\authorized_keys)))"
        Write-Host "$PubKeyContent" -ForegroundColor DarkGray
        
        # 成功信息
        ssh -o BatchMode=yes $LoginInfo "echo Upload successful. Now connected to $LoginInfo"
    }
}
# Add-SSHKeyToServer administrator@192.168.3.123 $env:USERPROFILE\.ssh\id_ed25519.pub
# Add-SSHKeyToServer administrator@192.168.3.123 $env:USERPROFILE\.ssh\id_rsa.pub
# Add-SSHKeyToServer sftp@192.168.3.123 $env:USERPROFILE\.ssh\id_ed25519.pub
# Add-SSHKeyToServer sftp@192.168.3.123 $env:USERPROFILE\.ssh\id_rsa.pub
# Add-SSHKeyToServer sftp@192.168.3.123 -PubKeyContent (Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub)
# Add-SSHKeyToServer sftp@192.168.3.123
