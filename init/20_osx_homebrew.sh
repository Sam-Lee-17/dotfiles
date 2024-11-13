is_osx || return 1

if [[ ! "$(type -P brew)" ]]; then
  e_header "Installing Homebrew"
  true | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

[[ ! "$(type -P brew)" ]] && e_error "Homebrew failed to install." && return 1

e_header "Updating Homebrew"
brew doctor
brew update

function brew_tap_kegs() {
  mapfile -t kegs < <(set_diff "${kegs[*]}" "$(brew tap)")
  if ((${#kegs[@]} > 0)); then
    e_header "Tapping Homebrew kegs: ${kegs[*]}"
    for keg in "${kegs[@]}"; do
      brew tap "$keg"
    done
  fi
}

function brew_install_recipes() {
  mapfile -t recipes < <(set_diff "${recipes[*]}" "$(brew list)")
  if (( ${#recipes[@]} > 0)); then
    e_header "Installing Homebrew recipes: ${recipes[*]}"
    for recipe in "${recipes[@]}"; do
      brew install "$recipe"
    done
  fi
}