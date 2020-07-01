#!/bin/bash

BUILD_VERSION=0
VERSION="latest"
DOWN=0
UP=0
SCALE=2
HELP=0

Usage () {
cat <<EOF

Usage:
    $0 [help] [up] [down] [restart] [version=<version-string>] [scale=<number of agents>]

EOF
}

Empty () {
cat <<EOF

The image version is missing

Is JENKINS_RUNNER = $JENKINS_RUNNER a valid environment variable

Is there a valid password in $HOME/.ssh/$JENKINS_RUNNER.password

Does $JENKINS_RUNNER have read access to Artifactory Docker

What is the result of docker login?

EOF
}

Info () {
cat <<EOF
    version: $VERSION down:$DOWN up:$UP scale:$SCALE
EOF
}

if [ $# -eq 0 ]; then
	Usage
	exit 0
fi

if [ -z $JCASC_HOME ]; then
	JCASC_HOME=$HOME/jcasc-home
fi

export JCASC_HOME

if [ ! -d $JCASC_HOME ]; then
	echo Error: No directory $JCASC_HOME found
	echo \ \ Create $JCASC_HOME  
	echo \ \ or update the \$JCASC_HOME variable
	exit 1
fi

for var in "$@"; do
    echo "$var"
	case $var in
	up)
		UP=1
		;;
	down)
		DOWN=1
		;;
	restart)
		DOWN=1
		UP=1
		;;
	version*)
		VERSION=${var##*=}
		BUILD_VERSION=1
		;;
	scale*)
		SCALE=${var##*=}
		;;
	help)
		HELP=1
		;;
	*)
		Usage
		exit 1
		;;
	esac
done

Info

if [ -z $VERSION ]; then
	Empty
	exit 1
fi

export JCASC_VERSION=$VERSION
export CONFIG_VERSION="$(git describe --dirty) of $(git remote show origin | grep Fetch | sed 's/.*URL: //')"

set -e

if [ $DOWN -eq 1 ]; then
	echo "Stopping jCasC"
	docker-compose down
fi

if [ $UP -eq 1 ]; then
	echo "Starting jCasC:$JCASC_VERSION"
	docker-compose up -d --scale agent=$SCALE
fi