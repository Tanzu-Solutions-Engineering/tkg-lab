# Setup an account with Okta for OpenID Connect (OIDC)

Setup a free Okta account: https://developer.okta.com/signup/

Once logged in...

Choose Users->People from the top menu.

Add People.  For each user, Password Set by Admin, YOUR_PASSWORD, Uncheck user must change password:

- Alana Smith, alana@winterfell.live

Choose Users->Groups from the top menu.

Add Groups:

- platform-team

Click on platform-team group
Click Manage People, then add alana to the platform-team

Choose Applications from top menu.

Choose Web, Next.

Give your app a name: TKG
Remove Base URL
Login redirect URIs: https://dex.mgmt.tkg-aws-lab.winterfell.live/callback
Logout redirect URIs: https://dex.mgmt.tkg-aws-lab.winterfell.live/logout	
Grant type allowed: Authorization Code

> Note: Use your root domain above

Click Done button

Capture ClientID and Client Secret

Go to API->Authorization Servers on the top menu

Click on the `default` authorization Server

Click on Scopes tab, then Add Scope name=groups and mark include in public metadata

Click on Claims tab, then Add Claim 
  - name=groups
  - Include in toke type=ID Token
  - value type=Groups
  - Filter Matches regex => .*
  - Include in= The following scopes `groups`

On the top left, Choose the arrow next to Developer Console and choose Classic UI

Go to Applications->Applications

Pick your app

Pick Sign On sub tab of the app

Click the Edit button associated with **OpenID Connect ID Token**
Groups claim type => Filter
Groups claim filter => **groups** Matches regex **.\***