# XNAT Docker Local Deployment

## Overview

### Folder Structure

- **[docker-compose.yaml](./docker-compose.yaml):** Defines the containers that are a part of the XNAT local deployment
  - *A more detailed explanation of the file is provided [below](#docker-compose-overview)*
- **[.env.example](./env/.env.example):**: Defines the key/value pairs used to configure XNAT's runtime environment
  - *The values in this example file are intentionally not provided. See [below](#setting-up-the-deployments-environment-variables) for setting up the environment correctly.*
- **[ldap-provider.properties.example](./config/ldap-provider.properties.example):**: Defines the key/value pairs used to an LDAP authentication provider in XNAT
  - *The values in this example file are intentionally not provided. See [below](#setting-up-the-deployments-authentication-providers) for setting up the provider correctly.*
- **[oidc-provider.properties.example](./config/oidc-provider.properties.example):**: Defines the key/value pairs used to an OIDC authentication provider in XNAT
  - *The values in this example file are intentionally not provided. See [below](#setting-up-the-deployments-authentication-providers) for setting up the provider correctly.*

### Docker Compose Overview

<!-- TODO: Overview of the files/folders -->
<!-- TODO: Overview of the docker compose file -->

- The XNAT application is named `xnat-web`
- XNAT's database is named `postgres`

- build
- image
- ports
- env_file
- volumes
- depends_on
- healthcheck

## Setting up Docker

This deployment requires [Docker](https://www.docker.com/) with Docker Compose to run. Docker Desktop bundles both and is the tool recommended by the XNAT development team.

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

### Setting up the Deployment's Environment Variables

>[!WARNING]
> Environment files contain sensitive credentials that should not be added to git source control

1. The [.env.example](./env/.env) file should be copied and renamed `.env`.
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

### Setting up the Deployment's Authentication Providers

>[!WARNING]
> These files contain sensitive credentials that should not be added to git source control

#### Setting up the Deployment's LDAP Provider

1. The [ldap-provider.properties.example](./config/ldap-provider.properties.example) file should be copied and renamed `ldap-provider.properties`.
2. Values for each key should be provided according to the [plugin's documentation](https://wiki.xnat.org/xnat-tools/xnat-ldap-authentication-plugin).

#### Setting up the Deployment's OIDC Provider

1. The [oidc-provider.properties.example](./config/oidc-provider.properties.example) file should be copied and renamed `oidc-provider.properties`.
2. Values for each key should be provided according to the [plugin's documentation](https://wiki.xnat.org/xnat-tools/openid-authentication-plugin).

## Running the Deployment

Bringing the compose stack up will start running the deployment:

```shell
docker-compose up
```

Bringing the compose stack down will stop running the deployment:

```shell
docker-compose down
```

The Docker images can be built without running the deployment:

```shell
docker-compose build
```
