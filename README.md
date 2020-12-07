# XNAT Cluster

This repository contains the files necessary to build, and deploy Brown
University's instance of XNAT to the SciDMZ cluster.

XNAT does not provide a Docker image for XNAT itself (though they do
provide a lot of Docker images that work with XNAT). The `Dockerfile`
builds XNAT as it's used at Brown University.

XNAT requires Apache Tomcat version 7, JDK 1.8, and Postgresql 9. No other
versions are supported.

This repository provides two ways of running development versions of XNAT,
via Docker Compose or Kubernetes.

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

If you desire LDAP authentication, copy `ldap.env.example` to `ldap.env`
and load your LDAP configuration. Then uncomment the `ldap-config` section
in the `kustomization.yaml` file. Similarly, uncomment the `ldap-config`
environment section in `app.yaml` and start the service as above.

## TODO
* [x] Trim down the `Dockerfile` to bare minimum necessary
* [x] Build and test the image using Docker
* [x] Create a repository, and deployer service account in the DTR
* [x] Create Kubernetes deployment manifest for XNAT
* [x] Deploy to minikube for test
* [x] Deploy to SciDMZ to for test
* [ ] Configure TrueNAS storage mounts in the cluster
* [x] Configure Postgres storage for metadata
* [ ] Document the process

[1]: https://minikube.sigs.k8s.io/docs/start/
