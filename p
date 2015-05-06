#!/usr/bin/env bash

#
# Setup.
#

VERSION="0.0.1"
UP=$'\033[A'
DOWN=$'\033[B'
P_PREFIX=${P_PREFIX-/usr/local}
BASE_VERSIONS_DIR=$P_PREFIX/p/versions

#
# Python source.
#

MIRROR=(${PYTHON_MIRROR-https://www.python.org/ftp/python/})

test -d $BASE_VERSIONS_DIR/python || mkdir -p $BASE_VERSIONS_DIR/python

#
# Log <type> <msg>
#

log() {
  printf "  \033[36m%10s\033[0m : \033[90m%s\033[0m\n" "$1" "$2"
}

#
# Exit with the given <msg ...>
#

abort() {
  printf "\n  \033[31mError: $@\033[0m\n\n" && exit 1
}

#
# Print a (differentiable from log) success message.
#

success() {
    printf "\n  \033[32mSuccess: $@\033[0m\n\n"
}

#
# Ensure we have curl or wget support.
#

GET=

# wget support (Added --no-check-certificate for Github downloads)
command -v wget > /dev/null && GET="wget --no-check-certificate -q -O-"

command -v curl > /dev/null && GET="curl -# -L"

test -z "$GET" && abort "curl or wget required"

#
# Functions used when showing versions installed
#

enter_fullscreen() {
  tput smcup
  stty -echo
}

leave_fullscreen() {
  tput rmcup
  stty echo
}

handle_sigint() {
  leave_fullscreen
  exit $?
}

handle_sigtstp() {
  leave_fullscreen
  kill -s SIGSTOP $$
}

#
# Output usage information.
#

display_help() {
  cat <<-EOF

  Usage: p [COMMAND] [args]

  Commands:

    p                              Output versions installed
    p status                       Output current status
    p <version>                    Activate to Python <version>
      p latest                     Activate to the latest Python release
      p stable                     Activate to the latest stable Python release
    p use <version> [args ...]     Execute Python <version> with [args ...]
    p bin <version>                Output bin path for <version>
    p rm <version ...>             Remove the given version(s)
    p prev                         Revert to the previously activated version
    p ls                           Output the versions of Python available
      p ls latest                  Output the latest Python version available
      p ls stable                  Output the latest stable Python version available

  Options:

    -V, --version   Output current version of p
    -h, --help      Display help information

EOF
  exit 0
}

#
# Output status.
#

display_status() {
    get_current_version

    log version $current
    log bin $(display_bin_path_for_version)
    log previous $(get_previous_version)
    log latest $(is_latest_version)
    log stable $(is_latest_stable_version)
}

#
# Hide cursor.
#

hide_cursor() {
  printf "\e[?25l"
}

#
# Show cursor.
#

show_cursor() {
  printf "\e[?25h"
}

#
# Output version after selected.
#

next_version_installed() {
  list_versions_installed | grep $selected -A 1 | tail -n 1
}

#
# Output version before selected.
#

prev_version_installed() {
  list_versions_installed | grep $selected -B 1 | head -n 1
}

#
# Output previous version.
#
get_previous_version() {
    if [ ! -f $BASE_VERSIONS_DIR/.prev ]; then
        echo "none"
    else
        echo $(cat $BASE_VERSIONS_DIR/.prev)
    fi
}

#
# Output n version.
#

display_p_version() {
  echo $VERSION && exit 0
}

#
# Gets current human-readable Python version.
#
get_current_version() {
    # current=$(python -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')
    local version=$(python -V 2>&1)
    current=${version#*Python }
}

#
# Check for installed version, and populate $active
#

check_current_version() {
  command -v python &> /dev/null
  if test $? -eq 0; then
    get_current_version
	if diff &> /dev/null \
	  $BASE_VERSIONS_DIR/python/$current/python.exe \
	  $(which python) ; then
	  active="python/$current"
	fi
  fi
}

#
# Display sorted versions directories paths.
#

versions_paths() {
  find $BASE_VERSIONS_DIR -maxdepth 2 -type d \
    | sed 's|'$BASE_VERSIONS_DIR'/||g' \
    | egrep "[0-9]+\.[0-9]+\.[0-9]+([a|b]?)([0-9]?)+" \
    | sort -k 1,1n -k 2,2n -k 3,3n -t . -k 4,4n -d -k 5,5n -r
}

#
# Display installed versions with <selected>
#

display_versions_with_selected() {
  selected=$1
  echo
  for version in $(versions_paths); do
    version_minus_python=${version#*python\/}
    if test "$version" = "$selected"; then
      printf "  \033[36mο\033[0m $version_minus_python\033[0m\n"
    else
      printf "    \033[90m$version_minus_python\033[0m\n"
    fi
  done
  echo
}

#
# List installed versions.
#

list_versions_installed() {
  for version in $(versions_paths); do
    echo ${version}
  done
}

#
# Display current python --version and others installed.
#

display_versions() {
  enter_fullscreen
  check_current_version
  display_versions_with_selected $active

  trap handle_sigint INT
  trap handle_sigtstp SIGTSTP

  while true; do
    read -n 3 c
    case "$c" in
      $UP)
        clear
        display_versions_with_selected $(prev_version_installed)
        ;;
      $DOWN)
        clear
        display_versions_with_selected $(next_version_installed)
        ;;
      *)
        activate $selected
        leave_fullscreen
        exit
        ;;
    esac
  done
}

#
# Move up a line and erase.
#

erase_line() {
  printf "\033[1A\033[2K"
}

#
# Check if the HEAD response of <url> is 200.
#

is_ok() {
    curl -Is $1 | head -n 1 | grep 200 > /dev/null
}

#
# Determine tarball url for <version>
#

tarball_url() {
    version_directory="${version%a*}"
    echo "${MIRROR}${version_directory%b*}/Python-${version}.tgz"
}

#
# Activate <version>
#

activate() {
    local version=$1
    check_current_version
    if test "$version" != "$active"; then
        echo $active > $BASE_VERSIONS_DIR/.prev

        ln -sf $BASE_VERSIONS_DIR/$version/python.exe $BASE_VERSIONS_DIR/python/python
    fi
}

#
# Activate previous Python.
#

activate_previous() {
    test -f $BASE_VERSIONS_DIR/.prev || abort "no previous versions activated"
    local prev=$(cat $BASE_VERSIONS_DIR/.prev)
    test -d $BASE_VERSIONS_DIR/$prev || abort "previous version $prev not installed"
    activate $prev
    echo
    get_current_version
    log activate $current
    echo

    success "Now using Python $current!"
}

#
# Activate default (prior to p) Python.
#
activate_default() {
    log activate default

    rm -rf $BASE_VERSIONS_DIR/python/python

    get_current_version
    success "Now using Python $current!\n  Use \`p <version>\` to activate another version."
}

#
# Install <version>
#

install() {
    local version=${1#v}

    local dots=$(echo $version | sed 's/[^.]*//g')
    if test ${#dots} -eq 1; then
        version=$($GET 2> /dev/null ${MIRROR} \
            | egrep -o '[0-9]+\.[0-9]+\.[0-9]+' \
            | egrep -v '^0\.[0-7]\.' \
            | egrep -v '^0\.8\.[0-5]$' \
            | sort -u -k 1,1n -k 2,2n -k 3,3n -t . \
            | egrep ^$version \
            | tail -n1)

        test $version || abort "invalid version ${1#v}"
    fi

    local dir=$BASE_VERSIONS_DIR/python/$version
    local url=$(tarball_url $version)

    if test -d $dir; then
        if [[ ! -e $dir/n.lock ]] ; then
            activate python/$version

            log activate $version

            get_current_version
            success "Now using Python $current!"

            exit
        fi
    fi

    echo
    log install Python-$version

    is_ok $url || abort "invalid version $version"

    log create $dir
    mkdir -p $dir
    if [ $? -ne 0 ] ; then
        abort "sudo required"
    else
        touch $dir/p.lock
    fi

    cd $dir

    log fetch $url

    curl -L# $url | tar -zx --strip 1

    erase_line
    rm -f $dir/p.lock

    log configure $version
    ./configure &> /dev/null

    log compile $version
    make &> /dev/null

    if [ ! -f "python.exe" ]; then
    	abort "Unable to compile Python $version!"
    fi

    activate python/$version
    log activate $version

    log refresh \$PATH
    export PATH=/usr/local/p/versions/python:$PATH

    get_current_version
    success "Now using Python $current!"

    # "Now using Python $(python -c 'import sys; print(".".join(map(str, sys.version_info[:])))')!"
}

#
# Remove <version ...>
#

remove_versions() {
    test -z $1 && abort "version(s) required"

    for version in "$@"; do
        rm -rf $BASE_VERSIONS_DIR/python/${version#v}
        log remove $version
    done

    versions=$@

    success "Removed Python ${versions// /, }!"
}

#
# Output bin path for <version>
#

display_bin_path_for_version() {
    get_current_version

    if [ ! -z $1 ]; then
        local version=${1#v}
    else
        if [ ! -d $BASE_VERSIONS_DIR/python/$current ]; then
            abort "Version required!"
        else
            local version=$current;
        fi
    fi

    local bin=$BASE_VERSIONS_DIR/python/$version/python.exe
    if test -f $bin; then
        printf "$bin \n"
    else
        abort "Python $version is not installed"
    fi
}

#
# Execute the given <version> of node with [args ...]
#

execute_with_version() {
    test -z $1 && abort "version required"
    local version=${1#v}
    local bin=$BASE_VERSIONS_DIR/python/$version/python.exe

    shift # remove version

    if test -f $bin; then
        $bin "$@"
    else
        abort "Python $version is not installed"
    fi
}

#
# Display the latest release version.
#

display_latest_version() {
    latest_directory=$($GET 2> /dev/null ${MIRROR} \
        | egrep -o '[0-9]+\.[0-9]+\.[0-9]+' \
        | sort -u -k 1,1n -k 2,2n -k 3,3n -t . \
        | tail -n1)

    $GET 2> /dev/null ${MIRROR}$latest_directory \
        | egrep -o '[0-9]+\.[0-9]+\.[0-9]+[a|b][0-9]+' \
        | sort -k 1,1n -k 2,2n -k 3,3n -t . -k 4,4n -d -k 5,5n -d \
        | tail -n1
}

#
# Determine if current version is the latest version.
#

is_latest_version() {
    get_current_version
    if [[ $current == $(display_latest_version) ]]; then
        echo "yes"
    else
        echo "no"
    fi
}

#
# Display the latest stable release version.
#

display_latest_stable_version() {
    $GET 2> /dev/null ${MIRROR} \
        | egrep -o '[0-9]+\.[0-9]*[02468]\.[0-9]+' \
        | sort -u -k 1,1n -k 2,2n -k 3,3n -t . \
        | tail -n1
}

#
# Determine if current version is the latest stable version.
#

is_latest_stable_version() {
    get_current_version
    if [[ $current == $(display_latest_stable_version) ]]; then
        echo "yes"
    else
        echo "no"
    fi
}

#
# Display the versions available.
#

display_remote_versions() {
    check_current_version
    local versions=""
    versions=$($GET 2> /dev/null ${MIRROR} \
    | egrep -o '[0-9]+\.[0-9]+\.[0-9]+' \
    | egrep -v '^0\.[0-7]\.' \
    | egrep -v '^0\.8\.[0-5]$' \
    | sort -u -k 1,1n -k 2,2n -k 3,3n -t . \
    | awk '{ print "  " $1 }')

    echo

    for v in $versions; do
        if test "$active" = "python/$v"; then
            printf "  \033[36mο\033[0m $v \033[0m\n"
        else
            if test -d $BASE_VERSIONS_DIR/python/$v; then
                printf "    $v \033[0m\n"
            else
                printf "    \033[90m$v\033[0m\n"
            fi
        fi
    done
    echo
}

#
# Handle arguments.
#

if test $# -eq 0; then
  test -z "$(versions_paths)" && abort "no installed version"
  display_versions
else
  while test $# -ne 0; do
    case $1 in
      -V|--version) display_p_version ;;
      -h|--help|help) display_help ;;
      status) display_status ;;
      bin|which)
        case $2 in
            latest) display_bin_path_for_version $($0 ls latest); exit ;;
            stable) display_bin_path_for_version $($0 ls stable); exit ;;
            *) display_bin_path_for_version $2; exit ;;
        esac
      exit ;;
      as|use) shift; execute_with_version $@; exit ;;
      rm|-) shift; remove_versions $@; exit ;;
      ls|list)
        case $2 in
            latest) display_latest_version; exit ;;
            stable) display_latest_stable_version; exit ;;
            *) display_remote_versions; exit ;;
        esac
      exit ;;
      prev) activate_previous; exit ;;
      default) activate_default; exit ;;
      latest) install $($0 ls latest); exit ;;
      stable) install $($0 ls stable); exit ;;
      *) install $1; exit ;;
    esac
    shift
  done
fi
