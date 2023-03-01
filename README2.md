# Devops-techtask

## Architecture:
The proposed architecture consists of the following components:

* Kubernetes cluster: used to manage the deployment and scaling of the application and Redis. It can be set up using a cloud provider like AWS or Google Cloud Platform, or a self-hosted solution like **Minikube**.
* Redis: used to store the state of the application. It can be deployed as a stateful set in Kubernetes, with persistent volumes to ensure data persistence.
* Golang application: the core of the solution, it serves a single endpoint that increments a counter for each call and returns the current count. It can be containerized and deployed as a deployment in Kubernetes, with multiple replicas to ensure high availability.
    * To secure Redis, we can use a password and set it as a **Kubernetes secret**, which can be mounted as an environment variable in the Redis container.


## Tools Used

The tools we will be using for this solution are:
* **Docker**: to create container images for the Golang service and Redis
* **Kubernetes**: to deploy the application and its dependencies
* **kubectl**: to interact with the Kubernetes cluster from the command line
* **Minikube**: to create a local Kubernetes cluster for development and testing purposes

> NOTE: If tools are not setup then you can follow the **prerequisite_setup.md** file to setup the tools in the Ubunto VM.


 have a standalone fresh Ubuntu VM (As mentioned in the Usecase), So I am using the **Minikube** for Kubernetes Environment.
 
## Implementation:

#### Here are the steps to implement the solution:

1. Create a Redis password and store it as a Kubernetes secret:

`kubectl create secret generic redis-password --from-literal=REDIS_PASSWORD=<password>`

Replace `<password>` with the actual Redis password you want to use.

2. Create a ConfigMap containing the Redis configuration file:

`kubectl apply -f kubernetes/configmap.yaml`

* This will create two configMaps
    1. `go-app-config` - have the redis confurations details (hostname, redis_port, redis_DB).
    2. `redis-config`- have the _redis.config_ content.

3. Create a persistent volume claim for redis, It will prevent **Data loss** incase of any failure.

`kubectl apply -f kubernetes/pvc.yaml`

4. Create a Redis deployment using the secret and and the Redis service:

`kubectl apply -f kubernetes/redis.yaml`

- The file will Deploy the below components:
    * Deployment named `redis` with attached configMap **redis-config** which has the redis configuration to enable **password authentication**, Using the **command** argument the configurations are getting appended in `/usr/local/etc/redis/redis.conf` file
    * Service named `redis-service` which will expose the deployemnt as **cluster_ip**, so that the frontend application could access redis **internally**. 

5. Build and containerize the Golang application using `Dockerfile`.

`docker build -t my-app .`

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

`kubectl apply -f kubernetes/app.yaml`

* The file will Deploy the below components:
    * **Deployment** named `go-app-deployment` with multiple replicas, image update strategy and attached configMap `go-app-config` data as ENV variables in the container. 
    * **Service** named `go-app-service` which will expose the Goland deployment as **Load balancer**, So that it will be accessible from outside the cluster via HTTP.
    * **Horizontal Pod Autoscaler** named `go-app-hpa` will monitor the CPU utilication(60%) and scale-up and scale-down the pods

8. Test the application

`minikube service go-app-service --url`

As we are using **Minikube** Kubernetes cluster, It will not show the external Ip of Load balancer service. Using the above command, we will get the external URL.
Test the application by accessing the endpoint <external-url>/:id, where <external-url> is the URL we got by running the above command


