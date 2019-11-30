---
author: Savic
date: 2019-06-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-automatically-manage-dns-records-from-digitalocean-kubernetes-using-externaldns
---

# How To Automatically Manage DNS Records From DigitalOcean Kubernetes Using ExternalDNS

_The author selected the [Free and Open Source Fund](https://www.brightfunds.org/funds/foss-nonprofits) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

When deploying web apps to Kubernetes, you usually use [Services](an-introduction-to-kubernetes#other-kubernetes-components) and Ingresses to expose apps beyond the cluster at your desired domain. This involves manually configuring not only the Ingress, but also the DNS records at your provider, which can be a time-consuming and error-prone process. This can become an obstacle as your application grows in complexity; when the external IP changes, it is necessary to update the DNS records accordingly.

To overcome this, the [Kubernetes sig-network team](https://github.com/kubernetes/community/tree/master/sig-network) created [ExternalDNS](https://github.com/kubernetes-incubator/external-dns) for the purpose of automatically managing external DNS records from within a Kubernetes cluster. Once deployed, ExternalDNS works in the background and requires almost no additional configuration. Whenever a Service or Ingress is created or changed, ExternalDNS will update the records right away.

In this tutorial, you will install ExternalDNS to your [DigitalOcean Kubernetes](https://www.digitalocean.com/products/kubernetes/) cluster via Helm and configure it to use DigitalOcean as your DNS provider. Then, you will deploy a sample web app with an Ingress and use ExternalDNS to point it to your domain name. In the end, you will have an automated DNS record managing system in place for both Services and Ingresses.

## Prerequisites

- A DigitalOcean Kubernetes cluster with your connection configured as the `kubectl` default. Instructions on how to configure `kubectl` are shown under the **Connect to your Cluster** step when you create your cluster. To create a Kubernetes cluster on DigitalOcean, see [Kubernetes Quickstart](https://www.digitalocean.com/docs/kubernetes/quickstart/).

- The Helm package manager installed on your local machine, and Tiller installed on your cluster. To do this, complete Steps 1 and 2 of the [How To Install Software on Kubernetes Clusters with the Helm Package Manager](how-to-install-software-on-kubernetes-clusters-with-the-helm-package-manager) tutorial.

- The Nginx Ingress Controller installed on your cluster using Helm in order to use ExternalDNS with Ingress Resources. To do this, follow [How to Set Up an Nginx Ingress on DigitalOcean Kubernetes Using Helm](how-to-set-up-an-nginx-ingress-on-digitalocean-kubernetes-using-helm). You’ll need to set the `publishService` property to `true` as per the instructions in Step 2.

- A DigitalOcean API key (Personal Access Token) with read and write permissions. To create one, visit [How to Create a Personal Access Token](https://www.digitalocean.com/docs/api/create-personal-access-token/).

- A fully registered domain name. This tutorial will use `echo.example.com` throughout. You can purchase a domain name on [Namecheap](https://www.namecheap.com/), get one for free on [Freenom](https://www.freenom.com/en/index.html?lang=en), or use the domain registrar of your choice.

## Step 1 — Installing ExternalDNS Using Helm

In this section, you will install ExternalDNS to your cluster using Helm and configure it to work with the DigitalOcean DNS service.

In order to override some of the default settings of the ExternalDNS Helm chart, you’ll need to create a `values.yaml` file that you’ll pass in to Helm during installation. On the machine you use to access your cluster in the prerequisites, create the file by running:

    nano externaldns-values.yaml

Add the following lines:

externaldns-values.yaml

    rbac:
      create: true
    
    provider: digitalocean
    
    digitalocean:
      apiToken: your_api_token
    
    interval: "1m"
    
    policy: sync # or upsert-only
    
    # domainFilters: ['example.com']

In the first block, you enable [RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) (Role Based Access Control) manifest creation, which must be enabled on RBAC-enabled Kubernetes clusters like DigitalOcean. In the next line, you set the DNS service provider to DigitalOcean. Then, in the next block, you’ll add your DigitalOcean API token by replacing `your_api_token`.

The next line sets the interval at which ExternalDNS will poll for changes to Ingresses and Services. You can set it to a lower value to propogate changes to your DNS faster.

The `policy` setting determines whether ExternalDNS will only insert DNS records (`upsert-only`) or create and delete them as needed (`sync`). Fortunately, since version 0.3, ExternalDNS supports the concept of ownership by creating accompanying [TXT](https://en.wikipedia.org/wiki/TXT_record) records in which it stores information about the domains it creates, limiting its scope of action to only those it created.

The `domainFilters` parameter is used for limiting the domains that ExternalDNS can manage. You can uncomment it and enter your domains in the form of a string array, but this isn’t necessary.

When you’ve finished editing, save and close the file.

Now, install ExternalDNS to your cluster by running the following command:

    helm install stable/external-dns --name external-dns -f externaldns-values.yaml

The output will look similar to the following:

    OutputNAME: external-dns
    LAST DEPLOYED: ...
    NAMESPACE: default
    STATUS: DEPLOYED
    
    RESOURCES:
    ==> v1/Pod(related)
    NAME READY STATUS RESTARTS AGE
    external-dns-69c545655f-xqjjf 0/1 ContainerCreating 0 0s
    
    ==> v1/Secret
    NAME TYPE DATA AGE
    external-dns Opaque 1 0s
    
    ==> v1/Service
    NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    external-dns ClusterIP 10.245.47.69 <none> 7979/TCP 0s
    
    ==> v1/ServiceAccount
    NAME SECRETS AGE
    external-dns 1 0s
    
    ==> v1beta1/ClusterRole
    NAME AGE
    external-dns 0s
    
    ==> v1beta1/ClusterRoleBinding
    NAME AGE
    external-dns 0s
    
    ==> v1beta1/Deployment
    NAME READY UP-TO-DATE AVAILABLE AGE
    external-dns 0/1 1 0 0s
    
    
    NOTES:
    ...

You can verify the ExternalDNS creation by running the following command:

    kubectl --namespace=default get pods -l "app=external-dns,release=external-dns" -w

    OutputNAME READY STATUS RESTARTS AGE
    external-dns-69bfcf8ccb-7j4hp 0/1 ContainerCreating 0 3s

You’ve installed ExternalDNS to your Kubernetes cluster. Next, you will deploy an example web app, expose it using an Nginx Ingress, and let ExternalDNS automatically point your domain name to the appropriate Load Balancer.

## Step 2 — Deploying and Exposing an Example Web App

In this section, you will deploy a dummy web app to your cluster in order to expose it using your Ingress. Then you’ll set up ExternalDNS to automatically configure DNS records for you. In the end, you will have DNS records for your domain pointed to the Load Balancer of the Ingress.

The dummy web app you’ll deploy is [`http-echo`](https://hub.docker.com/r/hashicorp/http-echo/) by Hashicorp. It is an in-memory web server that echoes back the message you give it. You’ll store its Kubernetes manifests in a file named `echo.yaml`. Create it and open it for editing:

    nano echo.yaml

Add the following lines to your file:

echo.yaml

    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: echo-ingress
    spec:
      rules:
      - host: echo.example.com
        http:
          paths:
          - backend:
              serviceName: echo
              servicePort: 80
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: echo
    spec:
      ports:
      - port: 80
        targetPort: 5678
      selector:
        app: echo
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: echo
    spec:
      selector:
        matchLabels:
          app: echo
      replicas: 3
      template:
        metadata:
          labels:
            app: echo
        spec:
          containers:
          - name: echo
            image: hashicorp/http-echo
            args:
            - "-text=Echo!"
            ports:
            - containerPort: 5678

In this configuration, you define a Deployment, an Ingress, and a Service. The Deployment consists of three replicas of the `http-echo` app, with a custom message (`Echo!`) passed in. The Service is defined to allow access to the Pods in the Deployment via port `80`. The Ingress is configured to expose the Service at your domain.

Replace `echo.example.com` with your domain, then save and close the file.

Now there is no need for you to configure the DNS records for the domain manually. ExternalDNS will do so automatically, as soon as you apply the configuration to Kubernetes.

To apply the configuration, run the following command:

    kubectl create -f echo.yaml

You’ll see the following output:

    Outputingress.extensions/echo-ingress created
    service/echo created
    deployment.apps/echo created

You’ll need to wait a short amount of time for ExternalDNS to notice the changes and create the appropriate DNS records. The `interval` setting in the Helm chart governs the length of time you’ll need to wait for your DNS record creation. In `values.yaml`, the interval length is set to 1 minute by default.

You can visit your DigitalOcean Control Panel to see an A and TXT record.

![Control Panel - Generated DNS Records](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/kubernetes_externaldns/externaldns.png)

Once the specified time interval has passed, access your domain using `curl`:

    curl echo.example.com

You’ll see the following output:

    OutputEcho!

This message confirms you’ve configured ExternalDNS and created the necessary DNS records to point to the Load Balancer of the Nginx Ingress Controller. If you see an error message, give it some time. Or, you can try accessing your domain from your browser where you’ll see `Echo!`.

You’ve tested ExternalDNS by deploying an example app with an Ingress. You can also observe the new DNS records in your DigitalOcean Control Panel. In the next step, you’ll expose the Service at your domain name.

## Step 3 — (Optional) Exposing the App Using a Service

In this optional section, you’ll use Services with ExternalDNS instead of Ingresses. ExternalDNS allows you to make different Kubernetes resources available to DNS servers. Using Services is a similar process to Ingresses with the configuration modified for this alternate resource.

**Note:** Following this step will delete the DNS records you’ve just created.

Since you’ll be customizing the Service contained in `echo.yaml`, you won’t need the `echo-ingress` anymore. Delete it using the following command:

    kubectl delete ing echo-ingress

The output will be:

    Outputingress.extensions/echo-ingress deleted

ExternalDNS will delete the existing DNS records it created in the previous step. In the remainder of the step, you can use the same domain you have used before.

Next, open the `echo.yaml` file for editing:

    nano echo.yaml

Replace the file contents with the following lines:

echo.yaml

    apiVersion: v1
    kind: Service
    metadata:
      name: echo
      annotations:
        external-dns.alpha.kubernetes.io/hostname: echo.example.com
    spec:
      type: LoadBalancer
      ports:
      - port: 80
        targetPort: 5678
      selector:
        app: echo
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: echo
    spec:
      selector:
        matchLabels:
          app: echo
      replicas: 3
      template:
        metadata:
          labels:
            app: echo
        spec:
          containers:
          - name: echo
            image: hashicorp/http-echo
            args:
            - "-text=Echo!"
            ports:
            - containerPort: 5678

You’ve removed Ingress from the file for the previous set up and changed the Service type to `LoadBalancer`. Furthermore, you’ve added an annotation specifying the domain name for ExternalDNS.

Apply the changes to your cluster by running the following command:

    kubectl apply -f echo.yaml

The output will be:

    Outputservice/echo configured
    deployment.apps/echo configured

You can watch the Service’s Load Balancer become available by running:

    kubectl get svc echo -w

You will see output similar to the following:

    OutputNAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    echo LoadBalancer 10.245.81.235 <pending> 80:31814/TCP 8s
    ...

As in the previous step, you’ll need to wait some time for the DNS records to be created and propagated. Once that is done, `curl` the domain you specified:

    curl echo.example.com

The output will be the same as the previous step:

    OutputEcho!

If you get an error, wait a little longer, or you can try a different domain. Since DNS records are cached on client systems, it may take a long time for the changes to actually propagate.

In this step, you created a Service (of type `LoadBalancer`) and pointed it to your domain name using ExternalDNS.

## Conclusion

ExternalDNS works silently in the background and provides a friction-free experience. Your Kubernetes cluster has just become the central source of truth regarding the domains. You won’t have to manually update DNS records anymore.

The real power of ExternalDNS will become apparent when creating testing environments from a Continuous Delivery system. If you want to set up one such system on your Kubernetes cluster, visit [How To Set Up a CD Pipeline with Spinnaker on DigitalOcean Kubernetes](how-to-set-up-a-cd-pipeline-with-spinnaker-on-digitalocean-kubernetes).
