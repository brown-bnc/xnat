# XNAT Kubernetes Local Deployment

## Overview

### Folder Structure

- **[kustomization.yaml](./kustomization.yaml):** The Kustomize entrypoint that composes the deployment
- **[namespace.yaml](./namespace.yaml):** The namespace isolating the deployment from other locally running projects
- **[app.yaml](./app.yaml):** The manifests for the XNAT application
- **[db.yaml](./db.yaml):** The manifests for the PostgreSQL database
- **[.env.example](./env/.env.example):** The key/value pairs used to configure XNAT's runtime environment
  - *See [below](#environment-variables) for setting up the environment correctly.*
- **[ldap-provider.properties.example](./config/ldap-provider.properties.example):** The key/value pairs used to configure an LDAP authentication provider in XNAT
  - *See [below](#ldap-provider) for setting up the provider correctly.*
- **[oidc-provider.properties.example](./config/oidc-provider.properties.example):** The key/value pairs used to configure an OIDC authentication provider in XNAT
  - *See [below](#oidc-provider) for setting up the provider correctly.*

### Kustomize Overview

Kustomize composes the deployment from three manifests (`namespace.yaml`, `app.yaml`, `db.yaml`). It generates secrets from the `.env` and provider `.properties` files.

#### `kustomization.yaml`

- **`namespace`:** Applies the shared namespace to every resource in the deployment
- **`resources`:** The manifest files included in the deployment
- **`secretGenerator`:** Generates Secrets that the pods consume
  - *`environment` — from `.env`, loaded into both containers as environment variables*
  - *`auth-config` — from the LDAP and OIDC `.properties` files, mounted into the XNAT container*

#### `namespace.yaml`

- **`Namespace`:** Defines a named space that isolates the deployment's resources from other locally running projects.

#### `app.yaml`

- **`Deployment`:** Runs the locally built `xnat:local` image
  - **`imagePullPolicy: Never`:** Forces Kubernetes to use the local image instead of pulling from a registry
  - **`ports`:** The container ports exposed by XNAT
    - *Note how these match what's exposed in the project's [Dockerfile](../Dockerfile)*
  - **`envFrom`:** Loads environment variables from the generated `environment` Secret
  - **`volumeMounts`:** Mounts the LDAP and OIDC properties files from the `auth-config` Secret
  - **`startupProbe` / `readinessProbe` / `livenessProbe`:** The command used to determine whether the container is healthy
    - *Sends an HTTP request to `/` on the container's `http` port*
- **`Service`:** Defines the port mapping between the cluster and the container

#### `db.yaml`

- **`Deployment`:** Runs the prebuilt `postgres:16` image
  - **`envFrom`:** Loads environment variables from the generated `environment` Secret
  - **`volumeMounts`:** Mounts the `db-data` PersistentVolumeClaim at Postgres's data directory
  - **`readinessProbe` / `livenessProbe`:** The command used to determine whether the pod is healthy
    - *Runs `pg_isready` against the configured database*
- **`Service`:** Defines the port mapping between the cluster and the container
- **`PersistentVolumeClaim`:** Pre-defined storage request that survives pod restarts

## Setting up Kubernetes

This deployment requires [Docker](https://www.docker.com/) with Kubernetes enabled and the [kubectl](https://kubernetes.io/docs/reference/kubectl/) CLI tool to run.

>[!NOTE]
> You may prefer [minikube](https://minikube.sigs.k8s.io/docs/start/) for running Kubernetes locally instead of Docker Desktop. Both are valid options.

### Setting up Kubernetes in Docker

1. Follow the [Docker documentation](https://docs.docker.com/desktop/install) to install Docker Desktop
2. Verify the install

   ```shell
   docker --version
   ```

3. Launch Docker Desktop and wait for the engine to report *"Running"*.
4. Follow the [Docker documentation](https://docs.docker.com/desktop/use-desktop/kubernetes/#enable-kubernetes) to enable Kubernetes.
   - *We recommend using the `Kubeadm` cluster type*

### Setting up kubectl

1. Follow the [Kubernetes documentation](https://kubernetes.io/docs/tasks/tools/#kubectl) to install `kubectl`.
2. Verify the install:

   ```shell
   kubectl version --client
   ```

3. Point `kubectl` at Docker's k8s cluster:

   ```shell
   kubectl config use-context docker-desktop
   ```

4. Verify the cluster is running:

   ```shell
   kubectl cluster-info
   ```

## Setting up the Deployment

### Environment Variables

>[!WARNING]
> Environment files contain sensitive credentials that should not be added to git source control

1. The [.env.example](./env/.env) file should be copied and renamed `.env`.
2. Values for each key should be provided.

The example values listed below are safe for local testing:

```properties
# Tomcat Options
CATALINA_OPTS=

# Database Options
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=xnat_test
POSTGRES_USER=xnat
POSTGRES_PASSWORD=password

# XNAT Options
XNAT_SITE_URL=https://localhost:8080
XNAT_ADMIN_EMAIL=admin@example.com
```

### Authentication Providers

>[!WARNING]
> These files contain sensitive credentials that should not be added to git source control

#### LDAP Provider

1. The [ldap-provider.properties.example](./config/ldap-provider.properties.example) file should be copied and renamed `ldap-provider.properties`.
2. Values for each key should be provided according to the [plugin's documentation](https://wiki.xnat.org/xnat-tools/xnat-ldap-authentication-plugin).

#### OIDC Provider

1. The [oidc-provider.properties.example](./config/oidc-provider.properties.example) file should be copied and renamed `oidc-provider.properties`.
2. Values for each key should be provided according to the [plugin's documentation](https://wiki.xnat.org/xnat-tools/openid-authentication-plugin).

## Running the Deployment

### Starting the Deployment

1. The Docker images must be built with a name (`xnat:local`) for Kubernetes to run:

   ```shell
   docker build -t xnat:local .
   ```

2. Applying the kustomize file will start running the deployment.

   ```shell
   # From this directory
   kubectl apply -k .
   # From the root directory
   kubectl apply -k ./k8s
   ```

3. Forward local traffic to/from the cluster

   ```shell
   # Forward traffic on the local 8080 port to port 80 on the XNAT service
   kubectl port-forward svc/xnat 8080:80
   ```

### Stopping the Deployment

Deleting the kustomize will stop running the deployment

```shell
# From this directory
kubectl delete -k .
# From the root directory
kubectl delete -k ./k8s
```
