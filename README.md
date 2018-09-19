# Kubernetes Job Buildkite Plugin

Allows your buildkite pipeline step to submit a kubernetes job.
Your buildkite repo will be checked out and made available to your job via an init container.
The agent will poll the job for completion, log the output and then delete the job.

Needs kustomize >= v1.0.7 and kubectl installed on your buildkite agent.
It also expects a secret called `buildkite-agent` with a key called `agent-ssh` which contains a private 
ssh key which is used to access git repositories.

## How?

* In your repo, create a kustomization overlay...

```
cat <<EOF > overlay/environment/kustomization.yaml
commonLabels:
  environment: test
bases:
- /kustomize/base
patches:
- batch.yaml
EOF

cat <<EOF > overlay/environment/batch.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: k8s-kustom-job
spec:
  template:
    metadata:
      annotations:
        iam.amazonaws.com/role: arn:aws:iam::123456789012:role/letmein
    spec:
      containers:
      - name: step
        image: bash
        command: [ "find", "." ]
EOF
```

* update your buildkite pipeline step to use the plugin

```
---
steps:

- label: ":kubernetes: job step"
  branches: master
  plugins:
    pr8kerl/kustomize-job:
      name: k8s-kustom-job
      overlay: overlays/environment
  agents:
    queue: bk-queue-name
```

* the plugin name parameter must match the name of the job in your overlay
* the plugin overlay parameter must match the overlay directory in your repo

