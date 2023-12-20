#通过更改git的默认branch为main，完成了pull的下载

#github 2022年将默认的branch从master更改为main。但git中默认的依旧是master
#修改git config设置默认的git branch 为main。可以避免一些pull是链接不上的错误
git config --global init.defaultBranch main

#git下载修改上传的流程
git init
git pull https://github.com/CyanZRoy/remote.git
#如果完成下载则没问题。若无法下载考虑科学上网和branch

#修改
vim README.md
touch 111.py

#上传
git add README.md
git add 111.py
#git status
git commit -m 'remote test complete'


#连接远程github
git remote -v #查看是否有远程库
git remote add origin https://github.com/CyanZRoy/remote.git  #创建origin远程库，目前origin这个如果不删除也没在github中看见。目前我把它理解成一个接口
git remote -u origin main  #连接并上传本地main branch
git remote rm origin  #删除origin远程库