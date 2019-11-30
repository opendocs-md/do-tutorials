---
author: Justin Ellingwood
date: 2014-07-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-oauth-authentication-with-digitalocean-as-a-user-or-developer
---

# How To Use OAuth Authentication with DigitalOcean as a User or Developer

## Introduction

Version 2 of the DigitalOcean API includes many changes that improve the experience for everybody. One of the most important new features is OAuth authentication for users and applications.

The OAuth system allows you to authenticate with your account using the API. This access can be granted in the form of personal access tokens for straight-forward use cases, but it also allows flexibility in allowing applications to access your account.

In this guide, we will discuss how grant or revoke an application’s ability to access to your account. We will also discuss the other side of the interaction by walking through how to register applications that leverage the API with DigitalOcean. This will allow you to use OAuth to request access to your users’ accounts.

## Authorizing Applications to Use Your Account as a User

If you are simply interested in giving applications access to your account, you will be able to grant authorization through the application and revoke access through the DigitalOcean control panel.

When using an application that utilizes DigitalOcean’s OAuth authentication, you will be redirected to a page to choose whether you would like to grant the application access to your DigitalOcean account.

The page will look like this:

![DigitalOcean app auth request](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/apps_and_api/auth_request.png)

The request will define whether the application is requesting read-only access, or read & write access. If you decide to grant the requested access, you will be returned to the application, which will now authenticate to operate on your account.

If you wish to revoke access, simply go to your DigitalOcean account and click on the “[Apps & API](https://cloud.digitalocean.com/settings/applications)” section in the left-hand navigation menu of the control panel:

![DigitalOcean left-hand nav](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/apps_and_api/left_nav.png)

Under the “Authorized Applications” section, you should see an entry for each of the applications you have granted access.

![DigitalOcean authorized app](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/apps_and_api/authorized_app.png)

Click on the “revoke” button to remove the associated application’s access to your account:

![DigitalOcean oauth revoke](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/apps_and_api/revoke_access.png)

The application will no longer have access to your account.

## Using OAuth to Authenticate Users as a Developer

To utilize OAuth as a developer, you need to go through two separate processes. First, you must register your application to gain the credentials necessary to request access. Afterwards, you must develop your application to correctly make requests and handle the responses from both the user’s browser and the DigitalOcean servers.

### Registering Developer Applications with DigitalOcean

If you are a developer needing to authenticate users through OAuth, you first need to register your application through the DigitalOcean control panel.

In the “[Apps & API](https://cloud.digitalocean.com/settings/applications)” section of the control panel, in the middle of the page, you will see a section titled “Developer Applications”:

![DigitalOcean developer applications section](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/apps_and_api/developer_apps_section.png)

To register a new application, click on the “Register new application button” on the right-hand side:

![DigitalOcean register app](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/apps_and_api/register.png)

You will be taken to the registration page.

![DigitalOcean app registration info](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/apps_and_api/app_info.png)

Here, you will need to supply some basic information like your application’s name and homepage, and provide a brief description. Keep in mind that this information will show up on the authorization request page for users.

You will also need to supply a callback URL for the application. This is a location where you will configured your application to handle authorization responses. See the next section, or the OAuth Authentication guide, to learn more about what is necessary to process an OAuth request.

When you submit your details, you will be taken to a page with the information needed to build the authorization application or script that will live at the callback URL you provided. This includes your client ID, your client secret, and a pre-formatted authorization request link to redirect users to:

![DigitalOcean app details](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/apps_and_api/app_details.png)

### Implementing DigitalOcean OAuth in your Application

To implement OAuth authentication, your application must first redirect your users to an endpoint at:

    https://cloud.digitalocean.com/v1/oauth/authorize

This redirect should contain your client ID, the callback URL as the value of `redirect_uri`, and set `response_type=code`. You can optionally set the scope of token that you are requesting (e.g. `scope=read%20write` for full access). An example redirect might look like:

    https://cloud.digitalocean.com/v1/oauth/authorize?client_id=client_id&redirect_uri=callback_URL&response_type=code&scope=read%20write

When the user is redirected to your supplied callback URL after granting access, a code that you need to capture will be included as a query parameter.

Next, send a POST request to:

    https://cloud.digitalocean.com/v1/oauth/token

Include your client ID, client secret, the callback URL as the `redirect_uri` value, the code you received from the user redirect, and set `grant_type=authorization_code`. An example request might look like this:

    https://cloud.digitalocean.com/v1/oauth/token?client_id=client_id&client_secret=client_secret&code=code_from_user_redirect&grant_type=authorization_code&redirect_uri=callback_URL

The entire response will look something like this:

    {"provider"=>:digitalocean, "info"=>{"name"=>"some_name", "email"=>"user@example.com"}, "credentials"=>{"token"=>"$AUTH_TOKEN", "expires_at"=>1405443515, "expires"=>true}, "extra"=>{}}

You can then use the `AUTH_TOKEN` in subsequent requests to take actions on the user’s account.

Most developers will leverage an OAuth library for their language of choice to make this process simpler, but it is always good to have a general idea of what is happening behind the scenes.

## Accepted Scopes

Scopes let you specify the type of access you need. Scopes limit access for OAuth tokens. Here is the list of scopes accepted by the DigitalOcean OAuth endpoint:

| Name | Description |
| --- | --- |
| (no scope) | Defaults to _read_ scope. |
| read | Grants read-only access to user account. This allows actions that can be requested using the GET and HEAD methods. |
| read write | Grants read/write access to user account, i.e. full access. This allows actions that can be requested using the DELETE, PUT, and POST methods, in addition to the actions allowed by the _read_ scope. |

## Developer Resources

### omniauth-digitalocean Gem

Since DigitalOcean uses Ruby internally, we are providing an open source OAuth strategy for the community to use. The [omniauth-digitalocean](https://github.com/digitaloceancloud/omniauth-digitalocean) gem is on Github and published to RubyGems. It’s based on [OmniAuth](https://github.com/intridea/omniauth), the widely used Rack-based library for multi-provider authentication, and is an easy way to integrate “sign in with DigitalOcean" into Rails and Rack frameworks.

## Conclusion

OAuth is a well established way of granting applications access to your account or requesting account access from users. The DigitalOcean “Apps & API” page strives to make this process as straight-forward as possible for both parties.

For a technical overview of DigitalOcean’s OAuth API, click here: [DigitalOcean OAuth Overview](https://developers.digitalocean.com/oauth/).

To learn more about how OAuth works, check out our community article: [An Introduction to OAuth 2](an-introduction-to-oauth-2).
