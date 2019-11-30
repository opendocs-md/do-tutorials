---
author: Savic
date: 2019-05-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-on-digitalocean-kubernetes-using-helm
---

# How To Set Up an Nginx Ingress on DigitalOcean Kubernetes Using Helm

_The author selected the [Free and Open Source Fund](https://www.brightfunds.org/funds/foss-nonprofits) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

Kubernetes [Ingresses](https://kubernetes.io/docs/concepts/services-networking/ingress/) offer you a flexible way of routing traffic from beyond your cluster to internal Kubernetes Services. Ingress _Resources_ are objects in Kubernetes that define rules for routing HTTP and HTTPS traffic to Services. For these to work, an Ingress _Controller_ must be present; its role is to implement the rules by accepting traffic (most likely via a Load Balancer) and routing it to the appropriate Services. Most Ingress Controllers use only one global Load Balancer for all Ingresses, which is more efficient than creating a Load Balancer per every Service you wish to expose.

[Helm](https://helm.sh/) is a package manager for managing Kubernetes. Using Helm Charts with your Kubernetes provides configurability and lifecycle management to update, rollback, and delete a Kubernetes application.

In this guide, you’ll set up the Kubernetes-maintained [Nginx Ingress Controller](https://github.com/kubernetes/ingress-nginx) using Helm. You’ll then create an Ingress Resource to route traffic from your domains to example Hello World back-end services. Once you’ve set up the Ingress, you’ll install [Cert-Manager](https://github.com/jetstack/cert-manager) to your cluster to be able to automatically provision Let’s Encrypt TLS certificates to secure your Ingresses.

## Prerequisites

- A DigitalOcean Kubernetes cluster with your connection configuration configured as the `kubectl` default. Instructions on how to configure `kubectl` are shown under the **Connect to your Cluster** step shown when you create your cluster. To learn how to create a Kubernetes cluster on DigitalOcean, see [Kubernetes Quickstart](https://www.digitalocean.com/docs/kubernetes/quickstart/).

- The Helm package manager installed on your local machine, and Tiller installed on your cluster. Complete steps 1 and 2 of the [How To Install Software on Kubernetes Clusters with the Helm Package Manager](how-to-install-software-on-kubernetes-clusters-with-the-helm-package-manager) tutorial.

- A fully registered domain name with two available A records. This tutorial will use `hw1.example.com` and `hw2.example.com` throughout. You can purchase a domain name on [Namecheap](https://www.namecheap.com/), get one for free on [Freenom](https://www.freenom.com/en/index.html?lang=en), or use the domain registrar of your choice.

## Step 1 — Setting Up Hello World Deployments

In this section, before you deploy the Nginx Ingress, you will deploy a Hello World app called [`hello-kubernetes`](https://hub.docker.com/r/paulbouwer/hello-kubernetes/) to have some Services to which you’ll route the traffic. To confirm that the Nginx Ingress works properly in the next steps, you’ll deploy it twice, each time with a different welcome message that will be shown when you access it from your browser.

You’ll store the deployment configuration on your local machine. The first deployment configuration will be in a file named `hello-kubernetes-first.yaml`. Create it using a text editor:

    nano hello-kubernetes-first.yaml

Add the following lines:

hello-kubernetes-first.yaml

    apiVersion: v1
    kind: Service
    metadata:
      name: hello-kubernetes-first
    spec:
      type: ClusterIP
      ports:
      - port: 80
        targetPort: 8080
      selector:
        app: hello-kubernetes-first
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: hello-kubernetes-first
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: hello-kubernetes-first
      template:
        metadata:
          labels:
            app: hello-kubernetes-first
        spec:
          containers:
          - name: hello-kubernetes
            image: paulbouwer/hello-kubernetes:1.5
            ports:
            - containerPort: 8080
            env:
            - name: MESSAGE
              value: Hello from the first deployment!

This configuration defines a Deployment and a Service. The Deployment consists of three replicas of the `paulbouwer/hello-kubernetes:1.5` image, and an environment variable named `MESSAGE`—you will see its value when you access the app. The Service here is defined to expose the Deployment in-cluster at port `80`.

Save and close the file.

Then, create this first variant of the `hello-kubernetes` app in Kubernetes by running the following command:

    kubectl create -f hello-kubernetes-first.yaml

You’ll see the following output:

    Outputservice/hello-kubernetes-first created
    deployment.apps/hello-kubernetes-first created

To verify the Service’s creation, run the following command:

    kubectl get service hello-kubernetes-first

The output will look like this:

    OutputNAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    hello-kubernetes-first ClusterIP 10.245.85.236 <none> 80:31623/TCP 35s

You’ll see that the newly created Service has a ClusterIP assigned, which means that it is working properly. All traffic sent to it will be forwarded to the selected Deployment on port `8080`. Now that you have deployed the first variant of the `hello-kubernetes` app, you’ll work on the second one.

Open a file called `hello-kubernetes-second.yaml` for editing:

    nano hello-kubernetes-second.yaml

Add the following lines:

hello-kubernetes-second.yaml

    apiVersion: v1
    kind: Service
    metadata:
      name: hello-kubernetes-second
    spec:
      type: ClusterIP
      ports:
      - port: 80
        targetPort: 8080
      selector:
        app: hello-kubernetes-second
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: hello-kubernetes-second
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: hello-kubernetes-second
      template:
        metadata:
          labels:
            app: hello-kubernetes-second
        spec:
          containers:
          - name: hello-kubernetes
            image: paulbouwer/hello-kubernetes:1.5
            ports:
            - containerPort: 8080
            env:
            - name: MESSAGE
              value: Hello from the second deployment!

Save and close the file.

This variant has the same structure as the previous configuration; the only differences are in the Deployment and Service names, to avoid collisions, and the message.

Now create it in Kubernetes with the following command:

    kubectl create -f hello-kubernetes-second.yaml

The output will be:

    Outputservice/hello-kubernetes-second created
    deployment.apps/hello-kubernetes-second created

Verify that the second Service is up and running by listing all of your services:

    kubectl get service

The output will be similar to this:

    OutputNAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    hello-kubernetes-first ClusterIP 10.245.85.236 <none> 80:31623/TCP 54s
    hello-kubernetes-second ClusterIP 10.245.99.130 <none> 80:30303/TCP 12s
    kubernetes ClusterIP 10.245.0.1 <none> 443/TCP 5m

Both `hello-kubernetes-first` and `hello-kubernetes-second` are listed, which means that Kubernetes has created them successfully.

You’ve created two deployments of the `hello-kubernetes` app with accompanying Services. Each one has a different message set in the deployment specification, which allow you to differentiate them during testing. In the next step, you’ll install the Nginx Ingress Controller itself.

## Step 2 — Installing the Kubernetes Nginx Ingress Controller

Now you’ll install the Kubernetes-maintained [Nginx Ingress Controller](https://github.com/kubernetes/ingress-nginx) using Helm. Note that there are several [Nginx Ingresses](https://github.com/nginxinc/kubernetes-ingress/blob/master/docs/nginx-ingress-controllers.md).

The Nginx Ingress Controller consists of a Pod and a Service. The Pod runs the Controller, which constantly polls the `/ingresses` endpoint on the API server of your cluster for updates to available Ingress Resources. The Service is of type LoadBalancer, and because you are deploying it to a DigitalOcean Kubernetes cluster, the cluster will automatically create a [DigitalOcean Load Balancer](https://www.digitalocean.com/products/load-balancer/), through which all external traffic will flow to the Controller. The Controller will then route the traffic to appropriate Services, as defined in Ingress Resources.

Only the LoadBalancer Service knows the IP address of the automatically created Load Balancer. Some apps (such as [ExternalDNS](https://github.com/kubernetes-incubator/external-dns)) need to know its IP address, but can only read the configuration of an Ingress. The Controller can be configured to publish the IP address on each Ingress by setting the `controller.publishService.enabled` parameter to `true` during `helm install`. It is recommended to enable this setting to support applications that may depend on the IP address of the Load Balancer.

To install the Nginx Ingress Controller to your cluster, run the following command:

    helm install stable/nginx-ingress --name nginx-ingress --set controller.publishService.enabled=true

This command installs the Nginx Ingress Controller from the `stable` charts repository, names the Helm release `nginx-ingress`, and sets the `publishService` parameter to `true`.

The output will look like:

    OutputNAME: nginx-ingress
    LAST DEPLOYED: ...
    NAMESPACE: default
    STATUS: DEPLOYED
    
    RESOURCES:
    ==> v1/ConfigMap
    NAME DATA AGE
    nginx-ingress-controller 1 0s
    
    ==> v1/Pod(related)
    NAME READY STATUS RESTARTS AGE
    nginx-ingress-controller-7658988787-npv28 0/1 ContainerCreating 0 0s
    nginx-ingress-default-backend-7f5d59d759-26xq2 0/1 ContainerCreating 0 0s
    
    ==> v1/Service
    NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    nginx-ingress-controller LoadBalancer 10.245.9.107 <pending> 80:31305/TCP,443:30519/TCP 0s
    nginx-ingress-default-backend ClusterIP 10.245.221.49 <none> 80/TCP 0s
    
    ==> v1/ServiceAccount
    NAME SECRETS AGE
    nginx-ingress 1 0s
    
    ==> v1beta1/ClusterRole
    NAME AGE
    nginx-ingress 0s
    
    ==> v1beta1/ClusterRoleBinding
    NAME AGE
    nginx-ingress 0s
    
    ==> v1beta1/Deployment
    NAME READY UP-TO-DATE AVAILABLE AGE
    nginx-ingress-controller 0/1 1 0 0s
    nginx-ingress-default-backend 0/1 1 0 0s
    
    ==> v1beta1/Role
    NAME AGE
    nginx-ingress 0s
    
    ==> v1beta1/RoleBinding
    NAME AGE
    nginx-ingress 0s
    
    NOTES:
    ...

Helm has logged what resources in Kubernetes it created as a part of the chart installation.

You can watch the Load Balancer become available by running:

    kubectl get services -o wide -w nginx-ingress-controller

You’ve installed the Nginx Ingress maintained by the Kubernetes community. It will route HTTP and HTTPS traffic from the Load Balancer to appropriate back-end Services, configured in Ingress Resources. In the next step, you’ll expose the `hello-kubernetes` app deployments using an Ingress Resource.

## Step 3 — Exposing the App Using an Ingress

Now you’re going to create an Ingress Resource and use it to expose the `hello-kubernetes` app deployments at your desired domains. You’ll then test it by accessing it from your browser.

You’ll store the Ingress in a file named `hello-kubernetes-ingress.yaml`. Create it using your editor:

    nano hello-kubernetes-ingress.yaml

Add the following lines to your file:

hello-kubernetes-ingress.yaml

    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: hello-kubernetes-ingress
      annotations:
        kubernetes.io/ingress.class: nginx
    spec:
      rules:
      - host: hw1.example.com
        http:
          paths:
          - backend:
              serviceName: hello-kubernetes-first
              servicePort: 80
      - host: hw2.example.com
        http:
          paths:
          - backend:
              serviceName: hello-kubernetes-second
              servicePort: 80

In the code above, you define an Ingress Resource with the name `hello-kubernetes-ingress`. Then, you specify two host rules, so that `hw1.example.com` is routed to the `hello-kubernetes-first` Service, and `hw2.example.com` is routed to the Service from the second deployment (`hello-kubernetes-second`).

Remember to replace the highlighted domains with your own, then save and close the file.

Create it in Kubernetes by running the following command:

    kubectl create -f hello-kubernetes-ingress.yaml

Next, you’ll need to ensure that your two domains are pointed to the Load Balancer via A records. This is done through your DNS provider. To configure your DNS records on DigitalOcean, see [How to Manage DNS Records](https://www.digitalocean.com/docs/networking/dns/how-to/manage-records/).

You can now navigate to `hw1.example.com` in your browser. You will see the following:

![Hello Kubernetes - First Deployment](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_ingress_helm/step3a.png)

The second variant (`hw2.example.com`) will show a different message:

![Hello Kubernetes - Second Deployment](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_ingress_helm/step3b.png)

With this, you have verified that the Ingress Controller correctly routes requests; in this case, from your two domains to two different Services.

You’ve created and configured an Ingress Resource to serve the `hello-kubernetes` app deployments at your domains. In the next step, you’ll set up Cert-Manager, so you’ll be able to secure your Ingress Resources with free TLS certificates from Let’s Encrypt.

## Step 4 — Securing the Ingress Using Cert-Manager

To secure your Ingress Resources, you’ll install Cert-Manager, create a ClusterIssuer for production, and modify the configuration of your Ingress to take advantage of the TLS certificates. ClusterIssuers are Cert-Manager Resources in Kubernetes that provision TLS certificates. Once installed and configured, your app will be running behind HTTPS.

Before installing Cert-Manager to your cluster via Helm, you’ll manually apply the required [CRDs](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) (Custom Resource Definitions) from the jetstack/cert-manager repository by running the following command:

    kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml

You will see the following output:

    Outputcustomresourcedefinition.apiextensions.k8s.io/certificates.certmanager.k8s.io created
    customresourcedefinition.apiextensions.k8s.io/challenges.certmanager.k8s.io created
    customresourcedefinition.apiextensions.k8s.io/clusterissuers.certmanager.k8s.io created
    customresourcedefinition.apiextensions.k8s.io/issuers.certmanager.k8s.io created
    customresourcedefinition.apiextensions.k8s.io/orders.certmanager.k8s.io created

This shows that Kubernetes has applied the custom resources you require for cert-manager.

**Note:** If you’ve followed this tutorial and the prerequisites, you haven’t created a Kubernetes namespace called `cert-manager`, so you won’t have to run the command in this note block. However, if this namespace does exist on your cluster, you’ll need to inform Cert-Manager not to validate it with the following command:

    kubectl label namespace cert-manager certmanager.k8s.io/disable-validation="true"

[The Webhook component of Cert-Manager](https://docs.cert-manager.io/en/release-0.5/admin/resource-validation-webhook.html) requires TLS certificates to securely communicate with the Kubernetes API server. In order for Cert-Manager to generate certificates for it for the first time, resource validation must be disabled on the namespace it is deployed in. Otherwise, it would be stuck in an infinite loop; unable to contact the API and unable to generate the TLS certificates.

The output will be:

    Outputnamespace/cert-manager labeled

Next, you’ll need to add the [Jetstack Helm repository](https://charts.jetstack.io) to Helm, which hosts the Cert-Manager chart. To do this, run the following command:

    helm repo add jetstack https://charts.jetstack.io

Helm will display the following output:

    Output"jetstack" has been added to your repositories

Finally, install Cert-Manager into the `cert-manager` namespace:

    helm install --name cert-manager --namespace cert-manager jetstack/cert-manager

You will see the following output:

    OutputNAME: cert-manager
    LAST DEPLOYED: ...
    NAMESPACE: cert-manager
    STATUS: DEPLOYED
    
    RESOURCES:
    ==> v1/ClusterRole
    NAME AGE
    cert-manager-edit 3s
    cert-manager-view 3s
    cert-manager-webhook:webhook-requester 3s
    
    ==> v1/Pod(related)
    NAME READY STATUS RESTARTS AGE
    cert-manager-5d669ffbd8-rb6tr 0/1 ContainerCreating 0 2s
    cert-manager-cainjector-79b7fc64f-gqbtz 0/1 ContainerCreating 0 2s
    cert-manager-webhook-6484955794-v56lx 0/1 ContainerCreating 0 2s
    
    ...
    
    NOTES:
    cert-manager has been deployed successfully!
    
    In order to begin issuing certificates, you will need to set up a ClusterIssuer
    or Issuer resource (for example, by creating a 'letsencrypt-staging' issuer).
    
    More information on the different types of issuers and how to configure them
    can be found in our documentation:
    
    https://docs.cert-manager.io/en/latest/reference/issuers.html
    
    For information on how to configure cert-manager to automatically provision
    Certificates for Ingress resources, take a look at the `ingress-shim`
    documentation:
    
    https://docs.cert-manager.io/en/latest/reference/ingress-shim.html

The output shows that the installation was successful. As listed in the `NOTES` in the output, you’ll need to set up an Issuer to issue TLS certificates.

You’ll now create one that issues Let’s Encrypt certificates, and you’ll store its configuration in a file named `production_issuer.yaml`. Create it and open it for editing:

    nano production_issuer.yaml

Add the following lines:

production\_issuer.yaml

    apiVersion: certmanager.k8s.io/v1alpha1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-prod
    spec:
      acme:
        # The ACME server URL
        server: https://acme-v02.api.letsencrypt.org/directory
        # Email address used for ACME registration
        email: your_email_address
        # Name of a secret used to store the ACME account private key
        privateKeySecretRef:
          name: letsencrypt-prod
        # Enable the HTTP-01 challenge provider
        http01: {}

This configuration defines a ClusterIssuer that contacts Let’s Encrypt in order to issue certificates. You’ll need to replace `your_email_address` with your email address in order to receive possible urgent notices regarding the security and expiration of your certificates.

Save and close the file.

Roll it out with `kubectl`:

    kubectl create -f production_issuer.yaml

You will see the following output:

    Outputclusterissuer.certmanager.k8s.io/letsencrypt-prod created

With Cert-Manager installed, you’re ready to introduce the certificates to the Ingress Resource defined in the previous step. Open `hello-kubernetes-ingress.yaml` for editing:

    nano hello-kubernetes-ingress.yaml

Add the highlighted lines:

hello-kubernetes-ingress.yaml

    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: hello-kubernetes-ingress
      annotations:
        kubernetes.io/ingress.class: nginx
        certmanager.k8s.io/cluster-issuer: letsencrypt-prod
    spec:
      tls:
      - hosts:
        - hw1.example.com
        - hw2.example.com
        secretName: letsencrypt-prod
      rules:
      - host: hw1.example.com
        http:
          paths:
          - backend:
              serviceName: hello-kubernetes-first
              servicePort: 80
      - host: hw2.example.com
        http:
          paths:
          - backend:
              serviceName: hello-kubernetes-second
              servicePort: 80

The `tls` block under `spec` defines in what Secret the certificates for your sites (listed under `hosts`) will store their certificates, which the `letsencrypt-prod` ClusterIssuer issues. This must be different for every Ingress you create.

Remember to replace the `hw1.example.com` and `hw2.example.com` with your own domains. When you’ve finished editing, save and close the file.

Re-apply this configuration to your cluster by running the following command:

    kubectl apply -f hello-kubernetes-ingress.yaml

You will see the following output:

    Outputingress.extensions/hello-kubernetes-ingress configured

You’ll need to wait a few minutes for the Let’s Encrypt servers to issue a certificate for your domains. In the meantime, you can track its progress by inspecting the output of the following command:

    kubectl describe certificate letsencrypt-prod

The end of the output will look similar to this:

    OutputEvents:
      Type Reason Age From Message
      ---- ------ ---- ---- -------
      Normal Generated 56s cert-manager Generated new private key
      Normal GenerateSelfSigned 56s cert-manager Generated temporary self signed certificate
      Normal OrderCreated 56s cert-manager Created Order resource "hello-kubernetes-1197334873"
      Normal OrderComplete 31s cert-manager Order "hello-kubernetes-1197334873" completed successfully
      Normal CertIssued 31s cert-manager Certificate issued successfully

When your last line of output reads `Certificate issued successfully`, you can exit by pressing `CTRL + C`. Navigate to one of your domains in your browser to test. You’ll see the padlock to the left of the address bar in your browser, signifying that your connection is secure.

In this step, you have installed Cert-Manager using Helm and created a Let’s Encrypt ClusterIssuer. After, you updated your Ingress Resource to take advantage of the Issuer for generating TLS certificates. In the end, you have confirmed that HTTPS works correctly by navigating to one of your domains in your browser.

## Conclusion

You have now successfully set up the Nginx Ingress Controller and Cert-Manager on your DigitalOcean Kubernetes cluster using Helm. You are now able to expose your apps to the Internet, at your domains, secured using Let’s Encrypt TLS certificates.

For further information about the Helm package manager, read this [introduction article](an-introduction-to-helm-the-package-manager-for-kubernetes).
