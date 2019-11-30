---
author: ABCOM
date: 2018-08-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-generate-short-unique-digital-address-any-location-angularjs-php
---

# How to Generate a Short and Unique Digital Address for Any Location Using AngularJS and PHP

## Introduction

Postal addresses are usually lengthy and sometimes difficult to remember. There are a number of scenarios where a shorter address would be desirable. For example, having the ability to send a short address consisting of only a couple of characters could ensure faster delivery of emergency ambulance services. Pieter Geelen and Harold Goddijn developed the [Mapcode system](http://www.mapcode.com/) in 2001 to make it easy to create a short-form address for any physical address in the world.

In this tutorial, you will develop a web app that uses the Google Maps API to generate a short digital address for any address of your choice. You will do this by cloning the base code for this app from GitHub and then adding code to it that will make it fully functional. This app will also be able to retrieve the original physical address from a given mapcode.

## Prerequisites

In order to complete this tutorial, you will need the following:

- Access to an Ubuntu 18.04 server. This server should have a non- **root** user with `sudo` privileges and a firewall configured. To set this up, you can follow our [Initial Server Setup Guide for Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04).

- A LAMP stack installed on your machine. This is necessary because the application that you are going to develop in this tutorial uses AngularJS and PHP, and the digital address that the application generates will be stored in a MySQL database. Follow our guide on [How To Install Linux, Apache, MySQL, PHP (LAMP) stack on Ubuntu 18.04](how-to-install-linux-apache-mysql-php-lamp-stack-ubuntu-18-04) to set this up.

- Git installed on your server. You can follow the tutorial [Contributing to Open Source: Getting Started with Git](contributing-to-open-source-getting-started-with-git) to install and set up Git.

## Step 1 — Getting a Google API Key

In this tutorial, you will use JavaScript to create an interface to Google Maps. Google assigns API keys to enable developers to use the JavaScript API on Google Maps, which you will need to obtain and add to your web app’s code.

To get your own API key, head to Google’s [“Get API Key” page](https://developers.google.com/maps/documentation/javascript/get-api-key). Click on the **GET STARTED** button in Step 1, and a pop-up will open as shown in the following image:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/mapcode/googlemapsapi1.png)

Select **Maps** by clicking the check box and hit **CONTINUE**. If you aren’t already logged into a Google account, you will be asked to do so. Then, the window will ask you to provide a name for the project, which can be anything you’d like:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/mapcode/googlemapsapi2.png)

Following this, it will ask you to enter your billing information. Note that Google provides API keys as part of a free trial, but it requires you to set up and enable billing in order retrieve them.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/mapcode/googlemapsapi3.png)

After entering this information, your API key will appear on the screen. Copy and store it in a location where you can easily retrieve it, as you will need to add it to your project code later on.

After obtaining your API key, you can begin building the foundation of your application by creating a MySQL database.

## Step 2 — Creating the Database

The web application described in this tutorial accepts an address from the user and generates a mapcode for it along with the latitude and longitude of the specified location. You will store this data in a MySQL database so that you can retrieve it later on just by entering the respective digital address.

Begin by opening the MySQL shell and authenticating with your password:

    mysql -u root -p

At the prompt, create a database called `digitaladdress` using the following command:

    CREATE DATABASE IF NOT EXISTS `digitaladdress`;

Next, select this new database so that you can create a table within it:

    USE `digitaladdress`;

After selecting the `digitaladdress` database, create a table called `locations` within it to store the physical address, its longitude, latitude, and the mapcode that your application will create from this data. Run the following `CREATE TABLE` statement to create the `locations` table within the database:

    CREATE TABLE `locations` (
      `digitaladdress` varchar(50) DEFAULT NULL,
      `state` varchar(30) DEFAULT NULL,
      `zip` varchar(30) DEFAULT NULL,
      `street` varchar(30) DEFAULT NULL,
      `town` varchar(30) DEFAULT NULL,
      `house` varchar(30) DEFAULT NULL,
      `latitude` varchar(30) DEFAULT NULL,
      `longitude` varchar(30) DEFAULT NULL,
      KEY `digitaladdress` (`digitaladdress`)
    );

This table has eight columns: `digitaladdress`, `state`, `zip`, `street`, `town`, `house`, `latitude`, and `longitude`. The first column, `digitaladdress`, is _indexed_ using the `KEY` command. Indexes in MySQL function similarly to how they work in an encyclopedia or other reference work. Any time you or your application issue a query containing a `WHERE` statement, MySQL reads every entry in each column, row-by-row, which can become an extremely resource-intensive process as your table accumulates more and more entries. Indexing a column like this takes the data from the column and stores it alphabetically in a separate location, which means that MySQL will not have to look through every row in the table. It only has to find the data you’re looking for in the index and then jump to the corresponding row in the table.

After adding this table, exit the MySQL prompt:

    exit

With your database and table set up and your Google Maps API key in hand, you’re ready to create the project itself.

## Step 3 — Creating the Project

As mentioned in the introduction, we will clone the base code for this project from GitHub and then add some extra code to make the application functional. The reason for this, rather than walking you through the process of creating each file and adding all the code yourself, is to speed up the process of getting the app running. It will also allow us to focus on adding and understanding the code that allows the app to communicate with both the Google Maps and Mapcode APIs.

You can find the skeleton code for the full project on [this GitHub project page](https://github.com/do-community/digiaddress). Use the following `git` command to clone the project to your server:

    git clone https://github.com/do-community/digiaddress.git

This will create a new folder called `digiaddress` in your home directory. Move this directory to your server’s web root. If you followed the LAMP stack tutorial linked in the prerequisites, this will be the `/var/www/html` directory:

    sudo mv digiaddress/ /var/www/html/

This project contains several PHP and JS files to which you’ll add some code later on in this tutorial. To view the directory structure, first install the `tree` package using `apt`:

    sudo apt install tree

Then run the `tree` command with the `digiaddress` directory given as an argument:

    tree /var/www/html/digiaddress/

    Outputdigiaddress/
    ├── README.md
    ├── db.php
    ├── fetchaddress.php
    ├── findaddress.php
    ├── generateDigitalAddress.php
    ├── geoimplement.php
    ├── index.php
    └── js
        ├── createDigitialAddressApp.js
        └── findAddressApp.js

You can see from this output that the project consists of six PHP files and two JavaScript files. Together, these files create the application’s two main functionalities: creating a mapcode from a physical address, and decoding a mapcode to retrieve the original physical address. The following files enable the first functionality:

- `index.php`
- `geoimplement.php`
- `generateDigitialAddress.php`
- `db.php`
- `createDigitialAddressApp.js`

The `index.php` file contains the code for the application’s user interface (UI), which consists of a form where users can enter a physical address. The `index.php` file calls the `geoimplement.php` file any time a user submits the form. `geoimplement.php` makes a call to the Google Maps API and passes the address along to it. The Google server then responds with a JSON containing the specified address’s information, including its latitude and longitude. This information is then passed to the `generateDigitalAddress.php` file which calls the Mapcode API to obtain a mapcode for the given location, as specified by its latitude and longitude. The resulting mapcode, along with the latitude, longitude, and the physical address, are then stored in the database that you created in Step 2. `db.php` acts as a helper for this operation. The `createDigitalAddressApp.js` file performs a number of operations that control the UX elements seen in the app, including setting a marker and boundary rectangle on the Google Maps interface.

The remaining three files enable the second function of the application — that is, retrieving a physical address from a given mapcode:

- `findaddress.php`
- `fetchaddress.php`
- `findAddressApp.js`

The `findaddress.php` file defines the application UI, which is distinct from the one defined in `index.php`. The application accepts a previously-generated mapcode as an input and displays the corresponding physical address stored in the database. Whenever a user submits this form, `findaddress.php` sends a call to `fetchaddress.php` which then retrieves the respective mapcode from the database. The `findAddressApp.js` file contains the helper code for setting a marker and a boundary rectangle on the Google Maps interface.

Test the installation by visiting `http://your_server_ip/digiaddress` in your browser, making sure to change `your_server_ip` to reflect your server’s IP address.

**Note:** If you don’t know your server’s IP address, you can run the following `curl` command. This command will print the page content of `icanhazip.com`, a website that shows the IP address of the machine accessing it:

    curl http://icanhazip.com

Once there, you will see this heading at the top of your browser window:

    Generate Digital Address

This confirms that you have correctly downloaded the project files. With that, let us proceed with the development of the app’s primary function: generating a mapcode.

## Step 4 — Developing the Application’s UI

While the boilerplate code for the application interface is included in the files you downloaded in the previous step, you still need to make a few changes and additions to some of these files to make the application functional and engaging for users. We will get started with updating the code to develop the application’s UI.

Open the `index.php` file using your preferred editor. Here, we’ll use `nano`:

    nano /var/www/html/digiaddress/index.php

Look for the following line of code:

/var/www/html/digiaddress/index.php

    . . .
    <script async defer src="https://maps.googleapis.com/maps/api/js?key=<YOUR KEY>"></script>
    . . .

Replace `<YOUR KEY>` with the Google API key you obtained in Step 1. After adding your API key, the line should look similar to this:

/var/www/html/digiaddress/index.php

    . . .
    <script async defer src="https://maps.googleapis.com/maps/api/js?key=ExampleAPIKeyH2vITfv1eIHbfka9ym634Esw7u"></script>
    . . .

Next, find the following comment in the `index.php` file:

/var/www/html/digiaddress/index.php

    . . .
                <!-- add form code here -->
    . . .

We’ll add a few dozen lines of code below this comment which will create a form where users can enter the address of a physical location which the application will use to generate a mapcode. Under this comment, add the following highlighted code which creates a title called **Enter Address** at the top of the form:

/var/www/html/digiaddress/index.php

    . . .
                <!-- add form code here -->
    
                <div class="form-border spacing-top">
                    <div class="card-header" style="background:#cc0001; color:#ffff">
                        <h5>Enter Address</h5>
                    </div>
                    <div class="extra-padding">
    . . .

Below this, add the following HTML code. This creates a form with five text fields (along with their appropriate labels) where users will input their information:

/var/www/html/digiaddress/index.php

                    . . .
                    <form>
                            <div class="form-group input-group-sm">
                                <label for="state">State</label>
                                <input type="text" class="form-control rounded-0 textbox-border" id="state"
                                       placeholder="" ng-model="address.state"/>
                            </div>
                            <div class="form-group input-group-sm">
                                <label for="zip" class="animated-label">Zip</label>
                                <input type="text" class="form-control rounded-0 textbox-depth textbox-border"
                                       id="zip" ng-model="address.zip" disabled="disabled"/>
                            </div>
                            <div class="form-group input-group-sm">
                                <label for="town">Town</label>
                                <input type="text" class="form-control rounded-0 textbox-border"
                                       id="town" ng-model="address.town" disabled="disabled"/>
                            </div>
                            <div class="form-group input-group-sm">
                                <label for="street">Street</label>
                                <input type="text" class="form-control rounded-0 textbox-border" id="street"
                                       placeholder="" ng-model="address.street" disabled="disabled"/>
                            </div>
                            <div class="form-group input-group-sm">
                                <label for="house">House</label>
                                <input type="text" class="form-control rounded-0 textbox-border" id="house"
                                       placeholder="" ng-model="address.house" disabled="disabled"/>
                            </div>
                     . . .

Below the form code, add the following lines. These create two hidden controls which pass along the latitude and longitude information derived from any address submitted through the form:

/var/www/html/digiaddress/index.php

                                . . .
                                <div class="form-group input-group-sm">
                                    <input type="hidden" ng-model="address.lat"/>
                                </div>
                                <div class="form-group input-group-sm">
                                    <input type="hidden" ng-model="address.long"/>
                                </div>
                                . . .

Lastly, close out this section by adding the following code. This creates a **Generate** button which will allow users to submit the form:

/var/www/html/digiaddress/index.php

                                . . .
                                <button type="submit" disabled="disabled" class="btn btn-color btn-block rounded-0" id="generate"
                                        style="color:#ffff;background-color: #cc0001;">Generate
                                </button>
                        </form>
                    </div>
                </div>
            . . .

After adding these elements, this section of the file should match this:

/var/www/html/digiaddress/index.php

    . . .
                <!-- add form code here -->
    
                <div class="form-border spacing-top">
                    <div class="card-header" style="background:#cc0001; color:#ffff">
                        <h5>Enter Address</h5>
                    </div>
                    <div class="extra-padding">
                        <form>    
                                <div class="form-group input-group-sm">
                                    <label for="state">State</label>
                                    <input type="text" class="form-control rounded-0 textbox-border" id="state"
                                           placeholder="" ng-model="address.state"/>
                                </div>
                                <div class="form-group input-group-sm">
                                    <label for="zip" class="animated-label">Zip</label>
                                    <input type="text" class="form-control rounded-0 textbox-depth textbox-border"
                                           id="zip" ng-model="address.zip" disabled="disabled"/>
                                </div>
                                <div class="form-group input-group-sm">
                                    <label for="town">Town</label>
                                    <input type="text" class="form-control rounded-0 textbox-border "
                                           id="town" ng-model="address.town" disabled="disabled"/>
                                </div>
                                <div class="form-group input-group-sm">
                                    <label for="street">Street</label>
                                    <input type="text" class="form-control rounded-0 textbox-border" id="street"
                                           placeholder="" ng-model="address.street" disabled="disabled"/>
                                </div>
                                <div class="form-group input-group-sm">
                                    <label for="house">House</label>
                                    <input type="text" class="form-control rounded-0 textbox-border" id="house"
                                           placeholder="" ng-model="address.house" disabled="disabled"/>
                                </div>
    
                                <div class="form-group input-group-sm">
                                    <input type="hidden" ng-model="address.lat"/>
                                </div>
                                <div class="form-group input-group-sm">
                                    <input type="hidden" ng-model="address.long"/>
                                </div>
                                <button type="submit" disabled="disabled" class="btn btn-color btn-block rounded-0" id="generate"
                                        style="color:#ffff;background-color: #cc0001;">Generate
                                </button>
                        </form>
                    </div>
                </div>
                <br>
            </div>
    
            <!-- add google map control -->
                        . . .

Save the file by pressing `CTRL+O` then `ENTER`, and then visit the application in your browser again:

    http://your_server_ip/digiaddress

You will see the newly-added form fields and **Generate** button, and the application should look like this:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/mapcode/final_form.png)

At this point, if you enter address information into the form and try clicking the **Generate** button, nothing will happen. We will add the mapcode generation functionality later on, but let’s first focus on making this page more visually engaging by adding a map which users can interact with.

## Step 5 — Adding Google Maps Controls

When maps are displayed on a website through the Google Maps JavaScript API, they contain user interface features that allow visitors to interact with the map they see. These features are known as _controls_. We will continue editing the `index.php` file to add Google Maps controls to this app and, when finished, users will be able to view a map next to the input form, drag it around to view different locations, zoom in and out, and switch between Google’s map, satellite, and street views.

Find the following comment within the `index.php` file:

/var/www/html/digiaddress/index.php

    . . .
    <!-- add google map control -->
    . . .

Add the following highlighted code below this comment:

/var/www/html/digiaddress/index.php

    . . .
            <!-- add google map control -->
    
            <div class="col-sm-8 map-align" ng-init="initMap()">
                <div id="map" class="extra-padding" style="height: 100%;
                margin-bottom: 15px;"></div>
                <label id="geocoordinates" ng-show="latlng" ng-model="lt"></label><br/>
                <label id="geoaddress" ng-show="address" ng-model="padd"></label>
                </div>
            </div>
    . . .

Save the file, then visit the application in your browser again. You will see the following:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/mapcode/final_googlemap.png)

As you can see, we’ve successfully added a map to the application. You can drag the map around to focus on different locations, zoom in and out, and switch between the map, satellite, and street views. Looking back at the code you just added, notice that we’ve also added two label controls that will display the geocoordinates and the physical address that were entered on the form:

/var/www/html/digiaddress/index.php

                . . .
                <label id="geocoordinates" ng-show="latlng" ng-model="lt"></label><br/>
                <label id="geoaddress" ng-show="address" ng-model="padd"></label>
                . . .

Visit the application again in your browser and enter the name of a state in the first field. When you move your text cursor to the next field, the latitude and longitude labels don’t appear, nor does the location shown on the map change to reflect the information you’ve entered. Let’s enable these behaviors.

## Step 6 — Adding Event Listeners

Adding interactive elements to an application can help to keep its users engaged. We will implement a few interactive behaviors in this application through the use of _event listeners_.

An _event_ is any action that takes place on a web page. Events can be something done by a user or by the browser itself. Examples of common events are:

- Clicking an HTML button
- Changing the content of an input field
- Changing the focus from one page element to another

An _event listener_ is a directive that tells a program to take a certain action when a specific event takes place. In AngularJS, event listeners are defined with directives that generally follow this format:

    ng-event_type=expression

In this step, we will add an event listener that helps to process the information entered by users into a mapcode whenever they submit the form. We will also add a couple more event listeners that will make the application more interactive. Specifically, we’ll use these listeners to change the location shown in the application map, place a marker, and draw a rectangle around the location as users enter information into the form. We’ll add these event listeners to `index.php`, so open that file up again if you’ve closed it:

    nano /var/www/html/digiaddress/index.php

Scroll down to the first batch of code we added, and find the block that begins with `<form>`. It will look like this:

/var/www/html/digiaddress/index.php

                    . . .
                        <form>
                                <div class="form-group input-group-sm">
                                    <label for="state">State</label>
                                    <input type="text" class="form-control rounded-0 textbox-border" id="state"
                                           placeholder="" ng-model="address.state"/>
                                </div>
                                <div class="form-group input-group-sm">
                                    <label for="zip" class="animated-label">Zip</label>
                                    <input type="text" class="form-control rounded-0 textbox-depth textbox-border"
                                           id="zip" ng-model="address.zip" disabled="disabled"/>
                                </div>
                                <div class="form-group input-group-sm">
                                    <label for="town">Town</label>
                                    <input type="text" class="form-control rounded-0 textbox-border"
                                           id="town" ng-model="address.town" disabled="disabled"/>
                                </div>
                                <div class="form-group input-group-sm">
                                    <label for="street">Street</label>
                                    <input type="text" class="form-control rounded-0 textbox-border" id="street"
                                           placeholder="" ng-model="address.street" disabled="disabled"/>
                                </div>
                                <div class="form-group input-group-sm">
                                    <label for="house">House</label>
                                    <input type="text" class="form-control rounded-0 textbox-border" id="house"
                                           placeholder="" ng-model="address.house" disabled="disabled"/>
                                </div>
                        </form>
    . . .

To begin, add the following highlighted event listener to the opening `<form>` tag. This code tells the app to call the `processForm` function whenever a user submits information through the form. `processForm` is defined in the `createDigitalAddressApp.js` file, and serves as a helper function that sends the information submitted by users to the appropriate files which then process it into a mapcode. We will take a closer look at this function in Step 7:

/var/www/html/digiaddress/index.php

                    . . .
                        <form ng-submit="processForm()" class="custom-form">
                                <div class="form-group input-group-sm">
                                    <label for="state">State</label>
                                    <input type="text" class="form-control rounded-0 textbox-border" id="state"
                                           placeholder="" ng-model="address.state"
                                </div>
                    . . .

Next, continue editing this block by adding a couple `blur` event listeners. A `blur` event occurs when a given page element loses focus. Add the following highlighted lines to the `form` block’s `input` tags. These lines tell the application to call the `geocodeAddress` function when a user’s focus shifts away from the respective form fields we created in Step 4. Note that you must also delete the slashes and greater-than signs (`/>`) that close out each `input` tag. Failing to do so will prevent the app from registering the `blur` events correctly:

/var/www/html/digiaddress/index.php

                    . . .
                    <form ng-submit="processForm()" class="custom-form">
                                <div class="form-group input-group-sm">
                                    <label for="state">State</label>
                                    <input type="text" class="form-control rounded-0 textbox-border" id="state"
                                           placeholder="" ng-model="address.state"
                                           ng-blur="geocodeAddress(address,'state')" required=""/>
                                </div>
                                <div class="form-group input-group-sm">
                                    <label for="zip" class="animated-label">Zip</label>
                                    <input type="text" class="form-control rounded-0 textbox-depth textbox-border"
                                           id="zip" ng-model="address.zip" disabled="disabled"
                                           ng-blur="geocodeAddress(address,'zip')" required=""/>
                                </div>
                                <div class="form-group input-group-sm">
                                    <label for="town">Town</label>
                                    <input type="text" class="form-control rounded-0 textbox-border"
                                           id="town" ng-model="address.town" disabled="disabled"
                                           ng-blur="geocodeAddress(address,'town')" required=""/>
                                </div>
                                <div class="form-group input-group-sm">
                                    <label for="street">Street</label>
                                    <input type="text" class="form-control rounded-0 textbox-border" id="street"
                                           placeholder="" ng-model="address.street" disabled="disabled"
                                           ng-blur="geocodeAddress(address,'street')" required=""/>
                                </div>
                                <div class="form-group input-group-sm">
                                    <label for="house">House</label>
                                    <input type="text" class="form-control rounded-0 textbox-border" id="house"
                                           placeholder="" ng-model="address.house" disabled="disabled"
                                           ng-blur="geocodeAddress(address,'house')" required=""/>
                                </div>
    . . .

The first of these new lines — `ng-blur="geocodeAddress(address,'state')" required=""/>` — translates to “When the user’s focus shifts away from the ‘state’ field, call the `geocodeAddress` function.” The other new lines also call `geocodeAddress`, albeit when the user’s focus shifts away from their respective fields.

As with the `processForm` function, `geocodeAddress` is declared in the `createDigitalAddressApp.js` file, but there isn’t yet any code in that file that defines it. We will complete this function so that it places a marker and draws a rectangle on the application map after these `blur` events occur to reflect the information entered into the form. We’ll also add some code that takes the address information and processes it into a mapcode.

Save and close the `index.php` file (press `CTRL+X`, `Y`, then `ENTER`) and then open the`createDigitalAddressApp.js` file:

    nano /var/www/html/digiaddress/js/createDigitalAddressApp.js

In this file, find the following line:

/var/www/html/digiaddress/js/createDigitalAddressApp.js

    . . .
    $scope.geocodeAddress = function (address, field) {
    . . .

This line is where we declare the `geocodeAddress` function. A few lines below this, we declare a variable named `fullAddress` which constructs a human-readable mailing address from the information entered by a user into the application’s form fields. This is done through a series of `if` statements:

/var/www/html/digiaddress/js/createDigitalAddressApp.js

    . . .
    var fullAddress = "";
    
        if (address ['house']) {
            angular.element(document.getElementById('generate'))[0].disabled = false;
                fullAddress = address ['house'] + ",";
                    }
        if (address ['town']) {
            angular.element(document.getElementById('street'))[0].disabled = false;
                fullAddress = fullAddress + address ['town'] + ",";
        }
        if (address ['street']) {
            angular.element(document.getElementById('house'))[0].disabled = false;
                fullAddress = fullAddress + address ['street'] + ",";
        }
        if (address ['state']) {
            angular.element(document.getElementById('zip'))[0].disabled = false;
                fullAddress = fullAddress + address ['state'] + " ";
        }
        if (address ['zip']) {
            angular.element(document.getElementById('town'))[0].disabled = false;
                fullAddress = fullAddress + address ['zip'];
        }
    . . .

Directly after these lines is the following comment:

/var/www/html/digiaddress/js/createDigitalAddressApp.js

    . . .
    // add code for locating the address on Google maps
    . . .

Underneath this comment, add the following line which checks whether `fullAddress` is any value other than null:

/var/www/html/digiaddress/js/createDigitalAddressApp.js

                    . . .
                    if (fullAddress !== "") {
                    . . .

Add the following code below this line. This code submits the information entered into the form to the `geoimplement.php` file using the [HTTP _POST_ method](https://en.wikipedia.org/wiki/POST_(HTTP)) if `fullAddress` is not null:

/var/www/html/digiaddress/js/createDigitalAddressApp.js

                        . . .
                        $http({
                            method: 'POST',
                            url: 'geoimplement.php',
                            data: {address: fullAddress},
                            headers: {'Content-Type': 'application/x-www-form-urlencoded'}
    
                        }).then(function successCallback(results) {
                        . . .

Next, add the following line which checks whether the PHP call was returned successfully:

/var/www/html/digiaddress/js/createDigitalAddressApp.js

                            . . .
                            if (results.data !== "false") {
                            . . .

If the PHP call was successfully returned, we’ll be able to process the result. Add the following line, which removes any boundary rectangle that may have been previously drawn on the map by calling the `removeRectangle` function, which is defined at the top of the `createDigitalAddressApp.js` file:

/var/www/html/digiaddress/js/createDigitalAddressApp.js

                                . . .
                                removeRectangle();
                                . . .

Under the `removeRectangle();` line, add the following four lines which will create a marker pointing to the new location on the map control:

/var/www/html/digiaddress/js/createDigitalAddressApp.js

                                . . .
                                new google.maps.Marker({
                                    map: locationMap,
                                    position: results.data.geometry.location
                                });
                                . . .

Then add the following code, which obtains the latitude and longitude information from the result and displays it with the two HTML labels we created in the `index.php` file in Step 5:

/var/www/html/digiaddress/js/createDigitalAddressApp.js

                                . . .
                                lat = results.data.geometry.location.lat;
                                lng = results.data.geometry.location.lng;
    
                                $scope.address.lat = lat;
                                $scope.address.lng = lng;
    
                                geoCoordLabel = angular.element(document.querySelector('#geocoordinates'));
                                geoCoordLabel.html("Geo Coordinate: " + lat + "," + lng);
    
                                geoAddressLabel = angular.element(document.querySelector('#geoaddress'));
                                geoAddressLabel.html("Geo Address: " + fullAddress);
    
                                $scope.latlng = true;
                                . . .

Lastly, below these lines, add the following content. This code creates a viewport which marks a new boundary rectangle on the map:

/var/www/html/digiaddress/js/createDigitalAddressApp.js

                                . . .
                                if (results.data.geometry.viewport) {
    
                                    rectangle = new google.maps.Rectangle({
                                        strokeColor: '#FF0000',
                                        strokeOpacity: 0.8,
                                        strokeWeight: 0.5,
                                        fillColor: '#FF0000',
                                        fillOpacity: 0.35,
                                        map: locationMap,
                                        bounds: {
                                            north: results.data.geometry.viewport.northeast.lat,
                                            south: results.data.geometry.viewport.southwest.lat,
                                            east: results.data.geometry.viewport.northeast.lng,
                                            west: results.data.geometry.viewport.southwest.lng
                                        }
                                    });
    
                                    var googleBounds = new google.maps.LatLngBounds(results.data.geometry.viewport.southwest, results.data.geometry.viewport.northeast);
    
                                    locationMap.setCenter(new google.maps.LatLng(lat, lng));
                                    locationMap.fitBounds(googleBounds);
                                }
                            } else {
                                errorLabel = angular.element(document.querySelector('#lt'));
                                errorLabel.html("Place not found.");
                                $scope.latlng = true;
                                removeRectangle();
                            }
    
                        }, function errorCallback(results) {
                           console.log(results);
                        });
                    }
                    . . .

After adding this content, this section of the file will look like this:

/var/www/html/digiaddress/js/createDigitalAddressApp.js

                    . . .
                    // add code for locating the address on Google maps
                    if (fullAddress !== "") {
                        $http({
                            method: 'POST',
                            url: 'geoimplement.php',
                            data: {address: fullAddress},
                            headers: {'Content-Type': 'application/x-www-form-urlencoded'}
    
                        }).then(function successCallback(results) {
    
                            if (results.data !== "false") {
                                removeRectangle();
    
                                new google.maps.Marker({
                                    map: locationMap,
                                    position: results.data.geometry.location
                                });
    
                                lat = results.data.geometry.location.lat;
                                lng = results.data.geometry.location.lng;
    
                                $scope.address.lat = lat;
                                $scope.address.lng = lng;
    
                                geoCoordLabel = angular.element(document.querySelector('#geocoordinates'));
                                geoCoordLabel.html("Geo Coordinate: " + lat + "," + lng);
    
                                geoAddressLabel = angular.element(document.querySelector('#geoaddress'));
                                geoAddressLabel.html("Geo Address: " + fullAddress);
    
                                $scope.latlng = true;
    
                                if (results.data.geometry.viewport) {
    
                                    rectangle = new google.maps.Rectangle({
                                        strokeColor: '#FF0000',
                                        strokeOpacity: 0.8,
                                        strokeWeight: 0.5,
                                        fillColor: '#FF0000',
                                        fillOpacity: 0.35,
                                        map: locationMap,
                                        bounds: {
                                            north: results.data.geometry.viewport.northeast.lat,
                                            south: results.data.geometry.viewport.southwest.lat,
                                            east: results.data.geometry.viewport.northeast.lng,
                                            west: results.data.geometry.viewport.southwest.lng
                                        }
                                    });
    
                                    var googleBounds = new google.maps.LatLngBounds(results.data.geometry.viewport.southwest, results.data.geometry.viewport.northeast);
    
                                    locationMap.setCenter(new google.maps.LatLng(lat, lng));
                                    locationMap.fitBounds(googleBounds);
                                }
                            } else {
                                errorLabel = angular.element(document.querySelector('#lt'));
                                errorLabel.html("Place not found.");
                                $scope.latlng = true;
                                removeRectangle();
                            }
    
                        }, function errorCallback(results) {
                           console.log(results);
                        });
                    }
                    . . .

Save the file, but keep it open for now. If you were to visit the application in your browser again, you wouldn’t see any new changes to its appearance or behavior. Likewise, if you were to enter an address and click on the **Generate** button, the application still would not generate or display a mapcode. This is because we must still edit a few files before the mapcode functionality will work. Let’s continue to make these changes, and also take a closer look at how these mapcodes are generated.

## Step 7 — Understanding Mapcode Generation

While still looking at the `createDigitalAddressApp.js` file, scroll past the section of code that you added in the previous step to find the code that takes the information submitted through the form and process it into a unique mapcode. Whenever a user clicks the **Generate** button, the code within the `index.php` file submits the form and calls the `processForm` function, which is defined here in `createDigitalAddressApp.js`:

/var/www/html/digiaddress/js/createDigitalAddressApp.js

    . . .
    $scope.processForm = function () {
    . . .

`processForm` then makes an HTTP POST to the `generateDigitalAddress.php` file:

/var/www/html/digiaddress/js/createDigitalAddressApp.js

    . . .
    $http({
        method: 'POST',
        url: 'generateDigitalAddress.php',
        data: $scope.address,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'}
    }).then(function (response) {
    . . .

The [Stichting Mapcode Foundation](http://www.mapcode.com/aboutus.html) provides the API that generates mapcodes from physical addresses as a free web service. To understand how this call to the Mapcode web service works, close `createDigitalAddressApp.js` and open the `generateDigitialAddress.php` file:

    nano /var/www/html/digiaddress/generateDigitalAddress.php

At the top of the file, you’ll see the following:

/var/www/html/digiaddress/generateDigitalAddress.php

    <?php
    include("db.php");
    . . .

The line reading `include("db.php");` tells PHP to _include_ all the text, code, and markup from the `db.php` file within the `generateDigitalAddress.php` file. `db.php` holds the login credentials for the MySQL database you created in Step 2, and by including it within `generateDigitalAddress.php`, we can add any address information submitted through the form to the database.

Below this `include` statement are a few more lines that obtain the latitude and longitude information based on the request submitted by `createDigitalAddressApp.js`:

/var/www/html/digiaddress/generateDigitalAddress.php

    . . .
    $data = json_decode(file_get_contents("php://input"));
    $lat = $data->lat;
    $long = $data->lng;
    . . .

Look for the following comment in `generateDigitalAddress.php` file.

/var/www/html/digiaddress/generateDigitalAddress.php

    . . .
    // call to mapcode web service
    . . .

Add the following line of code below this comment. This code makes a call the Mapcode API, sending `lat` and `long` as parameters.

/var/www/html/digiaddress/generateDigitalAddress.php

    . . .
    // call to mapcode web service
    $digitaldata = file_get_contents("https://api.mapcode.com/mapcode/codes/".$lat.",".$long."?include=territory,alphabet&allowLog=true&client=web");
    . . .

The web service returns the JSON data which was assigned to `digitaldata`, and the following statement decodes that JSON:

/var/www/html/digiaddress/generateDigitalAddress.php

    . . .
    $digitalAddress["status"] = json_decode($digitaldata, TRUE)['local']['territory']." ".json_decode($digitaldata, TRUE)['local']['mapcode'];
    . . .

This returns a mapcode for the user-specified location. The following lines then store this information in the database:

/var/www/html/digiaddress/generateDigitalAddress.php

    . . .
    $obj = new databaseConnection();
    
    $conn = $obj->dbConnect();
    
    $obj->insertLocation($conn, $digitalAddress["status"],$data->state,$data->zip,$data->street,$data->town,$data->house,$lat,$long);
    . . .

Then, the final line echoes the mapcode back to the caller function:

/var/www/html/digiaddress/generateDigitalAddress.php

    . . .
    echo json_encode($digitalAddress);

Save and close this file, then reopen `createDigitalAddressApp.js` again:

    nano /var/www/html/digiaddress/js/createDigitalAddressApp.js

When a mapcode has been retrieved successfully, the following lines in the `createDigitalAddressApp.js` file displays it to the user in a dialog box:

/var/www/html/digiaddress/js/createDigitalAddressApp.js

    . . .
    digiAddress = response.data.status;
    . . .
    $('#digitalAddressDialog').modal('show');
    . . .

Although you did add a new line of code to `generateDigitalAddress.php`, you still won’t see any functional changes when you visit and interact with the app in your browser. This is because you’ve not yet added your Google API key to the `geoimplement.php` file, which makes the actual call to the Google Maps API.

## Step 8 — Enabling Calls to the Google Maps API

This application depends on the Google Maps API to translate a physical address into the appropriate latitude and longitude coordinates. These are then passed on to the Mapcode API which uses them to generate a mapcode. Consequently, if the application is unable to communicate with the Google Maps API to generate the location’s latitude and longitude, any attempt to generate a mapcode will fail.

Recall from Step 6 where, after constructing the `address` data, we passed the result along via an HTTP POST request in the `createDigitalAddressApp.js` file:

/var/www/html/digiaddress/js/createDigitalAddressApp.js

    $http({
        method: 'POST',
        url: 'geoimplement.php',
        data: {address: fullAddress},
        headers: {'Content-Type': 'application/x-www-form-urlencoded'}
    }).then(function successCallback(results) {

This code block sends the address data entered by a user to the `geoimplement.php` file which contains the code that calls the Google Maps API. Go ahead and open this file:

    nano /var/www/html/digiaddress/geoimplement.php

You’ll see that it first decodes the `address` that was received through the POST request:

/var/www/html/digiaddress/geoimplement.php

    . . .
    $data=json_decode(file_get_contents("php://input"));
    . . .

It then passes the `address` field of the input data to a `geocode` function which returns the geographic information on the address:

/var/www/html/digiaddress/geoimplement.php

    . . .
    $result = geocode($data->address);
    . . .

The result is then echoed back to the caller:

/var/www/html/digiaddress/geoimplement.php

    . . .
    echo json_encode($result);
    . . .

The `geocode` function encodes the `address` and passes it on to the Google Maps API, along with your application key:

/var/www/html/digiaddress/geoimplement.php

    . . .
    // url encode the address
    $address = urlencode($address);
    
    // google map geocode api url
    $url = "https://maps.googleapis.com/maps/api/geocode/json?address={$address}&key=<YOUR KEY>";
    . . .

Before scrolling on, go ahead and add your API key to the line under the `// google map geocode api url` comment:

/var/www/html/digiaddress/geoimplement.php

    . . .
    // google map geocode api url
    $url = "https://maps.googleapis.com/maps/api/geocode/json?address={$address}&key=ExampleAPIKeyH2vITfv1eIHbfka9ym634Esw7u";
    . . .

After sending the call to the Google Maps API, the response is decoded and its value is returned by the function:

/var/www/html/digiaddress/geoimplement.php

    . . .
    // get the json response
    $resp_json = file_get_contents($url);
    
    // decode the json
    $resp = json_decode($resp_json, true);
    
    if ($resp['status'] == 'OK') {
        return $resp['results'][0];
    } else {
        return false;
    }
    . . .

Save this file, and visit your application once again. Input `US-NY` in the state field and then hit `TAB` to change the input focus to the next field. You will see the following output:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/mapcode/final_finalmap.png)

Notice that the geocoordinates and physical address that you entered in the form appear underneath the map. This makes the application feel much more engaging and interactive.

**Note:** When it comes to abbreviations for place names, Mapcode uses the ISO 3166 standard. This means that it may not interpret some commonly-used abbreviations as expected. For example, if you’d like to generate a Mapcode for an address in Louisiana and you enter `LA`, the map will jump to Los Angeles, California (rather than the state of Louisiana).

You can avoid confusion with US postal abbreviations by preceding them with `US-`. In the context of this Louisiana example, you would enter `US-LA`.

To learn more about how Mapcode uses this standard, check out the [Territories and standard codes reference page](http://www.mapcode.com/isos.html).

Despite this improvement to how the application displays locations on the map, the app still isn’t fully functional. The last step you need to take before you can generate a mapcode is to edit the `db.php` file to allow the application to access your database.

## Step 9 — Adding Database Credentials and Testing Mapcode Generation

Recall that this application stores every address entered into the form — along with its latitude, longitude, and mapcode — in the database you created in Step 2. This is made possible by the code within the `db.php` file, which stores your database credentials and allows the application to access the `locations` table within it.

As a final step to enable the mapcode generation functionality, open the `db.php` file for editing:

    nano /var/www/html/digiaddress/db.php

Near the top of this file, find the line that begins with `$pass`. This line submits your MySQL login credentials in order to allow the application to access your database. Replace `your_password` with your **root** MySQL user’s password:

/var/www/html/digiaddress/db.php

    . . .
            $username = "root";
            $pass = "your_password";
    . . .

That is the last change you need to make in order to generate a mapcode from a physical address. Save and close the file, then go ahead and refresh the application in your browser once again. Enter in an address of your choice and click the **Generate** button. The output will look similar to this:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/mapcode/final_digitaladdress.png)

At this stage, you have completed your application and you can now generate a short digital address for any physical location in the world. Feel free to experiment with different addresses, and note that the address you enter does not necessarily need to be within the United States.

Your final task is to enable this app’s second functionality: retrieving an address from the database using its respective mapcode.

## Step 10 — Retrieving a Physical Address

Now that you’re able to generate a mapcode from a given physical address, your final step is to retrieve the original physical address, as derived from the mapcode. To accomplish this, we will develop a PHP user interface, shown here:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/mapcode/final_getaddress.png)

The code for this UI is available in the `findaddress.php` file. As the UI defined within this file is fairly similar to the UI we covered earlier in Step 4, we will not look too closely at all the details of how it works. We will, however, go through these three files to explain generally how they function.

In order to enable the address retrieval functionality, you’ll need to add your Google API key to the `findaddress.php` file, so open it up with your preferred editor:

    nano /var/www/html/digiaddress/findaddress.php

Near the bottom of the file, find the line that begins with `<script async defer src=`. It will look like this:

/var/www/html/digiaddress/findaddress.php

    <script async defer src="https://maps.googleapis.com/maps/api/js?key=<YOUR KEY>"></script>

Replace `<YOUR KEY>` with your Google API key as you’ve done in the previous steps, then save the file. Before closing it, though, let’s take a quick look to see how these files work together.

When a user submits the form it triggers a `submit` event, and an event listener calls the `fetchadd` function:

/var/www/html/digiaddress/findaddress.php

    . . .
    <form ng-submit="fetchadd()" class="custom-form">
    . . .

The `fetchadd` function sends the digital address to `fetchaddress.php` with a POST request:

/var/www/html/digiaddress/js/findAddressApp.js

    . . .
    $http({
        method : 'POST',
        url : 'fetchaddress.php',
        data : {digiaddress: $scope.digiaddress}
    }).then(function(response){
    . . .

If the POST is successful, the function returns a JSON response. The following line parses this response:

/var/www/html/digiaddress/js/findAddressApp.js

    . . .
    var jsonlatlng = JSON.parse(response.data.latlng);
    . . .

The next lines set the marker on the map:

/var/www/html/digiaddress/js/findAddressApp.js

    . . .
    marker = new google.maps.Marker({
        position: new google.maps.LatLng(jsonlatlng.latitude, jsonlatlng.longitude),
            map: locationMap
    });
    . . .

And the following prints the geocoordinates and the physical address:

/var/www/html/digiaddress/js/findAddressApp.js

    . . .
    geoCoordLabel = angular.element(document.querySelector('#geocoordinates'));
    geoCoordLabel.html("Geo Coordinate: "+ jsonlatlng.latitude +","+ jsonlatlng.longitude);
    
    geoAddressLabel = angular.element(document.querySelector('#geoaddress'));
    geoAddressLabel.html("Geo Address: " + jsonlatlng.house +","+ jsonlatlng.town +","+ jsonlatlng.street +","+ jsonlatlng.state + " " + jsonlatlng.zip );
    . . .

Visit this application in your browser by going to the following link:

    http://your_server_ip/digiaddress/findaddress.php

Test it out by entering in the mapcode you obtained earlier. The following figure shows a typical output:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/mapcode/final_fetchedaddress.png)

With that, your application is finished. You can now create a unique mapcode for any location in the world, and then use that mapcode to retrieve the location’s physical address.

## Conclusion

In this tutorial you used the Google Maps API to pin a location and gets its longitude, latitude information. This information is used to generate a unique and short digital address using Mapcode API. There are a number of practical use cases for mapcodes, ranging from emergency services to archaeological surveying. [The Stichting Mapcode Foundation](http://www.mapcode.com/aboutus.html) lists several such use cases.

### Acknowledgements

Many thanks to [Dinesh Karpe](https://www.linkedin.com/in/dineshkarpe) and [Sayli Patil](https://www.linkedin.com/in/ptsayli) for developing the entire project code.
