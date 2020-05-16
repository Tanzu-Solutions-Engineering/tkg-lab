# Update Okta for Application Team Users and Group

Go to your Okta Console.  Mine is https://dev-866145-admin.okta.com/dev/console.

Once logged in...

Choose Directory (top menu) > People > Add Person (For each user you add):
- Set First Name, Last Name and Email: (e.g: Cody Smith, cody@winterfell.live)
- Password Set by Admin, YOUR_PASSWORD
- Uncheck user must change password on first login

> Note: Do this for two users: Cody Smith, cody@winterfell.live; and Naomi Smith, naomi@winterfell.live.  Feel free to choose a different domain name.

Choose Directory (top menu) > Groups from the top menu > Add Groups:
- acme-fitness-devs

Click on acme-fitness-devs group > Manage People: Then add cody and naomi to the acme-fitness-devs. Save

## Go to Next Step

[Set policy on Workload Cluster and Namespace](docs/acme-fitness-lab/02_policy_acme.md)
