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
  $ source ./gitjump.sh
  ```
  or add it to your ~/.bashrc.

2. fire
  ```
  $ cd my/awesome/repos.git
  $ git first
  $ git next
  ```

Have fun!
