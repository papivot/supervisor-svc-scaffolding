#!/bin/bash

#### Create top level folders
mkdir -p $1
cd $1
mkdir -p distribution
mkdir -p config/_ytt_lib/bundle/config
mkdir -p config/_ytt_lib/bundle/config/overlays
mkdir -p config/_ytt_lib/bundle/config/upstream

##### Create sample files
#### config/config.yaml

cat > config/config.yaml << EOF
#@ load("@ytt:library", "library")
#@ load("@ytt:template", "template")
#@ load("@ytt:data", "data")

#! export vendored mongodb bundle as a var
#@ $1_lib = library.get("bundle/config")

#! define a map for values to be passed to vendored $1 lib
#@ def $1_values():
namespace: #@ data.values.namespace
#@ end

#! render yaml from vendored lib with data values
--- #@ template.replace($1_lib.with_data_values($1_values()).eval())

EOF

#### config/values.yaml

cat > config/values.yaml << EOF
#@data/values
---

#! The namespace in which to deploy $1.
namespace: $1

EOF

#### Create NS overlay file

cat > config/_ytt_lib/bundle/config/overlays/overlay-namespace.yaml << EOF
#@ load("@ytt:data", "data")
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind":"Namespace", "metadata": {"name": "$1"}})
---
apiVersion: v1
kind: Namespace
metadata:
  name: #@ data.values.namespace

#@overlay/match by=overlay.subset({"metadata": {"namespace": "$1"}}), expects=10
---
metadata:
  namespace: #@ data.values.namespace

#@ crb=overlay.subset({"kind":"ClusterRoleBinding"})
#@ rb=overlay.subset({"kind":"RoleBinding"})
#@overlay/match by=overlay.or_op(crb, rb), expects=3
---
subjects:
#@overlay/match by=overlay.subset({"namespace": "$1"})
- kind: ServiceAccount
  namespace: #@ data.values.namespace

EOF

echo "1. Download/Create your $1 product binaries, repositiories and other artifacts to the [[$1/distribution]] folder."
echo
echo "2. Create, modify and update the Kubernetes manifest in the distrubution folder. Once the required Kubernetes manifest files are ready, please move all the YAML manifests to [[$1/config/_ytt_lib/bundle/config/upstream]] folder."
echo
echo "3. Sample namespace modification YTT overlay is provided in the [[$1/config/_ytt_lib/bundle/config/overlays]] folder."
echo
echo "4. Modify and update the config as needed. Once completed, use kctrl to create the required repositories and artifacts. kctrl will need write access to a registry to upload the artifacts."
echo
echo "Sample commands provided for reference -"
echo "---"
echo "kctrl package init"
echo "kctrl package release --openapi-schema --version VERSION_NUMBER --build-ytt-validations"
