# DNS Setup

In order for the labs to work, you need to have an appropriate domain and DNS set up.  What this boils down to is a global domain that you own/control, with delegation of a subdomain for the lab work.  Many users will already have it set up for other purposes.  An example of this would look like:
* example.com (owned domain name)
  * tkg-aws-lab.example.com (NS Record -> Route53 Hosted Zone #1)
  * tkg-vsphere-lab.example.com (NS Record -> Route53 Hosted Zone #2)
* tkg-aws-lab.example.com (Managed by Route53 as a Public Hosted Zone)
  * \*.tkg-mgmt.tkg-aws-lab.example.com (Route53 Record Set - CNAME -> AWS LB)
  * \*.tkg-shared.tkg-aws-lab.example.com (Route53 Record Set - CNAME -> AWS LB)
  * etc...
* tkg-vsphere-lab.example.com (Managed by Route53 as a Public Hosted Zone)
  * \*.tkg-mgmt.tkg-vsphere-lab.example.com (Route53 Record Set - A Record -> Metal LB IP)
  * \*.tkg-shared.tkg-vsphere-lab.example.com (Route53 Record Set - A Record -> Metal LB IP)
  * etc...
* homelab.example.com (NS Record -> Google Cloud DNS)     # Not in scope for lab - for example only
  * opsman.homelab.example.com (Managed by GCloud DNS zone A Record -> 192.168.x.x)   # Not in scope for lab - for example only
  * etc...

## Screen Shots

This is what it looks liek to have 2 Hosted Zones in AWS Route53.  Each zone will independently manage all DNS entries within that subdomain.  The lab scripts will create entires as needed.  Note that when created, the Zone ID can be obtained from here and pasted into the params file.

![HostedZone](HostedZones.png)

Here is what the initial top-level domain delegation would look like.  This is from Google Domains, but the same strategy will work for other providers, such as GoDaddy.  The trick is to create a Hosted Zone first (where you want to manage all entries for the lab) and then paste the NS entries created into your domain management's DNS area.  This dlegates all lookups to the new Hosted Zone.

![DomainDNS](DomainDNS.png)

Once this linkage is set up, you can add entries to each hosted zone manually or via script.  The lab will update Route53 automatically, using you AWS Access/Secret key and the Hosted Zone ID that you set into the params file.  Once the labs are completed, this is what the Hosted Zone will look like.  There are 2 examples here, one for AWS and one for vSphere.  This is because of the way K8s LoadBalancers are managed.  On AWS, an EC2 Load Balancer is created for each cluster's API endpoint -and- for each Service type LoadBalancer created in the cluster.  On vSphere, there is no native LoadBalancer, so typically MetalLB is in use.  For the lab, we simply set the IP range for MetalLb inside ech cluster, and then point the DNS entry directly to the created LoadBalancer's IP address.

### Hosted Zone for AWS-deployed Lab
![AWSZoneDetails](HostedZone1Details.png)  
### Hosted Zone for vSphere-deployed Lab
![vSphereZoneDetails](HostedZone2Details.png)  
