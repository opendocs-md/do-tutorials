---
author: Jeremy Morris, Lisa Tagliaferri
date: 2019-03-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-tensorflow-on-ubuntu-18-04
---

# How To Install and Use TensorFlow on Ubuntu 18.04

## Introduction

[TensorFlow](https://www.tensorflow.org/) is open-source machine learning software used to train neural networks.TensorFlow’s neural networks are expressed in the form of [stateful dataflow graphs](https://www.tensorflow.org/programmers_guide/graphs). Each node in the graph represents the operations performed by neural networks on multi-dimensional arrays. These multi-dimensional arrays are commonly known as “tensors,” hence the name TensorFlow.

TensorFlow is a [deep learning](https://en.wikipedia.org/wiki/Deep_learning) software system. It works well for information retrieval, as demonstrated by Google in how they do search ranking in their machine learning artificial intelligence system, [RankBrain](https://en.wikipedia.org/wiki/RankBrain). TensorFlow can perform image recognition, as shown in Google’s [Inception](https://arxiv.org/abs/1409.4842), as well as human language audio recognition. It’s also useful in solving other problems not specific to machine learning, such as [partial differential equations](https://www.tensorflow.org/tutorials/pdes).

The TensorFlow architecture allows for deployment on multiple CPUs or GPUs within a desktop, server, or mobile device. There are also extensions for integration with [CUDA](https://developer.nvidia.com/cuda-zone), a parallel computing platform from Nvidia. This gives users who are deploying on a GPU direct access to the virtual instruction set and other elements of the GPU that are necessary for parallel computational tasks.

In this tutorial, we’ll install TensorFlow’s “CPU support only” version. This installation is ideal for people looking to install and use TensorFlow, but who don’t have an Nvidia graphics card or don’t need to run performance-critical applications.

You can install TensorFlow several ways. Each method has a different use case and development environment:

- **Python and Virtualenv** : In this approach, you install TensorFlow and all of the packages required to use TensorFlow in a Python virtual environment. This isolates your TensorFlow environment from other Python programs on the same machine. 
- **Native pip** : In this method, you install TensorFlow on your system globally. This is recommended for people who want to make TensorFlow available to everyone on a multi-user system. This method of installation does not isolate TensorFlow in a contained environment and may interfere with other Python installations or libraries.
- **Docker** : Docker is a container runtime environment and completely isolates its contents from preexisting packages on your system. In this method, you use a Docker container that contains TensorFlow and all of its dependencies. This method is ideal for incorporating TensorFlow into a larger application architecture already using Docker. However, the size of the Docker image will be quite large.

In this tutorial, you’ll install TensorFlow in a Python virtual environment with `virtualenv`. This approach isolates the TensorFlow installation and gets things up and running quickly. Once you complete the installation, you’ll validate your installation by running a short TensorFlow program and then use TensorFlow to perform image recognition.

## Prerequisites

Before you begin this tutorial, you’ll need the following:

- One Ubuntu 18.04 server with at least 1GB of RAM set up by following [the Ubuntu 18.04 initial server setup guide](initial-server-setup-with-ubuntu-18-04), including a sudo non-root user and a firewall. You’ll need at least 1GB of RAM to successfully perform the last example in this tutorial.

- Python 3.3 or higher and `virtualenv` installed. Follow [How To Install Python 3 on Ubuntu 18.04](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-18-04-server) to configure Python and `virtualenv`.

- Git installed, which you can do by following [How To Install Git on Ubuntu 18.04](how-to-install-git-on-ubuntu-18-04). You’ll use this to download a repository of examples.

## Step 1 — Installing TensorFlow

In this step we are going to create a virtual environment and install TensorFlow.

First, create a project directory. We’ll call it `tf-demo` for demonstration purposes, but choose a directory name that is meaningful to you:

    mkdir ~/tf-demo

Navigate to your newly created `tf-demo` directory:

    cd ~/tf-demo

Then create a new virtual environment called `tensorflow-dev`, for instance. Run the following command to create the environment:

    python3 -m venv tensorflow-dev

This creates a new `tensorflow-dev` directory which will contain all of the packages that you install while this environment is activated. It also includes `pip` and a standalone version of Python.

Now activate your virtual environment:

    source tensorflow-dev/bin/activate

Once activated, you will see something similar to this in your terminal:

    (tensorflow-dev)username@hostname:~/tf-demo $

Now you can install TensorFlow in your virtual environment.

Run the following command to install and upgrade to the newest version of TensorFlow available in [PyPi](https://pypi.python.org/pypi):

    pip install --upgrade tensorflow

TensorFlow will install, and you should get output that indicates that the install along with any dependent packages was successful.

    Output...
    Successfully installed absl-py-0.7.1 astor-0.7.1 gast-0.2.2 grpcio-1.19.0 h5py-2.9.0 keras-applications-1.0.7 keras-preprocessing-1.0.9 markdown-3.0.1 mock-2.0.0 numpy-1.16.2 pbr-5.1.3 protobuf-3.7.0 setuptools-40.8.0 tensorboard-1.13.1 tensorflow-1.13.1 tensorflow-estimator-1.13.0 termcolor-1.1.0 werkzeug-0.15.0 wheel-0.33.1
    ...
    
    Successfully installed bleach-1.5.0 enum34-1.1.6 html5lib-0.9999999 markdown-2.6.9 numpy-1.13.3 protobuf-3.5.0.post1 setuptools-38.2.3 six-1.11.0 tensorflow-1.4.0 tensorflow-tensorboard-0.4.0rc3 werkzeug-0.12.2 wheel-0.30.0

You can deactivate your virtual environment at any time by using the following command:

    deactivate

To reactivate the environment later, navigate to your project directory and run `source tensorflow-dev/bin/activate`.

Now that you have installed TensorFlow, let’s make sure the TensorFlow installation works.

## Step 2 — Validating Installation

To validate the installation of TensorFlow, we are going to run a simple program in TensorFlow as a non-root user. We will use the canonical beginner’s example of “Hello, world!” as a form of validation. Rather than creating a Python file, we’ll create this program using [Python’s interactive console](how-to-work-with-the-python-interactive-console).

To write the program, start up your Python interpreter:

    python

You will see the following prompt appear in your terminal:

    >>>

This is the prompt for the Python interpreter, and it indicates that it’s ready for you to start entering some Python statements.

First, type this line to import the TensorFlow package and make it available as the local variable `tf`. Press `ENTER` after typing in the line of code:

    import tensorflow as tf

Next, add this line of code to set the message “Hello, world!”:

    hello = tf.constant("Hello, world!")

Then create a new TensorFlow session and assign it to the variable `sess`:

    sess = tf.Session()

**Note** : Depending on your environment, you might see this output:

    Output2019-03-20 16:22:45.956946: W tensorflow/core/platform/cpu_feature_guard.cc:45] The TensorFlow library wasn't compiled to use SSE4.1 instructions, but these are available on your machine and could speed up CPU computations.
    2019-03-20 16:22:45.957158: W tensorflow/core/platform/cpu_feature_guard.cc:45] The TensorFlow library wasn't compiled to use SSE4.2 instructions, but these are available on your machine and could speed up CPU computations.
    2019-03-20 16:22:45.957282: W tensorflow/core/platform/cpu_feature_guard.cc:45] The TensorFlow library wasn't compiled to use AVX instructions, but these are available on your machine and could speed up CPU computations.
    2019-03-20 16:22:45.957404: W tensorflow/core/platform/cpu_feature_guard.cc:45] The TensorFlow library wasn't compiled to use AVX2 instructions, but these are available on your machine and could speed up CPU computations.
    2019-03-20 16:22:45.957527: W tensorflow/core/platform/cpu_feature_guard.cc:45] The TensorFlow library wasn't compiled to use FMA instructions, but these are available on your machine and could speed up CPU computations.

This tells you that you have an [instruction set](https://en.wikipedia.org/wiki/Instruction_set_architecture) that has the potential to be optimized for better performance with TensorFlow. If you see this, you can safely ignore it and continue.

Finally, enter this line of code to print out the result of running the `hello` TensorFlow session you’ve constructed in your previous lines of code:

In Python 3, `sess.run()` will return a byte string, which will be rendered as `b'Hello, world!'` if you run `print(sess.run(hello))` alone. In order to return `Hello, world!` as a string, let’s add the `decode()` method.

    print(sess.run(hello).decode())

You’ll see this output in your console:

    OutputHello, world!

This indicates that everything is working and that you can start using TensorFlow.

Exit the Python interactive console by pressing `CTRL+D` or typing `quit()`.

Next, let’s use TensorFlow’s image recognition API to get more familiar with TensorFlow.

## Step 3 — Using TensorFlow for Image Recognition

Now that TensorFlow is installed and you’ve validated it by running a simple program, we can take a look at TensorFlow’s image recognition capabilities.

In order to classify an image you need to train a model. Then you need to write some code to use the model. To learn more about machine learning concepts, consider reading “[An Introduction to Machine Learning](an-introduction-to-machine-learning).”

TensorFlow provides a [repository of models and examples](https://github.com/tensorflow/models), including code and a trained model for classifying images.

Use Git to clone the TensorFlow models repository from GitHub into your project directory:

    git clone https://github.com/tensorflow/models.git

You will receive the following output as Git checks out the repository into a new folder called `models`:

    OutputCloning into 'models'...
    remote: Enumerating objects: 32, done.
    remote: Counting objects: 100% (32/32), done.
    remote: Compressing objects: 100% (26/26), done.
    remote: Total 24851 (delta 17), reused 12 (delta 6), pack-reused 24819
    Receiving objects: 100% (24851/24851), 507.78 MiB | 32.73 MiB/s, done.
    Resolving deltas: 100% (14629/14629), done.
    Checking out files: 100% (2858/2858), done.

Switch to the `models/tutorials/image/imagenet` directory:

    cd models/tutorials/image/imagenet

This directory contains the `classify_image.py` file which uses TensorFlow to recognize images. This program downloads a trained model from `tensorflow.org` on its first run. Downloading this model requires that you have 200MB of free space available on disk.

In this example, we will classify a [pre-supplied image of a Panda](https://www.tensorflow.org/images/cropped_panda.jpg). Execute this command to run the image classifier program:

    python classify_image.py

You’ll receive output similar to this:

    Outputgiant panda, panda, panda bear, coon bear, Ailuropoda melanoleuca (score = 0.89107)
    indri, indris, Indri indri, Indri brevicaudatus (score = 0.00779)
    lesser panda, red panda, panda, bear cat, cat bear, Ailurus fulgens (score = 0.00296)
    custard apple (score = 0.00147)
    earthstar (score = 0.00117)

You have classified your first image using the image recognition capabilities of TensorFlow.

If you’d like to use another image, you can do this by adding the `-- image_file` argument to your `python3 classify_image.py` command. For the argument, you would pass in the absolute path of the image file.

## Conclusion

In this tutorial, you have installed TensorFlow in a Python virtual environment and validated that TensorFlow works by running through some examples. You now possess tools that make it possible for you to explore additional topics including [Convolutional Neural Networks](https://en.wikipedia.org/wiki/Convolutional_neural_network) and [Word Embeddings](https://papers.nips.cc/paper/5021-distributed-representations-of-words-and-phrases-and-their-compositionality.pdf).

TensorFlow’s [programmer’s guide](https://www.tensorflow.org/programmers_guide/) provides a useful resource and reference for TensorFlow development. You can also explore [Kaggle](https://www.kaggle.com/), a competitive environment for practical application of machine learning concepts that pit you against other machine learning, data science, and statistics enthusiasts. They have a robust [wiki](https://www.kaggle.com/wiki/Home) where you can explore and share solutions, some of which are on the cutting edge of statistical and machine learning techniques.
