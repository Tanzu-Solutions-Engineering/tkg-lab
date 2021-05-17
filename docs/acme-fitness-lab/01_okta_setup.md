# Update Okta for Application Team Users and Group

Go to your Okta Console.

Once logged in...

You will need to go to the Admin interface.  If you are in the standard interface by default, choose green Admin button on the top right.

## Create Developer User(s)

Choose Directory (side menu) > People > Add Person (For each user you add):
- Set First Name, Last Name and Email: (e.g: Cody Smith, cody@winterfell.live)
- Password Set by Admin, YOUR_PASSWORD
- Uncheck user must change password on first login

> Note: Do this for two users: Cody Smith, cody@winterfell.live; and Naomi Smith, naomi@winterfell.live.  Feel free to choose a different domain name.

## Create Development Group

Choose Directory (side menu) > Groups and then > Add Group:
- acme-fitness-devs

Click on acme-fitness-devs group > Manage People: Then add cody and naomi to the acme-fitness-devs. Save

## Go to Next Step

[Set policy on Workload Cluster and Namespace](02_policy_acme.md)
