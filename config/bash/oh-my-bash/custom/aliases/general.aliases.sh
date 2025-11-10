alias edit_alias='cd $HOME/.oh-my-bash/custom/aliases'
alias bash_update='source ~/.bashrc'
alias bash_edit='nano ~/.bashrc'
alias cd..='cd ..'
alias cd.='cd.'
alias e='exit'
alias nano='nano -l -T 4'

# Load zoxide
eval "$(zoxide init bash)"
# Override cd
cd() {
    if [ $# -eq 0 ]; then
        builtin cd ~
    else
        z "$@" || builtin cd "$@"
    fi
}
