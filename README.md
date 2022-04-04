# XNAT Cluster

This repository contains the files necessary to build, and test-deploy Brown
University's instance of XNAT to the SciDMZ cluster. Deployment to the cluster
is managed in [this repo](https://github.com/brown-ccv/k8s-deploy-bke)

The `Dockerfile` builds XNAT as it's used at Brown University.

XNAT requires Apache Tomcat version 9, JDK 1.8, and Postgresql 10. No other
versions are supported.

This repository provides two ways of running development versions of XNAT,
via Docker Compose or Kubernetes.

## Building the Docker image

The `docker-compose.yaml` file contains the necessary information to build
the Docker image. There is one argument to the Docker image build,
`$XNAT_VERSION`. The `Dockerfile` leverages a multi-stage build process
that clones the `xnat-web` repository and builds from source. The version
of `xnat-web` cloned depends on `$XNAT_VERSION`. `$XNAT_VERSION` may be a
tag or branch.

To build the Docker image run:

```
$ docker-compose build
```

## Docker Compose

To start the compose stack run:

```
$ docker-compose up
```

## Kubernetes

First you must install minikube. See [this guide][1] for more details. I
used `brew` on macOS to install minikube. Once minikube is installed, start
it with the following command.

Kubernetes version can be omitted, but I like to keep it there to make
sure my manifests are compatible with my clusters. Make sure the driver
you use matches your system configuration, and can support the nginx
ingress controller.

```
$ minikube start --kubernetes-version=v1.18.10 --driver=hyperkit
```

Once minikube has started, enable the ingress controller if you haven't
already.

```
$ minikube addons enable ingress
```

To run the Kubernetes deployment run:

```
$ kubectl apply -k .
```

This will set up XNAT with all the fixings including a local database.
`app.yaml` contains the manifests related to XNAT, `db.yaml` contains the
manifests for the database.

By default XNAT is configured as a `ClusterIp` service, meaning that XNAT
does not expose any external addresses. There are three ways to connect to
XNAT: Kubernetes port-forwarding, curl, and `/etc/hosts`.

Kubernetes offers a method of forwarding traffic to and from the cluster.
With this we can proxy traffic to a service running inside the cluster.

```
$ kubectl port-forward svc/xnat 8080:80
```

This command will forward `localhost:8080` traffic to the XNAT service
within the Kubernetes cluster. From there the service will forward the
traffic to the deployment.

If you want a quick sanity check, curl works great. The following command
forces curl to resolve the address `xnat.local` to your minikube IP
address. `xnat.local` is the name set up by the Kubernetes ingress, see
`app.yaml` for more details.

```
$ curl -vL --resolve xnat.local:80:$(minikube ip) http://xnat.local
```

Lastly, if you're doing prolonged testing with XNAT you can update your
hosts file to point `xnat.local` to your minikube IP address. This is
basically what we did with the previous curl command, but permanent.

```
$ sudo sh -c "echo $(minikube ip) xnat.local >> /etc/hosts"
```

After updating your hosts file you should be able to use `xnat.local` to
access your development XNAT deployment.

## LDAP

Multiple unique LDAP providers are supported. Each LDAP authentication
properties file must be mounted in the `/data/xnat/home/config/auth`
directory. The process varies depending on whether or not you're deploying
with Kubernetes or Docker Swarm.

If deploying with Kubernetes, the LDAP authentication properties files may
be specified as either a `ConfigMap` or `Secret` object. The `ConfigMap` or
`Secret` must then be referenced as a volume, and mounted in the container.

If deploying with Docker Swarm, add the LDAP authentication properties
files as a volume at `/data/xnat/home/config/auth` in the Docker container.

Examples are provided for both Kubernetes and Docker Swarm. Uncomment the
LDAP sections in `app.yaml` and `kustomization.yaml` for Kubernetes.
Uncomment the LDAP section in `docker-compose.yaml` for Docker Swarm.

## Automatic Initialization

If you want to skip the initialization page on first launch, provide both
`$XNAT_SITE_URL` and `$XNAT_ADMIN_EMAIL` when starting XNAT. The default
username/password will still be `admin:admin`. If you've provided an LDAP
configuration, the automatic initialization will enable your LDAP provider.

## Manual Configuration

You do not have to rely on the config generation rules detailed above to
configure XNAT. `/data/xnat/home/config` is exposed as a volume. You may
add your custom configs in that directory using the standard volume mount
mechanisms of Kubernetes or Docker Swarm. An example is not provided.

[1]: https://minikube.sigs.k8s.io/docs/start/
