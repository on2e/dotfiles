# shellcheck disable=SC1090,SC1091

# If not running bash, don't do anything
[ -n "${BASH_VERSION-}" ] || return 0

# If not running interactively, don't do anything
[[ "$-" == *i* ]] || return 0

# # Check whether this script is being sourced
# __bashrc_is_sourced() {
#   local top
#   top="$(("${#FUNCNAME[@]}" - 1))"
#   [[ "${FUNCNAME[${top}]}" == 'source' ]]
# }

# Check whether the shell is running in an xterm-compatible terminal
__bashrc_is_xterm() {
  case "${TERM-}" in
    xterm* | rxvt*) return 0 ;;
    *) return 1 ;;
  esac
}

# Check if given command exists
__bashrc_has() {
  command -v "${1-}" &>/dev/null
}

# Print message
__bashrc_print() {
  printf '%s\n' "$*"
}

# Log message
__bashrc_log() {
  __bashrc_print ".bashrc: $*"
}

# Log message to standard error
__bashrc_error() {
  >&2 __bashrc_log "$@"
}

# Print number of colors supported by terminal
__bashrc_num_colors() {
  # shellcheck disable=SC2015
  __bashrc_has 'tput' && tput colors 2>/dev/null || __bashrc_print -1
}

# Check whether the terminal supports colored output
__bashrc_has_colors() {
  [[ "$(__bashrc_num_colors)" -ge 8 ]]
}

# Print text wrapped in terminal color control sequences
# NOTE: Shamelessly plagiarized from https://github.com/nvm-sh/nvm
__bashrc_colorize_string() {
  local text="${1-}"
  local code
  code="$(__bashrc_print_color_code "${2-}" || :)"
  if __bashrc_has_colors && [[ -n "${code}" ]]; then
    local color reset
    # Wrap escape sequences in `\001` (SOH) and `\002` (STX) readline markers
    # to signal the start and end of non-printable characters, allowing Bash
    # to calculate the prompt size correctly and prevent line wrapping issues
    color="\001\033[${code}m\002"
    reset='\001\033[0m\002'
    if [[ "${color}" == "${reset}" ]]; then
      __bashrc_print "${reset}${text}"
    else
      __bashrc_print "${color}${text}${reset}"
    fi
  else
    __bashrc_print "${text}"
  fi
}

# Translate internal 012rRgGbBcCyYmMkKwW color codes to ANSI color codes
# NOTE: Shamelessly plagiarized from https://github.com/nvm-sh/nvm
__bashrc_print_color_code() {
  case "${1-}" in
    '0') __bashrc_print '0' ;;    # normal / reset
    '1') __bashrc_print '1' ;;    # bold
    '2') __bashrc_print '2' ;;    # faint
    'r') __bashrc_print '0;31' ;; # red
    'R') __bashrc_print '1;31' ;; # bold red
    'g') __bashrc_print '0;32' ;; # green
    'G') __bashrc_print '1;32' ;; # bold green
    'b') __bashrc_print '0;34' ;; # blue
    'B') __bashrc_print '1;34' ;; # bold blue
    'c') __bashrc_print '0;36' ;; # cyan
    'C') __bashrc_print '1;36' ;; # bold cyan
    'm') __bashrc_print '0;35' ;; # magenta
    'M') __bashrc_print '1;35' ;; # bold magenta
    'y') __bashrc_print '0;33' ;; # yellow
    'Y') __bashrc_print '1;33' ;; # bold yellow
    'k') __bashrc_print '0;30' ;; # black
    'K') __bashrc_print '1;30' ;; # bold black
    'w') __bashrc_print '0;37' ;; # white
    'W') __bashrc_print '1;37' ;; # bold white
    *)
      __bashrc_error "Invalid color code: ${1-}. Must be one of 012rRgGbBcCyYmMkKwW."
      return 1
      ;;
  esac
}

# Set environment variables
__bashrc_env() {
  # Set LS_COLORS using `dircolors`
  if __bashrc_has_colors && __bashrc_has 'dircolors'; then
    if [[ -s "${HOME}/.dircolors" ]]; then
      eval "$(dircolors -b "${HOME}/.dircolors")"
    else
      eval "$(dircolors -b)"
    fi
  fi

  # History

  # Do not save consecutive identical commands in the history list
  HISTCONTROL=ignoredups
  # Maximum number of commands to keep in the history list
  HISTSIZE=2000
  # Maximum number of commands to keep in the history file
  HISTFILESIZE=10000
  # Enable history entry timestamps displayed in a ISO 8601-like format
  HISTTIMEFORMAT='%F %T  '
}

# Set aliases
__bashrc_aliases() {
  if __bashrc_has_colors; then
    local cmd
    for cmd in ls dir vdir grep; do
      # shellcheck disable=SC2139
      alias "$cmd"="$cmd --color=auto"
    done
  fi
  if [[ -s "${HOME}/.bash_aliases" ]]; then
    . "${HOME}/.bash_aliases"
  fi
}

# Source initialization scripts located under ~/.bashrc.d
__bashrc_init_files() {
  [[ -d "${HOME}/.bashrc.d" ]] || return 0
  while read -r f; do
    . "${f}"
  done <<<"$(find "${HOME}/.bashrc.d" -mindepth 1 -maxdepth 1 -type f -name '*.sh' | sort)"
}

# Customize PS1 prompt string
__bashrc_ps1() {
  local user_host cwd git_prompt cmd_prompt

  user_host="$(__bashrc_colorize_string '\u@\h' 'G')"
  cwd="$(__bashrc_colorize_string '\w' 'B')"

  # Embed __git_ps1 function call in PS1 and source ~/.git-prompt.sh
  # See: https://github.com/git/git/blob/master/contrib/completion/git-prompt.sh
  # shellcheck disable=SC2034
  if [[ -s "${HOME}/.git-prompt.sh" ]]; then
    # shellcheck disable=SC2016
    git_prompt='$(__git_ps1 " ('"$(__bashrc_colorize_string '%s' '1')"')")'
    if __bashrc_has_colors; then
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
    cmd_prompt="$(__bashrc_colorize_string '\$' 'r') "
  else
    cmd_prompt="$(__bashrc_colorize_string '\$' 'g') "
  fi

  PS1="${user_host} ${cwd}${git_prompt}\n${cmd_prompt}"
  # Set terminal window title to username@hostname: directory
  # shellcheck disable=SC2025
  if __bashrc_is_xterm; then
    PS1="\001\033]0;\u@\h: \w\007\002${PS1}"
  fi
}

# Initialize interactive bash shell
__bashrc_main() {
  # if ! __bashrc_is_sourced; then
  #   __bashrc_error ".bashrc must be sourced, not executed!"
  #   __bashrc_clear
  #   exit 1
  # fi

  # Check the window size after each (non-builtin) command to update LINES and COLUMNS
  shopt -s checkwinsize
  # Append, not overwrite, history list to the history file on shell exit
  shopt -s histappend
  # Save multi-line commands in a single history entry
  shopt -s cmdhist

  __bashrc_env
  __bashrc_aliases
  __bashrc_init_files
  __bashrc_ps1
  __bashrc_clear
}

# Unset all functions defined in this script
__bashrc_clear() {
  unset -f __bashrc_is_xterm __bashrc_has __bashrc_print __bashrc_log \
    __bashrc_error __bashrc_num_colors __bashrc_has_colors \
    __bashrc_colorize_string __bashrc_print_color_code __bashrc_env \
    __bashrc_aliases __bashrc_init_files __bashrc_ps1 __bashrc_main \
    __bashrc_clear
}

__bashrc_main
