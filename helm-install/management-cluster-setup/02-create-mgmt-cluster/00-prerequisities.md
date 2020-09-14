Make sure you are connected to VMware VPN.

 - ###### Configure OIDC - [Setup](../management-cluster-setup/01-oidc-setup/oid_setup.md)

    Once you have the `Client ID` and `Client Secret`, encode them to BASE64 in your terminal and save those values

        #encode to base 64
        echo -n <client_id> | Base64
        echo -n <client_secret> | Base64

        Copy the client-id and secret as they will be used in the Configure Parameter step

 - ###### Create Hosted Zone in AWS

        Login to your AWS account and navigate to Route53 > Hosted Zone

        Create a new `Hosted Zone` and provide a domain name. Example: tkg.lab.<your-domain> (tkg.lab.tanzu-is-awesome.com)

        If your domain exist outside of AWS, like GCP, GoDaddy or etc. Copy the four `NS` records and add it to your domain name provider.

- ###### Setup Wavefront Id

        Login to Wavefront UI (Either from Pivotal OKTA or vmWare workspace)

        Go to profile > API Access and generate an API Token.

        Copy the token as it will be used in the Configure Parameter step


- ###### Configure Parameters in param.yml file - [Setup](00_set_params.md)

- ###### Clone TKG Extensions

  For Dex to work with your Okta OIDC account, you will need to copy the OIDC template file to your ~./tkg folder.
  These are the steps to download the file and place in the right folder:

        - Git clone the repository: https://gitlab.eng.vmware.com/TKG/tkg-extensions
        - Copy the plan(authentication/dex/aws/cluster-template-oidc.yaml) for a workload cluster with OIDC enabled to .tkg/providers/infrastructure-aws/<tkg_version>/

        Example: cp tkg-extensions/authentication/dex/aws/cluster-template-oidc.yaml ~/.tkg/providers/infrastructure-aws/v0.5.2


###### Once completed, return to Home page to start the installation of TKG Management Cluster

Back To [Home](../../README.md)
