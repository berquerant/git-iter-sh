# git-iter-sh

``` shell
❯ ./git-iter.sh
git-iter.sh -- run command on multiple repositories

Usage
  git-iter.sh do REPO_REGEX_OPT ... -- COMMAND ...
    Run command on multiple repositories.

  git-iter.sh grep REPO_REGEX_OPT ... -- GIT_GREP_REGEX_OPT ...
    Grep multiple repositories.

  git-iter.sh (ls|list) REPO_REGEX_OPT ...
    Grep repository names.

Environment variables
  GIT_ITER_MAX_PROCS
    Maximum number of processes used for execution.
    Default: 1

  GIT_ITER_LIST_REPOS
    Command to list absolute paths of all local repositories.
    Default: ghq list -p

  GIT_ITER_REPOS_ROOT
    Root of local repositories.
    Default: value of ghq root

  GIT_ITER_GREP_ABS_PATH
    If set, show absolute paths of files.

  GHQ
    ghq command.
    Default: ghq

  GREP
    grep command.
    Default: grep
```
