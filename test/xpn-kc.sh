#!/bin/sh
. shmod
import github.com/sageify/shert@v0.0.1 shert.sh

## cheat sheet - https://kubernetes.io/docs/reference/kubectl/cheatsheet/

shert_equals 'xdr='' ./kc co v' "'kubectl' 'config' 'view'"

assert_equals "'kubectl' 'config' 'view' '"'-o=jsonpath={.users[?(@.name == "e2e")].user.password}'"'" \
  "$(xdr='' ./kc co v --ojp '{.users[?(@.name == "e2e")].user.password}')"

assert_equals "'kubectl' 'config' 'get-contexts'" \
  "$(xdr='' ./kc co g)"
assert_equals "'kubectl' 'config' 'current-context'" \
  "$(xdr='' ./kc co c)"
assert_equals "'kubectl' 'config' 'use-context' 'docker-desktop'" \
  "$(xdr='' ./kc co u docker-desktop)"

assert_equals "'kubectl' 'config' 'set-credentials' 'kubeuser/foo.kubernetes.com' '--username=kubeuser' '--password=kubepassword'" \
  "$(xdr='' ./kc co scr kubeuser/foo.kubernetes.com -u kubeuser -p kubepassword)"
assert_equals "'kubectl' 'config' 'set-context' '--current' '--namespace' 'ggckad-s2'" \
  "$(xdr='' ./kc scns ggckad-s2)"

assert_equals "'kubectl' 'apply' '-f' './my-manifest.yaml'" \
  "$(xdr='' ./kc af ./my-manifest.yaml)"
assert_equals "'kubectl' 'create' 'deploy' 'nginx' '--image=nginx'" \
  "$(xdr='' ./kc cd nginx --image=nginx)"
assert_equals "'kubectl' 'create' 'deploy' 'nginx' '--image=nginx'" \
  "$(xdr='' ./kc create d nginx --image=nginx)"
assert_equals "'kubectl' 'create' 'deploy' 'nginx' '--image=nginx'" \
  "$(xdr='' ./kc c d nginx --image=nginx)"
assert_equals "'kubectl' 'explain' 'po'" \
  "$(xdr='' ./kc ep)"

# Viewing, finding resources

# Get commands with basic output
assert_equals "'kubectl' 'get' 'svc'" \
  "$(xdr='' ./kc gs)"
assert_equals "'kubectl' 'get' 'po' '--all-namespaces'" \
  "$(xdr='' ./kc gp --all)"
assert_equals "'kubectl' 'get' 'po' '-o=wide'" \
  "$(xdr='' ./kc gp --ow)"
assert_equals "'kubectl' 'get' 'deploy' 'my-dep'" \
  "$(xdr='' ./kc gd my-dep)"
assert_equals "'kubectl' 'get' 'po'" \
  "$(xdr='' ./kc gp)"
assert_equals "'kubectl' 'get' 'po' 'my-pod' '-o=yaml'" \
  "$(xdr='' ./kc gp my-pod -y)"

assert_equals "'kubectl' 'get' 'po' 'my-pod' '-o=yaml'" \
  "$(xdr='' ./kc g po my-pod -y)"

# Describe commands with verobose output
assert_equals "'kubectl' 'describe' 'no' 'my-node'" \
  "$(xdr='' ./kc d no my-node)"
assert_equals "'kubectl' 'describe' 'po' 'my-node'" \
  "$(xdr='' ./kc d p my-node)"

# List Services Sorted by Name
assert_equals "'kubectl' 'get' 'svc' '--sort-by=.metadata.name' '-o=yaml'" \
  "$(xdr='' ./kc gs -sy)"

assert_equals "'kubectl' 'get' 'po' '--field-selector=status.phase=Running'" \
  "$(xdr='' ./kc gp --fs status.phase=Running)"
