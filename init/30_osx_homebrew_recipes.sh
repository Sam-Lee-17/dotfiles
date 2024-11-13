is_osx || return 1

[[ ! "$(type -P brew)" ]] && e_error "Brew recipes need Homebrew to install." && return 1

recipes=(
  ansible
  bash
  git
  git-extras
  htop
  nmap
  ssh-copy-id
  thefuck
  tree
  wget
)

brew_install_recipes

binroot="$(brew --config | awk '/HOMEBREW_PREFIX/ {print $2}')"/bin

if [[ "$(type -P "$binroot"/htop)" ]] && [[ "$(stat -L -f "%Su:%Sg" "$binroot/htop")" != "root:wheel" ]]; then
  e_header "Updating htop permissions"
  sudo chown root:wheel "$binroot/htop"
  sudo chmod u+s "$binroot/htop"
fi

# bash
if "$(type -P "$binroot"/bash)" && grep </etc/shells -q "$binroot/bash"; then
  e_header "Adding $binroot/bash to the list of acceptable shells"
  echo "$binroot/bash" | sudo tee -a /etc/shells >/dev/null
fi
if [[ "$(dscl . -read ~ UserShell | awk '{print $2}')" != "$binroot/bash" ]]; then
  e_header "Making $binroot/bash your default shell"
  sudo chsh -s "$binroot/bash" "$USER" >/dev/null 2>&1
  e_arrow "Please exit and restart all your shells."
fi
