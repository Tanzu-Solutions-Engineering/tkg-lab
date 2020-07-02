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

Here is what the initial top-level domain delegation would look like.  THis is from Google Domains, but the same strategy will work for other providers, such as GoDaddy.  The trick is to create a Hosted Zone first (where you want to manage all entries for the lab) and then paste the NS entries created into your domain management's DNS area.  This dlegates all lookups to the new Hosted Zone.

![DomainDNS](DomainDNS.png)


