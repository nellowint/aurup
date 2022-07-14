_aurup_complete() {
	local cur prev letters words
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    letters="-S -R -Ss -Sy -L -h -U -V"
    words="--sync --remove --search --update --list --help --uninstall --version"

	case "$cur" in
		--*) COMPREPLY=( $( compgen -W "$words" -- $cur ) );;
		-*) COMPREPLY=( $( compgen -W "$letters" -- $cur ) );;
	esac
	return 0
}

complete -F _aurup_complete -o filenames aurup