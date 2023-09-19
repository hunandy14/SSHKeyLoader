## SSH Key載入器
自動上傳 SSH Key 到伺服器上

快速使用

```ps1
irm bit.ly/3Zlkg2p|iex; Add-SSHKeyToServer sftp 192.168.3.123 -Path "$env:USERPROFILE\.ssh\id_ed25519.pub"
```
