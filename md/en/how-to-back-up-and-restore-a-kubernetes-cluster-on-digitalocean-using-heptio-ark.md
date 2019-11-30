---
author: Hanif Jetha
date: 2018-10-02
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-back-up-and-restore-a-kubernetes-cluster-on-digitalocean-using-heptio-ark
---

# How To Back Up and Restore a Kubernetes Cluster on DigitalOcean Using Heptio Ark

 **Note:** The Ark project has been renamed to [Velero](https://github.com/heptio/velero) and has introduced multiple changes in v0.11.0. This guide will soon be updated to incorporate these changes. Thanks for your patience!

## Introduction

[Heptio Ark](https://heptio.github.io/ark/) is a convenient backup tool for Kubernetes clusters that compresses and backs up Kubernetes objects to object storage. It also takes snapshots of your cluster’s Persistent Volumes using your cloud provider’s block storage snapshot features, and can then restore your cluster’s objects and Persistent Volumes to a previous state.

StackPointCloud’s [DigitalOcean Ark Plugin](https://github.com/StackPointCloud/ark-plugin-digitalocean) allows you to use DigitalOcean block storage to snapshot your Persistent Volumes, and Spaces to back up your Kubernetes objects. When running a Kubernetes cluster on DigitalOcean, this allows you to quickly back up your cluster’s state and restore it should disaster strike.

In this tutorial we’ll set up and configure the Ark client on a local machine, and deploy the Ark server into our Kubernetes cluster. We’ll then deploy a sample Nginx app that uses a Persistent Volume for logging, and simulate a disaster recovery scenario.

## Prerequisites

Before you begin this tutorial, you should have the following available to you:

On your local computer:

- The `kubectl` command-line tool, configured to connect to your cluster. You can read more about installing and configuring `kubectl` in the [official Kubernetes documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
- The [`git`](https://git-scm.com/) command-line utility. You can learn how to install `git` in [Getting Started with Git](how-to-contribute-to-open-source-getting-started-with-git).

In your DigitalOcean account:

- A [DigitalOcean Kubernetes](https://www.digitalocean.com/products/kubernetes/) cluster, or a Kubernetes cluster (version `1.7.5` or later) on DigitalOcean Droplets
- A DNS server running inside of your cluster. If you are using DigitalOcean Kubernetes, this is running by default. To learn more about configuring a Kubernetes DNS service, consult [Customizing DNS Service](https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/) from the official Kuberentes documentation.
- A DigitalOcean Space that will store your backed-up Kubernetes objects. To learn how to create a Space, consult [the Spaces product documentation](https://www.digitalocean.com/docs/spaces/).
- An access key pair for your DigitalOcean Space. To learn how to create a set of access keys, consult [How to Manage Administrative Access to Spaces](https://www.digitalocean.com/docs/spaces/how-to/administrative-access/).
- A personal access token for use with the DigitalOcean API. To learn how to create a personal access token, consult [How to Create a Personal Access Token](https://www.digitalocean.com/docs/api/create-personal-access-token/).

Once you have all of this set up, you’re ready to begin with this guide.

## Step 1 — Installing the Ark Client

The Heptio Ark backup tool consists of a client installed on your local computer and a server that runs in your Kubernetes cluster. To begin, we’ll install the local Ark client.

In your web browser, navigate to the Ark/Velero GitHub repo [releases page](https://github.com/heptio/velero/releases), find the release corresponding to your OS and system architecture, and copy the link address. For the purposes of this guide, we’ll use an Ubuntu 18.04 server on an x86-64 (or AMD64) processor as our local machine, and the Ark `v0.10.0` release.

**Note:** To follow this guide, you should download and install [v0.10.0](https://github.com/heptio/velero/releases/tag/v0.10.0) of the Ark client.

Then, from the command line on your local computer, navigate to the temporary `/tmp` directory and `cd` into it:

    cd /tmp

Use `wget` and the link you copied earlier to download the release tarball:

    wget https://link_copied_from_release_page

Once the download completes, extract the tarball using `tar` (note the filename may differ depending on the release version and your OS):

    tar -xvzf ark-v0.10.0-linux-amd64.tar.gz

The `/tmp` directory should now contain the extracted `ark` binary as well as the tarball you just downloaded.

Verify that you can run the `ark` client by executing the binary:

    ./ark --help

You should see the following help output:

    OutputHeptio Ark is a tool for managing disaster recovery, specifically for Kubernetes
    cluster resources. It provides a simple, configurable, and operationally robust
    way to back up your application state and associated data.
    
    If you're familiar with kubectl, Ark supports a similar model, allowing you to
    execute commands such as 'ark get backup' and 'ark create schedule'. The same
    operations can also be performed as 'ark backup get' and 'ark schedule create'.
    
    Usage:
      ark [command]
    
    Available Commands:
      backup Work with backups
      client Ark client related commands
      completion Output shell completion code for the specified shell (bash or zsh)
      create Create ark resources
      delete Delete ark resources
      describe Describe ark resources
      get Get ark resources
      help Help about any command
      plugin Work with plugins
      restic Work with restic
      restore Work with restores
      schedule Work with schedules
      server Run the ark server
      version Print the ark version and associated image
    
    . . .

At this point you should move the `ark` executable out of the temporary `/tmp` directory and add it to your `PATH`. To add it to your `PATH` on an Ubuntu system, simply copy it to `/usr/local/bin`:

    sudo mv ark /usr/local/bin/ark

You’re now ready to configure the Ark server and deploy it to your Kubernetes cluster.

## Step 2 — Installing and Configuring the Ark Server

Before we deploy Ark into our Kubernetes cluster, we’ll first create Ark’s prerequisite objects. Ark’s prerequisites consist of:

- A `heptio-ark` Namespace

- The `ark` Service Account

- Role-based access control (RBAC) rules to grant permissions to the `ark` Service Account

- Custom Resources (CRDs) for the Ark-specific resources: `Backup`, `Schedule`, `Restore`, `Config`

A YAML manifest file containing the definitions for the above Kubernetes objects can be found in the [Ark source code](https://github.com/heptio/velero/releases). While still in the `/tmp` directory, download the source code tarball corresponding to the client release version you previously downloaded. In this tutorial, this is `v0.10.0`:

    wget https://github.com/heptio/velero/archive/v0.10.0.tar.gz

Now, extract the tarball using `tar` (note the filename may differ depending on the release version):

    tar -xvzf v0.10.0.tar.gz

Once downloaded, navigate into the `velero-0.10.0` directory:

    cd velero-0.10.0

The prerequisite resources listed above can be found in the `examples/common/00-prereqs.yaml` YAML file. We’ll create these resources in our Kubernetes cluster by using `kubectl apply` and passing in the file:

    kubectl apply -f examples/common/00-prereqs.yaml

You should see the following output:

    Outputcustomresourcedefinition.apiextensions.k8s.io/backups.ark.heptio.com created
    customresourcedefinition.apiextensions.k8s.io/schedules.ark.heptio.com created
    customresourcedefinition.apiextensions.k8s.io/restores.ark.heptio.com created
    customresourcedefinition.apiextensions.k8s.io/downloadrequests.ark.heptio.com created
    customresourcedefinition.apiextensions.k8s.io/deletebackuprequests.ark.heptio.com created
    customresourcedefinition.apiextensions.k8s.io/podvolumebackups.ark.heptio.com created
    customresourcedefinition.apiextensions.k8s.io/podvolumerestores.ark.heptio.com created
    customresourcedefinition.apiextensions.k8s.io/resticrepositories.ark.heptio.com created
    customresourcedefinition.apiextensions.k8s.io/backupstoragelocations.ark.heptio.com created
    customresourcedefinition.apiextensions.k8s.io/volumesnapshotlocations.ark.heptio.com created
    namespace/heptio-ark created
    serviceaccount/ark created
    clusterrolebinding.rbac.authorization.k8s.io/ark created

Now that we’ve created the necessary Ark Kubernetes objects in our cluster, we can download and install the [Ark DigitalOcean Plugin](https://github.com/StackPointCloud/ark-plugin-digitalocean), which will allow us to use DigitalOcean Spaces as a `backupStorageProvider` (for Kubernetes objects), and DigitalOcean Block Storage as a `persistentVolumeProvider` (for Persistent Volume backups).

Move back out of the `velero-0.10.0` directory and download version `v0.10.0` of the plugin. You can find the plugin’s release versions on the StackPointCloud DigitalOcean plugin [releases page](https://github.com/StackPointCloud/ark-plugin-digitalocean/releases).

    cd ..
    wget https://github.com/StackPointCloud/ark-plugin-digitalocean/archive/v0.10.0.tar.gz

Now, extract the tarball using `tar` (note the filename may differ depending on the release version, and may end with a `.1` if you did not delete the previous `v0.10.0.tar.gz` tarball that contains the Velero client/server source code):

    tar -xvzf v0.10.0.tar.gz.1

Move into the plugin directory:

    cd ark-plugin-digitalocean-0.10.0

We’ll now save the access keys for our DigitalOcean Space as a Kubernetes [Secret](https://kubernetes.io/docs/concepts/configuration/secret/). First, open up the `examples/credentials-ark` file using your favorite editor:

    nano examples/credentials-ark

Replace `<AWS_ACCESS_KEY_ID>` and `<AWS_SECRET_ACCESS_KEY>` with your Spaces access key and secret key:

examples/credentials-ark

    [default]
    aws_access_key_id=your_spaces_access_key_here
    aws_secret_access_key=your_spaces_secret_key_here

Save and close the file.

Now, create the `cloud-credentials` Secret using `kubectl`, inserting your API Personal Access Token using the `digitalocean_token` parameter:

    kubectl create secret generic cloud-credentials \
        --namespace heptio-ark \
        --from-file cloud=examples/credentials-ark \
        --from-literal digitalocean_token=your_personal_access_token

You should see the following output:

    Outputsecret/cloud-credentials created

To confirm that the `cloud-credentials` Secret was created successfully, you can `describe` it using `kubectl`:

    kubectl describe secrets/cloud-credentials --namespace heptio-ark

You should see the following output describing the `cloud-credentials` secret:

    OutputName: cloud-credentials
    Namespace: heptio-ark
    Labels: <none>
    Annotations: <none>
    
    Type: Opaque
    
    Data
    ====
    cloud: 115 bytes
    digitalocean_token: 64 bytes

We can now move on to creating an Ark `BackupStorageLocation` object named `default` that will configure the plugin’s object storage backend. To do this, we’ll edit a YAML manifest file and then create the object in our Kubernetes cluster.

Open `examples/05-ark-backupstoragelocation.yaml` in your favorite editor:

    nano examples/05-ark-backupstoragelocation.yaml

Insert your Space’s name and region in the highlighted fields:

examples/05-ark-backupstoragelocation.yaml

    . . . 
    ---
    apiVersion: ark.heptio.com/v1
    kind: BackupStorageLocation
    metadata:
      name: default
      namespace: heptio-ark
    spec:
      provider: aws
      objectStorage:
        bucket: space_name_here
      config:
        s3Url: https://space_region_here.digitaloceanspaces.com
        region: space_region_here

When you’re done, save and close the file.

Create the object in your cluster using `kubectl apply`:

    kubectl apply -f examples/05-ark-backupstoragelocation.yaml

You should see the following output:

    Outputbackupstoragelocation.ark.heptio.com/default created

You won’t need to repeat this procedure for the `VolumeSnapshotLocation` object, which configures the block storage backend. It is already preconfigured with the appropriate parameters. To inspect these, open `examples/06-ark-volumesnapshotlocation.yaml` in your editor:

    nano examples/06-ark-volumesnapshotlocation.yaml

examples/06-ark-volumesnapshotlocation.yaml

    . . . 
    ---
    apiVersion: ark.heptio.com/v1
    kind: VolumeSnapshotLocation
    metadata:
      name: default
      namespace: heptio-ark
    spec:
      provider: digitalocean-blockstore

When you’re done, close the file.

Create the object in your cluster using `kubectl apply`:

    kubectl apply -f examples/06-ark-volumesnapshotlocation.yaml

    Outputvolumesnapshotlocation.ark.heptio.com/default created

At this point, we’ve finished configuring the Ark server and can create its Kubernetes deployment, found in the `examples/10-deployment.yaml` configuration file. Let’s take a quick look at this file:

    cat examples/10-deployment.yaml

You should see the following text:

examples/10-deployment.yaml

    ---
    apiVersion: apps/v1beta1
    kind: Deployment
    metadata:
      namespace: heptio-ark
      name: ark
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            component: ark
          annotations:
            prometheus.io/scrape: "true"
            prometheus.io/port: "8085"
            prometheus.io/path: "/metrics"
        spec:
          restartPolicy: Always
          serviceAccountName: ark
          containers:
            - name: ark
              image: gcr.io/heptio-images/ark:latest
              command:
                - /ark
              args:
                - server
                - --default-volume-snapshot-locations=digitalocean-blockstore:default
              volumeMounts:
                - name: cloud-credentials
                  mountPath: /credentials
                - name: plugins
                  mountPath: /plugins
                - name: scratch
                  mountPath: /scratch
              env:
                - name: AWS_SHARED_CREDENTIALS_FILE
                  value: /credentials/cloud
                - name: ARK_SCRATCH_DIR
                  value: /scratch
                - name: DIGITALOCEAN_TOKEN
                  valueFrom:
                    secretKeyRef:
                      key: digitalocean_token
                      name: cloud-credentials
          volumes:
            - name: cloud-credentials
              secret:
                secretName: cloud-credentials
            - name: plugins
              emptyDir: {}
            - name: scratch
              emptyDir: {}

We observe here that we’re creating a Deployment called `ark` that consists of a single replica of the `gcr.io/heptio-images/ark:latest` container. The Pod is configured using the `cloud-credentials` secret we created earlier.

Create the Deployment using `kubectl apply`:

    kubectl apply -f examples/10-deployment.yaml

You should see the following output:

    Outputdeployment.apps/ark created

We can double check that the Deployment has been successfully created using `kubectl get` on the `heptio-ark` Namespace :

    kubectl get deployments --namespace=heptio-ark

You should see the following output:

    OutputNAME READY UP-TO-DATE AVAILABLE AGE
    ark 1/1 1 1 7s

The Ark server Pod may not start correctly until you install the Ark DigitalOcean plugin. To install the `ark-blockstore-digitalocean` plugin, use the `ark` client we installed earlier:

    ark plugin add quay.io/stackpoint/ark-blockstore-digitalocean:v0.10.0

You can specify the `kubeconfig` to use with the `--kubeconfig` flag. If you don’t use this flag, `ark` will check the `KUBECONFIG` environment variable and then fall back to the `kubectl` default (`~/.kube/config`).

At this point Ark is running and fully configured, and ready to back up and restore your Kubernetes cluster objects and Persistent Volumes to DigitalOcean Spaces and Block Storage.

In the next section, we’ll run a quick test to make sure that the backup and restore functionality works as expected.

## Step 3 — Testing Backup and Restore Procedure

Now that we’ve successfully installed and configured Ark, we can create a test Nginx Deployment, Persistent Volume, and Service and run through a backup and restore drill to ensure that everything is working properly.

The `ark-plugin-digitalocean` repository contains a sample Nginx manifest called `nginx-pv.yaml`.

Open this file using your editor of choice:

    nano examples/nginx-pv.yaml

You should see the following text:

    Output---
    kind: PersistentVolumeClaim
    apiVersion: v1
    metadata:
      name: nginx-logs
      namespace: nginx-example
      labels:
        app: nginx
    spec:
      storageClassName: do-block-storage
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
    
    ---
    apiVersion: apps/v1beta1
    kind: Deployment
    metadata:
      name: nginx-deployment
      namespace: nginx-example
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: nginx
        spec:
          volumes:
            - name: nginx-logs
              persistentVolumeClaim:
               claimName: nginx-logs
          containers:
          - image: nginx:1.7.9
            name: nginx
            ports:
            - containerPort: 80
            volumeMounts:
              - mountPath: "/var/log/nginx"
                name: nginx-logs
                readOnly: false
    
    ---
    apiVersion: v1
    kind: Service
    metadata:
      labels:
        app: nginx
      name: my-nginx
      namespace: nginx-example
    spec:
      ports:
      - port: 80
        targetPort: 80
      selector:
        app: nginx
      type: LoadBalancer

In this file, we observe specs for:

- An Nginx Deployment consisting of a single replica of the `nginx:1.7.9` container image
- A 5Gi Persistent Volume Claim (called `nginx-logs`), using the `do-block-storage` StorageClass
- A `LoadBalancer` Service that exposes port `80`

Update the `nginx` image version to `1.14.2`:

    Output. . .
          containers:
          - image: nginx:1.14.2
            name: nginx
            ports:
            - containerPort: 80
            volumeMounts:
    . . .

When you’re done, save and close the file.

Create the objects using `kubectl apply`:

    kubectl apply -f examples/nginx-pv.yml

You should see the following output:

    Outputnamespace/nginx-example created
    persistentvolumeclaim/nginx-logs created
    deployment.apps/nginx-deployment created
    service/my-nginx created

Check that the Deployment succeeded:

    kubectl get deployments --namespace=nginx-example

You should see the following output:

    OutputNAME DESIRED CURRENT UP-TO-DATE AVAILABLE AGE
    nginx-deployment 1 1 1 1 1h

Once `Available` reaches 1, fetch the Nginx load balancer’s external IP using `kubectl get`:

    kubectl get services --namespace=nginx-example

You should see both the internal `CLUSTER-IP` and `EXTERNAL-IP` for the `my-nginx` Service:

    OutputNAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    my-nginx LoadBalancer 10.32.27.0 203.0.113.0 80:30754/TCP 3m

Note the `EXTERNAL-IP` and navigate to it using your web browser.

You should see the following NGINX welcome page:

![Nginx Welcome Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/kubernetes_backup/nginx_welcome.png)

This indicates that your Nginx Deployment and Service are up and running.

Before we simulate our disaster scenario, let’s first check the Nginx access logs (stored on a Persistent Volume attached to the Nginx Pod):

Fetch the Pod’s name using `kubectl get`:

    kubectl get pods --namespace nginx-example

    OutputNAME READY STATUS RESTARTS AGE
    nginx-deployment-77d8f78fcb-zt4wr 1/1 Running 0 29m

Now, `exec` into the running Nginx container to get a shell inside of it:

    kubectl exec -it nginx-deployment-77d8f78fcb-zt4wr --namespace nginx-example -- /bin/bash

Once inside the Nginx container, `cat` the Nginx access logs:

    cat /var/log/nginx/access.log

You should see some Nginx access entries:

    Output10.244.17.1 - - [01/Oct/2018:21:47:01 +0000] "GET / HTTP/1.1" 200 612 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/203.0.113.11 Safari/537.36" "-"
    10.244.17.1 - - [01/Oct/2018:21:47:01 +0000] "GET /favicon.ico HTTP/1.1" 404 570 "http://203.0.113.0/" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/203.0.113.11 Safari/537.36" "-"

Note these down (especially the timestamps), as we will use them to confirm the success of the restore procedure.

We can now perform the backup procedure to copy all `nginx` Kubernetes objects to Spaces and take a Snapshot of the Persistent Volume we created when deploying Nginx.

We’ll create a backup called `nginx-backup` using the `ark` client:

    ark backup create nginx-backup --selector app=nginx

The `--selector app=nginx` instructs the Ark server to only back up Kubernetes objects with the `app=nginx` Label Selector.

You should see the following output:

    OutputBackup request "nginx-backup" submitted successfully.
    Run `ark backup describe nginx-backup` for more details.

Running `ark backup describe nginx-backup` should provide the following output after a short delay:

    OutputName: nginx-backup
    Namespace: heptio-ark
    Labels: <none>
    Annotations: <none>
    
    Phase: Completed
    
    Namespaces:
      Included: *
      Excluded: <none>
    
    Resources:
      Included: *
      Excluded: <none>
      Cluster-scoped: auto
    
    Label selector: app=nginx
    
    Snapshot PVs: auto
    
    TTL: 720h0m0s
    
    Hooks: <none>
    
    Backup Format Version: 1
    
    Started: 2018-09-26 00:14:30 -0400 EDT
    Completed: 2018-09-26 00:14:34 -0400 EDT
    
    Expiration: 2018-10-26 00:14:30 -0400 EDT
    
    Validation errors: <none>
    
    Persistent Volumes:
      pvc-e4862eac-c2d2-11e8-920b-92c754237aeb:
        Snapshot ID: 2eb66366-c2d3-11e8-963b-0a58ac14428b
        Type: ext4
        Availability Zone:
        IOPS: <N/A>

This output indicates that `nginx-backup` completed successfully.

From the DigitalOcean Cloud Control Panel, navigate to the Space containing your Kubernetes backup files.

You should see a new directory called `nginx-backup` containing the Ark backup files.

Using the left-hand navigation bar, go to **Images** and then **Snapshots**. Within **Snapshots** , navigate to **Volumes**. You should see a Snapshot corresponding to the PVC listed in the above output.

We can now test the restore procedure.

Let’s first delete the `nginx-example` Namespace. This will delete everything in the Namespace, including the Load Balancer and Persistent Volume:

    kubectl delete namespace nginx-example

Verify that you can no longer access Nginx at the Load Balancer endpoint, and that the `nginx-example` Deployment is no longer running:

    kubectl get deployments --namespace=nginx-example

    OutputNo resources found.

We can now perform the restore procedure, once again using the `ark` client:

    ark restore create --from-backup nginx-backup

Here we use `create` to create an Ark `Restore` object from the `nginx-backup` object.

You should see the following output:

    OutputRestore request "nginx-backup-20180926143828" submitted successfully.
    Run `ark restore describe nginx-backup-20180926143828` for more details.

Check the status of the restored Deployment:

    kubectl get deployments --namespace=nginx-example

    OutputNAME DESIRED CURRENT UP-TO-DATE AVAILABLE AGE
    nginx-deployment 1 1 1 1 1m

Check for the creation of a Persistent Volume:

     kubectl get pvc --namespace=nginx-example

    OutputNAME STATUS VOLUME CAPACITY ACCESS MODES STORAGECLASS AGE
    nginx-logs Bound pvc-e4862eac-c2d2-11e8-920b-92c754237aeb 5Gi RWO do-block-storage 3m

Navigate to the Nginx Service’s external IP once again to confirm that Nginx is up and running.

Finally, check the logs on the restored Persistent Volume to confirm that the log history has been preserved post-restore.

To do this, once again fetch the Pod’s name using `kubectl get`:

    kubectl get pods --namespace nginx-example

    OutputNAME READY STATUS RESTARTS AGE
    nginx-deployment-77d8f78fcb-zt4wr 1/1 Running 0 29m

Then `exec` into it:

    kubectl exec -it nginx-deployment-77d8f78fcb-zt4wr --namespace nginx-example -- /bin/bash

Once inside the Nginx container, `cat` the Nginx access logs:

    cat /var/log/nginx/access.log

    Output10.244.17.1 - - [01/Oct/2018:21:47:01 +0000] "GET / HTTP/1.1" 200 612 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/203.0.113.11 Safari/537.36" "-"
    10.244.17.1 - - [01/Oct/2018:21:47:01 +0000] "GET /favicon.ico HTTP/1.1" 404 570 "http://203.0.113.0/" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/203.0.113.11 Safari/537.36" "-"

You should see the same pre-backup access attempts (note the timestamps), confirming that the Persistent Volume restore was successful. Note that there may be additional attempts in the logs if you visited the Nginx landing page after you performed the restore.

At this point, we’ve successfully backed up our Kubernetes objects to DigitalOcean Spaces, and our Persistent Volumes using Block Storage Volume Snapshots. We simulated a disaster scenario, and restored service to the test Nginx application.

## Conclusion

In this guide we installed and configured the Ark Kubernetes backup tool on a DigitalOcean-based Kubernetes cluster. We configured the tool to back up Kubernetes objects to DigitalOcean Spaces, and back up Persistent Volumes using Block Storage Volume Snapshots.

Ark can also be used to schedule regular backups of your Kubernetes cluster. To do this, you can use the `ark schedule` command. It can also be used to migrate resources from one cluster to another. To learn more about these two use cases, consult the [official Ark documentation](https://heptio.github.io/ark/v0.9.0/use-cases).

To learn more about DigitalOcean Spaces, consult the [official Spaces documentation](https://www.digitalocean.com/docs/spaces/). To learn more about Block Storage Volumes, consult the [Block Storage Volume documentation](https://www.digitalocean.com/docs/volumes/).

This tutorial builds on the README found in StackPointCloud’s `ark-plugin-digitalocean` [GitHub repo](https://github.com/StackPointCloud/ark-plugin-digitalocean).
