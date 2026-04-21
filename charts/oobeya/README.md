
# Oobeya Engineering Intelligence Platform. Engineering metrics, DORA, and DevOps insights

Oobeya is a platform designed to help software engineering teams deliver high-quality products faster and more efficiently. We believe streamlined collaboration and data-driven insights are key to unlocking every team's full potential.

---

**Warning**: Installation requires a valid ```StorageClass```.
Before you begin, please ensure that your cluster has a configured ```StorageClass```, as ```Persistent Volume Claims``` are required.

We have two methods for installation and updates. 

- Using values.yaml.
- Using commands.

We prefer to use values.yaml for installation and updates. We want changes to be overwritten.

## Contents

* [Quick Start](#quick-start)
* [Install with Values.yaml](#install-with-Values.yaml)
* [Install with commands](#install-with-commands)
* [Oobeya Ingress Description](#oobeya-ingress-description)
* [Upgrade Oobeya Version](#upgrade-oobeya-version)
* [Documents](#documents)


## Quick Start

You can pull Oobeya from the repository.

```
helm repo add oobeya https://oobeyaio.github.io/oobeya-helm-chart/
helm repo update
```

Please create a namespace for Oobeya.

```
kubectl create namespace oobeya
```

Please request a token from the Oobeya team for registry access.

```
kubectl create secret docker-registry oobeya-secret \
  --docker-server=https://oobeya.azurecr.io \
  --docker-username=(Credentials-Name) \
  --docker-password=(Your-Credentials) \
  --namespace=oobeya
```

## Install with Values.yaml

```
helm show values oobeya/oobeya > prod-values.yaml
```

We need to make some changes to values.yaml.

```
    mongoStorage:
      pvcName: oobeya-mongo-pvc
      storageClassName: local-path                      # StorageClass Name
      size: 100Gi                                       # Storage Size
    gitwiserStorage:
      enabled: true
      pvcName: oobeya-gitwiser-pvc
      storageClassName: local-path                      # StorageClass Name
      size: 20Gi                                        # Storage Size
```

```
oobeyaDashboard:
   .
   .
   corsAllowedOrigin: "http://your-IP-or-Domain"        # Your DNS or IP address
```

If you're using Nginx Ingress for access:

```
ingressNginx:
  enabled: false
  className: "nginx"
  host: "oobeya.local"
```

If you're using Traefik Ingress, similar definitions are included in the values.yaml file.

Finally, you can install it using the file.

```
helm install oobeya oobeya/oobeya -f prod-values.yaml
```

Once the READY status for all services is 1/1, network traffic will be routed through the ingress configurations.

## Install with commands

A StorageClass is absolutely essential to prevent data loss within the cluster. You can run the application by specifying the StorageClass name and the amount to be allocated.

In the `oobeyaDashboard.corsAllowedOrigin` section, you must enter the domain through which the Oobeya interface will be accessed.

```
helm install oobeya oobeya/oobeya \
  --set storage.mongoStorage.storageClassName="local-path" \
  --set storage.mongoStorage.size="100Gi" \
  --set storage.gitwiserStorage.storageClassName="local-path" \
  --set storage.gitwiserStorage.enabled="true" \
  --set storage.gitwiserStorage.size="30Gi" \
  --set oobeyaDashboard.corsAllowedOrigin="http://Your-Domain"
```

Once the READY status for all services is 1/1, network traffic will be routed through the ingress configurations.

## Oobeya Ingress Setup

If you are using ingress-nginx within the cluster, you need to make some additions to the installation command.

```
  --set ingressNginx.enabled=true
  --set ingressNginx.host="your.domain.com"
```

Once you complete the setup using this example and all services reach the 1/1 READY status, you can access the domain via the interface.

```
helm install oobeya oobeya/oobeya \
  --set storage.mongoStorage.storageClassName="local-path" \
  --set storage.mongoStorage.size="100Gi" \
  --set storage.gitwiserStorage.storageClassName="local-path" \
  --set storage.gitwiserStorage.enabled="true" \
  --set storage.gitwiserStorage.size="30Gi" \
  --set oobeyaDashboard.corsAllowedOrigin="http://Your-Domain" \
  --set ingressNginx.enabled=true \
  --set ingressNginx.host="your.domain.com"
```

## Oobeya Ingress Description

| Path | Service Name | Service Port | Description |
| --- | --- | --- | --- | 
| / | oobeya-ui | 4200 | Frontend User Interface | 
| /api | oobeya-dashboard | 8080 | Core Dashboard API Services |
| /apis | oobeya-gateway | 8099 | Main System Gateway |
| /v3/api-docs | oobeya-gateway | 8099 | OpenAPI/Swagger Documentation |


### An example that could be provided for any ingress

You can use the path and port values provided here with any ingress provider, such as Istio, Kong, etc.

```
.
.
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: oobeya-ui
            port:
              number: 4200
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: oobeya-dashboard
            port:
              number: 8080
      - path: /apis
        pathType: Prefix
        backend:
          service:
            name: oobeya-gateway
            port:
              number: 8099
      - path: /v3/api-docs
        pathType: Prefix
        backend:
          service:
            name: oobeya-gateway
            port:
              number: 8099
```


### Traefik
If you're using Traefik, you should make the changes this way instead of using the example above.

```
  --set ingressTraefik.enabled=true \
  --set ingressTraefik.host="oobeya-traefik.yourdomain.com" \
```

## Upgrade Oobeya Version

You can successfully update by following the upgrade steps for the current versions.

### Upgrade version with values.yaml

```
helm repo update

helm upgrade oobeya oobeya/oobeya \
  -f prod-values.yaml \
  --set beVersion=2.0.859 \
  --set feVersion=2.0.564
```

### Upgrade version with commands

There are certain points to keep in mind when performing a version upgrade; specifically, everything included in the installation command must also be included in the upgrade command.

Alternatively, we can use the ```--reuse-values``` option. 

```
helm repo update oobeya 
```
```
helm upgrade oobeya oobeya/oobeya \
  --reuse-values \
  --set beVersion=2.0.859 \
  --set feVersion=2.0.564
```



## Documents

For any post-installation support, please contact us at https://docs.oobeya.io or support@oobeya.io.


