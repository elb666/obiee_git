#!/bin/bash
# precommit.sh

# ======================================================================= #
# Pre-commit script for OBIEE-Git 
# Requirements:
#  - Run as MW user
#  - MW_HOME must be set
#  - MW_HOME/.obieegit must set 
#      - BI_REPO 
# 
# By: Eric Brown eric_brown@harvard.edu
# Created: Fri May 20 2016
# ======================================================================= #

usage()
{
    cat <<-EOF
	Usage: $PROGNAME
	
	Precommit script for OBIEE-Git 
	Requirements:
	 - Run as MW user
 	 - MW_HOME must be set
	 - MW_HOME/.obieegit must set 
	   - BI_REPO
	 - MW_HOME/.obieegit can optionally set 
	   - RPD_PASSWORD
           - else user will be prompted for RPD password
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
			exit $E_ARGS
		esac
	done

	shift $((OPTIND-1))
}

bail()
{
	echo "ERROR: " "$1" >&2
	echo "Aborting ${PROGNAME}." >&2
	exit ${2:-$E_DEFAULT}
}

checkenv()
{
	# check MW_HOME is set
	[[ -d $MW_HOME ]] || bail "MW_HOME not set." $E_ENVIRONMENT
}
        
setglobalvars()
{
	PROGNAME="${0##*/}"
	PROGDIR="${0%/*}"

	# Exit status codes:
	SUCCESS=0
	E_DEFAULT=1
	E_ENVIRONMENT=99
	E_CONVERSION=98
	E_ARGS=97

	# Set BI_REPO etc.
	. $MW_HOME/.obieegit || \
		bail "Failed to source \$MW_HOME/.obieegit." \
		$E_ENVIRONMENT

	[[ -d $BI_REPO ]] || \
		bail "BI_REPO not set. Check $MW_HOME/.obieegit" \
		$E_ENVIRONMENT

	# set default values if not already set
	CATALOG_NAME="${CATALOG_NAME:-catalog}" 
	RPD_BASE_NAME="${RPD_BASE_NAME:-rpd}"

}

rpdtoxml()         # rpdtoxml rpd.rpd xmldir [rpd password]
{
	. $MW_HOME/instances/instance1/bifoundation/OracleBIApplication/coreapplication/setup/bi-init.sh 
	$MW_HOME/Oracle_BI1/bifoundation/server/bin/biserverxmlgen \
		-R "$1" \
		-D "$2" \
		${3:+-P $3}
}
convertnewestrpd()
{
	local _rpd

	echo -e "Getting online rpd...\n"
	read -r _rpd < <(ls -1t $MW_HOME/instances/instance1/bifoundation/OracleBIServerComponent/coreapplication_obis1/repository/*.rpd)

	# if BI_REPO/repository doesn't exist, create it
	if ! [[ -d $BI_REPO/repository ]]; then
		echo -e "Directory $BI_REPO does not exist. Creating...\n"
		mkdir "$BI_REPO/repository"
	fi

	echo -e "Converting rpd to xml...\n"
	rpdtoxml "$_rpd" "$BI_REPO/repository/" "$RPD_PASSWORD" || \
	            bail "Conversion failed." $E_CONVERSION

	echo  # blank line for aesthetics
}

main()
{
	echo -e "\nStarting OG precommit.\n"
	getoptions "$@"
        checkenv
        setglobalvars

        if [[ $CONVERT = N ]]; then
		echo -e "Convert rpd bypassed.\n"
	else 
		convertnewestrpd
	fi

	echo -e "OG precommit complete.\n"
	exit $SUCCESS
}


main "$@"

