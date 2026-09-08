# XNAT Docker Local Deployment

## Overview

### Folder Structure

- **[docker-compose.yaml](./docker-compose.yaml):** The services that are part of the XNAT application
  - *A more detailed explanation of the file is provided [below](#docker-compose-overview)*
- **[.env.example](./env/.env.example):** The key/value pairs used to configure XNAT's runtime environment
  - *See [below](#environment-variables) for setting up the environment correctly.*
- **[ldap-provider.properties.example](./config/ldap-provider.properties.example):** The key/value pairs used to configure an LDAP authentication provider in XNAT
  - *See [below](#ldap-provider) for setting up the provider correctly.*
- **[oidc-provider.properties.example](./config/oidc-provider.properties.example):** The key/value pairs used to configure an OIDC authentication provider in XNAT
  - *See [below](#oidc-provider) for setting up the provider correctly.*

### Docker Compose Overview

The compose file defines two services: `xnat-web` (the XNAT application) and `postgres` (its database).

#### `xnat-web`

- **`build`:** Build the image locally from the project's [Dockerfile](../Dockerfile)
  - *Alternatively, `image` defines a prebuilt image to use*
- **`ports`:** The `host`:`container` port mappings
  - *Note how these ports match what's exposed in the project's [Dockerfile](../Dockerfile)*
- **`env_file`:** The path of file(s) containing environment variables loaded into the container
- **`volumes`:** The `host`:`container` path of file(s) mounted into the container
  - *Adds the plugin config files*
- **`depends_on`:** Tells the service to wait for the `postgres` service to pass its healthcheck before starting
- **`healthcheck`:** The command used to determine whether the container is healthy
  - *curls the website on localhost*

#### `postgres`

- **`image`:** The prebuilt postgres image to download and use
- **`env_file`:** The path of file(s) containing environment variables loaded into the container
- **`healthcheck`:** The command used to determine whether the container is healthy
  - *Runs `postgres`'s internal healthcheck*

## Setting up Docker

This deployment requires [Docker](https://www.docker.com/) with Docker Compose to run. Docker Desktop bundles both and is the recommended tool.

>[!NOTE]
> Linux users may prefer [Docker Engine](https://docs.docker.com/engine/install/) with the [Compose plugin](https://docs.docker.com/compose/install/linux/) instead of Docker Desktop.

1. Follow the [Docker documentation](https://docs.docker.com/desktop/install) to install Docker Desktop
2. Verify the install

   ```shell
   docker --version
   docker compose version
   ```

3. Launch Docker Desktop and wait for the engine to report *"Running"*.

## Setting up the Deployment

### Environment Variables

>[!WARNING]
> Environment files contain sensitive credentials that should not be added to git source control

1. The [.env.example](./env/.env.example) file should be copied and renamed `.env`.
2. Values for each key should be provided.

The example values listed below are safe for local testing:

```properties
# Tomcat Options
CATALINA_OPTS=

# Database Options
POSTGRES_HOST=localhost
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

Bringing the compose stack up will start running the deployment:

```shell
# From this directory
docker compose up
# From the root directory
docker compose -f ./docker/docker-compose.yaml up
```

### Verifying the Deployment

1. Open XNAT at [http://localhost:8080](http://localhost:8080).
2. Log in with the default administrator credentials: `admin` / `admin`.

>[!NOTE]
> The `XNAT_SITE_URL` and `XNAT_ADMIN_EMAIL` environment variables skip the first-launch initialization page. Without them, XNAT prompts for these values on first load.

### Building the Deployment

The Docker images can be built without running the deployment:

```shell
# From this directory
docker compose build
# From the root directory
docker compose -f ./docker/docker-compose.yaml build
```

### Stopping the Deployment

Bringing the compose stack down will stop running the deployment:

```shell
# From this directory
docker compose down
# From the root directory
docker compose -f ./docker/docker-compose.yaml down
```
