# Scaffolding for Generating Supervisor Services Manifests

Use this repository to create your own **Experimental Supervisor Service**. Users can deploy the manifest generated through this process on a vSphere 8.0.1+ environment using the [Supervisor Service deployment methodology](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-with-tanzu-services-workloads/GUID-052CF490-4B77-4CA2-8A4C-8624718ADA4E.html). These are experimental and should not be used in production environments. 

The author has a blog article on [Medium](https://navneet-verma.medium.com/authoring-and-installing-argocd-operator-as-a-supervisor-service-on-vcenter-9c175b15d251?source=friends_link&sk=37f83ced21bfe222b2ccbc9f18e90e93) that discusses how to use this repository to generate your custom Supervisor Service. 

### Prerequisites

* [Carvel](https://carvel.dev/) tools should be installed and configured on the workstation. The following binaries are required - `kctrl`, `imgpkg`, `ytt`, `kbld` and `kapp`.
* **Image upload** access to a container repository such as Harbor or DockerHub (not preferred as it may impact availability due to rate limiting). 
* You should have logged in successfully to the container registry using the `docker login` command. 

1. Copy the [supsvc-scaffold.sh](supsvc-scaffold.sh) BASH script to your Linux or MacOS workstation. 
2. Make sure the execute permissions are appropriately set. `chmod +x supsvc-scaffold.sh`
3. Edit the script and modify the following - Change `image: harbor.navneet.pro/library` reference to the name/folder of your container registry.
4. Save the file. 
5. Execute the script and follow the directions provided. 

### Note

While the script generates all the directory structure and configuration files, you need to customize the Kubernetes manifest files most. Additionally, you must tweak the **ytt overlays** appropriately to modify the references to namespaces in the Kubernetes manifest files. A sample `ytt` overlay file gets generated and can be modified per requirements. 

Upon successful completion of the overall process, two files are generated in the `carvel-artifacts/packages/name-of-supervisor-service.fling.vsphere.vmware.com` subfolder: `metadata.yml` and `package.yml`. These two files need to be concatenated with a `---` separator between them. The newly concatenated file is the Supervisor Service YAML, which is then used in the vCenter Server to install a new Supervisor Service. 

**PS** Also included in this repository are some sample package manifests. 
