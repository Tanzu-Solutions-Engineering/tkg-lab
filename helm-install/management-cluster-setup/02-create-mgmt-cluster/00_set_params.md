# Setup Parameters in param.yml file:

From the steps executed earlier, fill out the params file:

      aws:
        region: us-east-2
        access-key-id: <aws-access-id>
        secret-access-key: <aws-secret-access-id>
        dns:
          hosted-zone-id: <aws hosted zone from the step above>
          mgmt:
            name: '*.mgmt.tkg.lab.<your-domain>'
          svc:
            name: '*.svc.tkg.lab.<your-domain>'
          workload:
            name: '*.app.tkg.lab.<your-domain>'

      mgmtCluster:
        name: tkg-mgmt-cluster
        velero-bucket:
      svcCluster:
        name: shared-svc-cluster
        gangway: gangway.svc.tkg.lab.<your-domain>
        secret: supersecret
        velero-bucket: <AWS Bucket for Velero e.g: tkg-mgmt-velero-bucket>
      wlCluster:
        name: workload-cluster
        gangway: gangway.app.tkg.lab.<your-domain>
        secret: supersecret
        velero-bucket:
      oidc:
        # e.g: <your okta domain>//oauth2/default
        # https://dev-XXXXXX.okta.com/oauth2/default
        oidcUrl: <You can get this from OKTA setup from above>
        oidcClientId: <encoded BASE64 value from above>
        oidcClientSecret: <encoded BASE64 value from above>

      dex:
        host: dex.mgmt.tkg.lab.<your-domain>

      wavefront:
        apiKey: <your-wavefront-key>

      vmware:
        id: shashmi@vmware.com

      elasticsearch:
        host: elasticsearch.svc.tkg.lab.<your-domain>
        port: 80
      kibana:
        host: kibana.svc.tkg.lab.<your-domain>
