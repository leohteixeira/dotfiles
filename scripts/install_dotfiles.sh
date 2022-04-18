#!/bin/sh

set -eu

echo_task() {
  printf "\033[0;34m--> %s\033[0m\n" "$@"
}

get_default_branch() {
  path=$1
  git -C "${path}" remote show origin | grep 'HEAD branch' | cut -d' ' -f5
}

git_clean() {
  path=$(realpath "$1")
  branch="$(get_default_branch "${path}")"
  echo_task "Cleaning ${path} with branch ${branch}"
  git="git -C ${path}"
  ${git} checkout "${branch}"
  ${git} fetch origin "${branch}"
  ${git} reset --hard FETCH_HEAD
  ${git} clean -fdx
  unset path
  unset branch
  unset git
}

DOTFILES_REPO_HOST=${DOTFILES_REPO_HOST:-"https://github.com"}
DOTFILES_USER=${DOTFILES_USER:-"leohteixeira"}
DOTFILES_REPO="${DOTFILES_REPO_HOST}/${DOTFILES_USER}/dotfiles"
DOTFILES_BRANCH=${DOTFILES_BRANCH:-"master"}
DOTFILES_DIR="${HOME}/.dotfiles"

if command -v git >/dev/null 2>&1; then
  echo "Git does not seems to be installed"
  if ! sudo -n true 2>/dev/null; then
    echo_task "Prompting for sudo password to install Git"
    sudo true
  fi
  echo_task "Installing Git"
  sudo apt update
  sudo apt install git -y
fi

if [ -d "${DOTFILES_DIR}" ]; then
  git_clean "${DOTFILES_DIR}"
else
  echo_task "Cloning ${DOTFILES_REPO} on branch ${DOTFILES_BRANCH} to ${DOTFILES_DIR}"
  git clone -b "${DOTFILES_BRANCH}" "${DOTFILES_REPO}" "${DOTFILES_DIR}"
fi

if [ -f "${DOTFILES_DIR}/install.sh" ]; then
  INSTALL_SCRIPT="${DOTFILES_DIR}/install.sh"
elif [ -f "${DOTFILES_DIR}/install" ]; then
  INSTALL_SCRIPT="${DOTFILES_DIR}/install"
else
  echo "No install script found." >&2
  exit 1
fi

echo_task "Running ${INSTALL_SCRIPT}"
exec "${INSTALL_SCRIPT}"
