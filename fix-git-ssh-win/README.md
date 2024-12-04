修復在 Windows 系統上無法使用 SSH 遠端連接的錯誤
===

主要原因應該是在 Windows 上執行 Linux 程式導致的兼容問題  

將兩個修復文件放到登入的使用者文件底下即可，如果放在別的地方需要設置環境變數  

> 要注意的一點是不要用別的帳號直接打開 `C:\User\` 底下的使用者資料夾  
> 打開的時候會問你要不要獲得權限，如果按是會導致觸犯到 SSH 的權限問題  
> 那個使用者就無法使用私鑰連接了，要把權限撤回才行  
> 例如可以使用 runas /u:git powershell 切換到git這個使用者

快速修復

```ps1
$baseUrl = 'raw.githubusercontent.com/hunandy14/SSHKeyLoader/refs/heads/main/fix-git-ssh-win'
irm $baseUrl/git-receive-pack.cmd > $env:USERPROFILE\git-receive-pack.cmd
irm $baseUrl/git-upload-pack.cmd > $env:USERPROFILE\git-upload-pack.cmd

```
