#!/bin/bash

# ============================================================================ #
# Function library for OBIEE RPD XML related stuff
# 
# By: Eric Brown eric_brown@harvard.edu
# ============================================================================ #

getline2()
{
	if [[ -r $1 ]]; then
		{ read -r line; read -r line; } < $1
		printf "%s" "$line"
	fi
}

getobjname()  	   #@ getobjname rpdxmlfile [git_rev]
{
	local _obj="$1"
	local _rev="$2"
	local _objname

	[[ $_rev ]] && getobjname <(git show $_rev:./"$_obj" 2> /dev/null) && return
	
	_objname="$(getline2 "$_obj")"

	_objname="${_objname#*name=\"}"
	_objname="${_objname%%\"*}"

	printf "%s\n" "$_objname"
}

getobjtype()  	   #@ getobjtype rpdxmlfile [git_rev]
{
	local _obj="$1"
	local _rev="$2"
	local _rpdobjtype

	[[ $_rev ]] && getobjtype <(git show $_rev:./"$_obj" 2> /dev/null) && return
	
	_rpdobjtype="$(getline2 "$_obj")"
	_rpdobjtype="${_rpdobjtype#*<}"
	_rpdobjtype="${_rpdobjtype%% *}"

	printf "%s\n" "$_rpdobjtype"
}

getobjparent() 	   #@ getobjparent rpdxmlfile [git_rev]
{		   #@ Returns relative path to parent obj
                   #@ Returns null if the obj has no parent such as for a user

	local _obj="$1"
	local _rev="$2"

	local _objtype
	local _line2
	local _lookfor  
	local _parent   

	local _objtype="$(getobjtype "$_obj" "$_rev")"
	[[ $_objtype ]] || return 1

	# different object types have different parent types
	# this is what to look for in the xml to identify the parent
	case "$_objtype" in
	PhysicalCatalog | \
	PhysicalTable | \
	PresentationHierarchy | \
	PresentationTable | \
	Schema )
		_lookfor="containerRef"
		;;
	InitBlock )
		_lookfor="connectionPoolRef"
		;;
	ConnectionPool | \
	PhysicalDisplayFolder )
		_lookfor="databaseRef"
		;;
	Variable )
		_lookfor="initBlockRef"
		;;
	LogicalTableSource )
		_lookfor="logicalTableRef"
		;;
	ObjectPrivilege )
		_lookfor="privilegePackageRef"
		;;
	PrivilegePackage )
		_lookfor="roleRef"
		;;
	Dimension | \
	LogicalTable | \
	PresentationCatalog )
		_lookfor="subjectAreaRef"
		;;
	* )
	 	return ## obj doesn't have a parent	
		;;
	esac
 
	if [[ $_rev ]]; then
		_parent="$(getline2 <(git show "$_rev":./"$_obj" 2> /dev/null))"
	else
		_parent="$(getline2 "$_obj")" 
	fi

	# some objects e.g. variables don't always have parents so check
	# first. if _lookfor is in line2, then there is a parent. else 
	# return
	[[ $_parent =~ $_lookfor ]] || return

	# trim everything upto and including _lookfor="
	_parent="${_parent#*$_lookfor=\"}"
	# '#' terminates the parent, so trim everything from # to the end
	_parent="${_parent%%#*}"
	# trim so we just have the basename and directory name
	_parent="${_parent##*/base/}"

	# now adjust the _parent so it points relatively to _obj
	if [[ $(dirname "$_obj") == '.' ]]; then 
		_prefix="../"
	elif [[ $(dirname "$(dirname "$_obj")") == '.' ]] ; then 
		_prefix=""
	else 
		_prefix="$(dirname "$(dirname "$_obj")")/" 
	fi	
	
	printf "%s\n" "$_prefix$_parent"

}

getobjpar()        #@ getobjparent rpdxmlfile [git_rev]
{
	getobjparent "$@"
}

getobjparentname() #@ getobjparentname rpdxmlfile [git_rev]
{
	getobjname "$(getobjparent "$1" "$2")" "$2"
}

getobjpname()      #@ getobjpname rpdxmlfile [git_rev]
{
	getobjparentname "$@"
}

getobjqualifiedname() #@ getobjqualifiedname rpdxmlfile [git_rev]
{                     #@ returns "parent"."name" or "name" if no parent
	local _obj="$1"
	local _rev="$2"

	_objname="$(getobjname "$_obj" "$_rev")"
	_pname="$(getobjpname "$_obj" "$_rev")"

	# if len(_objname)>0 then put it in quotes
	_objname="${_objname:+\"$_objname\"}"
	# if len(_pname)>0 then put it in quotes and add a dot
	_pname="${_pname:+\"$_pname\".}"

	printf "%s%s\n" "$_pname" "$_objname"
}

getobjqname()      #@ getobjparentname rpdxmlfile [git_rev]
{
	getobjqualifiedname "$@"
}

getobjfullname()   #@ getobjfullname rpdxmlfile [git_rev]
{		   #@ Returns fully qualified name

        ! [[ "$1" ]] && return
	
	local _obj="$1"
	local _rev="$2"

	_objname="$(getobjname "$_obj" "$_rev")"
	_parent="$(getobjparent "$_obj" "$_rev")"

	# put the name in quotes
	_objname="\"$_objname\""

	while [[ $_parent ]] ; do
		_parentname="$(getobjname "$_parent" "$_rev")"
		# prepend parentname (in quotes) to objname
		_objname="\"$_parentname\".$_objname"

		# get the parent's parent for loop
		_parent="$(getobjparent "$_parent" "$_rev")"
	done

	printf "%s\n" "$_objname"
}

getobjfname()      #@ getobjfname rpdxmlfile [git_rev]
{
	getobjfullname "$@"
}

isreorder()        #@ isreorder file1 file2
{                  #@ returns 0 if file1 is just a reorder of file2
                   #@ returns 1 otherwise
	diff -q <(sort "$1") <(sort "$2") > /dev/null
}

extractobj()
{
	# this matches the format of paths to rpd xml 
	_regexp="[[:graph:]/]*[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}\\.xml"

	[[ $1 =~ $_regexp ]] && printf '%s' "${BASH_REMATCH[0]}"
}

replacepathwobjqname()
{
	line="$1"
	commit="$2"

	_obj="$(extractobj "$line")"	
	_objqname="$(getobjqname $_obj $commit)"

	line="${line/$_obj/$_objqname}"

	printf '%s\n' "$line"
}

getreporoot()     # returns repo root if in git repo; else nothing
{
	git rev-parse --show-toplevel 2> /dev/null
}

clearreorders() 
{
	local _repo_root

	_repo_root=$(getreporoot)
	if [[ $_repo_root ]]; then
		cd $_repo_root || return 1
	else
		echo "$FUNCNAME must be run in a git repo"
		return 1
	fi
	
	# Read filenames of modified repository files from git diff
	while read -r file_status test_file ; do

		# we only need to test M[odified] files
		[[ $file_status = M ]] || continue

	        # if it is the same as the original when reordered, then go checkout the original
	        if isreorder <(git show HEAD:$test_file) $test_file ;  then
		        echo "Resetting" $(getobjtype $test_file) $(getobjqname $test_file)
                        git checkout HEAD -- $test_file;
                fi

        done < <( git status --porcelain -- repository/oracle )
} 

cleargroups()
{
	local _repo_root

	_repo_root=$(getreporoot)
	if [[ $_repo_root ]]; then
		cd $_repo_root || return 1
	else
		echo "$FUNCNAME must be run in a git repo"
		return 1
	fi
	
	git reset -- repository/oracle/bi/server/base/Group
	git clean -fd -- repository/oracle/bi/server/base/Group
	git co HEAD -- repository/oracle/bi/server/base/Group
}

clearvariables()
{
	local _repo_root

	_repo_root=$(getreporoot)
	if [[ $_repo_root ]]; then
		cd $_repo_root || return 1
	else
		echo "$FUNCNAME must be run in a git repo"
		return 1
	fi
	
	git co HEAD -- repository/oracle/bi/server/base/Variable
}

clearvars()
{
	clearvariables "$@"
}
