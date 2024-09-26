# BASIC CMD 
## 建立git repository 
    git init 
## 查看 git 狀態
    git status
## 加入新建/移除檔案
    git add "檔名.副檔名" ( 在使用git status 確認 )
## 存檔
    git commit -m "此次更改命名"
## 查看存檔紀錄
    git log 
## 把所有檔案 加入 git 上
    git add. 
## 上傳檔案
    上傳至github
    於github create repository -> private -> 獲得 github存檔指令
    git remote add origin 網址
    git remote 確認
    git push -u remote名稱 branch名稱  //-u是remote預設為origin 未來push如果不指定都會push到 origin
    git push origin master (把maste   branch名稱 放入至origin  remote名稱)
     Ctrl+ins  复制
     Shift+ins 粘贴
    git clone github網址 換別台電腦下載到github&使用
    使用git log 會出現之前的commit紀錄
    遇到git (end)  按下q恢復
