# XNAT Cluster

This repository contains the files necessary to build, and deploy Brown
University's instance of XNAT to the SciDMZ cluster.

XNAT does not provide a Docker image for XNAT itself (though they do
provide a lot of Docker images that work with XNAT). The `Dockerfile`
builds XNAT as it's used at Brown University.

XNAT requires Apache Tomcat version 7, and JDK 1.8. No other versions are
supported.

## TODO
* [ ] Trim down the `Dockerfile` to bare minimum necessary
* [ ] Build and test the image using Docker
* [ ] Create a repository, and deployer service account in the DTR
* [ ] Create Kubernetes deployment manifest for XNAT
* [ ] Deploy to minikube for test
* [ ] Deploy to SciDMZ to for test
* [ ] Configure TrueNAS storage mounts in the cluster
* [ ] Configure Postgres storage for metadata
* [ ] Document the process
