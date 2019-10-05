#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`
set -e

usage(){
	echo "
Options:
  -h,--help       show this message
  -v,--verbose    increase verbose level
"
}

init(){
	sudo true
	[[ -e "/etc/os-release" ]] && source /etc/os-release || ID=""
}

parse_args(){
	while [[ "$#" -gt 0 ]]; do
		case $1 in
			-h|--help) usage; exit 0 ;;
			-v) set -x; VERBOSE="-v" ;;
			*) echo "unknown arg: $1"; usage; exit 1 ;;
		esac
		shift
	done
}

run(){
	REBOOT="0"
	[[ -z "$ID" ]] && echo "[FATAL] Could not find the OS name" && exit 1
	if [ -e "$SCRIPT_DIR/${ID}-${VARIANT_ID}" ]; then
		ID="${ID}-${VARIANT_ID}"
	fi
	if [ -e "$SCRIPT_DIR/${ID}" ]; then
		$SCRIPT_DIR/$ID/run.sh
	else
		echo "[ERROR] The $ID distribution is not supported"
		exit 1
	fi
	setup_docker
	setup_user_and_groups
	setup_skwr

	echo;echo "[Host setup completed]"
	echo

	if [[ "$REBOOT" != "0" ]]; then
		echo "Rebooting ..."
		sleep 5
		sudo reboot
	fi
}

setup_docker(){
	echo; echo "[Configuring docker]"
	if [[ `ps -fu root | grep -c "/dockerd "` = "0" ]]; then
		echo "  - Activating dockerd"
		sudo systemctl start docker
		sudo systemctl enable docker
	fi
	if [[ `egrep -c ^docker: /etc/group` = "0" ]]; then
		echo "  - Creating docker group"
		egrep -q "^docker:" /etc/group || groupadd docker
	fi
	if [ `groups | tr ' ' '\n' | egrep -c "^docker$"` = "0" ]; then
		echo "  - Adding user to docker group"
		sudo usermod -aG docker $USER
		REBOOT=1
	fi
}

setup_skwr(){
	SKWR_DIR=`cd $SCRIPT_DIR/../..; pwd`
	if [[ -L "/usr/local/bin/skwr" ]]; then
		sudo rm -f "/usr/local/bin/skwr"
	fi
	sudo ln -s "$SKWR_DIR/bin/skwr.sh" "/usr/local/bin/skwr"
	for D in /usr/share/bash-completion/completions; do
		if [[ -d "$D" ]];then
			[[ -h "$D/skwr" ]] && sudo rm $D/skwr || true
			sudo ln -s $SKWR_DIR/etc/skwr.completion $D/skwr || echo "Cannot install bash auto-completion"
		fi
	done
}

# Setup users
setup_user_and_groups(){
        echo;echo "[User and group config]"
        if [ `egrep -c "^skwr:" /etc/group` = "0" ]; then
                echo "  - Creating skwr group"
                sudo groupadd -g 9999 skwr
        fi

        # Setup user
        if [ `groups | tr ' ' '\n' | egrep -c "^skwr$"` = "0" ]; then
                echo "  - Adding user to skwr"
				USER_GROUPS=`groups | sed 's:  *:,:g'`
                sudo usermod -g skwr $USER
				sudo usermod -G "$USER_GROUPS" $USER
				REBOOT=1
        fi
        echo "  - User and group configured"
}

init
parse_args $*
run
