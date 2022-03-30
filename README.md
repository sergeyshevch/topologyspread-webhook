# Topology Spread webhook
[![Docker Repository on Quay](https://quay.io/repository/sergeyshevch/topologyspread-webhook/status "Docker Repository on Quay")](https://quay.io/repository/sergeyshevch/topologyspread-webhook)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fsergeyshevch%2Ftopologyspread-webhook.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fsergeyshevch%2Ftopologyspread-webhook?ref=badge_shield)
[![GitHub license](https://img.shields.io/github/license/sergeyshevch/topologyspread-webhook)](https://github.com/sergeyshevch/topologyspread-webhook/blob/main/LICENSE)

This project is a simple k8s mutating webhook than mutate pod specification and replace configured 
podAntiAffinity with topologySpreadConstraints.

Installed webhook will automatically mutate all pods that selected by webhook's label selector

## Installation

You can deploy topologyspread webhook with several ways.
1. With bundled manifests:
```shell
# You can simple apply ready manifest to your cluster, that will install topologyspread-webhook without customization
kubectl apply -f https://raw.githubusercontent.com/sergeyshevch/topologyspread-webhook/master/deploy/topologyspread-webhook-install-bundle.yaml
```

2. With kustomize:
```shell
# You can use kustomize for deployment
git clone https://github.com/sergeyshevch/topologyspread-webhook.git
kustomize build config/default | kubectl apply -f -
```

3. With helm chart (preferred)
```shell
helm add sergeyshevch sergeyshevch.github.io/sharts
helm install sergeyshevch/topologyspread-webhook --namespace topologyspread-webhook --create-namespace
```

## Verifying installation

You can verify the installation by checking topologyspread-webhook pod status

## Configuration

Topologyspread webhook support the following set of arguments.
- `metrics-bind-address` - The address the metric endpoint binds to. (default to `:8080`)
- `health-probe-bind-address` - The address the probe endpoint binds to. (default to `:8081`)
- `leader-elect` - Enable leader election (Only one replica will be active at any given time)
- `preferred-max-skew-default` - Max skew value that will be used in converting of PreferredDuringSchedulingIgnoredDuringExecution podAntiAffinity (default to `5`)

## Integrations
This projects can be easily integrated with next kubernetes projects/operators:
- cert-manager: MutatingWebhookConfiguration can use certificates from cert-manager (included in helm-chart)
- prometheus-operator: Helm chart includes ready ServiceMonitor configuration

## License

This project is released under the Apache 2.0 license

[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fsergeyshevch%2Ftopologyspread-webhook.svg?type=large)](https://app.fossa.com/projects/git%2Bgithub.com%2Fsergeyshevch%2Ftopologyspread-webhook?ref=badge_large)