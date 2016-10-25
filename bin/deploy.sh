#!/bin/bash
# deploy.sh

# ===================================================================== #
# Main deployment script for OBIEE-Git 
# Requirements:
#  - Run as MW user
#  - MW_HOME must be set
#  - MW_HOME/.wl_connect must set
#      - WEBLOGIC_URL
#  - MW_HOME/.obieegit must set 
#      - BI_REPO
# 
# By: Eric Brown eric_brown@harvard.edu
# Created: Fri May 20 2016
# ===================================================================== #

usage()
{
    cat <<-EOF
	Usage: $PROGNAME [-n]
	
	Main deployment script for OBIEE-Git 
	Requirements:
	 - Run as MW user
 	 - MW_HOME must be set
	 - MW_HOME/.wl_connect must set
	   - WEBLOGIC_URL
	 - MW_HOME/.obieegit must set 
	   - BI_REPO
	Options:
	 -n	don't convert rpd
EOF
}

getoptions()
{
	OPTIND=1
	while getopts "n" OPT ; do
		case $OPT in 
		n )
			CONVERT=N
			;;
		* )
			usage
			exit $E_DEFAULT
		esac
	done

	shift $((OPTIND-1))
}

bail()
{
    echo "$1" >&2
    echo "Aborting ${PROGNAME}." >&2
    exit $2 
}

checkenv()
{
	# check MW_HOME is set
	[[ -d $MW_HOME ]] || bail "MW_HOME not set." $E_ENVIRONMENT
}
        
setglobalvars()
{
	PROGNAME="${0##*/}"
	#PROGDIR="${0%/*}"
	PROGDIR="$MW_HOME/obiee_git/bin"

	# Exit status codes:
	SUCCESS=0
	E_DEFAULT=1
	E_ENVIRONMENT=99
	E_CONVERSION=98
	E_ARGS=97
	E_DEPLOYMENT=96

	# set path to OBIEE-Git lib
	PROGLIB="$PROGDIR/../lib"
	[[ -d $PROGLIB ]] || \
		bail "Directory "$PROGLIB" must contain OBIEE-Git library"\
		$E_ENVIRONMENT

	# Set BI_REPO etc.
	. $MW_HOME/.obieegit || \
		bail "Failed to source \$MW_HOME/.obieegit." \
		$E_ENVIRONMENT

	[[ -d $BI_REPO ]] || \
		bail "BI_REPO not set. Check $MW_HOME/.obieegit." \
		$E_ENVIRONMENT

	# set default values if not already set
	CATALOG_NAME="${CATALOG_NAME:-catalog}" 
	RPD_BASE_NAME="${RPD_BASE_NAME:-rpd}"
	

	# Set WEBLOGIC_URL
	. $MW_HOME/.wl_connect || \
		bail "Failed to source \$MW_HOME/.wl_connect." \
		$E_ENVIRONMENT

	[[ $WEBLOGIC_URL ]] || \
		bail "WEBLOGIC_URL not set. Check $MW_HOME/.wl_connect." \
		$E_ENVIRONMENT
}

xmltorpd()         # xmltorpd xmldir rpd.rpd [rpd password]
{
	. $MW_HOME/instances/instance1/bifoundation/OracleBIApplication/coreapplication/setup/bi-init.sh 
	$MW_HOME/Oracle_BI1/bifoundation/server/bin/biserverxmlexec \
		-D "$1" \
		-O "$2" \
		${3:+-P $3}
}

convertxml()
{
	local _rpd="$BI_REPO/repository/$RPD_BASE_NAME.rpd"
	local _xml_dir="$BI_REPO/repository"

	echo -e "Converting xml to rpd...\n"
	xmltorpd "$_xml_dir" "$_rpd" "$RPD_PASSWORD" || \
		bail "Conversion failed." $E_CONVERSION

	echo  # need a blank line for aesthetics
}

deployrpd()
{
	local _rpd="$BI_REPO/repository/$RPD_BASE_NAME.rpd"

	# read python script into variable
	local _pythonscript="$(cat "$PROGLIB/deploytemplate.py")"

	# replace for WEBLOGIC_URL, RPD, and RPD_PASSWORD
	_pythonscript="${_pythonscript//%WEBLOGIC_URL%/$WEBLOGIC_URL}"
	_pythonscript="${_pythonscript//%RPD%/$_rpd}"
	_pythonscript="${_pythonscript//%RPD_PASSWORD%/$RPD_PASSWORD}"

	. $MW_HOME/user_projects/domains/bifoundation_domain/bin/setDomainEnv.sh
	. $MW_HOME/oracle_common/common/bin/setWlstEnv.sh
	$MW_HOME/oracle_common/common/bin/wlst.sh \
		<(printf "%s" "$_pythonscript") || \
		bail "RPD deployment failed." $E_DEPLOYMENT

	echo 
}

main()
{
	echo -e "\nStarting OG deploy.\n"
	getoptions "$@"
	checkenv
	setglobalvars

        if [[ $CONVERT = N ]]; then
		echo -e "Convert rpd bypassed.\n"
	else 
		convertxml
	fi

	deployrpd

	echo -e "OG deploy complete.\n"
	exit $SUCCESS
}

main "$@"

