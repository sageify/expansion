#!/bin/sh

# returns 0 if expanded, 1 otherwise (a directive on a native command, native with no entry in .xpn)
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
          directive_arg_count=${direct#*=}
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
$(printf %s "${xpn#<}" | xargs -n 100 printf %s\\n)
_
      return 1
      ;;
    '+'* | '*'*)
      next_param="${xpn%${xpn#?}}"
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
  case $1 in
  *[[:space:]\|\&\;\<\>\(\)\$\`\\\"\'*?[]* | ~*)
    printf %s "$1" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"
    ;;
  *)
    printf %s "$1"
    ;;
  esac
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
  # word = flag indicates xargs needs to be treated as an entire word
  # next_param = flag indicates next param appended after next word or prepended
  unset -v xpn xargs word next_param prepend append directive_arg_count

  if [ $native_count -gt 0 ]; then
    # processing native parameters (never expanding)
    native_count=$((native_count - 1))
  else
    case $1 in
    *[![:alnum:]_-]*) ;;
    -*) xpn_word "$cmd$1" "$native_first:$1" ;;
    *)
      if [ $arg_count -gt 0 ] && ! xpn_word "$cmd$1"; then
        arg_count=$((arg_count - 1))
        if [ $cmd_count -gt 0 ]; then
          cmd="$cmd$1>"
          cmd_count=$((cmd_count - 1))
          if [ "$directive_arg_count" ]; then
            arg_count=$directive_arg_count
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
      if [ "$next_param" ]; then
        # command>--sh * -- /bin/sh  --sh pod   pod -- /bin/sh
        # command>-n +-name=  -n jane  -name=jane"
        # abort if hit end of param_pos; -n (no jane)
        [ $param_pos -gt $# ] && echo "xpn: expecting additional argument" 1>&2 && exit 1
        case $next_param in
        '+') append="$1" ;;
        '*') prepend="$1" ;;
        esac

        shift
      fi

      if [ "$word" ]; then
        set -- "$xargs$append" "$@"
      else
        while IFS= read -r xarg; do
          set -- "$xarg$append" "$@"
          unset -v append
          # xargs in reverse order
        done <<_
$(printf %s "$xargs" | xargs printf %s\\n | sed '1!G;h;$!d')
_
      fi

      [ "${prepend+.}" ] && set -- "$prepend" "$@"

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
