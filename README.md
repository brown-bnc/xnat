# XNAT Cluster

This repository contains the files necessary to build, and test-deploy Brown
University's instance of XNAT to the SciDMZ cluster.

The `Dockerfile` builds XNAT as it's used at Brown University.

XNAT requires Apache Tomcat version 9, JDK 1.8, and Postgresql 10. No other
versions are supported.

This repository provides two ways of running development versions of XNAT,
via Docker Compose or Kubernetes. Neither the `kustomization.yaml` nor the `docker-compose.yaml` provided in this repository are used in production. They were used only for testing purposes.
Our deployment of the production instance in done via kubernetes and managed in [this repo](https://github.com/brown-ccv/k8s-deploy-bke)

## Image Versioning and Releases

There is a GitHub Action that builds the `Dockerfile`. After merging to the `main` branch, please tag a new release. The release name will be used as the tag for the image. The practice is to align with the version of xnat being used. For instance, release number `1.8.4`, means we used XNAT version `1.8.4`. If a patch is needed on our image for an already tagged version, just spell the patch. For instance `1.8.4-OIFH-plugin` add the `OIFH-plugin` with XNAT version `1.8.4`.

## Local Testing

### Automatic Initialization

If you want to skip the initialization page on first launch, provide both `$XNAT_SITE_URL` and `$XNAT_ADMIN_EMAIL` when starting XNAT. The default username/password will still be `admin:admin`. If you've provided an LDAP configuration, the automatic initialization will enable your LDAP provider.

### Authentication Providers

For more details on setting up custom auth providers, see [XNAT's documentation](https://wiki.xnat.org/documentation/configuring-authentication-providers).

#### Authentication Providers: LDAP

Multiple unique LDAP providers are supported. Each LDAP properties file must be mounted in the `/data/xnat/home/config/auth` directory.

For an example of an LDAP provider configuration file, see [ldap-provider.properties.example`](./config/ldap-provider.properties.example).

#### Authentication Providers: OIDC

Each OIDC properties file must be mounted in the `/data/xnat/home/config/auth` directory.

For an example of an OIDC provider configuration file, see [oidc-provider.properties.example`](./config/oidc-provider.properties.example).

## Local Building & Deployments

> [!IMPORTANT]
> The QA and production instances of the application are deployed on Brown's infrastructure and managed in the [BKE repository](https://github.com/brown-ccv/k8s-deploy-bke). The methods listed below are intended solely for ensuring the image builds correctly.

### Docker Compose Deployment

The [docker-compose.yaml](./docker-compose.yaml) file contains the necessary information to build the Docker image and connect it to a locally running database. The XNAT application is built as the `xnat-web` service.

To build the Docker image run:

```shell
# Build the images
docker-compose build
# Start the compose stack
docker-compose up
# Bring down the compose stack
docker-compose down
```

### Kubernetes Deployment

#### Enabling Minikube

`minikube` is a useful tool for initializing a local instance of kubernetes. See [this guide](https://minikube.sigs.k8s.io/docs/start/) to get it set up. Once installed, start the cluster and ensure ingress controllers are enabled:

```shell
minikube start --kubernetes-version=v1.18.10 --driver=hyperkit
minikube addons enable ingress
```

#### Run the kubernetes deployment

To build the docker image for Kubernetes run:

```shell
docker build -t xnat:local .
```

To run the Kubernetes deployment run:

```shell
kubectl apply -k .
```

This will set up XNAT with all the fixings, including a local database.

- `app.yaml` contains the manifests related to XNAT
- `db.yaml` contains the manifests for the database.
- `namespace.yaml` contains the manifest for the project's namespace
  - This ensures the project never conflicts with any other locally running projects

Kubernetes offers a method of forwarding traffic to and from the cluster. This command will forward `localhost:8080` traffic to the XNAT service within the Kubernetes cluster. From there the service will forward the traffic to the deployment.

```shell
kubectl port-forward svc/xnat 8080:80
```

You should now be able to use `xnat.local` to access your XNAT deployment.
