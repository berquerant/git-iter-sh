#!/bin/bash

usage() {
    local -r name="${0##*/}"
    cat - <<EOS >&2
${name} -- run command on multiple repositories

Usage
  ${name} do REPO_REGEX_OPT ... -- COMMAND ...
    Run command on multiple repositories.

  ${name} grep REPO_REGEX_OPT ... -- GIT_GREP_REGEX_OPT ...
    Grep multiple repositories.

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
EOS
}

__ghq() {
    ${GHQ:-ghq} "$@"
}

__grep() {
    ${GREP:-grep} "$@"
}

__max_procs() {
    echo "${GIT_ITER_MAX_PROCS:-1}"
}

# List absolute paths of all local repositories.
__list_repos() {
    ${GIT_ITER_LIST_REPOS:-__ghq list -p}
}

# Show root of repositories.
__repos_root() {
    if [[ -n "$GIT_ITER_REPOS_ROOT" ]] ; then
        echo "$GIT_ITER_REPOS_ROOT"
    else
        __ghq root
    fi
}

__select_repos() {
    __list_repos | __grep "$@"
}

# Run command in $1.
#
# $1: directory
# $2-: command and options
__git_iter_do() {
    local -r dir="$1"
    shift
    pushd "$dir" > /dev/null || return 1
    "$@"
    popd > /dev/null || return 1
}

__git_iter_do_each() {
    xargs -n 1 -P "$(__max_procs)" -IT "$0" __git_iter_do T "$@"
}

# Connect 2 functions with pipe and call them.
#
# $1: function1
# $2: function2
# $3-: arguments, before -- are arguments of function1, rest are arguments of function2
__git_iter_call() {
    local -r function1="$1"
    local -r function2="$2"
    shift 2
    local function1_args=()
    for arg in "$@" ; do
        if [[ "$arg" == "--" ]] ; then
            shift
            break
        fi
        function1_args+=("$arg")
        shift
    done

    "$function1" "${function1_args[@]}" | "$function2" "$@"
}

git_iter_do() {
    __git_iter_call __select_repos __git_iter_do_each "$@"
}

__git_iter_grep() {
    local repo_path
    if [[ -n "$GIT_ITER_GREP_ABS_PATH" ]] ; then
        repo_path="$(pwd)"
    else
        local -r root="$(__repos_root)/"
        local -r sed_expr="s|${root}||"
        # relative path from repos root
        repo_path="$(pwd | sed "$sed_expr")"
    fi
    git grep -H "$@" | awk -v r="$repo_path" '{print r"/"$0}'
}

git_iter_grep() {
    local args=()
    local replaced=0
    for arg in "$@" ; do
        args+=("$arg")
        if [[ "$replaced" == 0 && "$arg" == "--" ]] ; then
            replaced=1
            args+=("__git_iter_grep")
            continue
        fi
    done
    git_iter_do "${args[@]}"
}

main() {
    local -r cmd="$1"
    shift
    case "$cmd" in
        "do") git_iter_do "$@" ;;
        "grep") git_iter_grep "$@" ;;
        "__git_iter_do") __git_iter_do "$@" ;;
        *)
            usage
            return 1
            ;;
    esac
}

main "$@"
