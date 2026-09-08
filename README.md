# XNAT

> [!IMPORTANT]
> XNAT requires Apache Tomcat 9, JDK 21, and PostgreSQL 12 or later. Tomcat 10 and newer are not supported.

This repository contains the files necessary to build Brown University's instance of XNAT and deploy it locally.

- The [Dockerfile](./Dockerfile) builds XNAT as it's used at Brown University
- The [docker/](./docker/) files deploy the image locally using Docker Compose
- The [k8s/](./k8s/) files deploy the image locally using Kubernetes

## Plugin Support

>[!WARNING]
> Plugin versions must be compatible with the XNAT version being built. Update versions in the [Dockerfile](./Dockerfile) when upgrading XNAT.

XNAT plugins are installed directly into the Docker image during build time.The [Dockerfile](./Dockerfile) installs the plugins towards the end of the file.

### Authentication Plugins

>[!TIP]
> For more details on setting up custom auth providers, see [XNAT's documentation](https://wiki.xnat.org/documentation/configuring-authentication-providers).

The authentication providers available to users for logging into the portal. Each provider's properties file must be mounted in the `/data/xnat/home/config/auth` directory.

- **[LDAP](https://wiki.xnat.org/xnat-tools/xnat-ldap-authentication-plugin):** Authenticates users against an external LDAP directory
- **[OpenID](https://wiki.xnat.org/xnat-tools/openid-authentication-plugin):** Authenticates users through OIDC identity providers

### Imaging & Workflow Plugins

- **[OHIF Viewer](https://wiki.xnat.org/xnat-ohif-viewer):** Web viewer for DICOM images within XNAT
- **[DICOM Query/Retrieve](https://wiki.xnat.org/xnat-tools/dicom-query-retrieve-plugin):** Queries and pulls studies from remote DICOM nodes via C-FIND and C-MOVE
- **[Container Service](https://wiki.xnat.org/container-service):** Runs containerized processing pipelines against XNAT data
- **[Pipeline Engine UI](https://wiki.xnat.org/xnat-tools/xnat-pipeline-engine-plugin):** Web interface for configuring and launching XNAT's pipeline engine
- **[Batch Transfer](https://github.com/NrgXnat/batch-transfer-plugin/blob/main/README.md):** Uploads and transfers imaging sessions to XNAT in bulk

## Image Versioning and Releases

The [docker-build-push](./.github/workflows/docker-build-push.yaml) action builds the XNAT application and pushes it to GitHub Container Registry.

A new release should be created in GitHub in order to resolve the correct version of XNAT in GHCR. This should be done after every PR is merged into the `main` branch!

The name of the release will be used as the tag for the image and should align with the version of XNAT being used. For instance, if the current version of XNAT is `1.8.4` then the name of the release should be `1.8.4`. If a patch must be applied to an already tagged image then the name of the patch should postfix the release number. For instance, `1.8.4-OIFH-plugin` adds the `OIFH-plugin` to XNAT version `1.8.4`.

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

Instructions for setting up LDAP and OIDC configuration files are provided for both the [docker](./docker/DOCKER.md#authentication-providers) and [k8s](./k8s/K8S.md#authentication-providers) deployments.
