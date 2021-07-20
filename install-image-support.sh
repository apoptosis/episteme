#!/usr/bin/env bash

set -o nounset -o pipefail -o errexit

emacs_major=26
emacs_minor=1
emacs_ver="$emacs_major.$emacs_minor"
arch="x86_64"
emacs_url_root="https://ftpmirror.gnu.org/emacs/windows/emacs-$emacs_major"

emacs_deps_zip="emacs-$emacs_major-$arch-deps.zip"
emacs_zip="emacs-$emacs_ver-$arch.zip"

if [[ "$(uname -r)" == *Microsoft ]]; then
    programfiles="$(bin/wslpath "%ProgramFiles%")"
    programfilesx86="$(bin/wslpath "%ProgramFiles(x86)%")"
    allusersprofile="$(bin/wslpath "%AllUsersProfile%")"
    public_desktop="$(bin/wslpath "%Public%\\Desktop")"
    desktop="$(bin/wslpath "%UserProfile%\\Desktop")"
else
    CSIDL_PROGRAM_FILES=38
    CSIDL_PROGRAM_FILESX86=42
    CSIDL_COMMON_APPDATA=35
    CSIDL_COMMON_DESKTOPDIRECTORY=25
    CSIDL_DESKTOP=0

    programfiles="$(cygpath -F "$CSIDL_PROGRAM_FILES")"
    programfilesx86="$(cygpath -F "$CSIDL_PROGRAM_FILESX86")"
    allusersprofile="$(cygpath -F "$CSIDL_COMMON_APPDATA")"
    public_desktop="$(cygpath -F "$CSIDL_COMMON_DESKTOPDIRECTORY")"
    desktop="$(cygpath -F "$CSIDL_DESKTOP")"
fi

emacs_root="$programfiles/Emacs"

old_tmpdir="${TMPDIR:-}"
TMPDIR="$(mktemp -dt install-windows-pkgs.XXXXXXXXXX)"
export TMPDIR

on_exit () {
    rm -rf "$TMPDIR"
}

trap on_exit EXIT

unzip_dest () {
    local zip="$1"
    local dest="$2"

    if [[ ! -d "$dest" ]]; then
        if ! mkdir -p "$dest"; then
            result="$?"
            echo "Can't create '$dest'. Try running under elevation" >&2
            exit "$result"
        fi

        unzip -n "$zip" -d "$dest"
    fi
}

install_emacs_pkg () {
    local zip="$1"
    local dest="$2"

    # XXX: move to tmp
    if [[ ! -d "$dest" ]]; then
        wget --directory-prefix "$TMPDIR" "$emacs_url_root/$zip"
        unzip_dest "$TMPDIR/$zip" "$dest"
    fi
}

on_exit
trap EXIT
TMPDIR="$old_tmpdir"

# XXX: Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
# XXX: sticking cmd.exe /c start before this causes all nature of space-quoting problems
powershell.exe windows\\add_path.ps1 "%ProgramFiles%\\Emacs\\emacs-$emacs_ver\\bin" "%ProgramFiles%\\Emacs\\emacs-$emacs_major-deps\\bin"

# XXX: would be nice to pin runemacs.exe to taskbar, but the need to edit
# that is probably best seen as Emacs bug/flaw
