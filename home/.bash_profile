# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# User specific environment and startup programs


# Added by Antigravity CLI installer
export PATH="@HOME@/.local/bin:$PATH"
. "@HOME@/.deno/env"
source @HOME@/.local/share/bash-completion/completions/deno.bash
