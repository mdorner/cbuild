#!/usr/bin/env sh

usage()
{
	[ "x$#" != "x0" ] &&  echo "$@"
	cat <<- CBUILD_HELP
	cbuild        -- a simple script helper around cmake with git

	Commands:

	clean          -- clean all build-artefacts from the current build
	configure      -- set configurations via cmake (forwards all args)
	help           -- show this help dialog
	make           -- invoke the configured make-program (forwards all args)
	show           -- show environment and derived variables
	CBUILD_HELP
	exit 1
}

is_zero()
{
	[ "x$1" = "x0" ] && return 0 || return 1
}

load_git_vars()
{
	: ${GIT_ROOT:="$(git rev-parse --show-toplevel)"}
	is_zero $? || return 1
	GIT_BRANCH="$(git symbolic-ref --short HEAD)"
	GIT_TAG="$(git describe --abbrev=0 2>/dev/null)"
	is_zero $? || GIT_TAG="0.0"
	GIT_COMMIT_NR="$(git log --pretty=oneline | wc -l)"
	return 0
}

load_buildenv()
{
	: ${RELATIVE_BUILD_PATH:=".build"}
	load_git_vars
	BUILD_SUFFIX="$(echo "$GIT_BRANCH" | sed 's|/|-|g')"
	CURRENT_DIR="$(realpath "$PWD")"
	while [ "x$CURRENT_DIR" != "x/" ]; do
		[ -f "$CURRENT_DIR/CMakeLists.txt" ] && : ${MAKE_DIR:=$CURRENT_DIR}
		CURRENT_PARENT="$(dirname "$CURRENT_DIR")"
		if [ -f "$CURRENT_PARENT/CMakeLists.txt" ]; then
			CURRENT_DIR="$CURRENT_PARENT"
		else
			break
		fi
	done
	PROJECT_ROOT="$CURRENT_DIR"
	unset CURRENT_PARENT
	unset CURRENT_DIR

	BUILD_ROOT="$PROJECT_ROOT/$RELATIVE_BUILD_PATH"
	CMAKE_PROJECT_FILE="$PROJECT_ROOT/CMakeLists.txt"
	BUILD_DIR="$BUILD_ROOT/$BUILD_SUFFIX"
	[ -z "$PROJECT_ROOT" ] || [ ! -f "$CMAKE_PROJECT_FILE" ] && return 1
	[ -d "$BUILD_DIR" ] || mkdir -p "$BUILD_DIR" || return 1
	MAKE_DIR="$(realpath "$BUILD_DIR/${MAKE_DIR##$PROJECT_ROOT}")"
	MAKE_PROG="$(cd "$BUILD_DIR" && cmake -LA "$PROJECT_ROOT" | grep -e "^CMAKE_MAKE_PROGRAM" | cut -d '=' -f 2)"
	return 0
}

main()
{
	[ "x${DEBUG:-0}" = "x1" ] && set -o xtrace
	[ "x$#" = "x0" ] && usage "No arguments provided"
	case $1 in
		-h | --h* | help) usage;;
	esac

	load_buildenv "$PWD" || exit 1

	case $1 in
		clean)
			shift
			echo "Now removing all of $BUILD_DIR"
			rm -rf "$BUILD_DIR";;
		conf*) # configure
			shift
			case $1 in
				-h | --help) cmake --help && exit $?
			esac
			(cd "$BUILD_DIR" && cmake $@ "$PROJECT_ROOT");;
		make)
			shift
			[ -d "$MAKE_DIR" ] \
				&& (cd $MAKE_DIR && $MAKE_PROG $@) \
				||(cd "$BUILD_DIR" && $MAKE_PROG $@)
			ln -s "$BUILD_DIR" "$BUILD_ROOT/latest";;
		show)
			shift
			while [ "x$#" != "x0" ]; do
				echo $(set | grep -e "^$1=" | sed "s|$1=||g")
				shift
			done;;
		*) # undefined
			usage "Unknown command: $@";;
	esac
	exit $?
}

[ "x${LOAD_LIB:-0}" != "x1" ] && main $@
