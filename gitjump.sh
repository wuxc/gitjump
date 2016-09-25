#! /bin/bash
#
# Author: wuxc (https://github.com/wuxc)
# License: MIT
# Usage: 
#   $ source path/to/gitjump.sh
#   $ cd your/repos.git
#   $ git first
#   $ git next

orig_git=`/usr/bin/which git`
logfile=".git/jump_logfile"
branch_prefix="jump-branch-"

function _git_jump_help {
    cat <<-EOF
Hello, this is git jump.
A tiny git command wrapper for view git commits.
commands:
    'git jump 100': jump to 100th commit ('git j' for short)
    'git jump +10': jump 10 commits newer
    'git jump -10': jump 10 commits older
    'git jump 03308b1a': jump to commitid starts with 03308b1a
    'git next' ('git n' for short): jump to next commit (equivalent to 'git jump +1')
    'git prev' ('git p' for short): jump to previous commit (equivalent to 'git jump -1')
    'git first' : jump to oldest commit (equivalent to 'git jump 1')
    'git last' : jump to most recent commit (equivalent to 'git jump 0')
EOF
}

function _git_is_merge {
    sha=$1
    msha=`$orig_git rev-list --merges ${sha}~1..$sha`
    [ -z "$msha" ] && return 1
    return 0
}

function _git_check_logfile {
    ## check & create logfile
    if [ ! -f $logfile ]; then
        _git_jump_help
        current=`$orig_git branch | grep "*" | cut -c 3-`
        if [ $current != "master" ]; then
            echo "You are currently on branch: $current"
            echo "Continue? (Y/N)"
            read ans
            if [ "$ans" != 'y' -a $ans != 'Y' ]; then
                echo "Abort."
                return -1
            fi
        fi
        $orig_git log --pretty=oneline > $logfile
    fi
}

function _git_checkout_commit {
    ## check if the branch exists & remove old branches
    ## args: commitid, next_commitid
    commitid=$1
    next_commitid=$2
    branch_name="${branch_prefix}${commitid:0:8}"
    current=`$orig_git branch | grep "*" | cut -c 3-`
    if [ $branch_name = $current ]; then
        echo "Already on commit $commitid"
        return
    fi
    ## clear old branches
    already_exist=false
    for line in `$orig_git branch | grep -v "*" | grep $branch_prefix`
    do
        if [ $line = $branch_name ]; then
            already_exist=true
            continue
        fi
        $orig_git branch -D -q $line
    done
    ## discard modifications before switch branch
    $orig_git clean -fdq
    $orig_git checkout -- .
    ## switch branch
    echo "checking out to: $branch_name ($commitid)"
    if $already_exist; then
        $orig_git checkout $branch_name > /dev/null
    else
        $orig_git checkout $commitid -b $branch_name > /dev/null
    fi
    branch=`$orig_git branch | grep "*" | cut -c 3-`
    echo "on branch: $branch"
    ## stop on newest
    if [ -z $next_commitid ]; then
        echo "Newest reached. No next commit."
        return
    fi
    ## cherry-pick commit and unstash changes
    _git_is_merge $next_commitid
    ismerge="$?"
    if [ $ismerge = "0" ]; then
        $orig_git cherry-pick -m 1 --no-commit --allow-empty --allow-empty-message $next_commitid
    else
        $orig_git cherry-pick --no-commit --allow-empty --allow-empty-message $next_commitid
    fi
    $orig_git reset HEAD -- . >> /dev/null
    echo "applied modifications from $next_commitid"
    $orig_git log $next_commitid -1 --pretty=format:"%n %Cgreen%an (%ae)%Creset %cd%n %Cblue%s%Creset%n"
    $orig_git diff --stat
}

function _git_jump {
    _git_check_logfile || return

    if [ -z $1 ]; then
        _git_jump_help
        return
    fi

    commit=$1
    sign=${commit:0:1}
    if [ $sign = "+" -o $sign = "-" ]; then
        commit=${commit:1}
    else
        sign=
    fi

    ## 0 for newest
    totallines=`cat $logfile | awk 'END{print NR}'`
    if [ $commit -eq 0 ] &> /dev/null; then
        commit=$totallines
    fi

    ## check for number
    expr $commit + 0 &> /dev/null
    if [ $? = 0 -o $? = 1 ]; then
        if [ -z $sign ]; then
            n=$commit
        else
            current=`$orig_git show | head -n1 | cut -d' ' -f2`
            n=`cat $logfile|grep -n "^$current" | cut -d':' -f1`
            n=$(($totallines+1-$n))
            if [ $sign = "+" ]; then
                n=$(($n+$commit))
            else
                n=$(($n-$commit))
            fi
        fi
    else
        n=`cat $logfile | grep -n "^$1" | cut -d':' -f1`
        if [ "$n" = "" ]; then
            echo "No match commitid found for '$1'"
            return
        elif [ `echo $n | tr '\n' ' ' | awk -F' ' '{print NF}'` -gt 1 ]; then
            echo "Multiple matches found for '$1', please use more specific commit id."
            return
        fi
        n=$(($totallines+1-$n))
    fi
    if [ $n -gt $totallines -o $n -le 0 ]; then
        echo "No more commit! (range: 1 - $totallines)"
        return
    fi

    progress="$n/$totallines"
    ## find out nth & n+1th commits
    ## special case for newest
    if [ $n -eq $totallines ]; then
        old=`head -n1 $logfile | awk '{print $1}'`
        new=
    else
        let n++
        commits=`cat $logfile | tail -n $n | head -n2 | cut -d' ' -f1`
        new=`echo $commits | tr '\n' ' ' | awk '{print $1}'`
        old=`echo $commits | tr '\n' ' ' | awk '{print $2}'`
    fi
    ## special case for oldest -1
    if [ -z $old ]; then
        echo "Oldest reached. No prev commits."
        return
    fi
    _git_checkout_commit $old $new
    echo "Progress: $progress"
}

function git {
    ## no git installed
    if [ "$orig_git" = "" ]; then
        echo "git: command not found"
        return 127
    fi
    ## not a git repos
    $orig_git show > /dev/null 2>&1
    if [ $? != 0 ]; then
        $orig_git "$@"
        return $?
    fi
    ## find .git directory
    n=1
    gitdir=".git"
    while [ $n -le 100  ];
    do
        if [ -d $gitdir ]; then
            break;
        fi
        gitdir="../$gitdir"
        let n++
    done
    if [ ! -d $gitdir ]; then
        echo "Cannot find .git directory."
        return -1
    fi
    ## handle next | prev
    workdir=`pwd`
    if [ $# -ge 1 ]; then
        case $1 in
            n|next) builtin cd $gitdir/..; _git_jump +1; builtin cd $workdir; return ;;
            p|prev) builtin cd $gitdir/..; _git_jump -1; builtin cd $workdir; return ;;
            first) builtin cd $gitdir/..; _git_jump 1; builtin cd $workdir; return ;;
            last) builtin cd $gitdir/..; _git_jump 0; builtin cd $workdir; return ;;
            j|jump) builtin cd $gitdir/..; _git_jump $2; builtin cd $workdir; return ;;
        esac
    fi

    $orig_git "$@"
}
