# project-local version via .nvmrc if present
autoload -U add-zsh-hook
load_nvmrc() {
  local node_version
  if [[ -f .nvmrc ]]; then
    node_version=$(<.nvmrc)
    nvm use --silent "$node_version" >/dev/null 2>&1 || nvm install "$node_version"
  fi
}
add-zsh-hook chpwd load_nvmrc
load_nvmrc
