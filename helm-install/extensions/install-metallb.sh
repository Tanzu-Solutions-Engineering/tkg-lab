

helm upgrade -n metallb --create-namespace --install metallb bitnami/metallb -f $METALLB_VALUES_FILE