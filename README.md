## SSH Key載入器
自動上傳 SSH Key 到伺服器上

<br>

快速使用

```ps1
irm bit.ly/3Zlkg2p|iex; Add-SSHKeyToServer UserName@192.168.3.123
```

<br>

詳細說明

```ps1
# 載入函式
irm bit.ly/3Zlkg2p|iex;

# 上傳公鑰 (預設 ~\.ssh\id_ed25519.pub 可省略)
Add-SSHKeyToServer UserName@192.168.3.123 -PubKeyPath "$env:USERPROFILE\.ssh\id_ed25519.pub"

# 上傳公鑰 (直接輸入公鑰)
Add-SSHKeyToServer UserName@192.168.3.123 -PubKeyContent (gc "$env:USERPROFILE\.ssh\id_ed25519.pub")

# 上傳公鑰 (變更連接埠)
Add-SSHKeyToServer UserName@192.168.3.123 -Port 22

```



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
icacls "D:\sshkey\id_rsa" /inheritance:r /grant:r "$($env:USERNAME):R"
```

cmd
```ps1
icacls "D:\sshkey\id_rsa" /inheritance:r /grant:r "%username%:R"
```
