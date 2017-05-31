#!/bin/bash
# lib-obieegit.sh

# ===================================================================== #
# Function library for OBIEE-Git related stuff
# Requires lib-rpd.sh to be in the same directory
# 
# By: Eric Brown eric_brown@harvard.edu
# Created: Fri May 20 2016
# ===================================================================== #


getfuncs()
{
	[[ $1 ]] || return
	grep -o "^.*()" $1
}

merge_a_to_b() 	#@ Usage: merge_a_to_b branchA branchB
{		#@ Merge branch A into B (no ff, no commit)
	local _branch_a="$1"
	local _branch_b="$2"

	[[ $_branch_a =~ [[:digit:]]{5} ]] && _branch_a="sisagile-$_branch_a"
	[[ $_branch_b =~ [[:digit:]]{5} ]] && _branch_b="sisagile-$_branch_b"

	git checkout "$_branch_a" 
	[[ $? != 0 ]] && return # return if checking out the branch failed
	git pull 
	git checkout "$_branch_b"
	[[ $? != 0 ]] && return # return if checking out the branch failed
	git pull 
	git merge --no-ff --no-commit "$_branch_a" 
	ogstatus
}

mergetomaster()	#@ Usage: mergetodev branch
{		#@ Merge branch into dev_master (no ff, no commit)

	merge_a_to_b $1 master
}

a_not_b()
{
	# always origin/a origin/b no matter input
	# e.g. a_not_b dev_master tst_master
	# returns all commits on dev_master that haven't gone to tst yet
	# in prep for doing merge_a_to_b
	git log origin/${2/origin\//}..origin/${1/origin\//}
}

a_not_b_fp()
{
	# always origin/a origin/b no matter input
	# e.g. a_not_b dev_master tst_master
	# returns first parent commits on dev_master that haven't 
	# gone to tst yet in prep for doing merge_a_to_b
	git log --first-parent --oneline \
		origin/${2/origin\//}..origin/${1/origin\//} 
}

a_or_b_not_c_fp()
{
	# always origin/a origin/b origin/c no matter input
	# e.g. a_not_b dev_master tst_master prod_master
	# returns first parent commits on dev_master or tst_master
	# that haven't gone to tst yet in prep for doing merge_a_to_b
	git log --first-parent --oneline \
		origin/${3/origin\//}..origin/${2/origin\//} \
		origin/${3/origin\//}..origin/${1/origin\//}
}
