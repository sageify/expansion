#!/bin/sh
. shmod
import github.com/sageify/shert@v0.0.1 shert.sh

## cheat sheet - https://kubernetes.io/docs/reference/kubectl/cheatsheet/

export xdr=

shert_equals './kc cfg v' "kubectl config view"

shert_equals "./kc cfg v --ojp '{.users[?(@.name == \"e2e\")].user.password}'" \
  "kubectl config view '"'-o=jsonpath={.users[?(@.name == "e2e")].user.password}'"'"

shert_equals './kc cfg gc' "kubectl config get-contexts"

shert_equals './kc cfg cc' "kubectl config current-context"
shert_equals './kc cfg uc docker-desktop' "kubectl config use-context docker-desktop"

shert_equals './kc cfg scr kubeuser/foo.kubernetes.com -u kubeuser -p kubepassword' \
  "kubectl config set-credentials kubeuser/foo.kubernetes.com --username=kubeuser --password=kubepassword" \

shert_equals './kc sns ggckad-s2' \
  "kubectl config set-context --current --namespace ggckad-s2" \

shert_equals './kc af ./my-manifest.yaml' "kubectl apply -f ./my-manifest.yaml"

shert_equals './kc c dep nginx --image=nginx' "kubectl create deployment nginx --image=nginx"
shert_equals './kc create dep nginx --image=nginx' "kubectl create deployment nginx --image=nginx"
shert_equals './kc c deploy nginx --image=nginx' "kubectl create deploy nginx --image=nginx"

shert_equals './kc explain po' "kubectl explain po"


# Viewing, finding resources

# Get commands with basic output
shert_equals './kc svc' "kubectl get svc" \

shert_equals './kc po -A' "kubectl get po -A"
shert_equals './kc po --ow' "kubectl get po -o=wide"

shert_equals './kc deploy my-dep' "kubectl get deploy my-dep"
shert_equals './kc po' "kubectl get po"
shert_equals './kc po my-pod -y' "kubectl get po my-pod -o=yaml" \
  
shert_equals './kc g po my-pod -y' "kubectl get po my-pod -o=yaml"

# Describe commands with verobose output
shert_equals './kc des no my-node'  "kubectl describe no my-node"
shert_equals './kc des po my-node' "kubectl describe po my-node"

# List Services Sorted by Name
shert_equals './kc svc -sy' "kubectl get svc --sort-by=.metadata.name -o=yaml"

shert_equals './kc po --fs status.phase=Running' "kubectl get po --field-selector=status.phase=Running"
