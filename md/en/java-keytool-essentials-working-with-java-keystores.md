---
author: Mitchell Anicas
date: 2014-10-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/java-keytool-essentials-working-with-java-keystores
---

# Java Keytool Essentials: Working with Java Keystores

## Introduction

Java Keytool is a key and certificate management tool that is used to manipulate Java Keystores, and is included with Java. A Java Keystore is a container for authorization certificates or public key certificates, and is often used by Java-based applications for encryption, authentication, and serving over HTTPS. Its entries are protected by a keystore password. A keystore entry is identified by an _alias_, and it consists of keys and certificates that form a trust chain.

This cheat sheet-style guide provides a quick reference to `keytool` commands that are commonly useful when working with Java Keystores. This includes creating and modifying Java Keystores so they can be used with your Java applications.

**How to Use This Guide:**

- If you are not familiar with certificate signing requests (CSRs), read the CSR section of our [OpenSSL cheat sheet](openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs/)
- This guide is in a simple, cheat sheet format–self-contained command line snippets
- Jump to any section that is relevant to the task you are trying to complete (Hint: use the _Contents_ menu on the bottom-left or your browser’s _Find_ function)
- Most of the commands are one-liners that have been expanded to multiple lines (using the `\` symbol) for clarity

## Creating and Importing Keystore Entries

This section covers Java Keytool commands that are related to generating key pairs and certificates, and importing certificates.

### Generate Keys in New/Existing Keystore

Use this method if you want to use HTTP (HTTP over TLS) to secure your Java application. This will create a new key pair in a new or existing Java Keystore, which can be used to create a CSR, and obtain an SSL certificate from a Certificate Authority.

This command generates a 2048-bit RSA key pair, under the specified alias (`domain`), in the specified keystore file (`keystore.jks`):

    keytool -genkeypair \
            -alias domain \
            -keyalg RSA \
            -keystore keystore.jks

If the specified keystore does not already exist, it will be created after the requested information is supplied. This will prompt for the keystore password (new or existing), followed by a Distinguished Name prompt (for the private key), then the desired private key password.

### Generate CSR For Existing Private Key

Use this method if you want to generate an CSR that you can send to a CA to request the issuance of a CA-signed SSL certificate. It requires that the keystore and alias already exist; you can use the previous command to ensure this.

This command creates a CSR (`domain.csr`) signed by the private key identified by the alias (`domain`) in the (`keystore.jks`) keystore:

    keytool -certreq \
            -alias domain \
            -file domain.csr \
            -keystore keystore.jks

After entering the keystore’s password, the CSR will be generated.

### Import Signed/Root/Intermediate Certificate

Use this method if you want to import a signed certificate, e.g. a certificate signed by a CA, into your keystore; it must match the private key that exists in the specified alias. You may also use this same command to import _root_ or _intermediate_ certificates that your CA may require to complete a chain of trust. Simply specify a unique alias, such as `root` instead of `domain`, and the certificate that you want to import.

This command imports the certificate (`domain.crt`) into the keystore (`keystore.jks`), under the specified alias (`domain`). If you are importing a signed certificate, it must correspond to the private key in the specified alias:

    keytool -importcert \
            -trustcacerts -file domain.crt \
            -alias domain \
            -keystore keystore.jks

You will be prompted for the keystore password, then for a confirmation of the import action.

**Note:** You may also use the command to import a CA’s certificates into your Java truststore, which is typically located in `$JAVA_HOME/jre/lib/security/cacerts` assuming `$JAVA_HOME` is where your JRE or JDK is installed.

### Generate Self-Signed Certificate in New/Existing Keystore

Use this command if you want to generate a self-signed certificate for your Java applications. This is actually the same command that is used to create a new key pair, but with the validity lifetime specified in days.

This command generates a 2048-bit RSA key pair, valid for `365` days, under the specified alias (`domain`), in the specified keystore file (`keystore.jks`):

    keytool -genkey \
            -alias domain \
            -keyalg RSA \
            -validity 365 \
            -keystore keystore.jks

If the specified keystore does not already exist, it will be created after the requested information is supplied. This will prompt for the keystore password (new or existing), followed by a Distinguished Name prompt (for the private key), then the desired private key password.

## Viewing Keystore Entries

This section covers listing the contents of a Java Keystore, such as viewing certificate information or exporting certificates.

### List Keystore Certificate Fingerprints

This command lists the SHA fingerprints of all of the certificates in the keystore (`keystore.jks`), under their respective aliases:

    keytool -list \
            -keystore keystore.jks

You will be prompted for the keystore’s password. You may also restrict the output to a specific alias by using the `-alias domain` option, where “domain” is the alias name.

### List Verbose Keystore Contents

This command lists verbose information about the entries a keystore (`keystore.jks`) contains, including certificate chain length, fingerprint of certificates in the chain, distinguished names, serial number, and creation/expiration date, under their respective aliases:

    keytool -list -v \
            -keystore keystore.jks

You will be prompted for the keystore’s password. You may also restrict the output to a specific alias by using the `-alias domain` option, where “domain” is the alias name.

**Note:** You may also use this command to view which certificates are in your Java truststore, which is typically located in `$JAVA_HOME/jre/lib/security/cacerts` assuming `$JAVA_HOME` is where your JRE or JDK is installed.

### Use Keytool to View Certificate Information

This command prints verbose information about a certificate file (`certificate.crt`), including its fingerprints, distinguished name of owner and issuer, and the time period of its validity:

    keytool -printcert \
            -file domain.crt

You will be prompted for the keystore password.

### Export Certificate

This command exports a binary DER-encoded certificate (`domain.der`), that is associated with the alias (`domain`), in the keystore (`keystore.jks`):

    keytool -exportcert
            -alias domain
            -file domain.der
            -keystore keystore.jks

You will be prompted for the keystore password. If you want to convert the DER-encoded certificate to PEM-encoding, follow our [OpenSSL cheat sheet](openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs#convert-certificate-formats).

## Modifying Keystore

This section covers the modification of Java Keystore entries, such as deleting or renaming aliases.

### Change Keystore Password

This command is used to change the password of a keystore (`keystore.jks`):

    keytool -storepasswd \
            -keystore keystore.jks

You will be prompted for the current password, then the new password. You may also specify the new password in the command by using the `-new newpass` option, where “newpass” is the password.

### Delete Alias

This command is used to delete an alias (`domain`) in a keystore (`keystore.jks`):

    keytool -delete \
            -alias domain \
            -keystore keystore.jks

You will be prompted for the keystore password.

### Rename Alias

This command will rename the alias (`domain`) to the destination alias (`newdomain`) in the keystore (`keystore.jks`):

    keytool -changealias \
            -alias domain \
            -destalias newdomain \
            -keystore keystore.jks

You will be prompted for the keystore password.

## Conclusion

That should cover how most people use Java Keytool to manipulate their Java Keystores. It has many other uses that were not covered here, so feel free to ask or suggest other uses in the comments.

This tutorial is based on the version of keystore that ships with Java 1.7.0 update 65. For help installing Java on Ubuntu, follow [this guide](how-to-install-java-on-ubuntu-with-apt-get).
