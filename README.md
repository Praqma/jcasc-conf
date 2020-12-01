# jcasc-conf
Wrapper for running Jenkins with prebuilt docker images with JCasC

## How to use

[docker-compose.yml](docker-compose.yml) refers to images available in DockerHub, to start up your Jenkins simply pull the repository and run

```
./jcasc.sh up
```

It will use the latest version of jcasc and jcasc-agent images from DockerHub. But it is also possible, and recommended, to always specify which version of the image you want to use. You can also specify how many jcasc-agent based containers you want to use to serve as build agents, e.g.

```
./jcasc.sh up version=sha-8ddfdb5 scale=3
```

To change the configuration edit/add yaml file in casc_config folder on the machine where you run your Jenkins and reload configuration using JCasC.
Details about JCasC available [here](https://github.com/jenkinsci/configuration-as-code-plugin)

### Staging

When you want to update your Jenkins you need to build your new image with desired version of Jenkins and plugins (using [Praqma/jcasc-core](https://github.com/Praqma/jcasc-core) if you rely on default solution for this repo) and restart your Jenkins.

In the end, a full Jenkins version and plugins upgrade may require multiple restarts and there is no guarantee everything will work without a problem. 

Simple staging solution, implemented in this repository, let's you run a separate Jenkins instance, next to existing one. It reuses JENKINS_HOME and configuration files (so out of the box it won't work if you run on a separate machine) and starts up in a quiet mode - which means no jobs will start. 

When starting staging, existing JENKINS_HOME content is copied from the location $JCASC_HOME variable points to, to $STAGING_HOME (that will point to $JCASC_HOME-staging unless you set it up in advance)

To run staging Jenkins:

```
./jcasc.sh staging version=sha-8ddfdb5
```

You can use it to manually upgrade all the plugins and generate a new plugins_extra.txt file that you can use to build your new Jenkins image or confirm the existing configuration is compatible with plugins or Jenkins after upgrade.

Once you're done make sure to preserve the new configuration (from `staging_configs/prod` folder) since the content of the file will now be kept.

To stop the staging Jenkins:

```
./jcasc.sh stop-staging
```

### Login credentials

Check [docker-compose.yml](docker-compose.yml) to learn what are the username (JENKINS_RUNNER) and password (JENKINS_PASSWORD) of the Jenkins user. That is just a basic and rather unsecure example where empty environment variables take default values. There are of course much more safe ways of doing that. More details later.

## Where do the images come from?

In a [Praqma/jcasc-core](https://github.com/Praqma/jcasc-core) you can find Dockerfiles for both Jenkins and build agent. Every time new commits appear on master the images are build and pushed to DockerHub - you can always check the latest released version there:
* https://hub.docker.com/repository/docker/praqma/jcasc/tags?page=1
* https://hub.docker.com/repository/docker/praqma/jcasc-agent/tags?page=1
