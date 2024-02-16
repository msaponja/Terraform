# Terraform

### Goal(s)?

Mostly learning, but besides that I realy wanted to deploy VMs that would serve up as Kubernetes working Nodes.

### Enviroment

* Terraform: 1.7.2
* Proxmox: 8.1.3
* Provider: bpg/proxmox (0.46.3)
* VM: ubuntu-22.04-server-cloudimg-amd64

### Privacy

All input data used for the initialization of the provider or creation of the nodes is randomly generated and it doesn't represent any real enviroment. It's there for format purposes.

### Configuration

1. Connection
   
I used auto.tfvar for credentials input even if it's not security wise, but it helps it purpose.

> [!NOTE]
> Not all Proxmox API operations are supported via API Token. You may see errors like error creating container: received an HTTP 403 response - Reason: Permission check failed (changing feature flags for privileged container is only allowed for root@pam) or error creating VM: received an HTTP 500 response - Reason: only root can set 'arch' config when using API Token authentication, even when Administrator role or the root@pam user is used with the token. The workaround is to use password authentication for those operations.
   
2. Create VM

In this step I downloaded the image instead of using the local one. I followed some of the recommended guidelines for kubernetes node sizing.
Cloud-config is the main focus of this resource configuration, but I also added provisioner so I could change node names accordingly.
There are probably better ways to do it, but I lost to many hours already to fix that trivia.

3. Cloud-init

As I already mentioned in the comments, first, check if your datastore support snippets. Datacenter -> Storage -> Edit (Storage) -> Content 
After that comes the cloud init configuration which is long on purpose, because I tried to cover as much ground as possible.
At the end of the cloud-config sections the are some optional things to do and the one which is absolutely necessary if you want to join node to the cluser.

4. Output

Output section is there so you could see the IP address and ID of the newly created machine if you somehow don't have the access to proxmox dashboard or CLI.

5. Result

Kubernetes Node ready for some workload.
Keep in mind when you `terraform destroy` enviroment that you also need to delete the working nodes from your master node.
