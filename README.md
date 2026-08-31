
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
* [External MongoDB Configuration](#external-mongodb-configuration)
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

If you're using Traefik Ingress or running on OpenShift, similar definitions are included in the values.yaml file (`ingressTraefik`, `ingressOpenshift`).

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

## External MongoDB Configuration

By default, Oobeya deploys and manages its own internal MongoDB instance. If you want to use your own external MongoDB — a single instance or a replica set — set `oobeyaExternalMongo.isExternal: true` and provide your connection URI.

```yaml
oobeyaExternalMongo:
  isExternal: true
  mongoUri: "<your-mongodb-connection-uri>"
  healthCheckHost: "<a-reachable-mongo-host>"
  healthCheckPort: "27017"
```

### How `mongoUri` works

Paste your MongoDB connection URI exactly as it was given to you — host(s), credentials, database name, and full query string all included. Oobeya automatically detects and replaces only the database name in the URI for each of its services; everything else (hosts, credentials, `authSource`, `replicaSet`, `tls`, etc.) is preserved as-is. You do not need to split the URI into separate fields, and you do not need to remove or edit the database name in it — the chart handles that.

Each Oobeya service uses its own MongoDB database, defined under `oobeyaExternalMongo.databases`:

```yaml
oobeyaExternalMongo:
  databases:
    dashboard: "dashboardDB"
    devteam: "devteamDB"
    gitwiser: "gitwiserDB"
    uaa: "uaaDB"
    agilespace: "agilespaceDB"
    addons: "addonsDB"
    gateway: "gatewayDB"
```

You may rename these to match database names your DBA has already provisioned — the chart will still build a correct, valid URI for every service.

### Single-instance MongoDB example

```yaml
oobeyaExternalMongo:
  isExternal: true
  mongoUri: "mongodb://oobeya_user:StrongPassword@mongo.example.com:27017/anyDB?authSource=admin"
  healthCheckHost: "mongo.example.com"
  healthCheckPort: "27017"
```

### Shared / Replica Set MongoDB example

```yaml
oobeyaExternalMongo:
  isExternal: true
  mongoUri: "mongodb://oobeya_user:StrongPassword@mongo01.example.com:27017,mongo02.example.com:27017,mongo03.example.com:27017/anyDB?replicaSet=rs0&authSource=admin&tls=true&readPreference=primaryPreferred"
  healthCheckHost: "mongo01.example.com"
  healthCheckPort: "27017"
```

### About `healthCheckHost` / `healthCheckPort`

These two fields are used only by an init-container that waits for MongoDB to become reachable before the Dashboard service starts. They are separate from `mongoUri` because a replica set URI can list several hosts, while this TCP check needs exactly one. Point them to any single node you expect to be reachable — for a replica set, any one of its members is fine.

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

### OpenShift Route

If you're running on OpenShift, enable `ingressOpenshift` instead of `ingressNginx`/`ingressTraefik`. It creates a `route.openshift.io/v1` `Route` for each path (`/`, `/api`, `/apis`, `/v3/api-docs`) pointing at the same services and ports used by the other ingress options.

```yaml
ingressOpenshift:
  enabled: true
  host: "oobeya.apps.yourcluster.example.com"
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
```

Or with `--set`:

```
  --set ingressOpenshift.enabled=true \
  --set ingressOpenshift.host="oobeya.apps.yourcluster.example.com"
```

## Upgrade Oobeya Version

You can successfully update by following the upgrade steps for the current versions.

### Upgrade version with values.yaml

```
helm repo update

helm upgrade oobeya oobeya/oobeya \
  -f prod-values.yaml \
  --set beVersion=2.0.xxx \
  --set feVersion=2.0.xxx
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
  --set beVersion=2.0.xxx \
  --set feVersion=2.0.xxx
```



## Documents

For any post-installation support, please contact us at https://docs.oobeya.io or support@oobeya.io.


