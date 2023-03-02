# Devops-techtask

## Architecture:

The proposed architecture consists of the following components:

* Kubernetes cluster: used to manage the deployment and scaling of the application and Redis. It can be set up using a cloud provider like AWS or Google Cloud Platform, or a self-hosted solution like **Minikube**.
* Redis: used to store the state of the application. It can be deployed as a stateful set in Kubernetes, with persistent volumes to ensure data persistence.
* Golang application: the core of the solution, it serves a single endpoint that increments a counter for each call and returns the current count. It can be containerized and deployed as a deployment in Kubernetes, with multiple replicas to ensure high availability.
    * To secure Redis, we can use a password and set it as a **Kubernetes secret**, which can be mounted as an environment variable in the Redis container.


## Tools Used

The tools we will be using for this solution are:
* **Docker**: to create container images for the Golang service and Redis.
* **Kubernetes**: to deploy the application and its dependencies.
* **kubectl**: to interact with the Kubernetes cluster from the command line.
* **Minikube**: to create a local Kubernetes cluster.


## Setup:
> NOTE: If tools are not setup then you can follow the **prerequisite_setup.md** file to setup the tools in the Ubuntu VM.


We have a standalone fresh Ubuntu VM (As mentioned in the Usecase), So I am using the **Minikube** for Kubernetes Environment.
 
## Implementation:

#### Here are the steps to implement the solution:

1. Create a Redis password and store it as a Kubernetes secret:

```
kubectl create secret generic redis-password --from-literal=REDIS_PASSWORD=<password>
```
Replace `<password>` with the actual Redis password you want to use.

2. Create a ConfigMap containing the Redis configuration file:

| ISSUE: In the `kubernetes/configmap.yaml` file on line 18 `requiredpass` is `${REDIS_PASSWORD}`. Idealy this _redis.conf_ file should get deploy into the container and replace the `${REDIS_CONTAINER}` with the environment variable which we are setting from secret in the deployment file. But unfortunately the variable is not getting substituted with the environment variable, I have tried a lot of ways to do that but it is not working at all. I will be raising a support ticket for the same. |
| --- | 

> #### For now to execute we have to hardcode a password in `kubernetes/configmap.yaml` file. Replace the `${REDIS_PASSWORD}` with `<password>` which you have given while creating the secret in the 1st step.

```
kubectl apply -f kubernetes/configmap.yaml
```
* This will create two configMaps
    1. `go-app-config` - have the redis conffigurations details (hostname, redis_port, redis_DB).
    2. `redis-config`- have the _redis.conf_ content.


3. Create a persistent volume claim for redis, It will prevent **Data loss** incase of any failure.

```
kubectl apply -f kubernetes/pvc.yaml
```
4. Deploy Password Protected Redis:

```
kubectl apply -f kubernetes/redis.yaml
```
- The file will Deploy the below components:
    * **Deployment** named _redis_ with attached configMap **redis-config** which has the redis configuration to enable **password authentication**, Using the **command** argument the configurations are getting appended in _/usr/local/etc/redis/redis.conf_ file
    * **Service** named _redis-service_ which will expose the deployemnt as **cluster_ip**, so that the frontend application could access redis **internally**. 

5. Build and containerize the Golang application using _Dockerfile_.

```
docker build -t my-app .
```
* Dockerfile file is in two stages
    1. It will take the module files, download all the dependencies and build the binary 
    2. Copy the binary from the previous stage and run the binary

6. Tag & Push the Docker image to a Docker registry:

```
docker tag my-app <registry>/my-app:latest`
docker push <registry>/my-app:latest`
```
Replace `<registry>` with the actual docker registry where you want to push the image.
* Docker tag command will maintain the build version.
* Docker push will push the taged image to the repository.

7. Deploy the Golang application:

```
kubectl apply -f kubernetes/app.yaml
```
* The file will Deploy the below components:
    * **Deployment** named _go-app-deployment_ with multiple replicas, image update strategy and attached configMap _go-app-config_ data as ENV variables in the container. 
    * **Service** named _go-app-service_ which will expose the Goland deployment as **Load balancer**, So that it will be accessible from outside the cluster via HTTP.
    * **Horizontal Pod Autoscaler** named _go-app-hpa_ will monitor the CPU utilication(60%) and scale-up and scale-down the pods

8. Test the application

```
minikube service go-app-service --url
```

> NOTE: This Command will generate the external IP for the load balancer service. AS we are using **Minikube** Kubernetes cluster, We will not get the external Ip of Load balancer service using Kubectl get service command.

Test the application by accessing the endpoint `<external-url>/:id`, where `<external-url>` is the URL we got by running the above command.



***

## Devops-techtask On Google kubernetes engine GKE

#### We can also deploy this applications using GKE, Where The implementation will remain same

## Architecture:
The proposed architecture will consists of the following components:

* Kubernetes cluster: used to manage the deployment and scaling of the application and Redis. It can be set up using a cloud provider **Google Cloud Platform**
* Redis: used to store the state of the application. It can be deployed as a stateful set in Kubernetes, with persistent volumes to ensure data persistence.
* Golang application: the core of the solution, it serves a single endpoint that increments a counter for each call and returns the current count. It can be containerized and deployed as a deployment in Kubernetes, with multiple replicas to ensure high availability.
    * To secure Redis, we can use a password and set it as a **Kubernetes secret**, which can be mounted as an environment variable in the Redis container.


## Create and Setup GKE CLuster

>NOTE: Make sure Gcloud sdk is already installed in the machine

### configure google cloud project in which you have to create GKE cluster
```
gcloud config set project <PROJECT_ID>
```
Replace `PROJECT_ID` with your project ID.

### Authenticate with google cloud

>NOTE: You should have the IAM permissions to create kubernetes cluster
```
gcloud auth login
```
This will give you a link on which you can login you account and authenticate

### Create GKE cluster
```
gcloud container clusters create-auto <CLUSTER_NAME> \
    --region=<COMPUTE_REGION> \
    --network=<NETWORK> \
    --subnetwork=<SUBNETWORK> \
    --enable-private-endpoint \
    --enable-private-nodes \
    --cluster-ipv4-cidr=CLUSTER_IPV4_CIDR \
    --cluster-secondary-range-name=<NAME> \
    --services-ipv4-cidr=CIDR \
    --services-secondary-range-name=<NAME> 
```
Replace `CLUSTER_NAME` with your Cluster name.
This will create an **Private Kubernetes cluster** in Auto pilot mode. GKE Autopilot is a mode of operation in GKE in which Google manages your cluster configuration, including your nodes, scaling, security, and other preconfigured settings. Autopilot clusters are optimized to run most production workloads, and provision compute resources based on your Kubernetes manifests

### Get authentication credentials for the cluster
After creating your cluster, you need to get authentication credentials to interact with the cluster:
```
gcloud container clusters get-credentials <CLUSTER_NAME> \
    --region COMPUTE_REGION
```
This command configures `kubectl` to use the cluster you created.

>NOTE: The deployment yaml files we can use same as above.

***

## In addtition to this I can also setup the CI/CD process for the same.