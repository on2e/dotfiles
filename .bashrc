# shellcheck disable=SC1090,SC1091

# If not running bash, don't do anything
[ -n "${BASH_VERSION-}" ] || return 0

# If not running interactively, don't do anything
[[ "$-" == *i* ]] || return 0

# Check whether the shell is running in an xterm-compatible terminal
__dot_is_xterm() {
  case "${TERM-}" in
    xterm* | rxvt*) return 0 ;;
    *) return 1 ;;
  esac
}

# Check if given command exists
__dot_has() {
  command -v "${1-}" &>/dev/null
}

# Print number of colors supported by terminal
__dot_num_colors() {
  # shellcheck disable=SC2015
  __dot_has 'tput' && tput colors 2>/dev/null || echo -1
}

# Check whether the terminal supports colored output
__dot_has_colors() {
  [[ "$(__dot_num_colors)" -ge 8 ]]
}

# Print text wrapped in ANSI color escape sequences
__dot_colorize_string() {
  local text="${1-}"
  local code="${2-}"
  if __dot_has_colors; then
    # Wrap escape sequences in `\001` (SOH) and `\002` (STX) readline markers
    # to signal the start and end of non-printable characters, allowing Bash
    # to calculate the prompt size correctly and prevent line wrapping issues
    local color="\001\033[${code}m\002"
    local reset='\001\033[0m\002'
    if [[ -z "${code}" ]] || [[ "${code}" == 0 ]]; then
      echo "${reset}${text}"
    else
      echo "${color}${text}${reset}"
    fi
  else
    echo "${text}"
  fi
}

# Set environment variables
__dot_env() {
  # Locale
  export LANG='en_US.UTF-8'
  export LANGUAGE='en_US:en'

  # XDG
  export XDG_CONFIG_HOME="${HOME}/.config"
  export XDG_CACHE_HOME="${HOME}/.cache"
  export XDG_DATA_HOME="${HOME}/.local/share"
  export XDG_STATE_HOME="${HOME}/.local/state"

  # Editing and viewing
  if __dot_has 'nvim'; then
    export EDITOR='nvim'
    export MANPAGER='nvim +Man!'
  else
    export EDITOR='vi'
    export MANPAGER='less'
  fi
  export VISUAL="${EDITOR}"
  # -i : Ignore case in search patterns with no uppercase characters
  # -F : Exit if input file fits on the first screen
  # -M : Increase prompt verbosity
  # -R : Interpret ANSI color escape sequences (with some caveats)
  export LESS='-iFMR'

  # History

  # Do not save consecutive identical commands in the history list
  export HISTCONTROL=ignoredups
  # Maximum number of commands to keep in the history list (memory)
  export HISTSIZE=2000
  # Maximum number of commands to keep in the history file (disk)
  export HISTFILESIZE=10000
  # Enable history entry timestamps displayed in a ISO 8601-like format
  export HISTTIMEFORMAT='%F %T  '

  # LS_COLORS
  if __dot_has_colors && __dot_has 'dircolors'; then
    if [[ -s "${HOME}/.dircolors" ]]; then
      eval "$(dircolors -b "${HOME}/.dircolors")"
    else
      eval "$(dircolors -b)"
    fi
  fi
}

# Set aliases
__dot_aliases() {
  if __dot_has_colors; then
    alias grep='grep --color=auto'
    alias ls='ls --group-directories-first --color=auto'
  else
    alias ls='ls --group-directories-first'
  fi
  if [[ -s "${HOME}/.bash_aliases" ]]; then
    . "${HOME}/.bash_aliases"
  fi
}

# Source initialization scripts located under ~/.bashrc.d
__dot_init_files() {
  [[ -d "${HOME}/.bashrc.d" ]] || return 0
  while read -r f; do
    . "${f}"
  done <<<"$(find "${HOME}/.bashrc.d" -mindepth 1 -maxdepth 1 -type f -name '*.sh' | sort)"
}

# Customize PS1 prompt string
__dot_ps1() {
  local user_host cwd git_prompt cmd_prompt

  user_host="$(__dot_colorize_string '\u@\h' '1;32')"
  cwd="$(__dot_colorize_string '\w' '1;34')"

  # Embed __git_ps1 function call in PS1 and source ~/.git-prompt.sh
  # See: https://github.com/git/git/blob/master/contrib/completion/git-prompt.sh
  # shellcheck disable=SC2034
  if [[ -s "${HOME}/.git-prompt.sh" ]]; then
    # shellcheck disable=SC2016
    git_prompt='$(__git_ps1 " ('"$(__dot_colorize_string '%s' '1')"')")'
    if __dot_has_colors; then
      GIT_PS1_SHOWCOLORHINTS='1'
    fi
    GIT_PS1_SHOWDIRTYSTATE='1'     # '*' unstaged, '+' staged, '#' no staged / no commits
    GIT_PS1_SHOWSTASHSTATE='1'     # '$' stashed
    GIT_PS1_SHOWUNTRACKEDFILES='1' # '%' untracked
    GIT_PS1_SHOWUPSTREAM='auto'    # '<' behind, '>' ahead, '<>' diverged, '=' equal
    . "${HOME}/.git-prompt.sh"
  fi

  # Red '#' for root user, green '$' for others
  if [[ "$(id -u)" == 0 ]]; then
    cmd_prompt="$(__dot_colorize_string '\$' '0;31') "
  else
    cmd_prompt="$(__dot_colorize_string '\$' '0;32') "
  fi

  PS1="${user_host} ${cwd}${git_prompt}\n${cmd_prompt}"

  # Set terminal window title to username@hostname: directory
  # shellcheck disable=SC2025
  if __dot_is_xterm; then
    PS1="\001\033]0;\u@\h: \w\007\002${PS1}"
  fi
}

# Initialize interactive bash shell
__dot_main() {
  # Check the window size after each (non-builtin) command to update LINES and COLUMNS
  shopt -s checkwinsize
  # Append, not overwrite, history list to the history file on shell exit
  shopt -s histappend
  # Save multi-line commands in a single history entry
  shopt -s cmdhist

  __dot_env
  __dot_aliases
  __dot_ps1
  __dot_init_files
  __dot_clear
}

# Unset all functions defined in this script
__dot_clear() {
  unset -f __dot_is_xterm __dot_has __dot_num_colors __dot_has_colors \
    __dot_colorize_string __dot_env __dot_aliases __dot_init_files __dot_ps1 \
    __dot_main __dot_clear
}

__dot_main
