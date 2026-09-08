# XNAT

> [!IMPORTANT]
> XNAT requires Apache Tomcat 9, JDK 21, and PostgreSQL 12 or later. Tomcat 10 and newer is not supported.

This repository contains the files necessary to build Brown University's instance of XNAT and deploy it locally.

- The [Dockerfile](./Dockerfile) file builds XNAT as it's used at Brown University.
- The [docker/](./docker/) files deploy the image locally using Docker Compose
- The [k8s/](./k8s/) files deploy the image locally using Kubernetes

## Plugin Support

### Authentication Plugins

>[!TIP]
> For more details on setting up custom auth providers, see [XNAT's documentation](https://wiki.xnat.org/documentation/configuring-authentication-providers).

Brown University's instance of XNAT currently includes the latest versions of the OpenID and LDAP authentication plugins. Each OIDC properties file must be mounted in the `/data/xnat/home/config/auth` directory.

### XSYNC Plugins

<!-- TODO: Add information about the other supported plugins -->
<!-- TODO: How many further subsections should there be? -->

## Image Versioning and Releases

The [docker-build-push](./.github/workflows/docker-build-push.yaml) action builds the XNAT application and pushes it to Github Container Registry.

A new release should be created in GitHub in order to resolve the correct version of XNAT in GHCR. This should be done after every PR is merged into the `main` branch!

The name of the release will be used as the tag for the image and should align with the version of XNAT being used. For instance, if the current version of XNAT is `1.8.4` then the name of the release should be `1.8.4`. If a patch must be applied to an already tagged image then the name of the patch should postfix the release number. For instance `1.8.4-OIFH-plugin` add the `OIFH-plugin` with XNAT version `1.8.4`.

## Local Deployments

>[!NOTE]
> The XNAT deployments running on Brown University's infrastructure (test, QA, and production) are managed via Kubernetes in the [k8s-deploy-bke](https://github.com/brown-ccv/k8s-deploy-bke) repository. The methods listed below are intended solely for local, test deployments.

The Docker and K8s folders provide some configuration files that automatically initialize the XNAT application.

- The [docker](./docker/) folder contains files and instructions for building and deploying the XNAT application locally using Docker Compose. Additional details can be found in [DOCKER.md](./docker/DOCKER.md).
- The [k8s](./k8s/) folder contains files and instructions for building and deploying the XNAT application locally using Kubernetes. Additional details can be found in [K8S.md](./k8s/K8S.md).

### Environment Variables

- The XNAT application must be connected to a postgres database to work. The connection is defined using custom environment variables
- Providing values for the `XNAT_SITE_URL` and `XNAT_ADMIN_EMAIL` environment variables will skip the initialization page on first launch. The default username/password is `admin`/`admin`.
- Additional tomcat options are provided through environment variables

### Authentication Providers

Instructions for setting up LDAP and OIDC configuration files are provided for both the [docker](./docker/DOCKER.md#setting-up-the-deployments-authentication-providers) and [k8s](./k8s/DOCKER.md#setting-up-the-deployments-authentication-providers) deployments.
