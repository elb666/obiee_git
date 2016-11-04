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

	[[ $_rev ]] && getobjname <(git show $_rev:./"$_obj") && return
	
	_objname="$(getline2 "$_obj")"

	_objname="${_objname#*name=\"}"
	_objname="${_objname%%\"*}"

	printf "%s\n" "$_objname"
	return
}

getobjtype()  	   #@ getobjtype rpdxmlfile [git_rev]
{
	local _obj="$1"
	local _rev="$2"
	local _rpdobjtype

	[[ $_rev ]] && getobjtype <(git show $_rev:./"$_obj") && return
	
	_rpdobjtype="$(getline2 "$_obj")"
	_rpdobjtype="${_rpdobjtype#*<}"
	_rpdobjtype="${_rpdobjtype%% *}"

	printf "%s\n" "$_rpdobjtype"
	return
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
		_parent="$(getline2 <(git show "$_rev":./"$_obj"))" 
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
	elif [[ $(dirname "$(dirname "$_obj")")  = '.' ]] ; then 
		_prefix=""
	else 
		_prefix="$(dirname "$(dirname "$_obj")")/" 
	fi	
	
	_parent="$_prefix""$_parent"
	
	printf "%s\n" "$_parent"

}

getobjpar()        #@ getobjparent rpdxmlfile [git_rev]
{
	getobjparent "$@"
}

getobjparentname() #@ getobjparentname rpdxmlfile [git_rev]
{
	local _obj="$1"
	local _rev="$2"

	getobjname "$(getobjparent "$_obj" "$_rev")" "$_rev"
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
