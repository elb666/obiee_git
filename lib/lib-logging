#!/bin/bash
# these settings can and should be overridden by the calling program
export PROGNAME="${PROGNAME:-defaultprogname}"
export LOGDIR="${LOGDIR:-/tmp}"
export ECHO_LOG_MESSAGE="${ECHO_LOG_MESSAGE:-N}"

# these cannot be overridden by the calling program
export LOGPREFIX="$PROGNAME"
export LOGFILE="$LOGDIR/${LOGPREFIX}.$(date +%Y%m%d).log"
export DATE_FMT="+%b %d, %Y %T %p %Z"
export DAYS=90
	
# create LOGDIR if not exists
if ! [[ -d $LOGDIR ]]; then
	echo -n "Log directory $LOGDIR does not exist. Creating..."
	mkdir -p $LOGDIR 
	if [[ $? != 0 ]]; then
		echo -e "\n\nERROR: failed to create log directory $LOGDIR\n" 2>&1
		exit 1
	else
		echo -e "done.\n"
	fi	
fi

# Remove log files older than $DAYS
find $LOGDIR/* -name "$LOGPREFIX*.log"  -mtime +${DAYS} -type f \
	-exec /bin/rm -f {} \; > /dev/null 2>&1

__logmessage()
{
	local _nl=$'\n'

	local _message_type="$1"
	shift
	local _message_body="$@"

	if [[ $_message_body = "-" ]] || [[ $_message_body = "" ]]; then
		while read -r line; do
			_message_body="$_message_body$_nl$line"
		done
	fi

	local _message="[$(date)] [$PROGNAME] [$_message_type] [[$_message_body]]"

	if [[ $ECHO_LOG_MESSAGE = Y ]]; then 
		if [[ $_message_type = ERROR ]]; then
			echo "$_message" | tee -a "$LOGFILE" >&2
		else
			echo "$_message" | tee -a "$LOGFILE"
		fi
	else
		echo "$_message" >> "$LOGFILE"
	fi
}

logerror()
{
	__logmessage ERROR "$@"
}

loginfo()
{
	__logmessage INFO "$@"
}
