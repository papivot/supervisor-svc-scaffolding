#!/bin/bash

##################################################
#### Create the top level folders
##################################################
mkdir -p $1
cd $1
mkdir -p distribution
mkdir -p config/_ytt_lib/bundle/config
mkdir -p config/_ytt_lib/bundle/config/overlays
mkdir -p config/_ytt_lib/bundle/config/upstream

##################################################
##### Create sample files
##################################################

##### Create config/config.yaml file #####
cat > config/config.yaml << EOF
#@ load("@ytt:library", "library")
#@ load("@ytt:template", "template")
#@ load("@ytt:data", "data")

#! export vendored $1 bundle as a var
#@ $1_lib = library.get("bundle/config")

#! define a map for values to be passed to vendored $1 lib
#@ def $1_values():
namespace: #@ data.values.namespace
#@ end

#! render yaml from vendored lib with data values
--- #@ template.replace($1_lib.with_data_values($1_values()).eval())
EOF

#### Create config/values.yaml file #####
cat > config/values.yaml << EOF
#@data/values
---

#! The namespace in which to deploy $1.
namespace: $1
EOF

#### Create overlay-namespace.yaml file #####
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

#### Create top level package-build.yaml sample file #####
cat > package-build.yaml << EOF
apiVersion: kctrl.carvel.dev/v1alpha1
kind: PackageBuild
metadata:
  creationTimestamp: null
  name: $1.fling.vsphere.vmware.com
spec:
  release:
  - resource: {}
  template:
    spec:
      app:
        spec:
          deploy:
          - kapp: {}
          template:
          - ytt:
              paths:
              - ./config
          - kbld: {}
      export:
      - imgpkgBundle:
          image: harbor.navneet.pro/library/$1
          useKbldImagesLock: true
        includePaths:
        - ./config
EOF

#### Create top level package-resources.yaml sample file #####
cat > package-resources.yaml << EOF
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  creationTimestamp: null
  name: $1.fling.vsphere.vmware.com.$2
spec:
  refName: $1.fling.vsphere.vmware.com
  releasedAt: null
  template:
    spec:
      deploy:
      - kapp: {}
      fetch:
      - git: {}
      template:
      - ytt:
          paths:
          - ./config
      - kbld: {}
  valuesSchema:
    openAPIv3:
      properties:
        namespace:
          default: $1
          description: The namespace in which to deploy $1.
          type: string
      title: $1.vsphere.vmware.com.$2 values schema
  version: $2

---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageMetadata
metadata:
  creationTimestamp: null
  name: $1.fling.vsphere.vmware.com
spec:
  categories:
  - CI/CD
  - GitOps
  displayName: $1
  iconSVGBase64: none
  longDescription: $1 is used to deploy instance of .....
  maintainers:
  - name: First
  - name: Second
  - name: Third
  providerName: VMware
  shortDescription: $1 is used to deploy ....

---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  annotations:
    kctrl.carvel.dev/local-fetch-0: .
  creationTimestamp: null
  name: $1
spec:
  packageRef:
    refName: $1.fling.vsphere.vmware.com
    versionSelection:
      constraints: $2
  serviceAccountName: $1-sa
status:
  conditions: null
  friendlyDescription: ""
  observedGeneration: 0
EOF

##################################################
### Check if Carvel binaries are present
##################################################
if ! command -v kctrl &> /dev/null
then
    echo "CRITICAL :: kctrl could not be found in the PATH. Download and install the latest binary before proceeding."
fi
if ! command -v ytt &> /dev/null
then
    echo "CRITICAL :: ytt could not be found in the PATH. Download and install the latest binary before proceeding."
fi
if ! command -v imgpkg &> /dev/null
then
    echo "CRITICAL :: imgpkg could not be found in the PATH. Download and install the latest binary before proceeding."
fi
if ! command -v kbld &> /dev/null
then
    echo "CRITICAL :: kbld could not be found in the PATH. Download and install the latest binary before proceeding."
fi
if ! command -v kapp &> /dev/null
then
    echo "CRITICAL :: kapp could not be found in the PATH. Download and install the latest binary before proceeding."
fi

echo 
echo
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
