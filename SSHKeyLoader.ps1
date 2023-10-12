# 上傳公鑰
function Add-SSHKeyToServer {
    [CmdletBinding(DefaultParameterSetName = "PubKeyPath")]
    param (
        # 連接資訊
        [Parameter(Position=0, Mandatory)]
        [string] $LoginInfo,
        # 公鑰
        [Parameter(Position=1, ParameterSetName="PubKeyPath", Mandatory)]
        [string] $PubKeyPath,
        # 其他選項
        [Parameter(ParameterSetName="PubKeyContent")]
        [string] $PubKeyContent,
        [Parameter(ParameterSetName="")]
        [string[]] $OptionCmd
    ) [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
    
    # 解析 LoginInfo
    $UserName, $HostName = $LoginInfo -split '@', 2
    if (-not $UserName -or -not $HostName) {
        Write-Error "Error:: Invalid LoginInfo format. It should be in 'UserName@HostName' format." -ErrorAction:Stop
    }
    
    # 處理公鑰路徑
    if ($PubKeyPath) {
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
        Write-Host "Public Key Content: $PubKeyContent" -ForegroundColor DarkGray
        ssh @OptionCmd $LoginInfo "whoami /groups | findstr /C:S-1-5-32-544 >nul && ((findstr `"$SearchContent`" C:\ProgramData\ssh\administrators_authorized_keys >nul || (echo $PubKeyContent>>C:\ProgramData\ssh\administrators_authorized_keys)) && (icacls.exe C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant Administrators:F /grant SYSTEM:F >nul)) || ((if not exist .ssh mkdir .ssh) && (findstr `"$SearchContent`" .ssh\authorized_keys >nul || (echo $PubKeyContent>>.ssh\authorized_keys)))"
        if($LastExitCode -eq 0) {
            Write-Host "Successfully uploaded the public key to host '$HostName'." -ForegroundColor Green
        } else {
            Write-Error "Failed uploaded the public key to host '$HostName'." -ErrorAction Stop
        }
    }
}
# Add-SSHKeyToServer administrator@192.168.3.123 $env:USERPROFILE\.ssh\id_ed25519.pub
# Add-SSHKeyToServer administrator@192.168.3.123 $env:USERPROFILE\.ssh\id_rsa.pub
# Add-SSHKeyToServer sftp@192.168.3.123 $env:USERPROFILE\.ssh\id_ed25519.pub
# Add-SSHKeyToServer sftp@192.168.3.123 $env:USERPROFILE\.ssh\id_rsa.pub
# Add-SSHKeyToServer sftp@192.168.3.123 -PubKeyContent (Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub)
# Add-SSHKeyToServer sftp@192.168.3.123 -PubKeyContent (Get-Content id_ed25519.pub)
# Add-SSHKeyToServer sftp@192.168.3.123 id_ed25519.pub -KnwHostPath known_hosts



# 驗證私鑰可用性
function Test-SSHKey {
    param (
        [Parameter(Position=0, ParameterSetName = "", Mandatory)]
        [string] $LoginInfo,
        [Parameter(Position=1, ParameterSetName = "")]
        [string] $PrvKeyPath,
        [Parameter(Position=2, ParameterSetName = "")]
        [string] $KnwHostPath
    ) [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
    
    # 解析 LoginInfo
    $UserName, $HostName = $LoginInfo -split '@', 2
    if (-not $UserName -or -not $HostName) {
        Write-Error "Error:: Invalid LoginInfo format. It should be in 'UserName@HostName' format." -ErrorAction:Stop
    }
    
    # 私鑰預設位置
    if (!$PrvKeyPath) { $PrvKeyPath = "$env:USERPROFILE\.ssh\id_ed25519" }
    $PrvKeyPath = [IO.Path]::GetFullPath($PrvKeyPath)
    
    # 信任伺服器公鑰預設位置
    if (!$KnwHostPath) { $KnwHostPath = "$env:USERPROFILE\.ssh\known_hosts" }
    $KnwHostPath = [IO.Path]::GetFullPath($KnwHostPath)

    # 組合選項值
    if ($PrvKeyPath) { $PrvKey  = "-o IdentityFile=`"$PrvKeyPath`"" }
    if ($KnwHostPath) { $KnwHost = "-o UserKnownHostsFile=`"$KnwHostPath`"" }
    
    # 測試連接
    $result = ssh $PrvKey $KnwHost -o BatchMode=yes $LoginInfo "echo True" 2>$null
    if (($LastExitCode -eq 0) -and ($result -eq "True")) {
        return $true
    } else {
        return $false
    }
} # Test-SSHKey sftp@192.168.3.123 id_ed25519 known_hosts



# 啟用SSHKEY的認證
function AvtivateSSHKeyAuth {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        # 登入資訊
        [Parameter(Position=0, ParameterSetName = "", Mandatory)]
        [string] $LoginInfo,
        # SSHKEY私鑰
        [Parameter(Position=1, ParameterSetName = "Default")]
        [Parameter(Position=1, ParameterSetName = "GeneratePrvKey")]
        [string] $PrvKeyPath,
        [Parameter(ParameterSetName = "GeneratePrvKey")]
        [switch] $GeneratePrvKey,
        # 其他選項
        [Parameter(ParameterSetName = "")]
        [string] $OutKnwHost,
        [switch] $NoSalt,
        [switch] $Force # 強制上傳sshkey (已有其他私鑰的情況下不會被上傳第二個key)
    ) [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
    
    # 解析 LoginInfo
    $UserName, $HostName = $LoginInfo -split '@', 2
    if (-not $UserName -or -not $HostName) {
        Write-Error "Error:: Invalid LoginInfo format. It should be in 'UserName@HostName' format." -ErrorAction:Stop
    }
    
    # 獲取伺服器端公鑰
    if ($OutKnwHost) {
        $knwHostPath = [IO.Path]::GetFullPath($OutKnwHost)
        $result = ssh-keyscan $HostName 2>$null
        if($LastExitCode -ne 0) { Write-Error "Failed to obtain the public key for host '$HostName'" -ErrorAction Stop }
        $result | Set-Content $knwHostPath
        if (!$NoSalt) {
            ssh-keygen -H -f $knwHostPath 2>$null 1>$null
            Remove-Item "$knwHostPath.old"
        }
    }
    
    # 私鑰預設位置
    if (!$PrvKeyPath) { $PrvKeyPath = "$env:USERPROFILE\.ssh\id_ed25519" }
    $PrvKeyPath = [IO.Path]::GetFullPath($PrvKeyPath)
    # 生成私鑰
    if ($GeneratePrvKey) { ssh-keygen -t ed25519 -f $PrvKeyPath }
    # 私鑰路徑無效
    if (!(Test-Path -PathType:Leaf $PrvKeyPath)) { Write-Error "Error:: Path `"$PrvKeyPath`" does not exist" -ErrorAction:Stop }
    
    # 從私鑰獲取公鑰
    $PubKeyContent = ssh-keygen -y -f $PrvKeyPath 2>&1
    if (($LastExitCode -ne 0) -and ($PubKeyContent -match "Permissions for .* are too open.")) {
        icacls $PrvKeyPath /inheritance:r /remove *S-1-1-0 /grant *S-1-5-32-544:F /grant *S-1-5-18:F /grant "$($env:USERNAME):M" |Out-Null
        $PubKeyContent = ssh-keygen -y -f $PrvKeyPath 2>&1
    } if ($LastExitCode -ne 0) {
        Write-Host ($PubKeyContent -join "`r`n")
        Write-Host ""
        Write-Error "Failed to extract the public key from private key at '$PrvKeyPath'" -ErrorAction Stop
    }
    
    # 組合選項值
    if ($PrvKeyPath) { $PrvKey  = "-o IdentityFile=`"$PrvKeyPath`"" }
    if ($KnwHostPath) { $KnwHost = "-o UserKnownHostsFile=`"$KnwHostPath`"" }

    # 上傳公鑰到伺服器
    if (!(Test-SSHKey $LoginInfo $PrvKeyPath $KnwHostPath) -or $Force) {
        $options = @($PrvKey, $KnwHost) | Where-Object { $_ }
        $options = $options | ForEach-Object { $_ -split ' ', 2 }
        Add-SSHKeyToServer $LoginInfo -PubKeyContent $PubKeyContent -OptionCmd $options
    }
    
    # 確認連接
    $result = ssh $PrvKey $KnwHost -o BatchMode=yes $LoginInfo "echo SSH key '$PrvKeyPath' authentication is now activated."
    Write-Host $result -ForegroundColor Green
}
# AvtivateSSHKeyAuth "sftp@192.168.3.123"
# AvtivateSSHKeyAuth "sftp@192.168.3.123" -GeneratePrvKey
# AvtivateSSHKeyAuth "sftp@192.168.3.123" -OutKnwHost "known_hosts" -NoSalt
# AvtivateSSHKeyAuth "sftp@192.168.3.123" -PrvKeyPath "id_ed25519" -OutKnwHost "known_hosts" -NoSalt
# AvtivateSSHKeyAuth "sftp@192.168.3.123" -PrvKeyPath "id_ed25519" -OutKnwHost "known_hosts" -NoSalt -GeneratePrvKey
# AvtivateSSHKeyAuth "sftp@192.168.3.123" -PrvKeyPath "Z:\sshkey\id_ed25519" -OutKnwHost "Z:\sshkey\known_hosts" -NoSalt -GeneratePrvKey
# AvtivateSSHKeyAuth "sftp@192.168.3.123" -PrvKeyPath "Z:\sshkey\id_ed25519" -OutKnwHost "Z:\sshkey\known_hosts" -NoSalt -GeneratePrvKey -Force
