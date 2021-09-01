#!/bin/bash -ex

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh


#In honor of @lamw
PREP_VSPHERE_OBJECTS=false
DEPLOY_MGMT_CLUSTER=false
REGISTER_MGMT_CLUSTER=false
SETUP_DNS=false
INSTALL_MGMT_AKO=false
INSTALL_MGMT_CONTOUR=false
INSTALL_MGMT_EXT_DNS=false
INSTALL_MGMT_CLUSTER_ISSUER=false
UPDATE_PINNIPED_CONFIG=false
DEPLOY_SS_CLUSTER=false
DEPLOY_SS_APPS=false
DEPLOY_SS_HARBOR=false
DEPLOY_SS_TBS=false
DEPLOY_FACADE_CLUSTER=false
DEPLOY_WORKLOAD_CLUSTER=false
DEPLOY_FACADE_TSM_INTEGRATION=false
DEPLOY_FACADE_TSM_GNS=false
DEPLOY_FACADE_APPS=false
DEPLOY_FACADE_SCG=false
DEPLOY_FACADE_KN=false
DEPLOY_WORKLOAD_TSM_INTEGRATION=false
DEPLOY_WORKLOAD_TSM_GNS=false
DEPLOY_WORKLOAD_APPS=false
DEPLOY_WORKLOAD_KN=false
CREATE_SS_GITLAB_TMC_WORKSPACE=false
DEPLOY_SS_GITLAB=true
DEPLOY_APP_ACCELERATOR=true
DEPLOY_ARGOCD=false
PUSH_ACCELERATORS=true



#prep vsphere
if  $PREP_VSPHERE_OBJECTS ; then
    $TKG_LAB_SCRIPTS/01-prep-vsphere-objects.sh
else
    echo "Skipping vSphere prep"
fi


if  $DEPLOY_MGMT_CLUSTER ; then
    $TKG_LAB_SCRIPTS/02-deploy-vsphere-mgmt-cluster.sh
    $TKG_LAB_SCRIPTS/03-post-deploy-mgmt-cluster.sh
else
    echo "Skipping mgmt cluster"
fi


if  $REGISTER_MGMT_CLUSTER ; then
    $TKG_LAB_SCRIPTS/tmc-mgmt-cluster-attach.sh
else
    echo "Skipping mgmt cluster registration"
fi


if  $SETUP_DNS ; then
    $TKG_LAB_SCRIPTS/create-dns-zone.sh
    $TKG_LAB_SCRIPTS/retrieve-lets-encrypt-ca-cert.sh
else
    echo "Skipping DNS Setup and LetsEncrypt CA"
fi

if  $INSTALL_MGMT_AKO ; then
    export KUBECONFIG=~/.kube-tkg/config
    export MGMT_CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
    kubectl config set-context ${MGMT_CLUSTER_NAME}-admin@${MGMT_CLUSTER_NAME}
    $TKG_LAB_SCRIPTS/deploy-ako.sh $(yq e .management-cluster.name $PARAMS_YAML)
else
    echo "Skipping AKO Install on mgmt cluster"
fi

if  $INSTALL_MGMT_CONTOUR ; then
    export KUBECONFIG=~/.kube-tkg/config
    export MGMT_CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
    kubectl config set-context ${MGMT_CLUSTER_NAME}-admin@${MGMT_CLUSTER_NAME}
    $TKG_LAB_SCRIPTS/generate-and-apply-contour-yaml.sh ${MGMT_CLUSTER_NAME}
else
    echo "Skipping mgmt contour install"
fi


if  $INSTALL_MGMT_EXT_DNS ; then
    export KUBECONFIG=~/.kube-tkg/config
    export MGMT_CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
    kubectl config set-context ${MGMT_CLUSTER_NAME}-admin@${MGMT_CLUSTER_NAME}
    $TKG_LAB_SCRIPTS/generate-and-apply-external-dns-yaml.sh \
        ${MGMT_CLUSTER_NAME} \
        $(yq e .management-cluster.ingress-fqdn $PARAMS_YAML)
else
    echo "Skipping mgmt external dns install"
fi


if  $INSTALL_MGMT_CLUSTER_ISSUER ; then
    export KUBECONFIG=~/.kube-tkg/config
    export MGMT_CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
    kubectl config set-context ${MGMT_CLUSTER_NAME}-admin@${MGMT_CLUSTER_NAME}
    $TKG_LAB_SCRIPTS/generate-and-apply-cluster-issuer-yaml.sh $(yq e .management-cluster.name $PARAMS_YAML)
else
    echo "Skipping mgmt clusterissuer"
fi


if  $UPDATE_PINNIPED_CONFIG ; then
    export KUBECONFIG=~/.kube-tkg/config
    export MGMT_CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
    kubectl config set-context ${MGMT_CLUSTER_NAME}-admin@${MGMT_CLUSTER_NAME}
    $TKG_LAB_SCRIPTS/update-pinniped-configuration.sh
else
    echo "Skipping pinniped update"
fi

if  $DEPLOY_SS_CLUSTER ; then
    $TKG_LAB_SCRIPTS/deploy-workload-cluster-tmc-ytt.sh  $(yq e .shared-services-cluster.name $PARAMS_YAML) \
        $(yq e .shared-services-cluster.worker-replicas $PARAMS_YAML) \
        $(yq e .shared-services-cluster.controlplane-endpoint $PARAMS_YAML) \
        $(yq e .shared-services-cluster.kubernetes-version $PARAMS_YAML)
else
    echo "Skipping shared services cluster create"
fi


if  $DEPLOY_SS_APPS ; then
    export KUBECONFIG=keys/$(yq e .shared-services-cluster.name $PARAMS_YAML).kubeconfig
    kubectl apply -f tkg-extensions-mods-examples/tanzu-kapp-namespace.yaml
    $TKG_LAB_SCRIPTS/deploy-cert-manager.sh $(yq e .shared-services-cluster.name $PARAMS_YAML)
    $TKG_LAB_SCRIPTS/generate-and-apply-contour-yaml.sh $(yq e .shared-services-cluster.name $PARAMS_YAML)
    $TKG_LAB_SCRIPTS/generate-and-apply-external-dns-yaml.sh \
    $(yq e .shared-services-cluster.name $PARAMS_YAML) \
    $(yq e .shared-services-cluster.ingress-fqdn $PARAMS_YAML)
    $TKG_LAB_SCRIPTS/generate-and-apply-cluster-issuer-yaml.sh $(yq e .shared-services-cluster.name $PARAMS_YAML)    
else
    echo "Skipping shared services apps install"
fi

if  $DEPLOY_SS_HARBOR ; then
    export KUBECONFIG=keys/$(yq e .shared-services-cluster.name $PARAMS_YAML).kubeconfig
    $TKG_LAB_SCRIPTS/generate-and-apply-harbor-yaml.sh \
        $(yq e .management-cluster.name $PARAMS_YAML) \
        $(yq e .shared-services-cluster.name $PARAMS_YAML)
else
    echo "Skipping shared services apps install"
fi

if  $DEPLOY_SS_TBS ; then
    export KUBECONFIG=keys/$(yq e .shared-services-cluster.name $PARAMS_YAML).kubeconfig
    $TKG_LAB_SCRIPTS/deploy-tbs.sh \
        $(yq e .shared-services-cluster.name $PARAMS_YAML)
else
    echo "Skipping TBS install"
fi

if  $DEPLOY_FACADE_CLUSTER ; then
    $TKG_LAB_SCRIPTS/deploy-workload-cluster-tmc-ytt.sh  $(yq e .facade-cluster.name $PARAMS_YAML) \
        $(yq e .facade-cluster.worker-replicas $PARAMS_YAML) \
        $(yq e .facade-cluster.controlplane-endpoint $PARAMS_YAML) \
        $(yq e .facade-cluster.kubernetes-version $PARAMS_YAML)
else
    echo "Skipping facade cluster create"
fi

if  $DEPLOY_FACADE_TSM_INTEGRATION ; then
    $TKG_LAB_SCRIPTS/deploy-tsm-integration-tmc-ytt.sh  $(yq e .facade-cluster.name $PARAMS_YAML) 
else
    echo "Skipping facade tsm integration"
fi

if  $DEPLOY_FACADE_TSM_GNS ; then
    export KUBECONFIG=keys/$(yq e .facade-cluster.name $PARAMS_YAML).kubeconfig
    $TKG_LAB_SCRIPTS/deploy-tsm-gns.sh  $(yq e .facade-cluster.name $PARAMS_YAML) 
else
    echo "Skipping facade tsm integration"
fi


if  $DEPLOY_WORKLOAD_CLUSTER ; then
    $TKG_LAB_SCRIPTS/deploy-workload-cluster-tmc-ytt.sh  $(yq e .workload-cluster.name $PARAMS_YAML) \
        $(yq e .workload-cluster.worker-replicas $PARAMS_YAML) \
        $(yq e .workload-cluster.controlplane-endpoint $PARAMS_YAML) \
        $(yq e .workload-cluster.kubernetes-version $PARAMS_YAML)
else
    echo "Skipping workload cluster create"
fi

if  $DEPLOY_WORKLOAD_TSM_INTEGRATION ; then
    $TKG_LAB_SCRIPTS/deploy-tsm-integration-tmc-ytt.sh  $(yq e .workload-cluster.name $PARAMS_YAML) 
else
    echo "Skipping workload TSM integration"
fi

if  $DEPLOY_WORKLOAD_TSM_GNS ; then
    export KUBECONFIG=keys/$(yq e .workload-cluster.name $PARAMS_YAML).kubeconfig
    $TKG_LAB_SCRIPTS/deploy-tsm-gns.sh  $(yq e .workload-cluster.name $PARAMS_YAML) 
else
    echo "Skipping workload tsm integration"
fi

if  $DEPLOY_FACADE_APPS ; then
    export KUBECONFIG=keys/$(yq e .facade-cluster.name $PARAMS_YAML).kubeconfig
    kubectl apply -f tkg-extensions-mods-examples/tanzu-kapp-namespace.yaml
    $TKG_LAB_SCRIPTS/deploy-cert-manager.sh $(yq e .facade-cluster.name $PARAMS_YAML)
    $TKG_LAB_SCRIPTS/generate-and-apply-external-dns-yaml-no-contour.sh \
    $(yq e .facade-cluster.name $PARAMS_YAML) \
    $(yq e .facade-cluster.ingress-fqdn $PARAMS_YAML)
    $TKG_LAB_SCRIPTS/generate-and-apply-cluster-issuer-yaml.sh $(yq e .facade-cluster.name $PARAMS_YAML)    
else
    echo "Skipping facade apps install"
fi

if  $DEPLOY_FACADE_SCG ; then
    export KUBECONFIG=keys/$(yq e .facade-cluster.name $PARAMS_YAML).kubeconfig
    $TKG_LAB_SCRIPTS/deploy-scg.sh  $(yq e .facade-cluster.name $PARAMS_YAML) 
else
    echo "Skipping Facade cluster SCG Install"
fi


if  $DEPLOY_FACADE_KN ; then
    export KUBECONFIG=keys/$(yq e .facade-cluster.name $PARAMS_YAML).kubeconfig
    $TKG_LAB_SCRIPTS/deploy-kn.sh  $(yq e .facade-cluster.name $PARAMS_YAML) 
else
    echo "Skipping Facade cluster KN Install"
fi

if  $DEPLOY_WORKLOAD_APPS ; then
    export KUBECONFIG=keys/$(yq e .workload-cluster.name $PARAMS_YAML).kubeconfig
    kubectl apply -f tkg-extensions-mods-examples/tanzu-kapp-namespace.yaml
    $TKG_LAB_SCRIPTS/deploy-cert-manager.sh $(yq e .workload-cluster.name $PARAMS_YAML)
    $TKG_LAB_SCRIPTS/generate-and-apply-external-dns-yaml-no-contour.sh \
    $(yq e .workload-cluster.name $PARAMS_YAML) \
    $(yq e .workload-cluster.ingress-fqdn $PARAMS_YAML)
    $TKG_LAB_SCRIPTS/generate-and-apply-cluster-issuer-yaml.sh $(yq e .workload-cluster.name $PARAMS_YAML)    
else
    echo "Skipping workload apps install"
fi

if  $DEPLOY_WORKLOAD_KN ; then
    export KUBECONFIG=keys/$(yq e .workload-cluster.name $PARAMS_YAML).kubeconfig
    $TKG_LAB_SCRIPTS/deploy-kn.sh  $(yq e .workload-cluster.name $PARAMS_YAML) 
else
    echo "Skipping Workload cluster KN Install"
fi

if  $CREATE_SS_GITLAB_TMC_WORKSPACE ; then
    export KUBECONFIG=keys/$(yq e .shared-services-cluster.name $PARAMS_YAML).kubeconfig
    $TKG_LAB_SCRIPTS/create-gitlab-tmc-workspace.sh
else
    echo "Skipping Create Gitlab Workspace in TMC"
fi

if  $DEPLOY_SS_GITLAB ; then
    export KUBECONFIG=keys/$(yq e .shared-services-cluster.name $PARAMS_YAML).kubeconfig
    $TKG_LAB_SCRIPTS/deploy-gitlab-helm-ytt.sh
else
    echo "Skipping Shared Services Gitlab Install"
fi

if  $DEPLOY_APP_ACCELERATOR ; then
    export KUBECONFIG=keys/$(yq e .shared-services-cluster.name $PARAMS_YAML).kubeconfig
    $TKG_LAB_SCRIPTS/deploy-app-accelerator.sh
else
    echo "Skipping App Accelerator Install"
fi

if  $DEPLOY_ARGOCD ; then
    export KUBECONFIG=keys/$(yq e .shared-services-cluster.name $PARAMS_YAML).kubeconfig
    $TKG_LAB_SCRIPTS/generate-and-apply-argocd-yaml.sh
else
    echo "Skipping ArgoCD Install"
fi

if  $PUSH_ACCELERATORS ; then
    export KUBECONFIG=${TKG_LAB_SCRIPTS}/../keys/$(yq e .shared-services-cluster.name $PARAMS_YAML).kubeconfig
    $TKG_LAB_SCRIPTS/push-accelerators.sh
else
    echo "Skipping Push Accelerators"
fi
