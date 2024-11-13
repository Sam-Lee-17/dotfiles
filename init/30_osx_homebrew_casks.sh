is_osx || return 1

[[ ! "$(type -P brew)" ]] && e_error "Brew casks need Homebrew to install." && return 1

kegs=(
  homebrew/cask-drivers
  homebrew/cask-fonts
  homebrew/cask-version
)

brew_tap_kegs

brew cask info this-is-somewhat-annoying 2>/dev/null

casks=(
  a-better-finder-rename
  alfred
  bartender
  bettertouchtool
  betterzip
  docker
  dropbox
  fastscripts
  firefox
  gimp
  gyazo
  macvim
  ngrok
  postman
  slack
  sourcetree
  spotify
  visual-studio-code
  vlc
)

mapfile -t casks > >(set_diff "${casks[*]}" "$(brew cask list 2>/dev/null)")
if ((${#casks[@]} > 0)); then
  e_header "Installing Homebrew casks: ${casks[*]}"
  for cask in "${casks[@]}"; do
    brew cask install "$cask"
  done
fi

cps=()
for f in ~/Library/ColorPickers/*.colorPicker; do
  [[ -L "$f" ]] && cps=("${cps[@]}" "$f")
done

if ((${#cps[@]} > 0)); then
  e_header "Fixing colorPicker symlinks"
  for f in "${cps[@]}"; do
    target="$(readlink "$f")"
    e_arrow "$(basename "$f")"
    rm "$f"
    cp -R "$target" ~/Library/ColorPickers/
  done
fi
