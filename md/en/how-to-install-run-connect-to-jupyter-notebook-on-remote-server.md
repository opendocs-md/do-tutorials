---
author: Andrew Andrade
date: 2018-09-12
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-run-connect-to-jupyter-notebook-on-remote-server
---

# How to Install, Run, and Connect to Jupyter Notebook on a Remote Server

_The author selected [the Apache Software Foundation](https://www.brightfunds.org/organizations/apache-software-foundation) to receive a $100 donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Jupyter Notebook](https://jupyter-notebook.readthedocs.io/en/stable/) is an open-source, interactive web application that allows you to write and run computer code in more than 40 programming languages, including [Python](https://www.python.org/), [R](https://www.r-project.org/), [Julia](https://julialang.org/), and [Scala](https://www.scala-lang.org/). A product from [Project Jupyter](http://jupyter.org/about), Jupyter Notebook is useful for iterative coding as it allows you to write a small snippet of code, run it, and return the result.

Jupyter Notebook provides the ability to create notebook documents, referred to simply as “notebooks”. Notebooks created from the Jupyter Notebook are shareable, reproducible research documents which include rich text elements, equations, code and their outputs (figures, tables, interactive plots). Notebooks can also be exported into raw code files, HTML or PDF documents, or used to create interactive slideshows or web pages.

This article will walk you through how to install and configure the Jupyter Notebook application on an Ubuntu 18.04 web server and how to connect to it from your local computer. Additionally, we will also go over how to use Jupyter Notebook to run some example Python code.

## Prerequisites

To complete this tutorial, you will need:

- One Ubuntu 18.04 server instance. This server must have a non-root user with sudo privileges and a firewall configured. Set this up by following our [initial server setup guide](initial-server-setup-with-ubuntu-18-04).
- Python 3, pip, and the Python `venv` module installed on the server. Do this by following Steps 1 and 2 of our tutorial on [How To Install Python 3 and Set Up a Local Programming Environment on Ubuntu 18.04](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-18-04-server).
- A modern web browser running on your local computer which you will use to access Jupyter Notebook.

Additionally, if your local computer is running Windows, you will need to install PuTTY on it in order to establish an SSH tunnel to your server. Follow our guide on [How to Create SSH Keys with PuTTY on Windows](how-to-use-ssh-keys-with-putty-on-digitalocean-droplets-windows-users) to download and install PuTTY.

## Step 1 — Installing Jupyter Notebook

Since notebooks are used to write, run and see the result of small snippets of code, you will first need to set up the programming language support. Jupyter Notebook uses a language-specific _kernel_, a computer program that runs and introspects code. Jupyter Notebook has [many kernels in different languages](https://github.com/jupyter/jupyter/wiki/Jupyter-kernels), the default being [IPython](https://ipython.org/). In this tutorial, you will set up Jupyter Notebook to run Python code through the IPython kernel.

Assuming that you followed the tutorials linked in the Prerequisites section, you should have [Python 3, pip and a virtual environment installed](how-to-install-python-3-and-set-up-a-local-programming-environment-on-ubuntu-18-04). The examples in this guide follow the convention used in the prerequisite tutorial on installing Python 3, which names the virtual environment “`my_env`”, but you should feel free to rename it.

Begin by activating the virtual environment:

    source my_env/bin/activate

Following this, your prompt will be prefixed with the name of your environment.

Now that you’re in your virtual environment, go ahead and install Jupyter Notebook:

    python3 -m pip install jupyter

If the installation was successful, you will see an output similar to the following:

    Output. . .
    Successfully installed MarkupSafe-1.0 Send2Trash-1.5.0 backcall-0.1.0 bleach-2.1.3 decorator-4.3.0 entrypoints-0.2.3 html5lib-1.0.1 ipykernel-4.8.2 ipython-6.4.0 ipython-genutils-0.2.0 ipywidgets-7.2.1 jedi-0.12.0 jinja2-2.10 jsonschema-2.6.0 jupyter-1.0.0 jupyter-client-5.2.3 jupyter-console-5.2.0 jupyter-core-4.4.0 mistune-0.8.3 nbconvert-5.3.1 nbformat-4.4.0 notebook-5.5.0 pandocfilters-1.4.2 parso-0.2.0 pexpect-4.5.0 pickleshare-0.7.4 prompt-toolkit-1.0.15 ptyprocess-0.5.2 pygments-2.2.0 python-dateutil-2.7.3 pyzmq-17.0.0 qtconsole-4.3.1 simplegeneric-0.8.1 six-1.11.0 terminado-0.8.1 testpath-0.3.1 tornado-5.0.2

With that, Jupyter Notebook has been installed onto your server. Next, we will go over how to run the application.

## Step 2 — Running the Jupyter Notebook

Jupyter Notebook must be run from your VPS so that you can connect to it from your local machine using an SSH Tunnel and your favorite web browser.

To run the Jupyter Notebook server, enter the following command:

    jupyter notebook

After running this command, you will see output similar to the following:

    Output[I 19:46:22.031 NotebookApp] Writing notebook server cookie secret to /home/sammy/.local/share/jupyter/runtime/notebook_cookie_secret
    [I 19:46:22.365 NotebookApp] Serving notebooks from local directory: /home/sammy/environments
    [I 19:46:22.365 NotebookApp] 0 active kernels
    [I 19:46:22.366 NotebookApp] The Jupyter Notebook is running at:
    [I 19:46:22.366 NotebookApp] http://localhost:8888/?token=Example_Jupyter_Token_3cadb8b8b7005d9a46ca4d6675
    [I 19:46:22.366 NotebookApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
    [W 19:46:22.366 NotebookApp] No web browser found: could not locate runnable browser.
    [C 19:46:22.367 NotebookApp]
    
        Copy/paste this URL into your browser when you connect for the first time,
        to login with a token:
            http://localhost:8888/?token=Example_Jupyter_Token_3cadb8b8b7005d9a46ca4d6675&tokenExample_Jupyter_Token_3cadb8b8b7005d9a46ca4d6675

You might notice in the output that there is a `No web browser found` warning. This is to be expected, since the application is running on a server and you likely haven’t installed a web browser onto it. This guide will go over how to connect to the Notebook on the server using SSH tunneling in the next section.

For now, exit the Jupyter Notebook by pressing `CTRL+C` followed by `y`, and then pressing `ENTER` to confirm:

    OutputShutdown this notebook server (y/[n])? y
    [C 20:05:47.654 NotebookApp] Shutdown confirmed
    [I 20:05:47.654 NotebookApp] Shutting down 0 kernels

Then log out of the server by using the `exit` command:

    exit

You’ve just run Jupyter Notebook on your server. However, in order to access the application and start working with notebooks, you’ll need to connect to the application using SSH tunneling and a web browser on your local computer.

## Step 3 — Connecting to the Jupyter Notebook Application with SSH Tunneling

_SSH tunneling_ is a simple and fast way to connect to the Jupyter Notebook application running on your server. Secure shell (more commonly known as [SSH](ssh-essentials-working-with-ssh-servers-clients-and-keys)) is a network protocol which enables you to connect to a remote server securely over an unsecured network.

The SSH protocol includes a port forwarding mechanism that allows you to tunnel certain applications running on a specific port number on a server to a specific port number on your local computer. We will learn how to securely “forward” the Jupyter Notebook application running on your server (on port `8888`, by default) to a port on your local computer.

The method you use for establishing an SSH tunnel will depend on your local computer’s operating system. Jump to the subsection below that is most relevant for your machine.

**Note:** It’s possible to set up and install the Jupyter Notebook using the DigitalOcean Web Console, but connecting to the application via an SSH tunnel must be done through the terminal or with PuTTY.

### SSH Tunneling using macOS or Linux

If your local computer is running Linux or macOS, it’s possible to establish an SSH tunnel just by running a single command.

`ssh` is the standard command to open an SSH connection, but when used with the `-L` directive, you can specify that a given port on the local host (that is, your local machine) will be forwarded to a given host and port on the remote host (in this case, your server). This means that whatever is running on the specified port on the remote server (`8888`, Jupyter Notebook’s default port) will appear on the specified port on your local computer (`8000` in the example command).

To establish your own SSH tunnel, run the following command. Feel free to change port `8000` to one of your choosing if, for example, `8000` is in use by another process. It is recommended that you use a port greater than or equal to `8000`, as those port numbers are unlikely to be used by another process. Be sure to include your own server’s IP address and the name of your server’s non-root user:

    ssh -L 8000:localhost:8888 sammy@your_server_ip

If there are no errors from this command, it will log you into your remote server. From there, activate the virtual environment:

    source ~/environments/my_env/bin/activate

Then run the Jupyter Notebook application:

    jupyter notebook

To connect to Jupyter Notebook, use your favorite web browser to navigate to the local port on the local host: `http://localhost:8000`. Now that you’re connected to Jupyter Notebook, continue on to Step 4 to learn how to use it.

### SSH Tunneling using Windows and PuTTY

PuTTY is an open-source SSH client for Windows which can be used to [connect to your server](how-to-use-ssh-keys-with-putty-on-digitalocean-droplets-windows-users). After downloading and installing PuTTY on your Windows machine (as described in the prerequisite tutorial), open the program and enter your server URL or IP address, as shown here:

![Enter server URL or IP into Putty](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jupyter_notebook/JN_putty_1.png)

Next, click **+ SSH** at the bottom of the left pane, and then click **Tunnels**. In this window, enter the port that you want to use to access Jupyter on your local machine (`8000` ). It is recommended to use a port greater or equal to `8000` as those port numbers are unlikely to be used by another process. If `8000` is used by another process, though, select a different, unused port number. Next, set the destination as `localhost:8888`, since port `8888` is the one that Jupyter Notebook is running on. Then click the **Add** button and the ports should appear in the **Forwarded ports** field:

![Configure SSH tunnel in Putty](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jupyter_notebook/JN_putty_2.png)

Finally, click the **Open** button. This will both connect your machine to the server via SSH and tunnel the desired ports. If no errors show up, go ahead and activate your virtual environment:

    source ~/environments/my_env/bin/activate

Then run Jupyter Notebook:

    jupyter notebook

Next, navigate to the local port in your favorite web browser, for example `http://localhost:8000` (or whatever port number you chose), to connect to the Jupyter Notebook instance running on the server. Now that you’re connected to Jupyter Notebook, continue on to Step 4 to learn how to use it.

## Step 4 — Using Jupyter Notebook

When accessed through a web browser, Jupyter Notebook provides a Notebook Dashboard which acts as a file browser and gives you an interface for creating, editing and exploring notebooks. Think of these notebooks as documents (saved with a `.ipynb` file extension) which you populate with any number of individual cells. Each cell holds an interactive text editor which can be used to run code or write rendered text. Additionally, notebooks allow you to write and run equations, include other rich media, such as images or interactive plots, and they can be exported and shared in various formats (`.ipyb`, `.pdf`, `.py`). To illustrate some of these functions, we’ll create a notebook file from the Notebook Dashboard, write a simple text board with an equation, and run some basic Python 3 code.

By this point you should have connected to the server using an SSH tunnel and started the Jupyter Notebook application from your server. After navigating to `http://localhost:8000`, you will be presented with a login page:

![Jupyter Notebook login screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jupyter_notebook/JN_login_screen_small.png)

In the **Password or token** field at the top, enter the token shown in the output after you ran `jupyter notebook` from your server:

    Output[I 20:35:17.004 NotebookApp] Writing notebook server cookie secret to /run/user/1000/jupyter/notebook_cookie_secret
    [I 20:35:17.314 NotebookApp] Serving notebooks from local directory: /home/sammy
    [I 20:35:17.314 NotebookApp] 0 active kernels
    [I 20:35:17.315 NotebookApp] The Jupyter Notebook is running at:
    [I 20:35:17.315 NotebookApp] http://localhost:8888/?token=Example_Jupyter_Token_3cadb8b8b7005d9a46ca4d6675
    [I 20:35:17.315 NotebookApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
    [W 20:35:17.315 NotebookApp] No web browser found: could not locate runnable browser.
    [C 20:35:17.316 NotebookApp]
    . . .

Alternatively, you can copy that URL from your terminal output and paste it into your browser’s address bar.

Automatically, Jupyter notebook will show all of the files and folders stored in the directory from which it’s run. Create a new notebook file by clicking **New** then **Python 3** at the top-right of the Notebook Dashboard:

![Create a new Python3 notebook](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jupyter_notebook/JN_new_python3.png)

Within this new notebook, change the first cell to accept markdown syntax by clicking **Cell** \> **Cell Type** \> **Markdown** on the navigation bar at the top. In addition to markdown, this Cell Type also allows you to write equations in LaTeX. For example, type the following into the cell after changing it to markdown:

    # Simple Equation
    
    Let us now implement the following equation in Python:
    $$ y = x^2$$
    
    where $x = 2$

To turn the markdown into rich text, press `CTRL + ENTER` and the following should be the result:

![Turn sample equation into rich text](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jupyter_notebook/JN_sample_equation.png)

You can use the markdown cells to make notes and document your code.

Now, let’s implement a simple equation and print the result. Click **Insert** \> **Insert Cell Below** to insert a cell. In this new cell, enter the following code:

    x = 2
    y = x*x
    print(y)

To run the code, press `CTRL + ENTER`, and the following will be the result:

![Solve sample equation](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jupyter_notebook/JN_sample_equation2.png)

These are some relatively simple examples of what you can do with Jupyter Notebook. However, it is a very powerful application with many potential use cases. From here, you can add some Python libraries and use the notebook as you would with any other Python development environment.

## Conclusion

You should be now able to write reproducible Python code and text using the Jupyter Notebook running on a remote server. To get a quick tour of Jupyter Notebook, click **Help** in the top navigation bar and select **User Interface Tour** as shown here:

![Finding Jupyter Notebook help tour](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jupyter_notebook/JN_help_tour.png)

If you’re interested, we encourage you to learn more about Jupyter Notebook by going through the [Project Jupyter documentation](http://jupyter.org/documentation). Additionally, you can build on what you learned in this tutorial by [learning how to code in Python 3](https://www.digitalocean.com/community/tutorial_series/how-to-code-in-python-3).
