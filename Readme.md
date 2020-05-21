# TKG Lab

![TKG Lab Base Diagram](docs/tkg-lab-base.png)
![TKG Lab Deployment Diagram](docs/tkg-deployment.png)

In this lab, we will deploy Tanzu Kubernetes Grid (standalone deployment model) to AWS or vSphere.  We will additionally deploy TKG extensions for ingress, authentication, and logging.

OSS Signed and Supported Extensions:

- **Contour** for ingress
- **Dex** and **Gangway** for authentication
- **Fluent-bit** for logging
- **Cert-manager** for certificate management

TKG Plus for additional Open Source Support:

- **Velero** for backup
- **Harbor** for image registry

Incorporates the following Tanzu SaaS products:

- **Tanzu Mission Control** for multi-cluster management
- **Tanzu Observability** by Wavefront for observability

Leverages the following external services:

- **AWS S3** as an object store for Velero backups
- **Okta** as an OIDC provider
- **GCP Cloud DNS / Router 53** as DNS provider
- **Let's Encrypt** as Certificate Authority

## Goals and Audience

The following demo is for Tanzu field team members to see how various components of Tanzu and OSS ecosystem come together to build a modern application platform.  We will highlight two different roles of the platform team and the application team's dev ops role.  This could be delivered as a presentation and demo.  Or it could be extended to include having the audience actually deploy the full solution on their own using their cloud resources. The latter would be for SE’s and likely require a full day.

Disclaimers

- Arguably, we have products, like TAS or TKGI that deliver components of these features and more with tighter integration, automation, and enterprise readiness today.
- Additionally, it is early days in our product integrations, automation, and enterprise readiness as these products have recently entered GA or are being integrated for the first time.

What we do have is a combination of open source and proprietary components, with a bias towards providing VMware built/signed OSS components by default, with flexibility to swap components and flexible integrations.

VMware commercial products included are: TKG, TO, TMC and OSS products.

3rd-party SaaS services included are: AWS S3, AWS Route 53, GCP Cloud DNS, Let's Encrypt, Okta.  Note: There is flexibility in deployment planning.  For instance, You could Swap GCP Cloud DNS with Route53.  Or you could swap Okta for Google or Auth0 for OpenID Connect.

## Scenario Business Context

The acme corporation is looking to grow its business by improving their customer engagement channels and quickly testing various marketing and sales campaigns.  Their current business model and methods can not keep pace with this anticipated growth.  They recognize that software will play a critical role in this business transformation.  Their development and ops engineers have chosen microservices and kubernetes as foundational components to their new delivery model.  They have engaged as a partner to help them with their ambitious goals.

## App Team

The acme fitness team has reached out the platform team requesting platform services.  They have asked for:

- Kubernetes based environment to deploy their acme-fitness microservices application
- Secure ingress for customers to access their application
- Ability to access application logs in real-time as well as 30 days of history
- Ability to access application metrics as well as 90+ days of history
- Visibility into overall platform settings and policy
- Daily backups of application deployment configuration and data
- 4 Total GB RAM, 3 Total CPU Core, and 10GB disk for persistent application data

Shortly after submitting their request, the acme fitness team received an email with the following:
- Cluster name
- Namespace name
- Base domain for ingress
- Link to view overall platform data, high-level observability, and policy
- Link to login to kubernetes and retrieve kubeconfig
- Link to search and browse logs
- Link to access detailed metrics

DEMO: With this information, let’s go explore and make use of the platform…

- Access login link to retrieve kubeconfig (gangway)
- Update ingress definition based upon base domain and deploy application (acme-fitness)
- Test access to the app as and end user (convoy)
- View application logs (kibana, elastic search, fluent-bit)
- View application metrics (tanzu observability)
- View backup configuration (velero)
- Browse overall platform data, observability, and policy (tmc)

Wow, that was awesome, what happened on the other side of the request for platform services?  How did that all happen?


## Required CLIs

- kubectl
- tmc
- tkg
- velero
- helm 3
- yt

## Foundational Lab Setup Steps

### Management Cluster
#### 1. [Install Management Cluster](docs/mgmt-cluster/01_install_tkg_mgmt.md)
#### 2. [Attach Management Cluster to TMC](docs/mgmt-cluster/02_attach_tmc_mgmt.md)
#### 3. [Configure DNS and Prep Certificate Signing](docs/mgmt-cluster/03_dns_certs_mgmt.md)
#### 4. [Configure Okta](docs/mgmt-cluster/04_okta_mgmt.md)
#### 5. [Retrieve TKG Extensions](docs/mgmt-cluster/05_extensions_mgmt.md)
#### 6. [Install Contour Ingress Controller](docs/mgmt-cluster/06_contour_mgmt.md)
#### 7. [Install Dex](docs/mgmt-cluster/07_dex_mgmt.md)
#### 8. [Install Tanzu Observability](docs/mgmt-cluster/08_to_mgmt.md)

### Setup Shared Services Cluster
#### 1. [Create new Shared Services Cluster](docs/shared-services-cluster/01_install_tkg_ssc.md)
#### 2. [Attach Shared Services Cluster to TMC](docs/shared-services-cluster/02_attach_tmc_ssc.md)
#### 3. [Set policy on Shared Services Cluster and Namespace](docs/shared-services-cluster/03_policy_ssc.md)
#### 4. [Install Contour Ingress Controller](docs/shared-services-cluster/04_contour_ssc.md)
#### 5. [Install Gangway](docs/shared-services-cluster/05_gangway_ssc.md)
#### 6. [Install ElasticSearch and Kibana](docs/shared-services-cluster/06_ek_scc.md)
#### 7. [Install FluentBit](docs/shared-services-cluster/07_fluentbit_ssc.md)
#### 8. [Install Tanzu Observability](docs/shared-services-cluster/08_to_wlc.md)
#### 9. [Install Velero and Setup Nightly Backup](docs/shared-services-cluster/9_velero_ssc.md)

### Finalize Management Cluster
#### 1. [Install FluentBit](docs/mgmt-cluster/9_fluentbit_mgmt.md)
#### 2. [Install Velero and Setup Nightly Backup](docs/mgmt-cluster/10_velero_mgmt.md)

### Setup Workload Cluster
#### 1. [Create new Workload Cluster](docs/workload-cluster/01_install_tkg_and_components_wlc.md)

At this point you have the basis for the lab exercises!

## Acme Fitness Lab

This lab will go through our simulated experience of receiving a request from an app team for cloud resources and following the steps for both the platform team receiving the request and the app team accessing and deploying their app once the request has been fulfilled.

### Platform Team Steps

#### 1. [Update Okta for Application Team Users and Group](docs/acme-fitness-lab/01_okta_setup.md)
#### 2. [Set policy on Workload Cluster and Namespace](docs/acme-fitness-lab/02_policy_acme.md)

### Switch to the App Team Perspective

#### 3. [Log-in to workload cluster and setup kubeconfig](docs/acme-fitness-lab/03-login-kubeconfg.md)
#### 4. [Get, update, and deploy Acme-fitness app](docs/acme-fitness-lab/04-deploy-app.md)

## Bonus Labs

The following labs additional labs can be run on the base lab configuration.

#### [Deploy Harbor Image Registry to Shared Services Cluster](docs/bonus-labs/harbor.md)
#### [Deploy Gitlab to Shared Services Cluster](docs/bonus-labs/deploy_gitlab.md)
#### [Apply Image Registry Policy with TMC](docs/bonus-labs/tmc_image_policy.md)
#### [Restore Bacup with Velero](docs/bonus-labs/velero_restore.md)
