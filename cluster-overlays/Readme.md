# Cluster Overlays

## Context

Tanzu Kubernetes Grid (TKG) leverages the Carvel tool suite (specifically [ytt](http://carvel.dev/ytt)) to dynamically
generate the [cluster-api](https://cluster-api.sigs.k8s.io/) resources that are used intially create clusters.

Furthmore, TKG has defined a set of parameters (and default values) that are used as input to this generatation process.  [TKG Docs](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.3/vmware-tanzu-kubernetes-grid-13/GUID-tanzu-config-reference.html) provide details on these parameters.

Whether you are using the UI installer or the cli to create a cluster with TKG, a cluster-config.yaml file is created/used to customize the default parameters for a given cluster.

The identified parameters represent the tested and supported set of configuration options for use.

## Beyond Out of the Box Configuraiton

You may find that your specific requires necessitates a configuration that is exposed via the OOTB configuration parameters.  Since TKG is built upon the open cluster-api, and the extensible templating provided by ytt, you have the option to create **overlays** to manipulate the cluster-api manifests prior to sending them off to the kubenetes api.

## Opinions

[TKG Docs](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.3/vmware-tanzu-kubernetes-grid-13/GUID-tanzu-k8s-clusters-config-plans.html) share the **mechanics** of different ways to customize beyond the OOTB parameters using overlays and plans.  There are options to use overlays and plans, which are two different approaches.

This guide walks through an opinionated approach to create/manage a set of customizations that you will maintain and own.  Generally accepted best practices are still evolving.  Considerations used in the development this opinion are:

- Desire to isolate custom configuration with a single overlay.
- Use a custom parameter that exposes the desired customization.
- By default the customization will not be performed.
- Operator enables the customization by setting relevent parameter in cluster-config.yaml.
- Desire to be able to place overlays into source control repository.
- Keep plans as OOTB dev/prod and use custom parameters.  This way customizations are visible in cluster-config.yaml and not obscured behind plans

## Common Customizations

If you find that you are creating customizations for something you feel should be included as an OOTB customation, work with your Tanzu SE to submit a feature request.  It maybe with successive releases, you can remove your overlays you custom parameters become OTTB parameters.

## Customizations

This guide showcases the following customizations used during TKG implementations and may be good candidates for future OOTB parameters.

- Custom Network Time Protocols
- Custom Search Domains to be used for short form DNS
- Custom DNS servers
- Custom MTU network settings
- Custom Trusted CA Certs

Each of these have two files:

- **nnn-default-values.yaml** - Defines the custom parameter and the default value
- **nnn.yaml** - yyt overlay file that applies the appropriate customization

## Prepare Overlays

You can execute this script to copy the overlays (and custom parameter definitions) into your machine's `~/.tanzu` directory structure.

```bash
./scripts/prep-cluster-overlays.sh
```

## Custom Config

The following paramaters can now be used within cluster-config.yaml files to trigger the overlays.

```yaml
CUSTOM_NTP_SERVERS: 
CUSTOM_SEARCH_DOMAIN: 
CUSTOM_NAMESERVERS: 
CUSTOM_MTU: 
CUSTOM_TRUSTED_CERTS_B64: 
```

## Creating and Testing Overlay/Parameter Parings

While creating the overlays, it is helpful to incrementally test.  The approach used to create these overlays is to have an existing TKG management cluster and then leverage the `--dry-run` flag to exercise the ytt templating and determine if your overlay is having the impact you expect in the resultant cluster-api resources.

```bash
CLUSTER_NAME=bearisland # or any cluster name of your choosing
CLUSTER_CONFIG=generated/$CLUSTER_NAME/cluster-config.yaml # or any cluster-config of your choosing
SOME_KEY=ntp # some relevant cluster-api spec key that you are looking to modif
# The output of tanzu cluste create is passed through grep to find the key and context you are looking for
tanzu cluster create -f $CLUSTER_CONFIG --dry-run | grep $SOME_KEY -C 10
```

## References

- [TKG Docs Custom Overlays and Plans](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.3/vmware-tanzu-kubernetes-grid-13/GUID-tanzu-k8s-clusters-config-plans.html)
- [TKG Docs to Trust Custom CA Certs](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.3/vmware-tanzu-kubernetes-grid-13/GUID-cluster-lifecycle-secrets.html?hWord=N4IghgNiBcIC4GsDmBaAxgVwM5wPYFt0wA6ABwFN8QBfIA#trust-custom-ca-certificates-on-cluster-nodes-3)
- [ytt Testing](https://carvel.dev/ytt/)
- [ytt Documentation](https://carvel.dev/ytt/docs/latest/)