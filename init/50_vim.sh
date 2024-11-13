mkdir -p "$DOTFILES"/caches/vim

if [[ "$(type -P vim)" ]]; then
  vim +PlugUpgrade +PlugUpdate +qall
fi
