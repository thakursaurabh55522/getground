### Update Packages
```
sudo apt-get update -y
sudo apt-get upgrade -y
```
### install curl
```
sudo apt-get install curl
```
### Install virtualbox
sudo apt-get install apt-transport-https
sudo apt-get install virtualbox virtualbox-ext-pack -y

### This will pop up the UI  
press tab and OK -- to accept licence
Again press tab and OK -- to accept terms

### Setup Kubectl
```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
```
### Validate binary
```
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
Response should be 
kubectl:ok
```
### Install kubectl
```
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client --output=yaml
```
### Verify
```
 o/p :
  clientVersion:
  buildDate: "2023-01-18T15:58:16Z"
  compiler: gc
  gitCommit: 8f94681cd294aa8cfd3407b8191f6c70214973a4
  gitTreeState: clean
  gitVersion: v1.26.1
  goVersion: go1.19.5
  major: "1"
  minor: "26"
  platform: linux/amd64
  kustomizeVersion: v4.5.7
```

### Setup Minikube

#### Download minikube binary file
```
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
```
#### Install minikube
```
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```
#### Start Minikube service
```
minikube start
```
#### Start Minukube Dashboard
```
minikube dashboard
```