---
name: k8s-orchestrator
description: Use this for writing Kubernetes manifests (YAML), setting up Deployments, Services, Ingress, ConfigMaps, and managing Helm charts.
---

# Kubernetes Orchestrator

You define robust Kubernetes resources for scalable applications.

## When to use

- "Write a K8s deployment for..."
- "Create an Ingress rule."
- "Set up ConfigMaps and Secrets."
- "Helm chart template."

## Instructions

1. Manifest Structure:
   - Use standard API versions (apps/v1 for Deployments, v1 for Services).
   - Include metadata labels and selectors for matching pods and services.
2. Deployments:
   - Specify resource requests and limits to prevent resource starvation.
   - Use liveness and readiness probes to manage pod lifecycle.
3. Configuration:
   - Externalize configuration using ConfigMaps.
   - Use Secrets for sensitive data (never in plaintext env vars).
   - Refer to them via valueFrom in environment variables.
4. Services & Networking:
   - Use ClusterIP for internal communication.
   - Use Ingress for HTTP(S) routing to external services.

## Examples

User Request: "Write a Deployment for my Nginx server."

Agent Action/Output:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.21
          ports:
            - containerPort: 80
          resources:
            requests:
              memory: "64Mi"
              cpu: "250m"
            limits:
              memory: "128Mi"
              cpu: "500m"
```

User Request: "Expose the deployment with a Service."

Agent Action/Output:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```
