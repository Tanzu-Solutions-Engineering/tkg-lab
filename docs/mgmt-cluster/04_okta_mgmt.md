# Setup an account with Okta for OpenID Connect (OIDC)

Setup a free Okta account: https://developer.okta.com/signup/

Once logged in...

Choose Directory (top menu) > People > Add Person:
- Set First Name, Last Name and Email: (e.g: Alana Smith, alana@winterfell.live)
- Password Set by Admin, YOUR_PASSWORD
- Uncheck user must change password on first login


Choose Directory (top menu) > Groups from the top menu > Add Groups:
- platform-team

Click on platform-team group > Manage People: Then add alana to the platform-team. Save

Choose Applications (top menu) > Add Application > Create New App > Web, Click Next.
  - Give your app a name: TKG
  - Remove Base URL
  - Login redirect URIs: https://dex.dragonstone.tkg-aws-e2-lab.winterfell.live/callback
  - Logout redirect URIs: https://dex.dragonstone.tkg-aws-e2-lab.winterfell.live/logout
  - Grant type allowed: Authorization Code
> Note: Use your dex-fqdn domain as defined in your params.yaml

Click Done button

Capture ClientID and Client Secret

Go to Security (top menu) > API > Authorization Servers > `default` authorization Server > Scopes tab > Add Scope
  - name=groups
  - mark include in public metadata

Click on Claims tab > Add Claim
  - name=groups
  - Include in toke type=ID Token
  - value type=Groups
  - Filter Matches regex => .*
  - Include in= The following scopes `groups`

On the top left, Choose the arrow next to Developer Console and choose Classic UI

Choose Applications (top menu) > Applications > Pick your app > Sign On tab > Edit **OpenID Connect ID Token** section
  - Groups claim type => Filter
  - Groups claim filter => **groups** Matches regex **.\***

## Go to Next Step

[Retrieve TKG Extensions](05_extensions_mgmt.md)
