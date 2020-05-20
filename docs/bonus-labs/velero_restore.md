# Velero Restore

What if we accidentally delete our application or the namespace that we used for the application.  This lab will show backing up and restoring with Velero.  To start, let's perform a namespace-specific backup:

```bash
velero backup create wlc-1-acme-fitness --include-namespaces acme-fitness
Backup request "wlc-1-acme-fitness" submitted successfully.
Run `velero backup describe wlc-1-acme-fitness` or `velero backup logs wlc-1-acme-fitness` for more details.

velero backup describe wlc-1-acme-fitness
<look for Completed>
```

The first test is to delete the deployments and PVCs within the namespace.  This will remove all pods and persistent data:

```bash
kubectl delete deployment -n acme-fitness --all
kubectl delete svc -n acme-fitness --all
kubectl delete pvc -n acme-fitness --all
kubectl get all,pvc -n acme-fitness
```

Now we can run the restore from velero:

```bash
velero restore create wlc-1-acme-fitness-04-24-2020 --from-backup wlc-1-acme-fitness
velero restore describe wlc-1-acme-fitness-04-24-2020
k get all,pvc -n acme-fitness
```

That's it! Back in business.
