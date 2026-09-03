_aurup_complete() {
	local cur letters words op i
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	letters="-S -R -Ss -Sy -L -c -h -V"
	words="--sync --remove --search --update --list --clear --help --version"
	local cache="$HOME/.aurup/package_list.txt"

	for (( i=1; i<COMP_CWORD; i++ )); do
		case "${COMP_WORDS[i]}" in
			-S|--sync) op="sync" ;;
			-Ss|--search) op="search" ;;
			-R|--remove) op="remove" ;;
		esac
	done

	case "$cur" in
		--*) COMPREPLY=( $( compgen -W "$words" -- "$cur" ) ) ;;
		-*) COMPREPLY=( $( compgen -W "$letters" -- "$cur" ) ) ;;
		*)
			case "$op" in
				sync)   COMPREPLY=( $( compgen -G "${cur}*.tar.gz" ) )
						[[ -z "$COMPREPLY" ]] && [[ -f "$cache" ]] &&
							COMPREPLY=( $( awk -v p="$cur" 'index($0,p)==1' "$cache" ) ) ;;
				search) [[ -f "$cache" ]] && COMPREPLY=( $( awk -v p="$cur" 'index($0,p)==1' "$cache" ) ) ;;
				remove) COMPREPLY=( $( pacman -Qm 2>/dev/null | cut -d' ' -f1 | awk -v p="$cur" 'index($0,p)==1' ) ) ;;
				*)      COMPREPLY=( $( compgen -W "$letters" -- "$cur" ) ) ;;
			esac
			;;
	esac
	return 0
}

complete -F _aurup_complete -o filenames aurup