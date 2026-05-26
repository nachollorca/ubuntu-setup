starship init fish | source
zoxide init fish | source
abbr -a ls 'eza -la'
abbr -a cd 'z'
alias oc="opencode"
alias pi="pi --theme ~/.pi/catppuccin-mocha.json"
set -gx fish_user_paths ~/.local/bin $fish_user_paths
set -x EDITOR micro

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv fish)"

function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	command yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end

# Start SSH agent if not running
if not set -q SSH_AUTH_SOCK
    eval (ssh-agent -c) > /dev/null
    ssh-add ~/.ssh/gh 2>/dev/null
end
