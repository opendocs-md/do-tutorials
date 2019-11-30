---
author: Chuks Opia
date: 2019-08-08
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-a-ruby-on-rails-project-with-a-react-frontend
---

# How To Set Up a Ruby on Rails Project with a React Frontend

_The author selected the [Electronic Frontier Foundation](https://www.brightfunds.org/organizations/electronic-frontier-foundation-inc) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Ruby on Rails](https://rubyonrails.org/) is a popular server-side web application framework, with [over 42,000 stars on GitHub](https://github.com/rails/rails) at the time of writing this tutorial. It powers a lot of the popular applications that exist on the web today, like [GitHub](https://github.com/), [Basecamp](https://basecamp.com/), [SoundCloud](https://soundcloud.com/), [Airbnb](https://www.airbnb.com/), and [Twitch](https://www.twitch.tv/). With its emphasis on programmer experience and the passionate community that has built up around it, Ruby on Rails will give you the tools you need to build and maintain your modern web application.

[React](https://reactjs.org/) is a JavaScript library used to create front-end user interfaces. Backed by Facebook, it is one of the most popular front-end libraries used on the web today. React offers features like a [virtual Document Object Model (DOM)](https://reactjs.org/docs/faq-internals.html), [component architecture](https://reactjs.org/docs/components-and-props.html), and state management, which make the process of front-end development more organized and efficient.

With the frontend of the web moving toward frameworks that are separate from the server-side code, combining the elegance of Rails with the efficiency of React will let you build powerful and modern applications informed by current trends. By using React to render components from within a Rails view instead of the Rails template engine, your application will benefit from the latest advancements in JavaScript and front-end development while still leveraging the expressiveness of Ruby on Rails.

In this tutorial, you will create a Ruby on Rails application that stores your favorite recipes then displays them with a React frontend. When you are finished, you will be able to create, view, and delete recipes using a React interface styled with [Bootstrap](https://getbootstrap.com/):

![Completed Recipe App](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_65434/Completed_Recipe_App.png)

If you would like to take a look at the code for this application, check out the [companion repository](https://github.com/do-community/react_rails_recipe) for this tutorial on the [DigitalOcean Community GitHub](https://github.com/do-community).

## Prerequisites

To follow this tutorial, you need to have the following:

- [Node.js](https://nodejs.org/en/) and [npm](https://www.npmjs.com/) installed on your development machine. This tutorial uses Node.js version 10.16.0 and npm version 6.9.0. Node.js is a JavaScript run-time environment that allows you to run your code outside of the browser. It comes with a pre-installed Package Manager called [npm](https://www.npmjs.com/), which lets you install and update packages. To install these on macOS or Ubuntu 18.04, follow the steps in [How to Install Node.js and Create a Local Development Environment on macOS](how-to-install-node-js-and-create-a-local-development-environment-on-macos) or the “Installing Using a PPA” section of [How To Install Node.js on Ubuntu 18.04](how-to-install-node-js-on-ubuntu-18-04).

- The Yarn package manager installed on your development machine, which will allow you to download the React framework. This tutorial was tested on version 1.16.0; to install this dependency, follow the [official Yarn installation guide](https://yarnpkg.com/en/docs/install#debian-stable).

- Installation of the Ruby on Rails framework. To get this, follow our guide on [How to Install Ruby on Rails with rbenv on Ubuntu 18.04](how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-18-04), or [How To Install Ruby on Rails with rbenv on CentOS 7](how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-18-04). If you would like to develop this application on macOS, please see this tutorial on [How To Install Ruby on Rails with rbenv on macOS](how-to-install-ruby-on-rails-with-rbenv-on-macos). This tutorial was tested on version 2.6.3 of Ruby and version 5.2.3 of Rails, so make sure to specify these versions during the installation process.

- Installation of PostgreSQL, as shown in Steps 1 and 2 of our tutorial [How To Use PostgreSQL with Your Ruby on Rails Application on Ubuntu 18.04](how-to-use-postgresql-with-your-ruby-on-rails-application-on-ubuntu-18-04) or [How To Use PostgreSQL with Your Ruby on Rails Application on macOS](how-to-use-postgresql-with-your-ruby-on-rails-application-on-macos). To follow this tutorial, use PostgreSQL version 10. If you are looking to develop this application on a different distribution of Linux or on another OS, see the [official PostgreSQL downloads page](https://www.postgresql.org/download/). For more information on how to use PostgreSQL, see our [How To Install and Use PostgreSQL](how-to-install-and-use-postgresql-on-ubuntu-18-04) tutorials.

## Step 1 — Creating a New Rails Application

In this step, you will build your recipe application on the Rails application framework. First, you’ll create a new Rails application, which will be set up to work with React out of the box with little configuration.

Rails provides a number of scripts called generators that help in creating everything that’s necessary to build a modern web application. To see a full list of these commands and what they do, run the following command in your Terminal window:

    rails -h

This will yield a comprehensive list of options, which will allow you to set the parameters of your application. One of the commands listed is the `new` command, which creates a new Rails application.

Now, you will create a new Rails application using the `new` generator. Run the following command in your Terminal window:

    rails new rails_react_recipe -d=postgresql -T --webpack=react --skip-coffee

The preceding command creates a new Rails application in a directory named `rails_react_recipe`, installs the required Ruby and JavaScript dependencies, and configures Webpack. Let’s walk through the flags that are associated with this `new` generator command:

- The `-d` flag specifies the preferred database engine, which in this case is PostgreSQL.
- The `-T` flag instructs Rails to skip the generation of test files, since you won’t be writing tests for the purposes of this tutorial. This command is also suggested if you want to use a Ruby testing tool different from the one Rails provides.
- The `--webpack` instructs Rails to preconfigure for JavaScript with the [webpack bundler](https://webpack.js.org/), in this case specifically for a React application.
- The `--skip-coffee` asks Rails not to set up [CoffeeScript](https://coffeescript.org/), which is not needed for this tutorial.

Once the command is done running, move into the `rails_react_recipe` directory, which is the root directory of your app:

    cd rails_react_recipe

Next, list out the contents of the directory:

    ls

This root directory has a number of auto-generated files and folders that make up the structure of a Rails application, including a `package.json` file containing the dependencies for a React application.

Now that you have successfully created a new Rails application, you are ready to hook it up to a database in the next step.

## Step 2 — Setting Up the Database

Before you run your new Rails application, you have to first connect it to a database. In this step, you’ll connect the newly created Rails application to a PostgreSQL database, so recipe data can be stored and fetched when needed.

The `database.yml` file found in `config/database.yml` contains database details like database name for different development environments. Rails specifies a database name for the different development environments by appending an underscore (`_`) followed by the environment name to your app’s name. You can always change any environment database name to whatever you prefer.

**Note:** At this point, you can alter `config/database.yml` to set up which PostgreSQL role you would like Rails to use to create your database. If you followed the Prerequisite **How To Use PostgreSQL with Your Ruby on Rails Application** and created a role that is secured by a password, you can follow the instructions in **Step 4** for [macOS](how-to-use-postgresql-with-your-ruby-on-rails-application-on-macos#step-4-%E2%80%94-configuring-and-creating-your-database) or [Ubuntu 18.04](how-to-use-postgresql-with-your-ruby-on-rails-application-on-ubuntu-18-04#step-4-%E2%80%93-configuring-and-creating-your-database).

As earlier stated, Rails offers a lot of commands to make developing web applications easy. This includes commands to work with databases, such as `create`, `drop`, and `reset`. To create a database for your application, run the following command in your Terminal window:

    rails db:create

This command creates a `development` and `test` database, yielding the following output:

    OutputCreated database 'rails_react_recipe_development'
    Created database 'rails_react_recipe_test'

Now that the application is connected to a database, start the application by running the following command in you Terminal window:

    rails s --binding=127.0.0.1

The `s` or `server` command fires up [Puma](https://puma.io/), which is a web server distributed with Rails by default, and `--binding=127.0.0.1` binds the server to your `localhost`.

Once you run this command, your command prompt will disappear, and you will see the following output:

    Output=> Booting Puma
    => Rails 5.2.3 application starting in development 
    => Run `rails server -h` for more startup options
    Puma starting in single mode...
    * Version 3.12.1 (ruby 2.6.3-p62), codename: Llamas in Pajamas
    * Min threads: 5, max threads: 5
    * Environment: development
    * Listening on tcp://127.0.0.1:3000
    Use Ctrl-C to stop

To see your application, open a browser window and navigate to `http://localhost:3000`. You will see the Rails default welcome page:

![Rails welcome page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66605/Rails_Welcome.png)

This means that you have properly set up your Rails application.

To stop the web server at anytime, press `CTRL+C` in the Terminal window where the server is running. Go ahead and do this now; you will get a goodbye message from Puma:

    Output^C- Gracefully stopping, waiting for requests to finish
    === puma shutdown: 2019-07-31 14:21:24 -0400 ===
    - Goodbye!
    Exiting

Your prompt will then reappear.

You have successfully set up a database for your food recipe application. In the next step, you will install all the extra JavaScript dependencies you need to put together your React frontend.

## Step 3 — Installing Frontend Dependencies

In this step, you will install the JavaScript dependencies needed on the frontend of your food recipe application. They include:

- [React Router](https://reacttraining.com/react-router/), for handling navigation in a React application.
- [Bootstrap](https://getbootstrap.com/), for styling your front-end components.
- [jQuery](https://jquery.com/) and [Popper](https://popper.js.org/), for working with Bootstrap.

Run the following command in your Terminal window to install these packages with the Yarn package manager:

    yarn add react-router-dom bootstrap jquery popper.js

This command uses Yarn to install the specified packages and adds them to the `package.json` file. To verify this, take a look at the `package.json` file located in the root directory of the project:

    nano package.json

You’ll see the installed packages listed under the `dependencies` key:

~/rails\_react\_recipe/package.json

    {
      "name": "rails_react_recipe",
      "private": true,
      "dependencies": {
        "@babel/preset-react": "^7.0.0",
        "@rails/webpacker": "^4.0.7",
        "babel-plugin-transform-react-remove-prop-types": "^0.4.24",
        "bootstrap": "^4.3.1",
        "jquery": "^3.4.1",
        "popper.js": "^1.15.0",
        "prop-types": "^15.7.2",
        "react": "^16.8.6",
        "react-dom": "^16.8.6",
        "react-router-dom": "^5.0.1"
      },
      "devDependencies": {
        "webpack-dev-server": "^3.7.2"
      }
    }

You have installed a few front-end dependencies for your application. Next, you’ll set up a homepage for your food recipe application.

## Step 4 — Setting Up the Homepage

With all the required dependencies installed, in this step you will create a homepage for the application. The homepage will serve as the landing page when users first visit the application.

Rails follows the [Model-View-Controller](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller) architectural pattern for applications. In the MVC pattern, a controller’s purpose is to receive specific requests and pass them along to the appropriate model or view. Right now the application displays the Rails welcome page when the root URL is loaded in the browser. To change this, you will create a controller and view for the homepage and match it to a route.

Rails provides a `controller` generator for creating a controller. The `controller` generator receives a controller name, along with a matching action. For more on this, check out the [official Rails documentation](https://guides.rubyonrails.org/action_controller_overview.html).

This tutorial will call the controller `Homepage`. Run the following command in your Terminal window to create a Homepage controller with an `index` action.

    rails g controller Homepage index

**Note:**  
On Linux, if you run into the error `FATAL: Listen error: unable to monitor directories for changes.`, this is due to a system limit on the number of files your machine can monitor for changes. Run the following command to fix it:

    echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

This will permanently increase the amount of directories that you can monitor with `Listen` to `524288`. You can change this again by running the same command and replacing `524288` with your desired number.

Running this command generates the following files:

- A `homepage_controller.rb` file for receiving all homepage-related requests. This file contains the `index` action you specified in the command.
- A `homepage.js` file for adding any JavaScript behavior related to the `Homepage` controller.
- A `homepage.scss` file for adding styles related to the `Homepage` controller.
- A `homepage_helper.rb` file for adding helper methods related to the `Homepage` controller.
- An `index.html.erb` file which is the view page for rendering anything related to the homepage.

Apart from these new pages created by running the Rails command, Rails also updates your routes file which is located at `config/routes.rb`. It adds a `get` route for your homepage which you will modify as your root route.

A root route in Rails specifies what will show up when users visit the root URL of your application. In this case, you want your users to see your homepage. Open the routes file located at `config/routes.rb` in your favorite editor:

    nano config/routes.rb

Inside this file, replace `get 'homepage/index'` with `root 'homepage#index'` so that the file looks like the following:

~/rails\_react\_recipe/config/routes.rb

    Rails.application.routes.draw do
      root 'homepage#index'
      # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
    end

This modification instructs Rails to map requests to the root of the application to the `index` action of the `Homepage` controller, which in turn renders whatever is in the `index.html.erb` file located at `app/views/homepage/index.html.erb` on to the browser.

To verify that this is working, start your application:

    rails s --binding=127.0.0.1

Opening the application in the browser, you will see a new landing page for your application:

![Application Homepage](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_65434/Application_Homepage.png)

Once you have verified that your application is working, press `CTRL+C` to stop the server.

Next, delete the contents of the `~/rails_react_recipe/app/views/homepage/index.html.erb` file. By doing this, you will ensure that the contents of `index.html.erb` do not interfere with the React rendering of your frontend.

Now that you have set up your homepage for your application, you can move to the next section, where you will configure the frontend of your application to use React.

## Step 5 — Configuring React as Your Rails Frontend

In this step, you will configure Rails to use React on the frontend of the application, instead of its template engine. This will allow you to take advantage of React rendering to create a more visually appealing homepage.

Rails, with the help of the [Webpacker gem](https://github.com/rails/webpacker), bundles all your JavaScript code into _packs_. These can be found in the packs directory at `app/javascript/packs`. You can link these packs in Rails views using the `javascript_pack_tag` helper, and you can link stylesheets imported into the packs using the `stylesheet_pack_tag` helper. To create an entry point to your React environment, you will add one of these packs to your application layout.

First, rename the `~/rails_react_recipe/app/javascript/packs/hello_react.jsx` file to `~/rails_react_recipe/app/javascript/packs/Index.jsx`.

    mv ~/rails_react_recipe/app/javascript/packs/hello_react.jsx ~/rails_react_recipe/app/javascript/packs/Index.jsx

After renaming the file, open `application.html.erb`, the application layout file:

    nano ~/rails_react_recipe/app/views/layouts/application.html.erb

Add the following highlighted lines of code at the end of the head tag in the application layout file:

~/rails\_react\_recipe/app/views/layouts/application.html.erb

    <!DOCTYPE html>
    <html>
      <head>
        <title>RailsReactRecipe</title>
        <%= csrf_meta_tags %>
        <%= csp_meta_tag %>
    
        <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
        <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
        <%= javascript_pack_tag 'Index' %>
      </head>
    
      <body>
        <%= yield %>
      </body>
    </html>

Adding the JavaScript pack to your application’s header makes all your JavaScript code available and executes the code in your `Index.jsx` file on the page whenever you run the app. Along with the JavaScript pack, you also added a `meta` `viewport` tag to control the dimensions and scaling of pages on your application.

Save and exit the file.

Now that your entry file is loaded onto the page, create a React component for your homepage. Start by creating a `components` directory in the `app/javascript` directory:

    mkdir ~/rails_react_recipe/app/javascript/components

The `components` directory will house the component for the homepage, along with other React components in the application. The homepage will contain some text and a call to action button to view all recipes.

In your editor, create a `Home.jsx` file in the `components` directory:

    nano ~/rails_react_recipe/app/javascript/components/Home.jsx

Add the following code to the file:

~/rails\_react\_recipe/app/javascript/components/Home.jsx

    import React from "react";
    import { Link } from "react-router-dom";
    
    export default () => (
      <div className="vw-100 vh-100 primary-color d-flex align-items-center justify-content-center">
        <div className="jumbotron jumbotron-fluid bg-transparent">
          <div className="container secondary-color">
            <h1 className="display-4">Food Recipes</h1>
            <p className="lead">
              A curated list of recipes for the best homemade meal and delicacies.
            </p>
            <hr className="my-4" />
            <Link
              to="/recipes"
              className="btn btn-lg custom-button"
              role="button"
            >
              View Recipes
            </Link>
          </div>
        </div>
      </div>
    );

In this code, you imported React and also the `Link` component from React Router. The `Link` component creates a hyperlink to navigate from one page to another. You then created and exported a functional component containing some Markup language for your homepage, styled with Bootstrap classes.

With your `Home` component in place, you will now set up routing using React Router. Create a `routes` directory in the `app/javascript` directory:

    mkdir ~/rails_react_recipe/app/javascript/routes

The `routes` directory will contain a few routes with their corresponding components. Whenever any specified route is loaded, it will render its corresponding component to the browser.

In the `routes` directory, create an `Index.jsx` file:

    nano ~/rails_react_recipe/app/javascript/routes/Index.jsx

Add the following code to it:

~/rails\_react\_recipe/app/javascript/routes/Index.jsx

    import React from "react";
    import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
    import Home from "../components/Home";
    
    export default (
      <Router>
        <Switch>
          <Route path="/" exact component={Home} />
        </Switch>
      </Router>
    );

In this `Index.jsx` route file, you imported a couple of modules: the `React` module that allows us to use React, and the `BrowserRouter`, `Route`, and `Switch` modules from React Router, which together help us navigate from one route to another. Lastly, you imported your `Home` component, which will be rendered whenever a request matches the root (`/`) route. Whenever you want to add more pages to your application, all you need to do is declare a route in this file and match it to the component you want to render for that page.

Save and exit the file.

You have now successfully set up routing using React Router. For React to be aware of the available routes and use them, the routes have to be available at the entry point to the application. To achieve this, you will render your routes in a component that React will render in your entry file.

Create an `App.jsx` file in the `app/javascript/components` directory:

    nano ~/rails_react_recipe/app/javascript/components/App.jsx

Add the following code into the `App.jsx` file:

~/rails\_react\_recipe/app/javascript/components/App.jsx

    import React from "react";
    import Routes from "../routes/Index";
    
    export default props => <>{Routes}</>;

In the `App.jsx` file, you imported React and the route files you just created. You then exported a component that renders the routes within [fragments](https://reactjs.org/docs/fragments.html). This component will be rendered at the entry point of the aplication, thereby making the routes available whenever the application is loaded.

Now that you have your `App.jsx` set up, it’s time to render it in your entry file. Open the entry `Index.jsx` file:

    nano ~/rails_react_recipe/app/javascript/packs/Index.jsx

Replace the code there with the following code:

~/rails\_react\_recipe/app/javascript/packs/Index.jsx

    import React from "react";
    import { render } from "react-dom";
    import 'bootstrap/dist/css/bootstrap.min.css';
    import $ from 'jquery';
    import Popper from 'popper.js';
    import 'bootstrap/dist/js/bootstrap.bundle.min';
    import App from "../components/App";
    
    document.addEventListener("DOMContentLoaded", () => {
      render(
        <App />,
        document.body.appendChild(document.createElement("div"))
      );
    });

In this code snippet, you imported React, the render method from ReactDOM, Bootstrap, jQuery, Popper.js, and your `App` component. Using ReactDOM’s render method, you rendered your `App` component in a `div` element, which was appended to the body of the page. Whenever the application is loaded, React will render the content of the `App` component inside the `div` element on the page.

Save and exit the file.

Finally, add some CSS styles to your homepage.

Open up your `application.css` in your `~/rails_react_recipe/app/assets/stylesheets` directory:

    nano ~/rails_react_recipe/app/assets/stylesheets/application.css

Next, replace the contents of the `application.css` file with the follow code:

~/rails\_react\_recipe/app/assets/stylesheets/application.css

    .bg_primary-color {
      background-color: #FFFFFF;
    }
    .primary-color {
      background-color: #FFFFFF;
    }
    .bg_secondary-color {
      background-color: #293241;
    }
    .secondary-color {
      color: #293241;
    }
    .custom-button.btn {
      background-color: #293241;
      color: #FFF;
      border: none;
    }
    .custom-button.btn:hover {
      color: #FFF !important;
      border: none;
    }
    .hero {
      width: 100vw;
      height: 50vh;
    }
    .hero img {
      object-fit: cover;
      object-position: top;
      height: 100%;
      width: 100%;
    }
    .overlay {
      height: 100%;
      width: 100%;
      opacity: 0.4;
    }

This creates the framework for a _hero image_, or a large web banner on the front page of your website, that you will add later. Additionally, this styles the button that the user will use to enter the application.

With your CSS styles in place, save and exit the file. Next, restart the web server for your application, then reload the application in your browser. You will see a brand new homepage:

![Homepage Style](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_65434/Homepage_Styled.png)

In this step, you configured your application so that it uses React as its frontend. In the next section, you will create models and controllers that will allow you to create, read, update, and delete recipes.

## Step 6 — Creating the Recipe Controller and Model

Now that you have set up a React frontend for your application, in this step you’ll create a Recipe model and controller. The recipe model will represent the database table that will hold information about the user’s recipes while the controller will receive and handle requests to create, read, update, or delete recipes. When a user requests a recipe, the recipe controller receives this request and passes it to the recipe model, which retrieves the requested data from the database. The model then returns the recipe data as a response to the controller. Finally, this information is displayed in the browser.

Start by creating a Recipe model by using the `generate model` subcommand provided by Rails and by specifying the name of the model along with its columns and data types. Run the following command in your Terminal window to create a `Recipe` model:

    rails generate model Recipe name:string ingredients:text instruction:text image:string

The preceding command instructs Rails to create a `Recipe` model together with a `name` column of type `string`, an `ingredients` and `instruction` column of type `text`, and an `image` column of type `string`. This tutorial has named the model `Recipe`, because by convention models in Rails use a singular name while their corresponding database tables use a plural name.

Running the `generate model` command creates two files:

- A `recipe.rb` file that holds all the model related logic.
- A `20190407161357_create_recipes.rb` file (the number at the beginning of the file may differ depending on the date when you run the command). This is a migration file that contains the instruction for creating the database structure.

Next, edit the recipe model file to ensure that only valid data is saved to the database. You can achieve this by adding some database validation to your model. Open your recipe model located at `app/models/recipe.rb`:

    nano ~/rails_react_recipe/app/models/recipe.rb

Add the following highlighted lines of code to the file:

    class Recipe < ApplicationRecord
      validates :name, presence: true
      validates :ingredients, presence: true
      validates :instruction, presence: true
    end

In this code, you added model validation which checks for the presence of a `name`, `ingredients`, and `instruction` field. Without the presence of these three fields, a recipe is invalid and won’t be saved to the database.

Save and quit the file.

For Rails to create the `recipes` table in your database, you have to run a [migration](https://guides.rubyonrails.org/v3.2/migrations.html), which in Rails is a way to make changes to your database programmatically. To make sure that the migration works with the database you set up, it is necessary to make changes to the `20190407161357_create_recipes.rb` file.

Open this file in your editor:

    nano ~/rails_react_recipe/db/migrate/20190407161357_create_recipes.rb

Add the following highlighted lines, so that the file looks like this:

db/migrate/20190407161357\_create\_recipes.rb

    class CreateRecipes < ActiveRecord::Migration[5.2]
      def change
        create_table :recipes do |t|
          t.string :name, null: false
          t.text :ingredients, null: false
          t.text :instruction, null: false
          t.string :image, default: 'https://raw.githubusercontent.com/do-community/react_rails_recipe/master/app/assets/images/Sammy_Meal.jpg'
          t.timestamps
        end
      end
    end

This migration file contains a Ruby class with a `change` method, and a command to create a table called `recipes` along with the columns and their data types. You also updated `20190407161357_create_recipes.rb` with a `NOT NULL` constraint on the `name`, `ingredients`, and `instruction` columns by adding `null: false`, ensuring that these columns have a value before changing the database. Finally, you added a default image URL for your image column; this could be another URL if you wanted to use a different image.

With these changes, save and exit the file. You’re now ready to run your migration and actually create your table. In your Terminal window, run the following command:

    rails db:migrate

Here you used the database migrate command, which executes the instructions in your migration file. Once the command runs successfully, you will receive an output similar to the following:

    Output== 20190407161357 CreateRecipes: migrating ====================================
    -- create_table(:recipes)
       -> 0.0140s
    == 20190407161357 CreateRecipes: migrated (0.0141s) ===========================

With your recipe model in place, create your recipes controller and add the logic for creating, reading, and deleting recipes. In your Terminal window, run the following command:

    rails generate controller api/v1/Recipes index create show destroy -j=false -y=false --skip-template-engine --no-helper

In this command, you created a `Recipes` controller in an `api/v1` directory with an `index`, `create`, `show`, and `destroy` action. The `index` action will handle fetching all your recipes, the `create` action will be responsible for creating new recipes, the `show` action will fetch a single recipe, and the `destroy` action will hold the logic for deleting a recipe.

You also passed some flags to make the controller more lightweight, including:

- `-j=false` which instructs Rails to skip generating associated JavaScript files.
- `-y=false` which instructs Rails to skip generating associated stylesheet files.
- `--skip-template-engine`, which instructs Rails to skip generating Rails view files, since React is handling your front-end needs.
- `--no-helper`, which instructs Rails to skip generating a helper file for your controller.

Running the command also updated your routes file with a route for each action in the `Recipes` controller. To use these routes, make changes to your `config/routes.rb` file.

Open up the routes file in your text editor:

    nano ~/rails_react_recipe/config/routes.rb

Once it is open, update it to look like the following code, altering or adding the highlighted lines:

~/rails\_react\_recipe/config/routes.rb

    Rails.application.routes.draw do
      namespace :api do
        namespace :v1 do
          get 'recipes/index'
          post 'recipes/create'
          get '/show/:id', to: 'recipes#show'
          delete '/destroy/:id', to: 'recipes#destroy'
        end
      end
      root 'homepage#index'
      get '/*path' => 'homepage#index'
      # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
    end

In this route file, you modified the HTTP verb of the `create` and `destroy` routes so that it can `post` and `delete` data. You also modified the routes for the `show` and `destroy` action by adding an `:id` parameter into the route. `:id` will hold the identification number of the recipe you want to read or delete.

You also added a catch all route with `get '/*path'` that will direct any other request that doesn’t match the existing routes to the `index` action of the `homepage` controller. This way, the routing on the frontend will handle requests that are not related to creating, reading, or deleting recipes.

Save and exit the file.

To see a list of routes available in your application, run the following command in your Terminal window:

    rails routes

Running this command displays a list of URI patterns, verbs, and matching controllers or actions for your project.

Next, add the logic for getting all recipes at once. Rails uses the [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord) library to handle database-related tasks like this. ActiveRecord connects classes to relational database tables and provides a rich API for working with them.

To get all recipes, you’ll use ActiveRecord to query the recipes table and fetch all the recipes that exist in the database.

Open the `recipes_controller.rb` file with the following command:

    nano ~/rails_react_recipe/app/controllers/api/v1/recipes_controller.rb

Add the following highlighted lines of code to the recipes controller:

~/rails\_react\_recipe/app/controllers/api/v1/recipes\_controller.rb

    class Api::V1::RecipesController < ApplicationController
      def index
        recipe = Recipe.all.order(created_at: :desc)
        render json: recipe
      end
    
      def create
      end
    
      def show
      end
    
      def destroy
      end
    end

In your `index` action, using the `all` method provided by ActiveRecord, you get all the recipes in your database. Using the `order` method, you order them in descending order by their created date. This way, you have the newest recipes first. Lastly, you send your list of recipes as a JSON response with `render`.

Next, add the logic for creating new recipes. As with fetching all recipes, you’ll rely on ActiveRecord to validate and save the provided recipe details. Update your recipe controller with the following highlighted lines of code:

~/rails\_react\_recipe/app/controllers/api/v1/recipes\_controller.rb

    class Api::V1::RecipesController < ApplicationController
      def index
        recipe = Recipe.all.order(created_at: :desc)
        render json: recipe
      end
    
      def create
        recipe = Recipe.create!(recipe_params)
        if recipe
          render json: recipe
        else
          render json: recipe.errors
        end
      end
    
      def show
      end
    
      def destroy
      end
    
      private
    
      def recipe_params
        params.permit(:name, :image, :ingredients, :instruction)
      end
    end

In the `create` action, you use ActiveRecord’s `create` method to create a new recipe. The `create` method has the ability to assign all controller parameters provided into the model at once. This makes it easy to create records, but also opens the possibility of malicious use. This can be prevented by using a feature provided by Rails known as [strong parameters](https://guides.rubyonrails.org/action_controller_overview.html#strong-parameters). This way, parameters can’t be assigned unless they’ve been whitelisted. In your code, you passed a `recipe_params` parameter to the `create` method. The `recipe_params` is a `private` method where you whitelisted your controller parameters to prevent wrong or malicious content from getting into your database. In this case, you are permitting a `name`, `image`, `ingredients`, and `instruction` parameter for valid use of the `create` method.

Your recipe controller can now read and create recipes. All that’s left is the logic for reading and deleting a single recipe. Update your recipes controller with the following code:

~/rails\_react\_recipe/app/controllers/api/v1/recipes\_controller.rb

    class Api::V1::RecipesController < ApplicationController
      def index
        recipe = Recipe.all.order(created_at: :desc)
        render json: recipe
      end
    
      def create
        recipe = Recipe.create!(recipe_params)
        if recipe
          render json: recipe
        else
          render json: recipe.errors
        end
      end
    
      def show
        if recipe
          render json: recipe
        else
          render json: recipe.errors
        end
      end
    
      def destroy
        recipe&.destroy
        render json: { message: 'Recipe deleted!' }
      end
    
      private
    
      def recipe_params
        params.permit(:name, :image, :ingredients, :instruction)
      end
    
      def recipe
        @recipe ||= Recipe.find(params[:id])
      end
    end

In the new lines of code, you created a private `recipe` method. The `recipe` method uses ActiveRecord’s `find` method to find a recipe whose `id`matches the `id` provided in the `params` and assigns it to an instance variable `@recipe`. In the `show` action, you checked if a recipe is returned by the `recipe` method and sent it as a JSON response, or sent an error if it was not.

In the `destroy` action, you did something similar using Ruby’s safe navigation operator `&.`, which avoids `nil` errors when calling a method. This let’s you delete a recipe only if it exists, then send a message as a response.

Now that you have finished making these changes to `recipes_controller.rb`, save the file and exit your text editor.

In this step, you created a model and controller for your recipes. You’ve written all the logic needed to work with recipes on the backend. In the next section, you’ll create components to view your recipes.

## Step 7 — Viewing Recipes

In this section, you will create components for viewing recipes. First you’ll create a page where you can view all existing recipes, and then another to view individual recipes.

You’ll start off by creating a page to view all recipes. However, before you can do this, you need recipes to work with, since your database is currently empty. Rails affords us the opportunity to create seed data for your application.

Open up the seed file `seeds.rb` to edit:

    nano ~/rails_react_recipe/db/seeds.rb

Replace the contents of this seed file with the following code:

~/rails\_react\_recipe/db/seeds.rb

    9.times do |i|
      Recipe.create(
        name: "Recipe #{i + 1}",
        ingredients: '227g tub clotted cream, 25g butter, 1 tsp cornflour,100g parmesan, grated nutmeg, 250g fresh fettuccine or tagliatelle, snipped chives or chopped parsley to serve (optional)',
        instruction: 'In a medium saucepan, stir the clotted cream, butter, and cornflour over a low-ish heat and bring to a low simmer. Turn off the heat and keep warm.'
      )
    end

In this code, you are using a loop to instruct Rails to create nine recipes with a `name`, `ingredients`, and `instruction`. Save and exit the file.

To seed the database with this data, run the following command in your Terminal window:

    rails db:seed

Running this command adds nine recipes to your database. Now you can fetch them and render them on the frontend.

The component to view all recipes will make a HTTP request to the `index` action in the `RecipesController` to get a list of all recipes. These recipes will then be displayed in cards on the page.

Create a `Recipes.jsx` file in the `app/javascript/components` directory:

    nano ~/rails_react_recipe/app/javascript/components/Recipes.jsx

Once the file is open, import the React and Link modules into it by adding the following lines:

~/rails\_react\_recipe/app/javascript/components/Recipes.jsx

    import React from "react";
    import { Link } from "react-router-dom";

Next, create a `Recipes` class that extends the `React.Component` class. Add the following highlighted code to create a React component that extends `React.Component`:

~/rails\_react\_recipe/app/javascript/components/Recipes.jsx

    import React from "react";
    import { Link } from "react-router-dom";
    
    class Recipes extends React.Component {
      constructor(props) {
        super(props);
        this.state = {
          recipes: []
        };
      }
    
    }
    export default Recipes;

Inside the [constructor](https://reactjs.org/docs/react-component.html#constructor), we are initializing a [state](https://reactjs.org/docs/react-component.html#state) object that holds the state of your recipes, which on initialization is an empty array (`[]`).

Next, add a `componentDidMount` method in the Recipe class. The [componentDidMount](https://reactjs.org/docs/react-component.html#componentdidmount) method is a React lifecycle method that is called immediately after a component is mounted. In this lifecycle method, you will make a call to fetch all your recipes. To do this, add the following lines:

~/rails\_react\_recipe/app/javascript/components/Recipes.jsx

    import React from "react";
    import { Link } from "react-router-dom";
    
    class Recipes extends React.Component {
      constructor(props) {
        super(props);
        this.state = {
          recipes: []
        };
      }
    
      componentDidMount() {
          const url = "/api/v1/recipes/index";
          fetch(url)
            .then(response => {
              if (response.ok) {
                return response.json();
              }
              throw new Error("Network response was not ok.");
            })
            .then(response => this.setState({ recipes: response }))
            .catch(() => this.props.history.push("/"));
      }
    
    }
    export default Recipes;

In your `componentDidMount` method, you made an HTTP call to fetch all recipes using the [Fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API). If the response is successful, the application saves the array of recipes to the recipe state. If there’s an error, it will redirect the user to the homepage.

Finally, add a `render` method in the `Recipe` class. The [render](https://reactjs.org/docs/react-component.html#render) method holds the React elements that will be evaluated and displayed on the browser page when a component is rendered. In this case, the `render` method will render cards of recipes from the component state. Add the following highlighted lines to `Recipes.jsx`:

~/rails\_react\_recipe/app/javascript/components/Recipes.jsx

    import React from "react";
    import { Link } from "react-router-dom";
    
    class Recipes extends React.Component {
      constructor(props) {
        super(props);
        this.state = {
          recipes: []
        };
      }
    
      componentDidMount() {
        const url = "/api/v1/recipes/index";
        fetch(url)
          .then(response => {
            if (response.ok) {
              return response.json();
            }
            throw new Error("Network response was not ok.");
          })
          .then(response => this.setState({ recipes: response }))
          .catch(() => this.props.history.push("/"));
      }
      render() {
        const { recipes } = this.state;
        const allRecipes = recipes.map((recipe, index) => (
          <div key={index} className="col-md-6 col-lg-4">
            <div className="card mb-4">
              <img
                src={recipe.image}
                className="card-img-top"
                alt={`${recipe.name} image`}
              />
              <div className="card-body">
                <h5 className="card-title">{recipe.name}</h5>
                <Link to={`/recipe/${recipe.id}`} className="btn custom-button">
                  View Recipe
                </Link>
              </div>
            </div>
          </div>
        ));
        const noRecipe = (
          <div className="vw-100 vh-50 d-flex align-items-center justify-content-center">
            <h4>
              No recipes yet. Why not <Link to="/new_recipe">create one</Link>
            </h4>
          </div>
        );
    
        return (
          <>
            <section className="jumbotron jumbotron-fluid text-center">
              <div className="container py-5">
                <h1 className="display-4">Recipes for every occasion</h1>
                <p className="lead text-muted">
                  We’ve pulled together our most popular recipes, our latest
                  additions, and our editor’s picks, so there’s sure to be something
                  tempting for you to try.
                </p>
              </div>
            </section>
            <div className="py-5">
              <main className="container">
                <div className="text-right mb-3">
                  <Link to="/recipe" className="btn custom-button">
                    Create New Recipe
                  </Link>
                </div>
                <div className="row">
                  {recipes.length > 0 ? allRecipes : noRecipe}
                </div>
                <Link to="/" className="btn btn-link">
                  Home
                </Link>
              </main>
            </div>
          </>
        );
      }
    }
    export default Recipes;

Save and exit `Recipes.jsx`.

Now that you have created a component to display all the recipes, the next step is to create a route for it. Open the front-end route file located at `app/javascript/routes/Index.jsx`:

    nano app/javascript/routes/Index.jsx

Add the following highlighted lines to the file:

~/rails\_react\_recipe/app/javascript/routes/Index.jsx

    import React from "react";
    import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
    import Home from "../components/Home";
    import Recipes from "../components/Recipes";
    
    export default (
      <Router>
        <Switch>
          <Route path="/" exact component={Home} />
          <Route path="/recipes" exact component={Recipes} />
        </Switch>
      </Router>
    );

Save and exit the file.

At this point, it’s a good idea to verify that your code is working correctly. As you did before, use the following command to start your server:

    rails s --binding=127.0.0.1

Go ahead and open the app in your browser. By clicking the **View Recipe** button on the homepage, you will see a display with your seed recipes:

![Recipes Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_65434/Recipe_Page.png)

Use `CTRL+C` in your Terminal window to stop the server and get your prompt back.

Now that you can view all the recipes that exist in your application, it’s time to create a second component to view individual recipes. Create a `Recipe.jsx` file in the `app/javascript/components` directory:

    nano app/javascript/components/Recipe.jsx

As with the `Recipes` component, import the React and Link modules by adding the following lines:

~/rails\_react\_recipe/app/javascript/components/Recipe.jsx

    import React from "react";
    import { Link } from "react-router-dom";

Next create a `Recipe` class that extends `React.Component` class by adding the highlighted lines of code:

~/rails\_react\_recipe/app/javascript/components/Recipe.jsx

    import React from "react";
    import { Link } from "react-router-dom";
    
    class Recipe extends React.Component {
      constructor(props) {
        super(props);
        this.state = { recipe: { ingredients: "" } };
    
        this.addHtmlEntities = this.addHtmlEntities.bind(this);
      }
    }
    
    export default Recipe;

Like with your `Recipes` component, in the constructor, you initialized a state object that holds the state of a recipe. You also bound an `addHtmlEntities` method to `this` so it can be accessible within the component. The `addHtmlEntities` method will be used to replace character entities with [HTML entities](https://www.w3schools.com/html/html_entities.asp) in the component.

In order to find a particular recipe, your application needs the `id` of the recipe. This means your `Recipe` component expects an `id` `param`. You can access this via the `props` passed into the component.

Next, add a `componentDidMount` method where you will access the `id` `param` from the `match` key of the `props` object. Once you get the `id`, you will then make an HTTP request to fetch the recipe. Add the following highlighted lines to your file:

~/rails\_react\_recipe/app/javascript/components/Recipe.jsx

    import React from "react";
    import { Link } from "react-router-dom";
    
    class Recipe extends React.Component {
      constructor(props) {
        super(props);
        this.state = { recipe: { ingredients: "" } };
    
        this.addHtmlEntities = this.addHtmlEntities.bind(this);
      }
    
      componentDidMount() {
        const {
          match: {
            params: { id }
          }
        } = this.props;
    
        const url = `/api/v1/show/${id}`;
    
        fetch(url)
          .then(response => {
            if (response.ok) {
              return response.json();
            }
            throw new Error("Network response was not ok.");
          })
          .then(response => this.setState({ recipe: response }))
          .catch(() => this.props.history.push("/recipes"));
      }
    
    }
    
    export default Recipe;

In the `componentDidMount` method, using [object destructuring](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Destructuring_assignment#Object_destructuring), you get the `id` `param` from the `props` object, then using the Fetch API, you make a HTTP request to fetch the recipe that owns the `id` and save it to the component state using the `setState` method. If the recipe does not exist, the app redirects the user to the recipes page.

Now add the `addHtmlEntities` method, which takes a string and replaces all escaped opening and closing brackets with their HTML entities. This will help us convert whatever escaped character was saved in your recipe instruction:

~/rails\_react\_recipe/app/javascript/components/Recipe.jsx

    import React from "react";
    import { Link } from "react-router-dom";
    
    class Recipe extends React.Component {
      constructor(props) {
        super(props);
        this.state = { recipe: { ingredients: "" } };
    
        this.addHtmlEntities = this.addHtmlEntities.bind(this);
      }
    
      componentDidMount() {
        const {
          match: {
            params: { id }
          }
        } = this.props;
    
        const url = `/api/v1/show/${id}`;
    
        fetch(url)
          .then(response => {
            if (response.ok) {
              return response.json();
            }
            throw new Error("Network response was not ok.");
          })
          .then(response => this.setState({ recipe: response }))
          .catch(() => this.props.history.push("/recipes"));
      }
    
      addHtmlEntities(str) {
        return String(str)
          .replace(/&lt;/g, "<")
          .replace(/&gt;/g, ">");
      }
    }
    
    export default Recipe;

Finally, add a `render` method that gets the recipe from the state and renders it on the page. To do this, add the following highlighted lines:

~/rails\_react\_recipe/app/javascript/components/Recipe.jsx

    import React from "react";
    import { Link } from "react-router-dom";
    
    class Recipe extends React.Component {
      constructor(props) {
        super(props);
        this.state = { recipe: { ingredients: "" } };
    
        this.addHtmlEntities = this.addHtmlEntities.bind(this);
      }
    
      componentDidMount() {
        const {
          match: {
            params: { id }
          }
        } = this.props;
    
        const url = `/api/v1/show/${id}`;
    
        fetch(url)
          .then(response => {
            if (response.ok) {
              return response.json();
            }
            throw new Error("Network response was not ok.");
          })
          .then(response => this.setState({ recipe: response }))
          .catch(() => this.props.history.push("/recipes"));
      }
    
      addHtmlEntities(str) {
        return String(str)
          .replace(/&lt;/g, "<")
          .replace(/&gt;/g, ">");
      }
    
      render() {
        const { recipe } = this.state;
        let ingredientList = "No ingredients available";
    
        if (recipe.ingredients.length > 0) {
          ingredientList = recipe.ingredients
            .split(",")
            .map((ingredient, index) => (
              <li key={index} className="list-group-item">
                {ingredient}
              </li>
            ));
        }
        const recipeInstruction = this.addHtmlEntities(recipe.instruction);
    
        return (
          <div className="">
            <div className="hero position-relative d-flex align-items-center justify-content-center">
              <img
                src={recipe.image}
                alt={`${recipe.name} image`}
                className="img-fluid position-absolute"
              />
              <div className="overlay bg-dark position-absolute" />
              <h1 className="display-4 position-relative text-white">
                {recipe.name}
              </h1>
            </div>
            <div className="container py-5">
              <div className="row">
                <div className="col-sm-12 col-lg-3">
                  <ul className="list-group">
                    <h5 className="mb-2">Ingredients</h5>
                    {ingredientList}
                  </ul>
                </div>
                <div className="col-sm-12 col-lg-7">
                  <h5 className="mb-2">Preparation Instructions</h5>
                  <div
                    dangerouslySetInnerHTML={{
                      __html: `${recipeInstruction}`
                    }}
                  />
                </div>
                <div className="col-sm-12 col-lg-2">
                  <button type="button" className="btn btn-danger">
                    Delete Recipe
                  </button>
                </div>
              </div>
              <Link to="/recipes" className="btn btn-link">
                Back to recipes
              </Link>
            </div>
          </div>
        );
      }
    
    }
    
    export default Recipe;

In this `render` method, you split your comma separated ingredients into an array and mapped over it, creating a list of ingredients. If there are no ingredients, the app displays a message that says **No ingredients available**. It also displays the recipe image as a hero image, adds a delete recipe button next to the recipe instruction, and adds a button that links back to the recipes page.

Save and exit the file.

To view the `Recipe` component on a page, add it to your routes file. Open your route file to edit:

    nano app/javascript/routes/Index.jsx

Now, add the following highlighted lines to the file:

~/rails\_react\_recipe/app/javascript/routes/Index.jsx

    import React from "react";
    import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
    import Home from "../components/Home";
    import Recipes from "../components/Recipes";
    import Recipe from "../components/Recipe";
    
    export default (
      <Router>
        <Switch>
          <Route path="/" exact component={Home} />
          <Route path="/recipes" exact component={Recipes} />
          <Route path="/recipe/:id" exact component={Recipe} />
        </Switch>
      </Router>
    );

In this route file, you imported your `Recipe` component and added a route for it. Its route has an `:id` `param` that will be replaced by the `id` of the recipe you want to view.

Use the `rails s` command to start your server again, then visit `http://localhost:3000` in your browser. Click the **View Recipes** button to navigate to the recipes page. On the recipes page, view any recipe by clicking its **View Recipe** button. You will be greeted with a page populated with the data from your database:

![Single Recipe Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_65434/Single_Recipe_Page.png)

In this section, you added nine recipes to your database and created components to view these recipes, both individually and as a collection. In the next section, you will add a component to create recipes.

## Step 8 — Creating Recipes

The next step to having a usable food recipe application is the ability to create new recipes. In this step, you will create a component for creating recipes. This component will contain a form for collecting the required recipe details from the user and will make a request to the `create` action in the `Recipe` controller to save the recipe data.

Create a `NewRecipe.jsx` file in the `app/javascript/components` directory:

    nano app/javascript/components/NewRecipe.jsx

In the new file, import the React and Link modules you have used so far in other components:

~/rails\_react\_recipe/app/javascript/components/NewRecipe.jsx

    import React from "react";
    import { Link } from "react-router-dom";

Next create a `NewRecipe` class that extends `React.Component` class. Add the following highlighted code to create a React component that extends `react.Component`:

~/rails\_react\_recipe/app/javascript/components/NewRecipe.jsx

    import React from "react";
    import { Link } from "react-router-dom";
    
    class NewRecipe extends React.Component {
      constructor(props) {
        super(props);
        this.state = {
          name: "",
          ingredients: "",
          instruction: ""
        };
    
        this.onChange = this.onChange.bind(this);
        this.onSubmit = this.onSubmit.bind(this);
        this.stripHtmlEntities = this.stripHtmlEntities.bind(this);
      }
    }
    
    export default NewRecipe;

In the `NewRecipe` component’s constructor, you initialized your state object with empty `name`, `ingredients`, and `instruction` fields. These are the fields you need to create a valid recipe. You also have three methods; `onChange`, `onSubmit`, and `stripHtmlEntities`, which you bound to `this`. These methods will handle updating the state, form submissions, and converting special characters (like `<`) into their escaped/encoded values (like `&lt;`), respectively.

Next, create the `stripHtmlEntities` method itself by adding the highlighted lines to the `NewRecipe` component:

~/rails\_react\_recipe/app/javascript/components/NewRecipe.jsx

    class NewRecipe extends React.Component {
      constructor(props) {
        super(props);
        this.state = {
          name: "",
          ingredients: "",
          instruction: ""
        };
    
        this.onChange = this.onChange.bind(this);
        this.onSubmit = this.onSubmit.bind(this);
        this.stripHtmlEntities = this.stripHtmlEntities.bind(this);
      }
    
      stripHtmlEntities(str) {
        return String(str)
          .replace(/</g, "&lt;")
          .replace(/>/g, "&gt;");
      }
    
    }
    
    export default NewRecipe;

In the `stripHtmlEntities` method, you’re replacing the `<` and `>` characters with their escaped value. This way you’re not storing raw HTML in your database.

Next add the `onChange` and `onSubmit` methods to the `NewRecipe` component to handle editing and submission of the form:

~/rails\_react\_recipe/app/javascript/components/NewRecipe.jsx

    class NewRecipe extends React.Component {
      constructor(props) {
        super(props);
        this.state = {
          name: "",
          ingredients: "",
          instruction: ""
        };
    
        this.onChange = this.onChange.bind(this);
        this.onSubmit = this.onSubmit.bind(this);
        this.stripHtmlEntities = this.stripHtmlEntities.bind(this);
      }
    
      stripHtmlEntities(str) {
        return String(str)
          .replace(/</g, "&lt;")
          .replace(/>/g, "&gt;");
      }
    
      onChange(event) {
        this.setState({ [event.target.name]: event.target.value });
      }
    
      onSubmit(event) {
        event.preventDefault();
        const url = "/api/v1/recipes/create";
        const { name, ingredients, instruction } = this.state;
    
        if (name.length == 0 || ingredients.length == 0 || instruction.length == 0)
          return;
    
        const body = {
          name,
          ingredients,
          instruction: instruction.replace(/\n/g, "<br> <br>")
        };
    
        const token = document.querySelector('meta[name="csrf-token"]').content;
        fetch(url, {
          method: "POST",
          headers: {
            "X-CSRF-Token": token,
            "Content-Type": "application/json"
          },
          body: JSON.stringify(body)
        })
          .then(response => {
            if (response.ok) {
              return response.json();
            }
            throw new Error("Network response was not ok.");
          })
          .then(response => this.props.history.push(`/recipe/${response.id}`))
          .catch(error => console.log(error.message));
      }
    
    }
    
    export default NewRecipe;

In the `onChange` method, you used the ES6 [computed property names](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Object_initializer#Computed_property_names) to set the value of every user input to its corresponding key in your state. In the `onSubmit` method, you checked that none of the required inputs are empty. You then build an object that contains the parameters required by the recipe controller to create a new recipe. Using [regular expression](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions), you replace every new line character in the instruction with a break tag, so you can retain the text format entered by the user.

To protect against [Cross-Site Request Forgery (CSRF)](https://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)) attacks, Rails attaches a CSRF security token to the HTML document. This token is required whenever a non-`GET` request is made. With the `token` constant in the preceding code, your application verifies the token on the server and throws an exception if the security token doesn’t match what is expected. In the `onSubmit` method, the application retrieves the [CSRF token](https://guides.rubyonrails.org/security.html#csrf-countermeasures) embedded in your HTML document by Rails and makes a HTTP request with a JSON string. If the recipe is successfully created, the application redirects the user to the recipe page where they can view their newly created recipe.

Lastly, add a `render` method that renders a form for the user to enter the details for the recipe the user wishes to create:

~/rails\_react\_recipe/app/javascript/components/NewRecipe.jsx

    class NewRecipe extends React.Component {
      constructor(props) {
        super(props);
        this.state = {
          name: "",
          ingredients: "",
          instruction: ""
        };
    
        this.onChange = this.onChange.bind(this);
        this.onSubmit = this.onSubmit.bind(this);
        this.stripHtmlEntities = this.stripHtmlEntities.bind(this);
      }
    
      stripHtmlEntities(str) {
        return String(str)
          .replace(/</g, "&lt;")
          .replace(/>/g, "&gt;");
      }
    
      onChange(event) {
        this.setState({ [event.target.name]: event.target.value });
      }
    
      onSubmit(event) {
        event.preventDefault();
        const url = "/api/v1/recipes/create";
        const { name, ingredients, instruction } = this.state;
    
        if (name.length == 0 || ingredients.length == 0 || instruction.length == 0)
          return;
    
        const body = {
          name,
          ingredients,
          instruction: instruction.replace(/\n/g, "<br> <br>")
        };
    
        const token = document.querySelector('meta[name="csrf-token"]').content;
        fetch(url, {
          method: "POST",
          headers: {
            "X-CSRF-Token": token,
            "Content-Type": "application/json"
          },
          body: JSON.stringify(body)
        })
          .then(response => {
            if (response.ok) {
              return response.json();
            }
            throw new Error("Network response was not ok.");
          })
          .then(response => this.props.history.push(`/recipe/${response.id}`))
          .catch(error => console.log(error.message));
      }
    
      render() {
        return (
          <div className="container mt-5">
            <div className="row">
              <div className="col-sm-12 col-lg-6 offset-lg-3">
                <h1 className="font-weight-normal mb-5">
                  Add a new recipe to our awesome recipe collection.
                </h1>
                <form onSubmit={this.onSubmit}>
                  <div className="form-group">
                    <label htmlFor="recipeName">Recipe name</label>
                    <input
                      type="text"
                      name="name"
                      id="recipeName"
                      className="form-control"
                      required
                      onChange={this.onChange}
                    />
                  </div>
                  <div className="form-group">
                    <label htmlFor="recipeIngredients">Ingredients</label>
                    <input
                      type="text"
                      name="ingredients"
                      id="recipeIngredients"
                      className="form-control"
                      required
                      onChange={this.onChange}
                    />
                    <small id="ingredientsHelp" className="form-text text-muted">
                      Separate each ingredient with a comma.
                    </small>
                  </div>
                  <label htmlFor="instruction">Preparation Instructions</label>
                  <textarea
                    className="form-control"
                    id="instruction"
                    name="instruction"
                    rows="5"
                    required
                    onChange={this.onChange}
                  />
                  <button type="submit" className="btn custom-button mt-3">
                    Create Recipe
                  </button>
                  <Link to="/recipes" className="btn btn-link mt-3">
                    Back to recipes
                  </Link>
                </form>
              </div>
            </div>
          </div>
        );
      }
    
    }
    
    export default NewRecipe;

In the render method, you have a form that contains three input fields; one for the `recipeName`, `recipeIngredients`, and `instruction`. Each input field has an `onChange` event handler that calls the `onChange` method. Also, there’s an `onSubmit` event handler on the submit button that calls the `onSubmit` method which then submits the form data.

Save and exit the file.

To access this component in the browser, update your route file with its route:

    nano app/javascript/routes/Index.jsx

Update your route file to include these highlighted lines:

~/rails\_react\_recipe/app/javascript/routes/Index.jsx

    import React from "react";
    import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
    import Home from "../components/Home";
    import Recipes from "../components/Recipes";
    import Recipe from "../components/Recipe";
    import NewRecipe from "../components/NewRecipe";
    
    export default (
      <Router>
        <Switch>
          <Route path="/" exact component={Home} />
          <Route path="/recipes" exact component={Recipes} />
          <Route path="/recipe/:id" exact component={Recipe} />
          <Route path="/recipe" exact component={NewRecipe} />
        </Switch>
      </Router>
    );

With the route in place, save and exit your file. Restart your development server and visit `http://localhost:3000` in your browser. Navigate to the recipes page and click the **Create New Recipe** button. You will find a page with a form to add recipes to your database:

![Create Recipe Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_65434/Create_Recipe_Page.png)

Enter the required recipe details and click the **Create Recipe** button; you will see the newly created recipe on the page.

In this step, you brought your food recipe application to life by adding the ability to create recipes. In the next step, you’ll add the functionality to delete recipes.

## Step 9 — Deleting Recipes

In this section, you will modify your Recipe component to be able to delete recipes.

When you click the delete button on the recipe page, the application will send a request to delete a recipe from the database. To do this, open up your `Recipe.jsx` file:

    nano app/javascript/components/Recipe.jsx

In the constructor of the `Recipe` component, bind `this` to the `deleteRecipe` method:

~/rails\_react\_recipe/app/javascript/components/Recipe.jsx

    class Recipe extends React.Component {
      constructor(props) {
        super(props);
        this.state = { recipe: { ingredients: "" } };
        this.addHtmlEntities = this.addHtmlEntities.bind(this);
        this.deleteRecipe = this.deleteRecipe.bind(this);
      }
    ...

Now add a `deleteRecipe` method to the Recipe component:

~/rails\_react\_recipe/app/javascript/components/Recipe.jsx

    class Recipe extends React.Component {
      constructor(props) {
        super(props);
        this.state = { recipe: { ingredients: "" } };
    
        this.addHtmlEntities = this.addHtmlEntities.bind(this);
        this.deleteRecipe = this.deleteRecipe.bind(this);
      }
    
      componentDidMount() {
        const {
          match: {
            params: { id }
          }
        } = this.props;
        const url = `/api/v1/show/${id}`;
        fetch(url)
          .then(response => {
            if (response.ok) {
              return response.json();
            }
            throw new Error("Network response was not ok.");
          })
          .then(response => this.setState({ recipe: response }))
          .catch(() => this.props.history.push("/recipes"));
      }
    
      addHtmlEntities(str) {
        return String(str)
          .replace(/&lt;/g, "<")
          .replace(/&gt;/g, ">");
      }
    
      deleteRecipe() {
        const {
          match: {
            params: { id }
          }
        } = this.props;
        const url = `/api/v1/destroy/${id}`;
        const token = document.querySelector('meta[name="csrf-token"]').content;
    
        fetch(url, {
          method: "DELETE",
          headers: {
            "X-CSRF-Token": token,
            "Content-Type": "application/json"
          }
        })
          .then(response => {
            if (response.ok) {
              return response.json();
            }
            throw new Error("Network response was not ok.");
          })
          .then(() => this.props.history.push("/recipes"))
          .catch(error => console.log(error.message));
      }
    
      render() {
        const { recipe } = this.state;
        let ingredientList = "No ingredients available";
    ... 

In the `deleteRecipe` method, you get the `id` of the recipe to be deleted, then build your url and grab the CSRF token. Next, you make a `DELETE` request to the `Recipes` controller to delete the recipe. If the recipe is successfully deleted, the application redirects the user to the recipes page.

To run the code in the `deleteRecipe` method whenever the delete button is clicked, pass it as the click event handler to the button. Add an `onClick` event to the delete button in the `render` method:

~/rails\_react\_recipe/app/javascript/components/Recipe.jsx

    ...
    return (
      <div className="">
        <div className="hero position-relative d-flex align-items-center justify-content-center">
          <img
            src={recipe.image}
            alt={`${recipe.name} image`}
            className="img-fluid position-absolute"
          />
          <div className="overlay bg-dark position-absolute" />
          <h1 className="display-4 position-relative text-white">
            {recipe.name}
          </h1>
        </div>
        <div className="container py-5">
          <div className="row">
            <div className="col-sm-12 col-lg-3">
              <ul className="list-group">
                <h5 className="mb-2">Ingredients</h5>
                {ingredientList}
              </ul>
            </div>
            <div className="col-sm-12 col-lg-7">
              <h5 className="mb-2">Preparation Instructions</h5>
              <div
                dangerouslySetInnerHTML={{
                  __html: `${recipeInstruction}`
                }}
              />
            </div>
            <div className="col-sm-12 col-lg-2">
              <button type="button" className="btn btn-danger" onClick={this.deleteRecipe}>
                Delete Recipe
              </button>
            </div>
          </div>
          <Link to="/recipes" className="btn btn-link">
            Back to recipes
          </Link>
        </div>
      </div>
    );
    ...

At this point in the tutorial, your complete `Recipe.jsx` file will look like this:

~/rails\_react\_recipe/app/javascript/components/Recipe.jsx

    import React from "react";
    import { Link } from "react-router-dom";
    
    class Recipe extends React.Component {
      constructor(props) {
        super(props);
        this.state = { recipe: { ingredients: "" } };
    
        this.addHtmlEntities = this.addHtmlEntities.bind(this);
        this.deleteRecipe = this.deleteRecipe.bind(this);
      }
    
      addHtmlEntities(str) {
        return String(str)
          .replace(/&lt;/g, "<")
          .replace(/&gt;/g, ">");
      }
    
      componentDidMount() {
        const {
          match: {
            params: { id }
          }
        } = this.props;
        const url = `/api/v1/show/${id}`;
        fetch(url)
          .then(response => {
            if (response.ok) {
              return response.json();
            }
            throw new Error("Network response was not ok.");
          })
          .then(response => this.setState({ recipe: response }))
          .catch(() => this.props.history.push("/recipes"));
      }
    
      deleteRecipe() {
        const {
          match: {
            params: { id }
          }
        } = this.props;
        const url = `/api/v1/destroy/${id}`;
        const token = document.querySelector('meta[name="csrf-token"]').content;
        fetch(url, {
          method: "DELETE",
          headers: {
            "X-CSRF-Token": token,
            "Content-Type": "application/json"
          }
        })
          .then(response => {
            if (response.ok) {
              return response.json();
            }
            throw new Error("Network response was not ok.");
          })
          .then(() => this.props.history.push("/recipes"))
          .catch(error => console.log(error.message));
      }
    
      render() {
        const { recipe } = this.state;
        let ingredientList = "No ingredients available";
        if (recipe.ingredients.length > 0) {
          ingredientList = recipe.ingredients
            .split(",")
            .map((ingredient, index) => (
              <li key={index} className="list-group-item">
                {ingredient}
              </li>
            ));
        }
    
        const recipeInstruction = this.addHtmlEntities(recipe.instruction);
    
        return (
          <div className="">
            <div className="hero position-relative d-flex align-items-center justify-content-center">
              <img
                src={recipe.image}
                alt={`${recipe.name} image`}
                className="img-fluid position-absolute"
              />
              <div className="overlay bg-dark position-absolute" />
              <h1 className="display-4 position-relative text-white">
                {recipe.name}
              </h1>
            </div>
            <div className="container py-5">
              <div className="row">
                <div className="col-sm-12 col-lg-3">
                  <ul className="list-group">
                    <h5 className="mb-2">Ingredients</h5>
                    {ingredientList}
                  </ul>
                </div>
                <div className="col-sm-12 col-lg-7">
                  <h5 className="mb-2">Preparation Instructions</h5>
                  <div
                    dangerouslySetInnerHTML={{
                      __html: `${recipeInstruction}`
                    }}
                  />
                </div>
                <div className="col-sm-12 col-lg-2">
                  <button type="button" className="btn btn-danger" onClick={this.deleteRecipe}>
                    Delete Recipe
                  </button>
                </div>
              </div>
              <Link to="/recipes" className="btn btn-link">
                Back to recipes
              </Link>
            </div>
          </div>
        );
      }
    }
    
    export default Recipe;

Save and exit the file.

Restart the application server and navigate to the homepage. Click the **View Recipes** button to view all existing recipes, view any individual recipe, and click the **Delete Recipe** button on the page to delete the article. You will be redirected to the recipes page, and the deleted recipe will no longer exists.

With the delete button working, you now have a fully functional recipe application!

## Conclusion

In this tutorial, you created a food recipe application with Ruby on Rails and a React frontend, using PostgreSQL as your database and Bootstrap for styling. If you’d like to run through more Ruby on Rails content, take a look at our [Securing Communications in a Three-tier Rails Application Using SSH Tunnels](securing-communications-three-tier-rails-application-using-ssh-tunnels) tutorial, or head to our [How To Code in Ruby](https://www.digitalocean.com/community/tutorial_series/how-to-code-in-ruby) series to refresh your Ruby skills. To dive deeper into React, try out our [How To Display Data from the DigitalOcean API with React](how-to-display-data-from-the-digitalocean-api-with-react) article.
