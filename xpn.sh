#!/bin/sh

# returns 0 if expanded (xargs assigned), 1 otherwise (a directive on a native command, native with no entry in .xpn)
xpn_word() {
  for param; do
    xpn="$(grep -m 1 -e '^[[:space:]]*'"$param"'[[:space:]]' "$dot_xpn" | sed -e 's/^[[:space:]]*'"$param"'[[:space:]]*//')"
    case $xpn in
    '') continue ;;
    '<'*)
      while read -r direct; do
        # case is glob(7).  No way to specify number of digits should be unlimited. 999 should be enough
        case $direct in
        arg=[0-9] | arg=[0-9][0-9] | arg=[0-9][0-9][0-9])
          # specify new arg count
          arg_directive=${direct#*=}
          ;;
        cmd) cmd_count=1 ;;
        cmd+[0-9] | cmd+[0-9][0-9] | cmd+[0-9][0-9][0-9])
          # specify new depth for commands
          cmd_count=$((1 + ${direct#*+}))
          ;;
        cmd_arg=[0-9] | cmd_arg=[0-9][0-9] | cmd_arg=[0-9][0-9][0-9])
          cmd_arg_count=${direct#*=}
          ;;
        file=*) dot_xpn=$(dirname -- "$dot_xpn")/${direct#*=} ;;
        native+[0-9] | native+[0-9][0-9] | native+[0-9][0-9][0-9])
          native_count=$((0 + ${direct#*+}))
          ;;
        native) ;;
        word=*) xargs="${direct#*=}" word=0 && return 0 ;;
        xargs=*) xargs="${direct#*=}" && return 0 ;;
        *) echo "xpn: $xpn: Unknown directive" 1>&2 && exit 1 ;;
        esac
      done <<_
$(printf %s "${xpn#<}" | xargs printf %s\\n)
_
      return 1
      ;;
    '+'*)
      append_next_param=0
      xpn="${xpn#?}"
      ;;
    esac

    case $xpn in
    '`'*) xargs="${xpn#?}" word=0 ;;
    *) xargs="$xpn" ;;
    esac
    return 0
  done
  return 1
}

xpn_escape() {
  printf %s "$1" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"
}

# Command Expansion
#
# This script will expand command line options, flags and sub commands per the .xpn
# file in the home directory.  By default, expansions for git, kubectl and terraform
# are created.
#
# For example, 'kc g p' will get expanded to 'kubectrl get po'
#
#
# To use, create a link to this file with a configured command.
# By default, 'g', 'kc', and 'tf' are supported.
#
# ln -s xpn.sh kc
#

# must be a symoblic link to this file
if ! [ -L "$0" ]; then
  echo "xpn: Must be called with a symbolic link" 1>&2
  echo "     create link, for example: ln -s xpn.sh kc" 1>&2
  exit 1
fi

# current search order: XPN_CONFIG, link directory, $HOME/.xpn, this scripts directory
! dot_xpn="${XPN_CONFIG-$(dirname -- "$0")/.xpn}" && exit 1
if ! [ -f "$dot_xpn" ]; then
  ! dot_xpn="$HOME/.xpn" && exit 1
  if ! [ -f "$dot_xpn" ]; then
    ! dot_xpn="$(dirname -- "$(readlink -- "$0")")/.xpn" && exit 1
    ! [ -f "$dot_xpn" ] &&
      echo "xpn: Can't find .xpn configuration file" 1>&2 && exit 1
  fi
fi

#
# Main Loop
#

set -- "$(basename -- "$0")" "$@"

param_pos=1 native_count=0 cmd_count=1 cmd_arg_count=1 arg_count=1
while [ $param_pos -le $# ]; do
  unset -v xpn xargs word append_next_param arg_directive

  if [ $native_count -gt 0 ]; then
    native_count=$((native_count - 1))
  else
    case $1 in
    *[![:alnum:]_-]*) ;;
    -? | --*) xpn_word "$cmd$1" "$native_first:$1" ;;
    -*)
      xpn_word "$cmd$1" "$native_first:$1"
      if ! [ "$xpn" ]; then
        # -au -> -a -u
        flags=${1#-}
        shift
        while [ "$flags" ]; do
          head=${flags%?}
          set -- "-${flags#$head}" "$@"
          flags="$head"
        done
        continue
      fi
      ;;
    *)
      if [ $arg_count -gt 0 ] && ! xpn_word "$cmd$1"; then
        arg_count=$((arg_count - 1))
        if [ $cmd_count -gt 0 ]; then
          cmd="$cmd$1>"
          cmd_count=$((cmd_count - 1))
          if [ "$arg_directive" ]; then
            arg_count=$arg_directive
          elif [ "$cmd_count" -eq 0 ]; then
            arg_count=0
          else
            arg_count=$cmd_arg_count
          fi
        fi
      fi
      ;;
    esac

    if [ "${xargs+.}" ]; then
      shift
      if [ "$append_next_param" ]; then
        # command>-n +name=: -n jane: -name=jane"
        # abort if hit end of param_pos; -n (no jane)
        [ $param_pos -gt $# ] && echo "xpn: missing argument" 1>&2 && exit 1
        append_next_param="$1"
        shift
      fi

      if [ "$word" ]; then
        set -- "$xargs$append_next_param" "$@"
      else
        while IFS= read -r word; do
          set -- "$word$append_next_param" "$@"
          unset -v append_next_param
        done <<_
$(printf %s "$xargs" | xargs printf %s\\n | sed '1!G;h;$!d')
_
      fi
      continue
    fi
  fi

  # have a native parameter
  native_last="$1"
  shift
  set -- "$@" "$native_last"
  [ $param_pos -eq 1 ] && native_first="$native_last"
  param_pos=$((param_pos + 1))
done

# shellcheck disable=SC2154
# if not an expansion dry run, execute underlying command
! [ "${xdr+x}" ] && exec "$@"

# dry run
xpn_escape "$1"
shift
for param; do
  printf ' '
  [ "$xdr" = l ] && printf '\\\n'
  xpn_escape "$param"
done
printf "\n"
