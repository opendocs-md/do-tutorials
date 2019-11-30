---
author: John Kwiatkoski
date: 2019-09-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-autoscale-your-workloads-on-digitalocean-kubernetes
---

# How To Autoscale Your Workloads on DigitalOcean Kubernetes

## Introduction

When working with an application built on [Kubernetes](an-introduction-to-kubernetes), developers will often need to schedule additional [pods](https://kubernetes.io/docs/concepts/workloads/pods/pod/) to handle times of peak traffic or increased load processing. By default, scheduling these additional pods is a manual step; the developer must change the number of desired [replicas](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/) in the [deployment object](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) to account for the increased traffic, then change it back when the additional pods are no longer needed. This dependency on manual intervention can be less than ideal in many scenarios. For example, your workload could hit peak hours in the middle of the night when no one is awake to scale the pods, or your website could get an unexpected increase in traffic when a manual response would not be quick enough to deal with the load. In these situations, the most efficient and least error prone approach is to automate your clusters scaling with the [Horizontal Pod Autoscaler (HPA)](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/).

By using information from the [Metrics Server](https://github.com/kubernetes-incubator/metrics-server), the HPA will detect increased resource usage and respond by scaling your workload for you. This is especially useful with microservice architectures, and will give your Kubernetes cluster the ability to scale your deployment based on metrics such as CPU utilization. When combined with [DigitalOcean Kubernetes (DOKS)](https://www.digitalocean.com/products/kubernetes/), a managed Kubernetes offering that provides developers with a platform for deploying containerized applications, using HPA can create an automated infrastructure that quickly adjusts to changes in traffic and load.

**Note:** When considering whether to use autoscaling for your workload, keep in mind that autoscaling works best for stateless applications, especially ones that are capable of having multiple instances of the application running and accepting traffic in parallel. This parallelism is important because the main objective of autoscaling is to dynamically distribute an application’s workload across multiple instances in your Kubernetes cluster to ensure your application has the resources necessary to service the traffic in a timely and stable manner without overloading any single instance.

An example of a workload that does not exhibit this parrallelism is database autoscaling. Setting up autoscaling for a database would be vastly more complex, as you would need to account for race conditions, issues with data integrity, data synchronization, and constant additions and removals of database cluster members. For reasons like these, we do not recommend using this tutorial’s autoscaling strategy for databases.

In this tutorial, you will set up a sample [Nginx](https://www.nginx.com/) deployment on DOKS that can autoscale horizontally to account for increased CPU load. You will accomplish this by deploying Metrics Server into your cluster to gather pod metrics for HPA to use when determining when to scale.

## Prerequisites

Before you begin this guide you’ll need the following:

- A DigitalOcean Kubernetes cluster with your connection configured as the `kubectl` default. Instructions on how to configure `kubectl` are shown under the **Connect to your Cluster** step when you create your cluster. To create a Kubernetes cluster on DigitalOcean, see [Kubernetes Quickstart](https://www.digitalocean.com/docs/kubernetes/quickstart/).

- The Helm package manager installed on your local machine, and Tiller installed on your cluster. To do this, complete Steps 1 and 2 of the [How To Install Software on Kubernetes Clusters with the Helm Package Manager](how-to-install-software-on-kubernetes-clusters-with-the-helm-package-manager) tutorial.

## Step 1 — Creating a Test Deployment

In order to show the effect of the HPA, you will first deploy an application that you will use to autoscale. This tutorial uses a standard [Nginx Docker image](https://docs.docker.com/samples/library/nginx/) as a deployment because it is fully capable of operating in parallel, is widely used within Kubernetes with such tools as the [Nginx Ingress Controller](https://github.com/kubernetes/ingress-nginx), and is lightweight to set up. This Nginx deployment will serve a static **Welcome to Nginx!** page that comes standard in the base image. If you already have a deployment you would like to scale, feel free to use that deployment and skip this step.

Create the sample deployment using the Nginx base image by issuing the following command. You can replace the name `web` if you would like to give your deployment a different name:

    kubectl create deployment web --image=nginx:latest

The `--image=nginx:latest` flag will create the deployment from the latest version of the Nginx base image.

After a few seconds, your `web` pod will spin up. To see this pod, run the following command, which will show you the pods running in the current namespace:

    kubectl get pods

This will give you output similar to the following:

    OutputNAME READY STATUS RESTARTS AGE
    web-84d7787df5-btf9h 1/1 Running 0 11s

Take note that there is only one pod originally deployed. Once autoscaling triggers, more pods will spin up automatically.

You now have a basic deployment up and running within the cluster. This is the deployment you are going to configure for autoscaling. Your next step is to configure this deployment to define its resource requests and limits.

## Step 2 — Setting CPU Limits and Requests on Your Deployment

In this step, you are going to set [requests and limits](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#resource-requests-and-limits-of-pod-and-container) on CPU usage for your deployment. _Limits_ in Kubernetes are set on the deployment to describe the maximum amount of the resource (either CPU or Memory) that the pod can use. _Requests_ are set on the deployment to describe how much of that resource is needed on a node in order for that node to be considered as a valid node for scheduling. For example, if your webserver had a memory request set at 1GB, only nodes with at least 1GB of free memory would be considered for scheduling. For autoscaling, it is necessary to set these limits and requests because the HPA will need to have this information when making scaling and scheduling decisions.

To set the requests and limits, you will need to make changes to the deployment you just created. This tutorial will use the following [`kubectl edit`](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#kubectl-edit) command to modify the API object configuration stored in the cluster. The `kubectl edit` command will open the editor defined by your `KUBE_EDITOR` or `EDITOR` environment variables, or fall back to [`vi` for Linux](installing-and-using-the-vim-text-editor-on-a-cloud-server#editing) or `notepad` for Windows by default.

Edit your deployment:

    kubectl edit deployment web

You will see the configuration for the deployment. You can now set resource limits and requests specified for your deployment’s CPU usage. These limits set the baseline for how much of each resource a pod of this deployment can use individually. Setting this will give the HPA a frame of reference to know whether a pod is being overworked. For example, if you expect your pod to have an upper `limit` of 100 millicores of CPU and the pod is currently using 95 millicores, HPA will know that it is at 95% capacity. Without providing that limit of 100 milicores, the HPA can’t decipher the pod’s full capacity.

We can set the limits and requests in the `resources` section:

Deployment Configuration File

    . . .
      template:
        metadata:
          creationTimestamp: null
          labels:
            app: web
        spec:
          containers:
          - image: nginx:latest
            imagePullPolicy: Always
            name: nginx
            resources: {}
            terminationMessagePath: /dev/termination-log
            terminationMessagePolicy: File
          dnsPolicy: ClusterFirst
          restartPolicy: Always
          schedulerName: default-scheduler
          securityContext: {}
          terminationGracePeriodSeconds: 30
    status:
      availableReplicas: 1
    . . .

For this tutorial, you will be setting `requests` for CPU to `100m` and memory to `250Mi`. These values are meant for demonstration purposes; every workload is different, so these values may not make sense for other workloads. As a general rule, these values should be set to the maximum that a pod of this workload should be expected to use. Monitoring the application and gathering resource usage data on how it performs during low and peak times is recommended to help determine these values. These values can also be tweaked and changed at any time, so you can always come back and optimize your deployment later.

Go ahead and insert the following highlighted lines under the `resources` section of your Nginx container:

Deployment Configuration File

    . . .
      template:
        metadata:
          creationTimestamp: null
          labels:
            app: web
        spec:
          containers:
          - image: nginx:latest
            imagePullPolicy: Always
            name: nginx
            resources:
              limits:
                cpu: 300m
              requests:
                cpu: 100m
                memory: 250Mi
            terminationMessagePath: /dev/termination-log
            terminationMessagePolicy: File
          dnsPolicy: ClusterFirst
          restartPolicy: Always
          schedulerName: default-scheduler
          securityContext: {}
          terminationGracePeriodSeconds: 30
    status:
      availableReplicas: 1
    . . .

Once you’ve inserted these lines, save and quit the file. If there is an issue with the syntax, `kubectl` will reopen the file for you with an error posted for more information.

Now that you have your limits and requests set, you need to ensure that your metrics are being gathered so that the HPA can monitor and correctly adhere to these limits. In order to do this, you will set up a service to gather the CPU metrics. For this tutorial, you will use the Metrics Server project for collecting these metrics, which you will install with a Helm chart.

## Step 3 — Installing Metrics Server

Next, you will install the [Kubernetes Metric Server](https://github.com/kubernetes-incubator/metrics-server). This is the server that scrapes pod metrics, which will gather the metrics that the HPA will use to decide if autoscaling is necessary.

To install the Metrics Server using [Helm](https://helm.sh/), run the following command:

    helm install stable/metrics-server --name metrics-server

This will install the latest stable version of Metrics Server. The `--name` flag names this release `metrics-server`.

Once you wait for this pod to initialize, try to use the `kubectl top pod` command to display your pod’s metrics:

    kubectl top pod

This command is meant to give a pod-level view of resource usage in your cluster, but because of the way that DOKS handles DNS, this command will return an error at this point:

    OutputError: Metrics not available for pod
    
    Error from server (ServiceUnavailable): the server is currently unable to handle the request (get pods.metrics.k8s.io)

This error occurs because DOKS nodes do not create a DNS record for themselves, and since Metrics Server contacts nodes through their hostnames, the hostnames do not resolve properly. To fix this problem, change how the Metrics Server communicates with nodes by adding runtime flags to the Metrics Server container using the following command:

    kubectl edit deployment metrics-server

You will be adding a flag under the `command` section.

metrics-server Configuration File

    . . .
      template:
        metadata:
          creationTimestamp: null
          labels:
            app: metrics-server
            release: metrics-server
        spec:
          affinity: {}
          containers:
          - command:
            - /metrics-server
            - --cert-dir=/tmp
            - --logtostderr
            - --secure-port=8443
            image: gcr.io/google_containers/metrics-server-amd64:v0.3.4
            imagePullPolicy: IfNotPresent
            livenessProbe:
              failureThreshold: 3
              httpGet:
                path: /healthz
    . . .

The flag you are adding is `--kubelet-preferred-address-types=InternalIP`. This flag tells the metrics server to contact nodes using their `internalIP` as opposed to their hostname. You can use this flag as a workaround to communicate with the nodes via internal IP addresses.

Also, add the `--metric-resolution` flag to change the default rate at which the Metrics Server scrapes metrics. For this tutorial, we will set Metrics Server to make data points every `60s`, but if you would like more metrics data, you could ask for the Metrics Server to scrape metrics every `10s` or `20s`. This will give you more data points of resource usage per period of time. Feel free to fine-tune this resolution to meet your needs.

Add the following highlighted lines to the file:

metrics-server Configuration File

    . . .
      template:
        metadata:
          creationTimestamp: null
          labels:
            app: metrics-server
            release: metrics-server
        spec:
          affinity: {}
          containers:
          - command:
            - /metrics-server
            - --cert-dir=/tmp
            - --logtostderr
            - --secure-port=8443
            - --metric-resolution=60s
            - --kubelet-preferred-address-types=InternalIP
            image: gcr.io/google_containers/metrics-server-amd64:v0.3.4
            imagePullPolicy: IfNotPresent
            livenessProbe:
              failureThreshold: 3
              httpGet:
                path: /healthz
    . . .

After the flag is added, save and exit your editor.

To verify your Metrics Server is running, use `kubectl top pod` after a few minutes. As before, this command will give us resource usage on a pod level. This time, a working Metrics Server will allow you to see metrics on each pod:

    kubectl top pod

This will give the following output, with your Metrics Server pod running:

    OutputNAME CPU(cores) MEMORY(bytes)
    metrics-server-db745fcd5-v8gv6 3m 12Mi
    web-555db5bf6b-f7btr 0m 2Mi        

You now have a functional Metrics Server and are able to view and monitor resource usage of pods within your cluster. Next, you are going to configure the HPA to monitor this data and react to periods of high CPU usage.

## Step 4 — Creating and Validating the Horizontal Pod Autoscaler

Lastly, it’s time to create the Horizontal Pod Autoscaler (HPA) for your deployment. The HPA is the actual Kubernetes object that routinely checks the CPU usage data collected from your Metrics Server and scales your deployment based on the thresholds you set in Step 2.

Create the HPA using the `kubectl autoscale` command:

    kubectl autoscale deployment web --max=4 --cpu-percent=80

This command creates the HPA for your `web` deployment. It also uses the `--max` flag to set the max replicas that `web` can be scaled to, which in this case you set as `4`.

The `--cpu-percent` flag tells the HPA at what percent usage of the limit you set in Step 2 you want to trigger the autoscale to occur. This also uses the requests to help schedule the scaled up pods to a node that can accomodate the initial resource allocation. In this example, if the limit you set on your deployment in Step 1 was 100 millicores (`100m`), this command would trigger an autoscale once the pod hit `80m` in average CPU usage. This would allow the deployment to autoscale prior to maxing out its CPU resources.

Now that your deployment can automatically scale, it’s time to put this to the test.

To validate, you are going to generate a load that will put your cluster over your threshold and then watch the autoscaler take over. To start, open up a second terminal to watch the currently scheduled pods and refresh the list of pods every 2 seconds. To accomplish this, use the `watch` command in this second terminal:

    watch "kubectl top pods"

The `watch` command issues the command given as its arguments continuously, displaying the output in your terminal. The duration between repetitions can be further configured with the `-n` flag. For the purposes of this tutorial, the default two seconds setting will suffice.

The terminal will now display the output of `kubectl top pods` initially and then every 2 seconds it will refresh the output that that command generates, which will look similar to this:

    OutputEvery 2.0s: kubectl top pods                                                                                                                                 
    
    NAME CPU(cores) MEMORY(bytes)
    metrics-server-6fd5457684-7kqtz 3m 15Mi
    web-7476bb659d-q5bjv 0m 2Mi

Take note of the number of pods currently deployed for `web`.

Switch back to your original terminal. You will now open a terminal inside your current `web` pod using `kubectl exec` and create an artificial load. You can accomplish this by going into the pod and installing the [`stress` CLI tool](https://packages.ubuntu.com/xenial/devel/stress).

Enter your pod using `kubectl exec`, replacing the highlighted pod name with the name of your `web` pod:

    kubectl exec -it web-f765fd676-s9729 /bin/bash

This command is very similar in concept to using `ssh` to log in to another machine. `/bin/bash` establishes a bash shell in your pod.

Next, from the bash shell inside your pod, update the repository metadata and install the `stress` package.

    apt update; apt-get install -y stress

**Note:** For CentOS-based containers, this would be:

    yum install -y stress

Next, generate some CPU load on your pod using the `stress` command and let it run:

    stress -c 3

Now, go back to your `watch` command in the second terminal. Wait a few minutes for the Metrics Server to gather CPU data that is above the HPA’s defined threshold. Note that metrics by default are gathered at whichever rate you set `--metric-resolution` equal to when configuring the metrics server. It may take a minute or so for the usage metrics to update.

After about two minutes, you will see additional `web` pods spin up:

    OutputEvery 2.0s: kubectl top pods                                                                                                                                 
    
    NAME CPU(cores) MEMORY(bytes)
    metrics-server-db745fcd5-v8gv6 6m 16Mi
    web-555db5bf6b-ck98q 0m 2Mi
    web-555db5bf6b-f7btr 494m 21Mi
    web-555db5bf6b-h5cbx 0m 1Mi
    web-555db5bf6b-pvh9f 0m 2Mi

You can now see that the HPA scheduled new pods based off the CPU load gathered by Metrics Server. When you are satisfied with this validation, use `CTRL+C` to stop the `stress` command in your first terminal, then exit your pod’s bash shell.

## Conclusion

In this article you created a deployment that will autoscale based on CPU load. You added CPU resource limits and requests to your deployment, installed and configured Metrics Server in your cluster through the use of Helm, and created an HPA to make scaling decisions.

This was a demonstration deployment of both Metrics Server and HPA. Now you can tweak the configuration to fit your particular use cases. Be sure to poke around the [Kubernetes HPA](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) docs for help and info on [requests and limitations](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/). Also, check out the [Metrics Server project](https://github.com/kubernetes-incubator/metrics-server) see all the tunable settings that may apply to your use case.

If you would like to do more with Kubernetes, head over to our [Kubernetes Community page](https://www.digitalocean.com/community/tags/kubernetes?type=tutorials) or explore our [Managed Kubernetes service](https://www.digitalocean.com/products/kubernetes/).
