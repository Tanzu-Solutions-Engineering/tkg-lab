# One Step Foundation Deployment for AWS

This lab can be used to deploy all three clusters included in the foundational lab setup.  You will execute a single script that calls all the scripts included in the step-by-step guides.  

>Note: The labs depending on a master `params.yaml` file that is used for environment specific configuration data.  A sample `params.yaml` file is included at the root of this repo.  It is recommended you copy this file and rename it to params.yaml, and then start making your adjustments.  `params.yaml` is included in the `.gitignore` so your version won't be included in an any future commits you have to the repo.

Ensure that your copy of `params.yaml` indicates `aws` as the IaaS.

Now you can execute the following script to perform all of those tasks:

```bash
./scripts/deploy-all-aws.sh
```

>Note: This process should take about 30 minutes to complete.

## Tear Down

Execute the following script to tear down your environment.

```bash
./scripts/delete-all-aws.sh
```
