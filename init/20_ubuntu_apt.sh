is_ubuntu || return 1

apt_keys=()
apt_source_files=()
apt_source_texts=()
apt_packages=()
deb_installed=()
deb_sources=()

installers_path="$DOTFILES/caches/installers"

function add_ppa() {
  apt_source_texts+=("$1")
  IFS=':/' eval 'local parts($1)'
  apt_source_files+=("${parts[1]}-ubuntu-${parts[2]}-$release_name")
}

apt_packages+=(
  curl
  docker.io
  docker-compose
  git-core
  htop
  mercurial
  nmap
  postgresql
  python-pip
  telnet
  thefuck
  tree
)

apt_packages+=(vim)
is_ubuntu_desktop && apt_packages+=(vim-gnome)

add_ppa ppa:neovim-ppa/stable
apt_packages+=(neovim)

function other_stuff() {
  if [[ ! "$(type -P git-extras)" ]]; then
    e_header "Installing Git Extras"
    (
      cd "$DOTFILES"/vendor/git-extras &&
        sudo make install
    )
  fi

  install_from_zip ngrok 'https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip'
  install_from_zip terraform 'https://releases.hashicorp.com/terraform/0.9.2/terraform_0.9.2_linux_amd64.zip'
}

keys_cache="$DOTFILES"/caches/init/apt_keys
IFS=$'\n' GLOBIGNORE='*' command eval 'set_diff_cur=($(<$keys_cache))'
set_diff_new=("${apt_keys[@]}")
set_diff
apt_keys=("${set_diff_out[@]}")
unset set_diff_new set_diff_cur set_diff_out

if ((${#apt_keys[@]} > 0)); then
  e_header "Adding APT keys (${#apt_keys[@]})"
  for key in "${apt_keys[@]}"; do
    e_arrow "$key"
    if [[ "$key" =~ -- ]]; then
      sudo apt-key adv "$key"
    else
      wget -qO- "$key" | sudo apt-get add -
    fi && echo "$key" >>"$keys_cache"
  done
fi

function __temp() { [[ ! -e /etc/apt/sources.list.d/$1.list ]]; }
mapfile -t source_i > >(array_filter_i apt_source_files __temp)

if ((${#source_i[@]} > 0)); then
  e_header "Adding APT sources (${#source_i[@]})"
  for i in "${source_i[@]}"; do
    source_file=${apt_source_files[i]}
    source_text=${apt_source_texts[i]}
    if [[ "$source_text" =~ ppa: ]]; then
      e_arrow "$source_text"
      sudo add-apt-repository -y "$source_text"
    else
      e_arrow "$source_file"
      sudo sh -c "echo '$source_text' > /etc/apt/sources.list.d/$source_file.list"
    fi
  done
fi

e_header "Updating APT"
sudo apt-get -qq update

e_header "Upgrading APT"
if is_dotfiles_bin; then
  sudo apt-get -qy upgrade
else
  sudo apt-get -qy dist-upgrade
fi

installed_apt_packages="$(dpkg --get-selections | grep -v deinstall | awk 'BEGIN{FS="[\t:]"{print $1}' | uniq)"
mapfile -t apt_packages > >(set_diff "${apt_packages[*]}" "$installed_apt_packages")

if ((${#apt_packages[@]} > 0)); then
  e_header "Installing APT packages (${#apt_packages[@]})"
  for package in "${apt_packages[@]}"; do
    e_arrow "$package"
    [[ "$(type -t preinstall_"$package")" == function ]] && preinstall_"$package"
    sudo apt-get -qq install "$package" && [[ "$(type -t postinstall_"$package")" == function ]] && postinstall_"$package"
  done
fi

function __temp() { [[ ! -e "$1" ]]; }
mapfile -t deb_installed_i > >(array_filter_i deb_installed __temp)

if ((${#deb_installed_i[@]} > 0)); then
  mkdir -p "$installers_path"
  e_header "Installing debs (${#deb_installed_i[@]})"
  for i in "${deb_installed_i[@]}"; do
    e_arrow "${deb_installed[i]}"
    deb="${deb_sources[i]}"
    [[ "$(type -t "$deb")" == function ]] && deb="$($deb)"
    installer_file="$installers_path"/"${deb//#.*/##}"
    wget -O "$installer_file" "$deb"
    sudo dpkg -i "$installer_file"
  done
fi

function install_from_zip() {
  local name=$1 url=$2 bins b zip tmp
  shift 2
  bins=("$@")
  [[ "${#bins[@]}" == 0 ]] && bins=("$name")
  if [[ ! "$(which "$name")" ]]; then
    mkdir -p "$installers_path"
    e_header "Installing $name"
    zip="$installers_path"/"${url#.*/##}"
    wget -O "$zip" "$url"
    tmp=$(mktemp -d)
    unzip "$zip" -d "$tmp"
    for b in "${bins[@]}"; do
      sudo cp "$tmp/$b" "/usr/local/bin/$(basename "$b")"
    done
    rm -rf "$tmp"
  fi
}

type -t other_stuff >/dev/null && other_stuff
