## SSH Key載入器
自動上傳 SSH Key 到伺服器上

快速使用

```ps1
irm bit.ly/3Zlkg2p|iex; Add-SSHKeyToServer UserName@192.168.3.123
```



<br><br><br>

詳細說明

```ps1
# 載入函式
irm bit.ly/3Zlkg2p|iex;

# 上傳公鑰 (預設 ~\.ssh\id_ed25519.pub 可省略)
Add-SSHKeyToServer UserName@192.168.3.123 -PubKeyPath "$env:USERPROFILE\.ssh\id_ed25519.pub"

# 上傳公鑰 (直接輸入公鑰)
Add-SSHKeyToServer UserName@192.168.3.123 -PubKeyContent (Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub)

# 上傳公鑰 (變更連接埠)
Add-SSHKeyToServer UserName@192.168.3.123 -Port 22

```
