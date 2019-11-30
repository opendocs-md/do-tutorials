---
author: Hanif Jetha
date: 2018-12-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-with-cert-manager-on-digitalocean-kubernetes
---

# How to Set Up an Nginx Ingress with Cert-Manager on DigitalOcean Kubernetes

## Introduction

Kubernetes [Ingresses](https://kubernetes.io/docs/concepts/services-networking/ingress/) allow you to flexibly route traffic from outside your Kubernetes cluster to Services inside of your cluster. This is accomplished using Ingress _Resources_, which define rules for routing HTTP and HTTPS traffic to Kubernetes Services, and Ingress _Controllers_, which implement the rules by load balancing traffic and routing it to the appropriate backend Services. Popular Ingress Controllers include [Nginx](https://github.com/kubernetes/ingress-nginx/blob/master/README.md), [Contour](https://github.com/heptio/contour), [HAProxy](https://www.haproxy.com/blog/haproxy_ingress_controller_for_kubernetes/), and [Traefik](https://github.com/containous/traefik). Ingresses provide a more efficient and flexible alternative to setting up multiple LoadBalancer services, each of which uses its own dedicated Load Balancer.

In this guide, we’ll set up the Kubernetes-maintained [Nginx Ingress Controller](https://github.com/kubernetes/ingress-nginx), and create some Ingress Resources to route traffic to several dummy backend services. Once we’ve set up the Ingress, we’ll install [cert-manager](https://github.com/jetstack/cert-manager) into our cluster to manage and provision TLS certificates for encrypting HTTP traffic to the Ingress.

## Prerequisites

Before you begin with this guide, you should have the following available to you:

- A Kubernetes 1.10+ cluster with [role-based access control](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) (RBAC) enabled
- The `kubectl` command-line tool installed on your local machine and configured to connect to your cluster. You can read more about installing `kubectl` [in the official documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
- A domain name and DNS A records which you can point to the DigitalOcean Load Balancer used by the Ingress. If you are using DigitalOcean to manage your domain’s DNS records, consult [How to Manage DNS Records](https://www.digitalocean.com/docs/networking/dns/how-to/manage-records/) to learn how to create A records.
- The Helm package manager installed on your local machine and Tiller installed on your cluster, as detailed in [How To Install Software on Kubernetes Clusters with the Helm Package Manager](how-to-install-software-on-kubernetes-clusters-with-the-helm-package-manager). Ensure that you are using Helm v2.12.1 or later or you may run into issues installing the cert-manager Helm chart. To check the Helm version you have installed, run `helm version` on your local machine.
- The `wget` command-line utility installed on your local machine. You can install `wget` using the package manager built into your operating system.

Once you have these components set up, you’re ready to begin with this guide.

## Step 1 — Setting Up Dummy Backend Services

Before we deploy the Ingress Controller, we’ll first create and roll out two dummy echo Services to which we’ll route external traffic using the Ingress. The echo Services will run the [`hashicorp/http-echo`](https://hub.docker.com/r/hashicorp/http-echo/) web server container, which returns a page containing a text string passed in when the web server is launched. To learn more about `http-echo`, consult its [GitHub Repo](https://github.com/hashicorp/http-echo), and to learn more about Kubernetes Services, consult [Services](https://kubernetes.io/docs/concepts/services-networking/service/) from the official Kubernetes docs.

On your local machine, create and edit a file called `echo1.yaml` using `nano` or your favorite editor:

    nano echo1.yaml

Paste in the following Service and Deployment manifest:

echo1.yaml

    apiVersion: v1
    kind: Service
    metadata:
      name: echo1
    spec:
      ports:
      - port: 80
        targetPort: 5678
      selector:
        app: echo1
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: echo1
    spec:
      selector:
        matchLabels:
          app: echo1
      replicas: 2
      template:
        metadata:
          labels:
            app: echo1
        spec:
          containers:
          - name: echo1
            image: hashicorp/http-echo
            args:
            - "-text=echo1"
            ports:
            - containerPort: 5678

In this file, we define a Service called `echo1` which routes traffic to Pods with the `app: echo1` label selector. It accepts TCP traffic on port `80` and routes it to port `5678`,`http-echo`’s default port.

We then define a Deployment, also called `echo1`, which manages Pods with the `app: echo1` [Label Selector](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/). We specify that the Deployment should have 2 Pod replicas, and that the Pods should start a container called `echo1` running the `hashicorp/http-echo` image. We pass in the `text` parameter and set it to `echo1`, so that the `http-echo` web server returns `echo1`. Finally, we open port `5678` on the Pod container.

Once you’re satisfied with your dummy Service and Deployment manifest, save and close the file.

Then, create the Kubernetes resources using `kubectl create` with the `-f` flag, specifying the file you just saved as a parameter:

    kubectl create -f echo1.yaml

You should see the following output:

    Outputservice/echo1 created
    deployment.apps/echo1 created

Verify that the Service started correctly by confirming that it has a ClusterIP, the internal IP on which the Service is exposed:

    kubectl get svc echo1

You should see the following output:

    OutputNAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    echo1 ClusterIP 10.245.222.129 <none> 80/TCP 60s

This indicates that the `echo1` Service is now available internally at `10.245.222.129` on port `80`. It will forward traffic to containerPort `5678` on the Pods it selects.

Now that the `echo1` Service is up and running, repeat this process for the `echo2` Service.

Create and open a file called `echo2.yaml`:

echo2.yaml

    apiVersion: v1
    kind: Service
    metadata:
      name: echo2
    spec:
      ports:
      - port: 80
        targetPort: 5678
      selector:
        app: echo2
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: echo2
    spec:
      selector:
        matchLabels:
          app: echo2
      replicas: 1
      template:
        metadata:
          labels:
            app: echo2
        spec:
          containers:
          - name: echo2
            image: hashicorp/http-echo
            args:
            - "-text=echo2"
            ports:
            - containerPort: 5678

Here, we essentially use the same Service and Deployment manifest as above, but name and relabel the Service and Deployment `echo2`. In addition, to provide some variety, we create only 1 Pod replica. We ensure that we set the `text` parameter to `echo2` so that the web server returns the text `echo2`.

Save and close the file, and create the Kubernetes resources using `kubectl`:

    kubectl create -f echo2.yaml

You should see the following output:

    Outputservice/echo2 created
    deployment.apps/echo2 created

Once again, verify that the Service is up and running:

    kubectl get svc

You should see both the `echo1` and `echo2` Services with assigned ClusterIPs:

    OutputNAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    echo1 ClusterIP 10.245.222.129 <none> 80/TCP 6m6s
    echo2 ClusterIP 10.245.128.224 <none> 80/TCP 6m3s
    kubernetes ClusterIP 10.245.0.1 <none> 443/TCP 4d21h

Now that our dummy echo web services are up and running, we can move on to rolling out the Nginx Ingress Controller.

## Step 2 — Setting Up the Kubernetes Nginx Ingress Controller

In this step, we’ll roll out `v0.24.1` of the Kubernetes-maintained [Nginx Ingress Controller](https://github.com/kubernetes/ingress-nginx). Note that there are [several](https://github.com/nginxinc/kubernetes-ingress/blob/master/docs/nginx-ingress-controllers.md) Nginx Ingress Controllers; the Kubernetes community maintains the one used in this guide and Nginx Inc. maintains [kubernetes-ingress](https://github.com/nginxinc/kubernetes-ingress). The instructions in this tutorial are based on those from the official Kubernetes Nginx Ingress Controller [Installation Guide](https://kubernetes.github.io/ingress-nginx/deploy/).

The Nginx Ingress Controller consists of a Pod that runs the Nginx web server and watches the Kubernetes Control Plane for new and updated Ingress Resource objects. An Ingress Resource is essentially a list of traffic routing rules for backend Services. For example, an Ingress rule can specify that HTTP traffic arriving at the path `/web1` should be directed towards the `web1` backend web server. Using Ingress Resources, you can also perform host-based routing: for example, routing requests that hit `web1.your_domain.com` to the backend Kubernetes Service `web1`.

In this case, because we’re deploying the Ingress Controller to a DigitalOcean Kubernetes cluster, the Controller will create a LoadBalancer Service that spins up a DigitalOcean Load Balancer to which all external traffic will be directed. This Load Balancer will route external traffic to the Ingress Controller Pod running Nginx, which then forwards traffic to the appropriate backend Services.

We’ll begin by first creating the Kubernetes resources required by the Nginx Ingress Controller. These consist of ConfigMaps containing the Controller’s configuration, Role-based Access Control (RBAC) Roles to grant the Controller access to the Kubernetes API, and the actual Ingress Controller Deployment which uses [v0.24.1](https://quay.io/repository/kubernetes-ingress-controller/nginx-ingress-controller?tag=0.24.1&tab=tags) of the Nginx Ingress Controller image. To see a full list of these required resources, consult the [manifest](https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.24.1/deploy/mandatory.yaml) from the Kubernetes Nginx Ingress Controller’s GitHub repo.

To create these mandatory resources, use `kubectl apply` and the `-f` flag to specify the manifest file hosted on GitHub:

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.24.1/deploy/mandatory.yaml

We use `apply` instead of `create` here so that in the future we can incrementally `apply` changes to the Ingress Controller objects instead of completely overwriting them. To learn more about `apply`, consult [Managing Resources](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#kubectl-apply) from the official Kubernetes docs.

You should see the following output:

    Outputnamespace/ingress-nginx created
    configmap/nginx-configuration created
    configmap/tcp-services created
    configmap/udp-services created
    serviceaccount/nginx-ingress-serviceaccount created
    clusterrole.rbac.authorization.k8s.io/nginx-ingress-clusterrole created
    role.rbac.authorization.k8s.io/nginx-ingress-role created
    rolebinding.rbac.authorization.k8s.io/nginx-ingress-role-nisa-binding created
    clusterrolebinding.rbac.authorization.k8s.io/nginx-ingress-clusterrole-nisa-binding created
    deployment.extensions/nginx-ingress-controller created

This output also serves as a convenient summary of all the Ingress Controller objects created from the `mandatory.yaml` manifest.

Next, we’ll create the Ingress Controller LoadBalancer Service, which will create a DigitalOcean Load Balancer that will load balance and route HTTP and HTTPS traffic to the Ingress Controller Pod deployed in the previous command.

To create the LoadBalancer Service, once again `kubectl apply` a manifest file containing the Service definition:

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.24.1/deploy/provider/cloud-generic.yaml

You should see the following output:

    Outputservice/ingress-nginx created

Now, confirm that the DigitalOcean Load Balancer was successfully created by fetching the Service details with `kubectl`:

    kubectl get svc --namespace=ingress-nginx

You should see an external IP address, corresponding to the IP address of the DigitalOcean Load Balancer:

    OutputNAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    ingress-nginx LoadBalancer 10.245.247.67 203.0.113.0 80:32486/TCP,443:32096/TCP 20h

Note down the Load Balancer’s external IP address, as you’ll need it in a later step.

**Note:** By default the Nginx Ingress LoadBalancer Service has `service.spec.externalTrafficPolicy` set to the value `Local`, which routes all load balancer traffic to nodes running Nginx Ingress Pods. The other nodes will deliberately fail load balancer health checks so that Ingress traffic does not get routed to them. External traffic policies are beyond the scope of this tutorial, but to learn more you can consult [A Deep Dive into Kubernetes External Traffic Policies](https://www.asykim.com/blog/deep-dive-into-kubernetes-external-traffic-policies) and [Source IP for Services with Type=LoadBalancer](https://kubernetes.io/docs/tutorials/services/source-ip/#source-ip-for-services-with-type-loadbalancer) from the official Kubernetes docs.

This load balancer receives traffic on HTTP and HTTPS ports 80 and 443, and forwards it to the Ingress Controller Pod. The Ingress Controller will then route the traffic to the appropriate backend Service.

We can now point our DNS records at this external Load Balancer and create some Ingress Resources to implement traffic routing rules.

## Step 3 — Creating the Ingress Resource

Let’s begin by creating a minimal Ingress Resource to route traffic directed at a given subdomain to a corresponding backend Service.

In this guide, we’ll use the test domain **example.com**. You should substitute this with the domain name you own.

We’ll first create a simple rule to route traffic directed at **echo1.example.com** to the `echo1` backend service and traffic directed at **echo2.example.com** to the `echo2` backend service.

Begin by opening up a file called `echo_ingress.yaml` in your favorite editor:

    nano echo_ingress.yaml

Paste in the following ingress definition:

echo\_ingress.yaml

    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: echo-ingress
    spec:
      rules:
      - host: echo1.example.com
        http:
          paths:
          - backend:
              serviceName: echo1
              servicePort: 80
      - host: echo2.example.com
        http:
          paths:
          - backend:
              serviceName: echo2
              servicePort: 80

When you’ve finished editing your Ingress rules, save and close the file.

Here, we’ve specified that we’d like to create an Ingress Resource called `echo-ingress`, and route traffic based on the Host header. An HTTP request Host header specifies the domain name of the target server. To learn more about Host request headers, consult the Mozilla Developer Network [definition page](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Host). Requests with host **echo1.example.com** will be directed to the `echo1` backend set up in Step 1, and requests with host **echo2.example.com** will be directed to the `echo2` backend.

You can now create the Ingress using `kubectl`:

    kubectl apply -f echo_ingress.yaml

You’ll see the following output confirming the Ingress creation:

    Outputingress.extensions/echo-ingress created

To test the Ingress, navigate to your DNS management service and create A records for `echo1.example.com` and `echo2.example.com` pointing to the DigitalOcean Load Balancer’s external IP. The Load Balancer’s external IP is the external IP address for the `ingress-nginx` Service, which we fetched in the previous step. If you are using DigitalOcean to manage your domain’s DNS records, consult [How to Manage DNS Records](https://www.digitalocean.com/docs/networking/dns/how-to/manage-records/) to learn how to create A records.

Once you’ve created the necessary `echo1.example.com` and `echo2.example.com` DNS records, you can test the Ingress Controller and Resource you’ve created using the `curl` command line utility.

From your local machine, `curl` the `echo1` Service:

    curl echo1.example.com

You should get the following response from the `echo1` service:

    Outputecho1

This confirms that your request to `echo1.example.com` is being correctly routed through the Nginx ingress to the `echo1` backend Service.

Now, perform the same test for the `echo2` Service:

    curl echo2.example.com

You should get the following response from the `echo2` Service:

    Outputecho2

This confirms that your request to `echo2.example.com` is being correctly routed through the Nginx ingress to the `echo2` backend Service.

At this point, you’ve successfully set up a basic Nginx Ingress to perform virtual host-based routing. In the next step, we’ll install [cert-manager](https://github.com/jetstack/cert-manager) using Helm to provision TLS certificates for our Ingress and enable the more secure HTTPS protocol.

## Step 4 — Installing and Configuring Cert-Manager

In this step, we’ll use Helm to install cert-manager into our cluster. cert-manager is a Kubernetes service that provisions TLS certificates from [Let’s Encrypt](https://letsencrypt.org/) and other certificate authorities and manages their lifecycles. Certificates can be requested and configured by annotating Ingress Resources with the `certmanager.k8s.io/issuer` annotation, appending a `tls` section to the Ingress spec, and configuring one or more _Issuers_ to specify your preferred certificate authority. To learn more about Issuer objects, consult the official cert-manager documentation on [Issuers](https://cert-manager.readthedocs.io/en/latest/reference/issuers.html).

**Note:** Ensure that you are using Helm v2.12.1 or later before installing cert-manager. To check the Helm version you have installed, run `helm version` on your local machine.

Before using Helm to install cert-manager into our cluster, we need to create the cert-manager [Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) (CRDs). Create these by `apply`ing them directly from the cert-manager [GitHub repository](https://github.com/jetstack/cert-manager/) :

    kubectl apply \
        -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml

You should see the following output:

    Outputcustomresourcedefinition.apiextensions.k8s.io/certificates.certmanager.k8s.io created
    customresourcedefinition.apiextensions.k8s.io/issuers.certmanager.k8s.io created
    customresourcedefinition.apiextensions.k8s.io/clusterissuers.certmanager.k8s.io created
    customresourcedefinition.apiextensions.k8s.io/orders.certmanager.k8s.io created
    customresourcedefinition.apiextensions.k8s.io/challenges.certmanager.k8s.io created

Next, we’ll add a label to the `kube-system` namespace, where we’ll install cert-manager, to enable advanced resource validation using a [webhook](https://docs.cert-manager.io/en/venafi/admin/resource-validation-webhook.html):

    kubectl label namespace kube-system certmanager.k8s.io/disable-validation="true"

Now, we’ll add the [Jetstack Helm repository](https://hub.helm.sh/charts/jetstack) to Helm. This repository contains the cert-manager [Helm chart](https://hub.helm.sh/charts/jetstack/cert-manager).

    helm repo add jetstack https://charts.jetstack.io

Finally, we can install the chart into the `kube-system` namespace:

    helm install --name cert-manager --namespace kube-system jetstack/cert-manager --version v0.8.0

You should see the following output:

    Output. . .
    NOTES:
    cert-manager has been deployed successfully!
    
    In order to begin issuing certificates, you will need to set up a ClusterIssuer
    or Issuer resource (for example, by creating a 'letsencrypt-staging' issuer).
    
    More information on the different types of issuers and how to configure them
    can be found in our documentation:
    
    https://cert-manager.readthedocs.io/en/latest/reference/issuers.html
    
    For information on how to configure cert-manager to automatically provision
    Certificates for Ingress resources, take a look at the `ingress-shim`
    documentation:
    
    https://cert-manager.readthedocs.io/en/latest/reference/ingress-shim.html

This indicates that the cert-manager installation succeeded.

Before we begin issuing certificates for our Ingress hosts, we need to create an Issuer, which specifies the certificate authority from which signed x509 certificates can be obtained. In this guide, we’ll use the Let’s Encrypt certificate authority, which provides free TLS certificates and offers both a staging server for testing your certificate configuration, and a production server for rolling out verifiable TLS certificates.

Let’s create a test Issuer to make sure the certificate provisioning mechanism is functioning correctly. Open a file named `staging_issuer.yaml` in your favorite text editor:

    nano staging_issuer.yaml

Paste in the following ClusterIssuer manifest:

staging\_issuer.yaml

    apiVersion: certmanager.k8s.io/v1alpha1
    kind: ClusterIssuer
    metadata:
     name: letsencrypt-staging
    spec:
     acme:
       # The ACME server URL
       server: https://acme-staging-v02.api.letsencrypt.org/directory
       # Email address used for ACME registration
       email: your_email_address_here
       # Name of a secret used to store the ACME account private key
       privateKeySecretRef:
         name: letsencrypt-staging
       # Enable the HTTP-01 challenge provider
       http01: {}

Here we specify that we’d like to create a ClusterIssuer object called `letsencrypt-staging`, and use the Let’s Encrypt staging server. We’ll later use the production server to roll out our certificates, but the production server may rate-limit requests made against it, so for testing purposes it’s best to use the staging URL.

We then specify an email address to register the certificate, and create a Kubernetes [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) called `letsencrypt-staging` to store the ACME account’s private key. We also enable the `HTTP-01` challenge mechanism. To learn more about these parameters, consult the official cert-manager documentation on [Issuers](https://cert-manager.readthedocs.io/en/latest/reference/issuers.html).

Roll out the ClusterIssuer using `kubectl`:

    kubectl create -f staging_issuer.yaml

You should see the following output:

    Outputclusterissuer.certmanager.k8s.io/letsencrypt-staging created

Now that we’ve created our Let’s Encrypt staging Issuer, we’re ready to modify the Ingress Resource we created above and enable TLS encryption for the `echo1.example.com` and `echo2.example.com` paths.

Open up `echo_ingress.yaml` once again in your favorite editor:

    nano echo_ingress.yaml

Add the following to the Ingress Resource manifest:

echo\_ingress.yaml

    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: echo-ingress
      annotations:  
        kubernetes.io/ingress.class: nginx
        certmanager.k8s.io/cluster-issuer: letsencrypt-staging
    spec:
      tls:
      - hosts:
        - echo1.example.com
        - echo2.example.com
        secretName: letsencrypt-staging
      rules:
      - host: echo1.example.com
        http:
          paths:
          - backend:
              serviceName: echo1
              servicePort: 80
      - host: echo2.example.com
        http:
          paths:
          - backend:
              serviceName: echo2
              servicePort: 80

Here we add some annotations to specify the `ingress.class`, which determines the Ingress Controller that should be used to implement the Ingress Rules. In addition, we define the `cluster-issuer` to be `letsencrypt-staging`, the certificate Issuer we just created.

Finally, we add a `tls` block to specify the hosts for which we want to acquire certificates, and specify a `secretName`. This secret will contain the TLS private key and issued certificate.

When you’re done making changes, save and close the file.

We’ll now update the existing Ingress Resource using `kubectl apply`:

    kubectl apply -f echo_ingress.yaml

You should see the following output:

    Outputingress.extensions/echo-ingress configured

You can use `kubectl describe` to track the state of the Ingress changes you’ve just applied:

    kubectl describe ingress

    OutputEvents:
      Type Reason Age From Message
      ---- ------ ---- ---- -------
      Normal CREATE 14m nginx-ingress-controller Ingress default/echo-ingress
      Normal UPDATE 1m (x2 over 13m) nginx-ingress-controller Ingress default/echo-ingress
      Normal CreateCertificate 1m cert-manager Successfully created Certificate "letsencrypt-staging"

Once the certificate has been successfully created, you can run an additional `describe` on it to further confirm its successful creation:

    kubectl describe certificate

You should see the following output in the `Events` section:

    OutputEvents:
      Type Reason Age From Message
      ---- ------ ---- ---- -------
      Normal Generated 63s cert-manager Generated new private key
      Normal OrderCreated 63s cert-manager Created Order resource "letsencrypt-staging-147606226"
      Normal OrderComplete 19s cert-manager Order "letsencrypt-staging-147606226" completed successfully
      Normal CertIssued 18s cert-manager Certificate issued successfully

This confirms that the TLS certificate was successfully issued and HTTPS encryption is now active for the two domains configured.

We’re now ready to send a request to a backend `echo` server to test that HTTPS is functioning correctly.

Run the following `wget` command to send a request to `echo1.example.com` and print the response headers to `STDOUT`:

    wget --save-headers -O- echo1.example.com

You should see the following output:

    OutputURL transformed to HTTPS due to an HSTS policy
    --2018-12-11 14:38:24-- https://echo1.example.com/
    Resolving echo1.example.com (echo1.example.com)... 203.0.113.0
    Connecting to echo1.example.com (echo1.example.net)|203.0.113.0|:443... connected.
    ERROR: cannot verify echo1.example.com's certificate, issued by ‘CN=Fake LE Intermediate X1’:
      Unable to locally verify the issuer's authority.
    To connect to echo1.example.com insecurely, use `--no-check-certificate'.

This indicates that HTTPS has successfully been enabled, but the certificate cannot be verified as it’s a fake temporary certificate issued by the Let’s Encrypt staging server.

Now that we’ve tested that everything works using this temporary fake certificate, we can roll out production certificates for the two hosts `echo1.example.com` and `echo2.example.com`.

## Step 5 — Rolling Out Production Issuer

In this step we’ll modify the procedure used to provision staging certificates, and generate a valid, verifiable production certificate for our Ingress hosts.

To begin, we’ll first create a production certificate ClusterIssuer.

Open a file called `prod_issuer.yaml` in your favorite editor:

    nano prod_issuer.yaml

Paste in the following manifest:

prod\_issuer.yaml

    apiVersion: certmanager.k8s.io/v1alpha1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-prod
    spec:
      acme:
        # The ACME server URL
        server: https://acme-v02.api.letsencrypt.org/directory
        # Email address used for ACME registration
        email: your_email_address_here
        # Name of a secret used to store the ACME account private key
        privateKeySecretRef:
          name: letsencrypt-prod
        # Enable the HTTP-01 challenge provider
        http01: {}

Note the different ACME server URL, and the `letsencrypt-prod` secret key name.

When you’re done editing, save and close the file.

Now, roll out this Issuer using `kubectl`:

    kubectl create -f prod_issuer.yaml

You should see the following output:

    Outputclusterissuer.certmanager.k8s.io/letsencrypt-prod created

Update `echo_ingress.yaml` to use this new Issuer:

    nano echo_ingress.yaml

Make the following changes to the file:

echo\_ingress.yaml

    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: echo-ingress
      annotations:  
        kubernetes.io/ingress.class: nginx
        certmanager.k8s.io/cluster-issuer: letsencrypt-prod
    spec:
      tls:
      - hosts:
        - echo1.example.com
        - echo2.example.com
        secretName: letsencrypt-prod
      rules:
      - host: echo1.example.com
        http:
          paths:
          - backend:
              serviceName: echo1
              servicePort: 80
      - host: echo2.example.com
        http:
          paths:
          - backend:
              serviceName: echo2
              servicePort: 80

Here, we update both the ClusterIssuer and secret name to `letsencrypt-prod`.

Once you’re satisfied with your changes, save and close the file.

Roll out the changes using `kubectl apply`:

    kubectl apply -f echo_ingress.yaml

    Outputingress.extensions/echo-ingress configured

Wait a couple of minutes for the Let’s Encrypt production server to issue the certificate. You can track its progress using `kubectl describe` on the `certificate` object:

    kubectl describe certificate letsencrypt-prod

Once you see the following output, the certificate has been issued successfully:

    OutputEvents:
      Type Reason Age From Message
      ---- ------ ---- ---- -------
      Normal Generated 82s cert-manager Generated new private key
      Normal OrderCreated 82s cert-manager Created Order resource "letsencrypt-prod-2626449824"
      Normal OrderComplete 37s cert-manager Order "letsencrypt-prod-2626449824" completed successfully
      Normal CertIssued 37s cert-manager Certificate issued successfully

We’ll now perform a test using `curl` to verify that HTTPS is working correctly:

    curl echo1.example.com

You should see the following:

    Output<html>
    <head><title>308 Permanent Redirect</title></head>
    <body>
    <center><h1>308 Permanent Redirect</h1></center>
    <hr><center>nginx/1.15.9</center>
    </body>
    </html>

This indicates that HTTP requests are being redirected to use HTTPS.

Run `curl` on `https://echo1.example.com`:

    curl https://echo1.example.com

You should now see the following output:

    Outputecho1

You can run the previous command with the verbose `-v` flag to dig deeper into the certificate handshake and to verify the certificate information.

At this point, you’ve successfully configured HTTPS using a Let’s Encrypt certificate for your Nginx Ingress.

## Conclusion

In this guide, you set up an Nginx Ingress to load balance and route external requests to backend Services inside of your Kubernetes cluster. You also secured the Ingress by installing the cert-manager certificate provisioner and setting up a Let’s Encrypt certificate for two host paths.

There are many alternatives to the Nginx Ingress Controller. To learn more, consult [Ingress controllers](https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-controllers) from the official Kubernetes documentation.
