# ~/.config/fish/config.fish

set fish_greeting
fastfetch

# Modern replacements for classic tools
alias ls "eza --icons --group-directories-first"
alias ll "eza -l --icons --group-directories-first"
alias la "eza -la --icons --group-directories-first"
alias tree "eza --tree --icons"
alias cat "bat"
alias du "dust"
alias top "btm"
alias ps "procs"
alias find "fd"
alias grep "rg"
alias diff "delta"

# Git shortcuts
abbr gs "git status"
abbr ga "git add"
abbr gc "git commit"
abbr gp "git push"
abbr gl "git log --oneline --graph --decorate"
abbr gd "git diff"

# Pipe any command's output straight to the clipboard: cat file.txt | clip
function clip
    wl-copy
end

# Atuin: disable up-arrow/Ctrl+R takeover — plain fish history on up-arrow,
# fzf-fish (installed via fisher below) owns Ctrl+R instead
atuin init fish --disable-up-arrow --disable-ctrl-r | source

zoxide init fish | source
starship init fish | source
