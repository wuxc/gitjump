#! /bin/bash
#
# Author: wuxc (https://github.com/wuxc)
# License: MIT
# Usage: 
#   $ source path/to/gitjump.sh
#   $ cd your/repos.git
#   $ git first
#   $ git next

docstring="Hello, this is git jump.\n
A tiny git command wrapper for view git commits.\n
commands:\n
\t'git next' ('git n' for short): jump to next commit,\n
\t'git prev' ('git p' for short): jump to previous commit,\n
\t'git first' : jump to oldest commit,\n
\t'git last'  : jump to most recent commit."
orig_git=`/usr/bin/which git`
logfile=".git/jump_logfile"
branch_prefix="branch-"

function _git_is_merge {
    sha=$1
    msha=`$orig_git rev-list --merges ${sha}~1..$sha`
    [ -z "$msha" ] && return 1
    return 0
    
}

function _git_check_logfile {
    ## check & create logfile
    if [ ! -f $logfile ]; then
        echo -e $docstring
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
    $orig_git clean -fd
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


function _git_jump_near {
    _git_check_logfile || return
    # get current commit id
    current=`$orig_git show|head -n1|cut -d' ' -f2`
    # get newer 2 & older 1 (nexnext - next - current - prev)
    nearby=`cat $logfile|grep -A1 -B2 $current|awk -F' ' '{print $1} END {print  NR}' | tr '\n' ' '`
    # remove trailing space
    if [ "${nearby:0-1}" = " " ]; then
        nearby=${nearby% *}
    fi
    lines=${nearby:0-1}
    case $lines in
        "0"|"1")
            echo "No more commits."
            return
        ;;
        "2")
            next=`echo $nearby|cut -d' ' -f1`
            prev=`echo $nearby|cut -d' ' -f2`
            if [ $current = $prev ]; then ## no prev
                prev=
            else ## no next & nexnext
                next=
                nexnext=
            fi
        ;;
        "3")
            nexnext=`echo $nearby|cut -d' ' -f1`
            next=`echo $nearby|cut -d' ' -f2`
            prev=`echo $nearby|cut -d' ' -f3`
            if [ $current = $prev ]; then ## no prev
                prev=
            elif [ $current = $next ]; then ## no nexnext
                next=$nexnext
                nexnext=
            fi
        ;;
        "4")
            nexnext=`echo $nearby|cut -d' ' -f1`
            next=`echo $nearby|cut -d' ' -f2`
            prev=`echo $nearby|cut -d' ' -f4`
        ;;
    esac

    if [ $1 = "prev" ]; then
        if [ -z $prev ]; then
            echo 'No prev commit.'
            return
        fi
        _git_checkout_commit $prev $current
    elif [ $1 = "next" ]; then
        if [ -z $next -o -z $nexnext ]; then
            echo 'No next commit.'
            return
        fi
        _git_checkout_commit $next $nexnext
    fi
}

function _git_jump_far {
    _git_check_logfile || return
    if [ $1 = "first" ]; then
        commits=`cat $logfile|tail -n2|cut -d' ' -f1`
    elif [ $1 = "last" ]; then
        commits=`cat $logfile|head -n2|cut -d' ' -f1`
    fi
    new=`echo $commits|tr '\n' ' '|awk '{print $1}'`
    old=`echo $commits|tr '\n' ' '|awk '{print $2}'`
    if [ "$old" = "" -o "$new" = "" ]; then
        echo "No more commits."
        return
    fi
    _git_checkout_commit $old $new
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
        echo 'Cannot find .git directory'.
        return -1
    fi
    ## handle next | prev
    if [ $# -eq 1 ]; then
        workdir=`pwd`
        case $1 in
            n|next) builtin cd $gitdir/..; _git_jump_near next; builtin cd $workdir; return ;;
            p|prev) builtin cd $gitdir/..; _git_jump_near prev; builtin cd $workdir; return ;;
            first) builtin cd $gitdir/..; _git_jump_far first; builtin cd $workdir; return ;;
            last) builtin cd $gitdir/..; _git_jump_far last; builtin cd $workdir; return ;;
        esac
    fi
    $orig_git "$@"
}
