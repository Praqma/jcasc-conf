#!/bin/bash

BUILD_VERSION=0
VERSION="latest"
DOWN=0
UP=0
STAGING=0
STAGING_STOP=0
SCALE=2

Usage () {
cat <<EOF

Usage:
    $0 [help|up|down|restart|staging|stop-staging] [version=<version-string>] [scale=<number of agents>]

Examples:
	$0 up version=123456 scale=1
	$0 staging version=123456

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
    version: $VERSION down:$DOWN up:$UP scale:$SCALE staging:$STAGING staging-stop:$STAGING_STOP
EOF
}

if [ $# -eq 0 ]; then
	Usage
	exit 0
fi

if [ -z $JCASC_HOME ]; then
	JCASC_HOME=$HOME/jcasc-home
fi

if [ -z $STAGING_HOME ]; then
	STAGING_HOME=$JCASC_HOME-staging
fi

export JCASC_HOME
export STAGING_HOME

if [ ! -d $JCASC_HOME ]; then
	echo Error: No directory $JCASC_HOME found
	echo \ \ Create $JCASC_HOME  
	echo \ \ or update the \$JCASC_HOME variable
	exit 1
fi

if [ ! -d $STAGING_HOME ]; then
	echo Error: No directory $STAGING_HOME found
	echo \ \ Create $STAGING_HOME  
	echo \ \ or update the \$STAGING_HOME variable
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
	staging*)
		STAGING=1
		;;
	stop-staging*)
		STAGING_STOP=1
		;;
	scale*)
		SCALE=${var##*=}
		;;
	help)
		Usage
		exit 1
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
export STAGING_VERSION=$VERSION
export CONFIG_VERSION="$(git describe --dirty) of $(git remote show origin | grep Fetch | sed 's/.*URL: //')"

set -e

if [ $DOWN -eq 1 ]; then
	echo "Stopping JCasC"
	docker-compose down
fi

if [ $UP -eq 1 ]; then
	echo "Starting JCasC:$JCASC_VERSION"
	docker-compose up -d --scale agent=$SCALE --scale staging=0
fi

if [ $STAGING -eq 1 ]; then
	echo "Creating JENKINS_HOME for staging at $STAGING_HOME"
	if [ -d $STAGING_HOME ]; then
		rm -rf $STAGING_HOME
	fi
	mkdir $STAGING_HOME
	cp -r $JCASC_HOME/. $STAGING_HOME

	echo "Copying existing config to staging_config"
	if [ -d $PWD/staging_configs/prod ]; then
		rm -rf $PWD/staging_configs/prod
	fi
	cp -r $PWD/casc_configs/. $PWD/staging_configs/prod
	
	echo "Starting staging JCasC:$STAGING_VERSION"
	docker-compose up -d staging
fi

if [ $STAGING_STOP -eq 1 ]; then
	echo "Stopping staging JCasC"
	docker-compose stop staging
	echo "Clean JENKINS_HOME for staging at $STAGING_HOME"
	rm -r $STAGING_HOME/*
fi