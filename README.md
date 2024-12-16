## SSH Key載入器
自動上傳 SSH Key 到伺服器上

<br>

快速使用

```ps1
irm bit.ly/3Zlkg2p|iex; AvtivateSSHKeyAuth "sftp@192.168.3.123" -GeneratePrvKey
```

> 產生新的金鑰並自動上傳到目標伺服器 (已經存在會詢問是否覆蓋)


<br>

測試連接
```ps1
ssh -i "$env:USERPROFILE\.ssh\id_ed25519" -o BatchMode=yes "sftp@192.168.3.123" "echo Connect successful."
```

```ps1
ssh -i "$env:USERPROFILE\.ssh\id_ed25519" -o UserKnownHostsFile="$env:USERPROFILE\.ssh\known_hosts" -o BatchMode=yes "sftp@192.168.3.123" "echo Connect successful."
```

<br>

安裝 OpenSSH
```ps1
irm bit.ly/4hbdNQf|iex; Install-OpenSSH 'C:\Program Files\OpenSSH' -IncludeServer -OpenFirewall
```



<br><br><br>

## 啟用私鑰授權
```ps1
# 載入函式
irm bit.ly/3Zlkg2p|iex;

# 啟用私鑰 (私鑰: 預設位置, 信任伺服器清單: 預設位置)
AvtivateSSHKeyAuth "sftp@192.168.3.123"

# 啟用私鑰並輸出未加鹽信任伺服器清單 (私鑰: 預設位置)
AvtivateSSHKeyAuth "sftp@192.168.3.123" -OutKnwHost "known_hosts" -NoSalt

# 啟用私鑰並輸出未加鹽信任伺服器清單
AvtivateSSHKeyAuth "sftp@192.168.3.123" -PrvKeyPath "id_ed25519" -OutKnwHost "known_hosts" -NoSalt

# 啟用私鑰並輸出未加鹽信任伺服器清單 (重新產生金鑰)
AvtivateSSHKeyAuth "sftp@192.168.3.123" -PrvKeyPath "id_ed25519" -OutKnwHost "known_hosts" -NoSalt -GeneratePrvKey


```



<br><br><br>

## 上傳Key到伺服器

```ps1
# 載入函式
irm bit.ly/3Zlkg2p|iex;

# 上傳公鑰 (預設 ~\.ssh\id_ed25519.pub 可省略)
Add-SSHKeyToServer "sftp@192.168.3.123" -PubKeyPath "$env:USERPROFILE\.ssh\id_ed25519.pub"

# 上傳公鑰 (直接輸入公鑰)
Add-SSHKeyToServer "sftp@192.168.3.123" -PubKeyContent (gc "$env:USERPROFILE\.ssh\id_ed25519.pub")

# 上傳公鑰 (變更連接埠)
Add-SSHKeyToServer "sftp@192.168.3.123" -Port 22


```

> 有避開重複上傳的問題，重複執行不會重複追加



<br><br><br>

## 創建SSH KEY

```ps1
# 創建新金鑰(安全性拉滿)
ssh-keygen -t ed25519
ssh-keygen -t ed25519  -f "$env:USERPROFILE\.ssh\id_ed25519" -N ""

# 創建新金鑰(PEM格式舊程式通常要用這個)
ssh-keygen -m PEM
ssh-keygen -m PEM -f "$env:USERPROFILE\.ssh\id_rsa" -N ""


```

參考
- https://learn.microsoft.com/zh-tw/windows-server/administration/openssh/openssh_keymanagement?WT.mc_id=DOP-MVP-37580#user-key-generation
- https://stackoverflow.com/questions/53134212/invalid-privatekey-when-using-jsch



<br><br><br>

## 私鑰權限問題
私鑰如果不是放在使用者家目錄底下，因為會被其他使用者存取 `ssh` 是禁止這種行為的  
要把權限設置成只有自己能存取 `ssh -i` 才能正常讀到私鑰使用  

powershell
```powershell
icacls ".\id_ed25519" /inheritance:r /remove *S-1-1-0 /grant *S-1-5-32-544:F /grant *S-1-5-18:F /grant "$($env:USERNAME):M"
```

cmd
```ps1
icacls ".\id_ed25519" /inheritance:r /remove *S-1-1-0 /grant *S-1-5-32-544:F /grant *S-1-5-18:F /grant "%username%:R"
```

> 要注意的是複製到使用者目錄以外的資料夾，會因為繼承的關係複製的當下權限繼承上一層資料夾  



<br><br><br>

## 從伺服器獲取伺服器公鑰

```powershell
ssh-keyscan 192.168.3.123
```



<br><br><br>

## 最簡啟用KEY方法

```ps1
# Generating public/private ed25519 key pair
ssh-keygen -t ed25519 -f $env:USERPROFILE\.ssh\id_ed25519

# Get the public key file generated previously on your client
$authorizedKey = Get-Content -Path $env:USERPROFILE\.ssh\id_ed25519.pub

# Generate PowerShell script to copy the client's public key to the server's authorized_keys.
$remotePowershell = "(if not exist .ssh mkdir .ssh) && echo $authorizedKey >> .ssh\authorized_keys"

# Connect to your server and run the PowerShell using the $remotePowerShell variable
ssh sftp@192.168.3.123 $remotePowershell

# Test Connect
ssh -i "$env:USERPROFILE\.ssh\id_ed25519" -o BatchMode=yes sftp@192.168.3.123 "echo Connect successful."


```

- https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement#standard-user




<br><br><br>

## 快速安裝 OpenSSH

```ps1
irm bit.ly/4hbdNQf|iex; Install-OpenSSH 'C:\Program Files\OpenSSH' -IncludeServer -OpenFirewall
```

> https://charlottehong.blogspot.com/2023/11/windoiws-openssh-server.html
