#### GitJump

A tiny git command wrapper for view git commits.

commands:

- ```git next``` (```git n``` for short): jump to next commit
- ```git prev``` (```git p``` for short): jump to previous commit
- ```git first``` : jump to oldest commit
- ```git last``` : jump to most recent commit

Usage:

1. load
  ```
  $ wget --no-check-certificate https://raw.githubusercontent.com/wuxc/gitjump/master/gitjump.sh
  $ source ./gitjump.sh
  ```
  or add it to your ~/.bashrc:
  
  ```
  $ echo "source `pwd`/gitjump.sh" >> ~/.bashrc
  ```

2. fire
  ```
  $ cd some/awesome/repos.git
  $ git first
  $ git next
  ```

Have fun!

Tested on bash/zsh on mac OS. 

Please create an issue if you find anything wrong or have a suggestion.
