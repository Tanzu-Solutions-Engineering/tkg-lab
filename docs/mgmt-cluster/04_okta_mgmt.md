# Setup an account with Okta for OpenID Connect (OIDC)

Setup a free Okta account: https://developer.okta.com/signup/

Once logged in...

You will need to go to the Admin interface.  If you are in the standard interface by default, choose green Admin button on the top right.

## Create Admin User

Choose Directory (side menu) > People > Add Person:
- Set First Name, Last Name and Email: (e.g: Alana Smith, alana@winterfell.live)
- Password Set by Admin, YOUR_PASSWORD
- Uncheck user must change password on first login

## Create Platform Team

Choose Directory (side menu) > Groups and then > Add Group:
- platform-team

Click on platform-team group > Manage People: Then add alana to the platform-team. Save

## Create Application for TKG

Choose Applications (side menu) > Application.  Then click Add Application button.  Then click Create New App button. Choose Web, OpenID Connect and Create button.
  - Give your app a name: TKG
  - Login redirect URIs: https://pinniped.<your-management-cluster-name>.<your-environment-name>.<your-subdomain>/callback 
  - Logout redirect URIs: https://pinniped.<your-management-cluster-name>.<your-environment-name>.<your-subdomain>/logout
> Note: Use your management-cluster.pinniped-fqdn domain as defined in your params.yaml

Click Save button

## Retrieve Client ID and Client Secret

Capture ClientID and Client Secret from Client Credentials card.  Capture Okta Domain from General Settings. You will need to put these into your params.yaml file.

```yaml
okta:
  auth-server-fqdn: # Your Okta Domain
  tkg-app-client-id: # Client Id
  tkg-app-client-secret: # Client Secret
```

## Setup groups to be returned

Go to Security (side menu) > API.  Choose Authorization Servers tab and select `default` authorization Server. Select Scopes tab and click Add Scope.
  - name=groups
  - mark include in public metadata

Click on Claims tab > Add Claim
  - name=groups
  - Include in toke type=ID Token
  - value type=Groups
  - Filter Matches regex => .*
  - Include in= The following scopes `groups`

Now choose Applications (side menu) > Applications > Pick your app > Sign On tab > Edit **OpenID Connect ID Token** section
  - Groups claim type => Filter
  - Groups claim filter => **groups** Matches regex **.\***

## Go to Next Step

[Retrieve TKG Extensions](05_extensions_mgmt.md)
