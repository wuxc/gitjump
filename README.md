[![Gitter](https://img.shields.io/gitter/room/nwjs/nw.js.svg?maxAge=2592000)](https://gitter.im/gitjump/Lobby)

#### GitJump

A tiny git command wrapper for view git commits.

commands:

- ```git jump 100```: jump to 100th commit (```git j``` for short)
- ```git jump +10```: jump 10 commits newer
- ```git jump -10```: jump 10 commits older
- ```git jump 03308b1a```: jump to commitid starts with 03308b1a
- ```git next``` (```git n``` for short): jump to next commit (equivalent to ```git jump +1```)
- ```git prev``` (```git p``` for short): jump to previous commit (equivalent to ```git jump -1```)
- ```git first``` : jump to oldest commit (equivalent to ```git jump 1```)
- ```git last``` : jump to most recent commit (equivalent to ```git jump 0```)

Usage:

1. load
  ```
  $ wget --no-check-certificate https://raw.githubusercontent.com/wuxc/gitjump/master/gitjump.sh
  $ source ./gitjump.sh
  ```
  or add it to your ~/.bashrc:
  
  ```
  # for Mac
  $ echo "source `pwd`/gitjump.sh" >> ~/.bash_profile
  # for Linux
  $ echo "source `pwd`/gitjump.sh" >> ~/.bashrc
  ```

2. fire
  ```
  $ cd some/awesome/repos.git
  $ git first
  $ git n; git status
  $ git diff 
  ......
  ```

Have fun!

Tested on bash/zsh on mac OS. 

Please create an issue if you find anything wrong or have a suggestion.
