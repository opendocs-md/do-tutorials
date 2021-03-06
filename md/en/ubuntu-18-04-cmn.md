---
author: Justin Ellingwood
date: 2018-11-08
language: zh
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/ubuntu-18-04-cmn
---

# Ubuntu 18.04 服务器初始设置

### 简介

首次新建 Ubuntu 18.04 服务器时，您应该在基本设置过程早期完成一些配置步骤。 这样将会增加服务器的安全性和可用性，并为后续操作打下坚实基础。

**注** ：以下指南展示如何手动完成有关新 Ubuntu 18.04 服务器的建议步骤。 通过手动执行此程序，可有助于学习一些基本的系统管理技能，并当作练习以全面了解要在服务器上执行的操作。 另外，如果您希望更快速地完成设置，您也可以[运行我们的初始服务器设置脚本](automating-initial-server-setup-with-ubuntu-18-04)，该脚本会自动执行这些步骤。

## 步骤 1 — 作为 Root 登录

要登录您的服务器，您将需要知道 **服务器的公共 IP 地址** 。 您还需要密码，或者如果您安装了用于身份验证的 SSH 密钥，则需要 **root** 用户帐户的私钥。 如果您尚未登录过自己的服务器，您可能需要遵循有关[如何使用 SSH 连接到 Droplet](how-to-connect-to-your-droplet-with-ssh) 的指南，其中详细说明了这一过程。

如果您尚未连接到自己的服务器，则使用以下命令（使用服务器的公共 IP 地址替代该命令的突出显示部分）作为 **root** 用户登录：

    ssh root@your_server_ip

接受有关主机验证的警告（如显示）。 如果您使用密码验证，则提供您的 **root** 密码以便登录。 如果您使用受密码保护的 SSH 密钥，则在每次会话中首次使用该密钥时，系统可能提示您输入密码。 如果这是您第一次使用密码登录服务器，系统也可能提示您更改 **root** 密码。

### 关于 Root

**root** 用户是指 Linux 环境中拥有非常广泛权限的管理用户。 由于 **root** 帐户拥有增强的权限，因此_不建议_您经常使用此帐户。 这是因为 **root** 帐户固有的部分权限能够进行非常具有破坏性的更改，即便是意外操作。

下一步是设置一个影响范围较小的替代用户帐户，以用于日常工作。 我们将教您如何在需要时获得增强的权限。

## 步骤 2 — 新建用户

一旦作为 **root** 用户登录，我们就已准备好添加将在日后用于登录的新用户帐户。

下例创建了一个名为 **sammy** 的新用户，但您可以使用自己喜欢的用户名将其替换：

    adduser sammy

您将需要回答几个问题，首先会从帐户密码开始。

输入一个强密码，或者如果您愿意，可以填入任何附加信息。 这不是必需操作，对于您希望跳过的任何字段，直接点击 `ENTER` 即可。

## 步骤 3 — 授予管理权限

现在，我们拥有一个具备普通帐户权限的新用户帐户。 但是，我们有时可能需要执行管理任务。

为避免注销我们的普通用户，然后再用 **root** 帐户登录，我们可以为普通帐户设置所谓的“超级用户”或 **root** 权限。 这样，通过在各个命令前面添加 `sudo`，我们的普通帐户就可以使用管理权限来运行命令。

要向新用户添加这些权限，我们需要将新用户添加至 **sudo** 群组。默认情况下，在 Ubuntu 18.04 上允许属于 **sudo** 群组的用户使用 `sudo` 命令。

作为 **root** 用户运行此命令，以将新用户添加至 **sudo** 群组（使用新用户替代突出显示的词）：

    usermod -aG sudo sammy

现在，作为普通用户登录后，您可以在命令前面输入 `sudo`，以使用超级用户权限来执行操作。

## 步骤 4 — 设置基本防火墙

Ubuntu 18.04 服务器可以使用 UFW 防火墙来确保仅允许连接至特定服务。 通过此应用程序，我们可以非常便捷地设置基本防火墙。

**注** ：如果服务器是在 DigitalOcean 上运行，您可以选择使用 [DigitalOcean 云防火墙](an-introduction-to-digitalocean-cloud-firewalls) 来替代 UFW 防火墙。 我们建议一次只使用一个防火墙，以免发生难以调试的冲突规则。

安装后，不同应用程序可以在 UFW 上注册各自的配置文件。 通过这些配置文件，UFW 可以按名称管理这些应用程序。 OpenSSH 是允许我们现在连接到服务器的服务，它在 UFW 上注册了一个配置文件。

您可以通过输入下列信息来查看此服务：

    ufw app list

    OutputAvailable applications:
      OpenSSH

我们需要确保防火墙允许 SSH 连接，以便我们可以在下次再次登录。 我们可以通过输入下列信息来允许此类连接：

    ufw allow OpenSSH

然后，我们可以通过输入下列信息来启用防火墙：

    ufw enable

输入 “`y`"，并按 `ENTER` 以继续操作。 您可以通过输入下列信息来了解仍允许 SSH 连接：

    ufw status

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)

由于 **防火墙当前阻止除 SSH 以外的所有连接** ，因此如果您安装并配置附加服务，您将需要调整防火墙设置，以允许可接受的接入。 您可以在[本指南](ufw-essentials-common-firewall-rules-and-commands) 中学习一些常用 UFW 操作。

## 步骤 5 — 为普通用户启用外部访问

现在，我们拥有一个日常使用的普通用户，我们需要确保可以直接 SSH 到该帐户。

**注：** 在验证您可以使用新用户登录并使用 `sudo` 之前，我们建议仍作为 **root** 登录。 这样，当您遇到问题时，您就可以作为 **root** 用户解决问题并进行任何必要的更改。 如果您使用 DigitalOcean Droplet，并遇到 **root** SSH 连接问题，您可以[使用 DigitalOcean Console 登录至 Droplet](how-to-use-the-digitalocean-console-to-access-your-droplet)。

新用户的 SSH 访问配置过程取决于服务器的 **root** 帐户是使用密码验证，还是使用 SSH 密钥验证。

### 如果 Root 帐户使用密码验证

如果您_使用密码_登录 **root** 帐户，则会启用 SSH 的密码验证。 通过使用新用户名打开一个新终端会话并使用 SSH，您可以 SSH 到您的新用户帐户：

    ssh sammy@your_server_ip

输入您的普通用户密码后，您即会登录。 请记住，如果您需要以管理权限来运行命令，则在命令前面输入 `sudo`，如下所示：

    sudo command_to_run

在每次会话中首次使用 `sudo` 时（及之后定期使用），系统会提示您输入普通用户密码。

为提高服务器的安全性， **我们强烈建议设置 SSH 密钥，而不是使用密码验证** 。 请遵循有关[在 Ubuntu 18.04 上设置 SSH 密钥](how-to-set-up-ssh-keys-on-ubuntu-1804) 的指南，以学习如何配置基于密钥的身份验证。

### 如果 Root 帐户使用 SSH 密钥验证

如果您_使用 SSH 密钥_登录至您的 **root** 帐户，则会_禁用_ SSH 的密码验证。 您需要将本地公钥副本添加至新用户的 `~/.ssh/authorized_keys` 文件，以便成功登录。

由于您的公钥已经位于服务器上 **root** 帐户的 `~/.ssh/authorized_keys` 文件中，因此我们可以将该文件和目录结构复制到现有会话中的新用户帐户。

要复制含有正确所有权和权限的文件，最简单的方式是使用 `rsync` 命令。 这样将会复制 **root** 用户的 `.ssh` 目录，保留权限并修改文件所有者；所有这些操作只需一个命令即可。 确保更改下列命令的突出显示部分，以便与您的普通用户名匹配：

**注** ：根据来源和目标的结尾带或不带斜杠，`rsync` 命令所采用的处理方式会有所不同。 使用下面的 `rsync` 时，确保源目录 (`~/.ssh`) **不** 包括结尾斜杠（检查并确保您未使用 `~/.ssh/`）。

如果您意外向该命令添加了结尾斜杠，`rsync` 会将 **root** 帐户 `~/.ssh` 目录的_内容_复制到 `sudo` 用户的主目录，而不会复制整个 `~/.ssh` 目录结构。 文件将位于错误的位置，并且 SSH 将不能找到并使用它们。

    rsync --archive --chown=sammy:sammy ~/.ssh /home/sammy

现在，打开一个新终端会话，并通过新用户名使用 SSH：

    ssh sammy@your_server_ip

您应当登录至新用户帐户，无需使用密码。 请记住，如果您需要以管理权限来运行命令，则在命令前面输入 `sudo`，如下所示：

    sudo command_to_run

在每次会话中首次使用 `sudo` 时（及之后定期使用），系统会提示您输入普通用户密码。

## 接下来如何操作？

此时，您已为服务器打下坚实基础。接下来，您可以在服务器上安装所需要的任何软件。
