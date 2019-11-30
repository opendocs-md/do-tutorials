---
author: Kathleen Juell
date: 2019-08-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-nested-resources-for-a-ruby-on-rails-application
---

# How To Create Nested Resources for a Ruby on Rails Application

## Introduction

[Ruby on Rails](https://rubyonrails.org/) is a web application framework written in [Ruby](https://www.digitalocean.com/community/tags/ruby) that offers developers an opinionated approach to application development. Working with Rails gives developers:

- Conventions for handling things like routing, stateful data, and asset management.
- A firm grounding in the [_model-view-controller_](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller) (MCV) architectural pattern, which separates an application’s logic, located in models, from the presentation and routing of application information.

As you add complexity to your Rails applications, you will likely work with multiple models, which represent your application’s business logic and interface with your database. Adding related models means establishing meaningful relationships between them, which then affect how information gets relayed through your application’s controllers, and how it is captured and presented back to users through views.

In this tutorial, you will build on an existing Rails application that offers users facts about sharks. This application already has a model for handling shark data, but you will add a nested resource for posts about individual sharks. This will allow users to build out a wider body of thoughts and opinions about individual sharks.

## Prerequisites

To follow this tutorial, you will need:

- A local machine or development server running Ubuntu 18.04. Your development machine should have a non-root user with administrative privileges and a firewall configured with `ufw`. For instructions on how to set this up, see our [Initial Server Setup with Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04) tutorial.
- [Node.js](https://nodejs.org) and [npm](https://www.npmjs.com/) installed on your local machine or development server. This tutorial uses Node.js version 10.16.3 and npm version 6.9.0. For guidance on installing Node.js and npm on Ubuntu 18.04, follow the instructions in the “Installing Using a PPA” section of [How To Install Node.js on Ubuntu 18.04](how-to-install-node-js-on-ubuntu-18-04#installing-using-a-ppa). 
- Ruby, [rbenv](https://github.com/rbenv/rbenv), and Rails installed on your local machine or development server, following Steps 1-4 in [How To Install Ruby on Rails with rbenv on Ubuntu 18.04](how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-18-04). This tutorial uses Ruby 2.5.1, rbenv 1.1.2, and Rails 5.2.3.
- SQLite installed, and a basic shark information application created, following the directions in [How To Build a Ruby on Rails Application](how-to-build-a-ruby-on-rails-application).

## Step 1 — Scaffolding the Nested Model

Our application will take advantage of Active Record [_associations_](https://guides.rubyonrails.org/association_basics.html) to build out a relationship between `Shark` and `Post` models: posts will belong to particular sharks, and each shark can have multiple posts. Our `Shark` and `Post` models will therefore be related through [`belongs_to`](https://guides.rubyonrails.org/association_basics.html#the-belongs-to-association) and [`has_many`](https://guides.rubyonrails.org/association_basics.html#the-has-many-association) associations.

The first step to building out the application in this way will be to create a `Post` model and related resources. To do this, we can use the `rails generate scaffold` command, which will give us a model, a [database migration](https://guides.rubyonrails.org/active_record_migrations.html) to alter the database schema, a controller, a full set of views to manage standard [Create, Read, Update, and Delete](https://en.wikipedia.org/wiki/) (CRUD) operations, and templates for partials, helpers, and tests. We will need to modify these resources, but using the `scaffold` command will save us some time and energy since it generates a structure we can use as a starting point.

First, make sure that you are in the `sharkapp` directory for the Rails project that you created in the prerequisites:

    cd sharkapp

Create your `Post` resources with the following command:

    rails generate scaffold Post body:text shark:references

With `body:text`, we’re telling Rails to include a `body` field in the `posts` database table — the table that maps to the `Post` model. We’re also including the `:references` keyword, which sets up an association between the `Shark` and `Post` models. Specifically, this will ensure that a [foreign key](https://en.wikipedia.org/wiki/Foreign_key) representing each shark entry in the `sharks` database is added to the `posts` database.

Once you have run the command, you will see output confirming the resources that Rails has generated for the application. Before moving on, you can check your database migration file to look at the relationship that now exists between your models and database tables. Use the following command to look at the contents of the file, making sure to substitute the timestamp on your own migration file for what’s shown here:

    cat db/migrate/20190805132506_create_posts.rb

You will see the following output:

    Outputclass CreatePosts < ActiveRecord::Migration[5.2]
      def change
        create_table :posts do |t|
          t.text :body
          t.references :shark, foreign_key: true
    
          t.timestamps
        end
      end
    end

As you can see, the table includes a column for a shark foreign key. This key will take the form of `model_name_id` — in our case, `shark_id`.

Rails has established the relationship between the models elsewhere as well. Take a look at the newly generated `Post` model with the following command:

    cat app/models/post.rb

    Outputclass Post < ApplicationRecord
      belongs_to :shark
    end

The `belongs_to` association sets up a relationship between models in which a single instance of the declaring model belongs to a single instance of the named model. In the case of our application, this means that a single post belongs to a single shark.

In addition to setting this relationship, the `rails generate scaffold` command also created routes and views for posts, as it did for our shark resources in [Step 3](how-to-build-a-ruby-on-rails-application#step-3-%E2%80%94-scaffolding-the-application) of [How To Build a Ruby on Rails Application](how-to-build-a-ruby-on-rails-application).

This is a useful start, but we will need to configure some additional routing and solidify the Active Record association for the `Shark` model in order for the relationship between our models and routes to work as desired.

## Step 2 — Specifying Nested Routes and Associations for the Parent Model

Rails has already set the `belongs_to` association in our `Post` model, thanks to the `:references` keyword in the `rails generate scaffold` command, but in order for that relationship to function properly we will need to specify a `has_many` association in our `Shark` model as well. We will also need to make changes to the default routing that Rails gave us in order to make post resources the children of shark resources.

To add the `has_many` association to the `Shark` model, open `app/models/shark.rb` using `nano` or your favorite editor:

    nano app/models/shark.rb

Add the following line to the file to establish the relationship between sharks and posts:

~/sharkapp/app/models/shark.rb

    class Shark < ApplicationRecord
      has_many :posts
      validates :name, presence: true, uniqueness: true
      validates :facts, presence: true
    end

One thing that is worth thinking about here is what happens to posts once a particular shark is deleted. We likely do not want the posts associated with a deleted shark persisting in the database. To ensure that any posts associated with a given shark are eliminated when that shark is deleted, we can include the `dependent` option with the association.

Add the following code to the file to ensure that the `destroy` action on a given shark deletes any associated posts:

~/sharkapp/app/models/post.rb

    class Shark < ApplicationRecord
      has_many :posts , dependent: :destroy
      validates :name, presence: true, uniqueness: true
      validates :facts, presence: true
    end

Once you have finished making these changes, save and close the file. If you are using `nano`, you can do this by pressing `CTRL+X`, `Y`, then `ENTER`.

Next, open your `config/routes.rb` file to modify the relationship between your resourceful routes:

    nano config/routes.rb

Currently, the file looks like this:

~/sharkapp/config/routes.rb

    Rails.application.routes.draw do
      resources :posts 
      resources :sharks
    
      root 'sharks#index'
      # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
    end

The current code establishes an independent relationship between our routes, when what we would like to express is a [dependent relationship](https://guides.rubyonrails.org/routing.html#nested-resources) between sharks and their associated posts.

Let’s update our route declaration to make `:sharks` the parent of `:posts`. Update the code in the file to look like the following:

~/sharkapp/config/routes.rb

    Rails.application.routes.draw do
      resources :sharks do
        resources :posts
      end
      root 'sharks#index'
      # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
    end

Save and close the file when you are finished editing.

With these changes in place, you can move on to updating your `posts` controller.

## Step 3 — Updating the Posts Controller

The association between our models gives us methods that we can use to create new post instances associated with particular sharks. To use these methods, we will need to add them our posts controller.

Open the posts controller file:

    nano app/controllers/posts_controller.rb

Currently, the file looks like this:

~/sharkapp/controllers/posts\_controller.rb

    class PostsController < ApplicationController
      before_action :set_post, only: [:show, :edit, :update, :destroy]
    
      # GET /posts
      # GET /posts.json
      def index
        @posts = Post.all
      end
    
      # GET /posts/1
      # GET /posts/1.json
      def show
      end
    
      # GET /posts/new
      def new
        @post = Post.new
      end
    
      # GET /posts/1/edit
      def edit
      end
    
      # POST /posts
      # POST /posts.json
      def create
        @post = Post.new(post_params)
    
        respond_to do |format|
          if @post.save
            format.html { redirect_to @post, notice: 'Post was successfully created.' }
            format.json { render :show, status: :created, location: @post }
          else
            format.html { render :new }
            format.json { render json: @post.errors, status: :unprocessable_entity }
          end
        end
      end
    
      # PATCH/PUT /posts/1
      # PATCH/PUT /posts/1.json
      def update
        respond_to do |format|
          if @post.update(post_params)
            format.html { redirect_to @post, notice: 'Post was successfully updated.' }
            format.json { render :show, status: :ok, location: @post }
          else
            format.html { render :edit }
            format.json { render json: @post.errors, status: :unprocessable_entity }
          end
        end
      end
    
      # DELETE /posts/1
      # DELETE /posts/1.json
      def destroy
        @post.destroy
        respond_to do |format|
          format.html { redirect_to posts_url, notice: 'Post was successfully destroyed.' }
          format.json { head :no_content }
        end
      end
    
      private
        # Use callbacks to share common setup or constraints between actions.
        def set_post
          @post = Post.find(params[:id])
        end
    
        # Never trust parameters from the scary internet, only allow the white list through.
        def post_params
          params.require(:post).permit(:body, :shark_id)
        end
    end

Like our sharks controller, this controller’s methods work with instances of the associated `Post` class. For example, the `new` method creates a new instance of the `Post` class, the `index` method grabs all instances of the class, and the `set_post` method uses `find` and `params` to select a particular post by `id`. If, however, we want our post instances to be associated with particular shark instances, then we will need to modify this code, since the `Post` class is currently operating as an independent entity.

Our modifications will make use of two things:

- The methods that became available to us when we added the `belongs_to` and `has_many` associations to our models. Specifically, we now have access to the [`build` method](https://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#method-i-has_many) thanks to the `has_many` association we defined in our `Shark` model. This method will allow us to create a collection of post objects associated with a particular shark object, using the `shark_id` foreign key that exists in our `posts` database.
- The routes and routing helpers that became available when we created a nested `posts` route. For a full list of example routes that become available when you create nested relationships between resources, see the [Rails documentation](https://guides.rubyonrails.org/routing.html#nested-resources). For now, it will be enough for us to know that for each specific shark — say `sharks/1` — there will be an associated route for posts related to that shark: `sharks/1/posts`. There will also be routing helpers like `shark_posts_path(@shark)` and `edit_sharks_posts_path(@shark)` that refer to these nested routes.

In the file, we’ll begin by writing a method, `get_shark`, that will run before each action in the controller. This method will create a local `@shark` instance variable by finding a shark instance by `shark_id`. With this variable available to us in the file, it will be possible to relate posts to a specific shark in the other methods.

Above the other `private` methods at the bottom of the file, add the following method:

~/sharkapp/controllers/posts\_controller.rb

    . . . 
    private
      def get_shark
        @shark = Shark.find(params[:shark_id])
      end
      # Use callbacks to share common setup or constraints between actions.
    . . . 

Next, add the corresponding filter to the **top** of the file, before the existing filter:

~/sharkapp/controllers/posts\_controller.rb

    class PostsController < ApplicationController
      before_action :get_shark

This will ensure that `get_shark` runs before each action defined in the file.

Next, you can use this `@shark` instance to rewrite the `index` method. Instead of grabbing all instances of the `Post` class, we want this method to return all post instances associated with a particular shark instance.

Modify the `index` method to look like this:

~/sharkapp/controllers/posts\_controller.rb

    . . .
      def index
        @posts = @shark.posts
      end
    . . .

The `new` method will need a similar revision, since we want a new post instance to be associated with a particular shark. To achieve this, we can make use of the `build` method, along with our local `@shark` instance variable.

Change the `new` method to look like this:

~/sharkapp/controllers/posts\_controller.rb

    . . . 
      def new
        @post = @shark.posts.build
      end
    . . . 

This method creates a post object that’s associated with the specific shark instance from the `get_shark` method.

Next, we’ll address the method that’s most closely tied to `new`: `create`. The `create` method does two things: it builds a new post instance using the parameters that users have entered into the `new` form, and, if there are no errors, it saves that instance and uses a route helper to redirect users to where they can see the new post. In the case of errors, it renders the `new` template again.

Update the `create` method to look like this:

~/sharkapp/controllers/posts\_controller.rb

      def create
        @post = @shark.posts.build(post_params)
    
            respond_to do |format|
             if @post.save  
                format.html { redirect_to shark_posts_path(@shark), notice: 'Post was successfully created.' }
                format.json { render :show, status: :created, location: @post }
             else
                format.html { render :new }
                format.json { render json: @post.errors, status: :unprocessable_entity }
          end
        end
      end

Next, take a look at the `update` method. This method uses a `@post` instance variable, which is not explicitly set in the method itself. Where does this variable come from?

Take a look at the filters at the top of the file. The second, auto-generated `before_action` filter provides an answer:

~/sharkapp/controllers/posts\_controller.rb

    class PostsController < ApplicationController
      before_action :get_shark
      before_action :set_post, only: [:show, :edit, :update, :destroy]
      . . .

The `update` method (like `show`, `edit`, and `destroy`) takes a `@post` variable from the `set_post` method. That method, listed under the `get_shark` method with our other `private` methods, currently looks like this:

~/sharkapp/controllers/posts\_controller.rb

    . . . 
    private
    . . . 
      def set_post
        @post = Post.find(params[:id])
      end
    . . .

In keeping with the methods we’ve used elsewhere in the file, we will need to modify this method so that `@post` refers to a particular instance in the **collection** of posts that’s associated with a particular shark. Keep the `build` method in mind here — thanks to the associations between our models, and the methods (like `build`) that are available to us by virtue of those associations, each of our post instances is part of a collection of objects that’s associated with a particular shark. So it makes sense that when querying for a particular post, we would query the collection of posts associated with a particular shark.

Update `set_post` to look like this:

~/sharkapp/controllers/posts\_controller.rb

    . . . 
    private
    . . . 
      def set_post
        @post = @shark.posts.find(params[:id])
      end
    . . .

Instead of finding a particular instance of the entire `Post` class by `id`, we instead search for a matching `id` in the collection of posts associated with a particular shark.

With that method updated, we can look at the `update` and `destroy` methods.

The `update` method makes use of the `@post` instance variable from `set_post`, and uses it with the `post_params` that the user has entered in the `edit` form. In the case of success, we want Rails to send the user back to the `index` view of the posts associated with a particular shark. In the case of errors, Rails will render the `edit` template again.

In this case, the only change we will need to make is to the `redirect_to` statement, to handle successful updates. Update it to redirect to `shark_post_path(@shark)`, which will redirect to the `index` view of the selected shark’s posts:

~/sharkapp/controllers/posts\_controller.rb

    . . . 
      def update
        respond_to do |format|
          if @post.update(post_params)
            format.html { redirect_to shark_post_path(@shark), notice: 'Post was successfully updated.' }
            format.json { render :show, status: :ok, location: @post }
          else
            format.html { render :edit }
            format.json { render json: @post.errors, status: :unprocessable_entity }
          end
        end
      end
    . . .

Next, we will make a similar change to the `destroy` method. Update the `redirect_to` method to redirect requests to `shark_posts_path(@shark)` in the case of success:

~/sharkapp/controllers/posts\_controller.rb

    . . . 
      def destroy
        @post.destroy
         respond_to do |format|
          format.html { redirect_to shark_posts_path(@shark), notice: 'Post was successfully destroyed.' }
          format.json { head :no_content }
        end
      end
    . . .

This is the last change we will make. You now have a posts controller file that looks like this:

~/sharkapp/controllers/posts\_controller.rb

    class PostsController < ApplicationController
      before_action :get_shark
      before_action :set_post, only: [:show, :edit, :update, :destroy]
    
      # GET /posts
      # GET /posts.json
      def index
        @posts = @shark.posts
      end
    
      # GET /posts/1
      # GET /posts/1.json
      def show
      end
    
      # GET /posts/new
      def new
        @post = @shark.posts.build
      end
    
      # GET /posts/1/edit
      def edit
      end
    
      # POST /posts
      # POST /posts.json
      def create
        @post = @shark.posts.build(post_params)
    
            respond_to do |format|
             if @post.save  
                format.html { redirect_to shark_posts_path(@shark), notice: 'Post was successfully created.' }
                format.json { render :show, status: :created, location: @post }
             else
                format.html { render :new }
                format.json { render json: @post.errors, status: :unprocessable_entity }
          end
        end
      end
    
      # PATCH/PUT /posts/1
      # PATCH/PUT /posts/1.json
      def update
        respond_to do |format|
          if @post.update(post_params)
            format.html { redirect_to shark_post_path(@shark), notice: 'Post was successfully updated.' }
            format.json { render :show, status: :ok, location: @post }
          else
            format.html { render :edit }
            format.json { render json: @post.errors, status: :unprocessable_entity }
          end
        end
      end
    
      # DELETE /posts/1
      # DELETE /posts/1.json
      def destroy
        @post.destroy
        respond_to do |format|
          format.html { redirect_to shark_posts_path(@shark), notice: 'Post was successfully destroyed.' }
          format.json { head :no_content }
        end
      end
    
      private
    
       def get_shark
         @shark = Shark.find(params[:shark_id])
       end
        # Use callbacks to share common setup or constraints between actions.
        def set_post
          @post = @shark.posts.find(params[:id])
        end
    
        # Never trust parameters from the scary internet, only allow the white list through.
        def post_params
          params.require(:post).permit(:body, :shark_id)
        end
    end

The controller manages how information is passed from the view templates to the database and vice versa. Our controller now reflects the relationship between our `Shark` and `Post` models, in which posts are associated with particular sharks. We can move on to modifying the view templates themselves, which are where users will pass in and modify post information about particular sharks.

## Step 4 — Modifying Views

Our view template revisions will involve changing the templates that relate to posts, and also modifying our sharks `show` view, since we want users to see the posts associated with particular sharks.

Let’s start with the foundational template for our posts: the `form` partial that is reused across multiple post templates. Open that form now:

    nano app/views/posts/_form.html.erb

Rather than passing only the `post` model to the `form_with` form helper, we will pass both the `shark` and `post` models, with `post` set as a child resource.

Change the first line of the file to look like this, reflecting the relationship between our shark and post resources:

~/sharkapp/views/posts/\_form.html.erb

    <%= form_with(model: [@shark, post], local: true) do |form| %>
    . . . 

Next, **delete** the section that lists the `shark_id` of the related shark, since this is not essential information in the view.

The finished form, complete with our edits to the first line and without the deleted `shark_id` section, will look like this:

~/sharkapp/views/posts/\_form.html.erb

    <%= form_with(model: [@shark, post], local: true) do |form| %>
      <% if post.errors.any? %>
        <div id="error_explanation">
          <h2><%= pluralize(post.errors.count, "error") %> prohibited this post from being saved:</h2>
    
          <ul>
          <% post.errors.full_messages.each do |message| %>
            <li><%= message %></li>
          <% end %>
          </ul>
        </div>
      <% end %>
    
      <div class="field">
        <%= form.label :body %>
        <%= form.text_area :body %>
      </div>
    
      <div class="actions">
        <%= form.submit %>
      </div>
    <% end %>

Save and close the file when you are finished editing.

Next, open the `index` view, which will show the posts associated with a particular shark:

    nano app/views/posts/index.html.erb

Thanks to the `rails generate scaffold` command, Rails has generated the better part of the template, complete with a table that shows the `body` field of each post and its associated `shark`.

Much like the other code we have already modified, however, this template treats posts as independent entities, when we would like to make use of the associations between our models and the collections and helper methods that these associations give us.

In the body of the table, make the following updates:

First, update `post.shark` to `post.shark.name`, so that the table will include the name field of the associated shark, rather than identifying information about the shark object itself:

~/sharkapp/app/views/posts/index.html.erb

    . . . 
      <tbody>
        <% @posts.each do |post| %>
          <tr>
            <td><%= post.body %></td>
            <td><%= post.shark.name %></td>
    . . . 

Next, change the `Show` redirect to direct users to the `show` view for the associated shark, since they will most likely want a way to navigate back to the original shark. We can make use of the `@shark` instance variable that we set in the controller here, since Rails makes instance variables created in the controller available to all views. We’ll also change the text for the link from `Show` to `Show Shark`, so that users will better understand its function.

Update the this line to the following:

~/sharkapp/app/views/posts/index.html.erb

    . . . 
      <tbody>
        <% @posts.each do |post| %>
          <tr>
            <td><%= post.body %></td>
            <td><%= post.shark.name %></td>
            <td><%= link_to 'Show Shark', [@shark] %></td>

In the next line, we want to ensure that users are routed the right nested path when they go to edit a post. This means that rather than being directed to `posts/post_id/edit`, users will be directed to `sharks/shark_id/posts/post_id/edit`. To do this, we’ll use the `shark_post_path` routing helper and our models, which Rails will treat as URLs. We’ll also update the link text to make its function clearer.

Update the `Edit` line to look like the following:

~/sharkapp/app/views/posts/index.html.erb

    . . . 
      <tbody>
        <% @posts.each do |post| %>
          <tr>
            <td><%= post.body %></td>
            <td><%= post.shark.name %></td>
            <td><%= link_to 'Show Shark', [@shark] %></td>
            <td><%= link_to 'Edit Post', edit_shark_post_path(@shark, post) %></td>

Next, let’s add a similar change to the `Destroy` link, updating its function in the string, and adding our `shark` and `post` resources:

~/sharkapp/app/views/posts/index.html.erb

    . . . 
      <tbody>
        <% @posts.each do |post| %>
          <tr>
            <td><%= post.body %></td>
            <td><%= post.shark.name %></td>
            <td><%= link_to 'Show Shark', [@shark] %></td>
            <td><%= link_to 'Edit Post', edit_shark_post_path(@shark, post) %></td>
            <td><%= link_to 'Destroy Post', [@shark, post], method: :delete, data: { confirm: 'Are you sure?' } %></td>

Finally, at the bottom of the form, we will want to update the `New Post` path to take users to the appropriate nested path when they want to create a new post. Update the last line of the file to make use of the `new_shark_post_path(@shark)` routing helper:

~/sharkapp/app/views/posts/index.html.erb

    . . . 
    <%= link_to 'New Post', new_shark_post_path(@shark) %>

The finished file will look like this:

~/sharkapp/app/views/posts/index.html.erb

    <p id="notice"><%= notice %></p>
    
    <h1>Posts</h1>
    
    <table>
      <thead>
        <tr>
          <th>Body</th>
          <th>Shark</th>
          <th colspan="3"></th>
        </tr>
      </thead>
    
      <tbody>
        <% @posts.each do |post| %>
          <tr>
            <td><%= post.body %></td>
            <td><%= post.shark.name %></td>
            <td><%= link_to 'Show Shark', [@shark] %></td>
            <td><%= link_to 'Edit Post', edit_shark_post_path(@shark, post) %></td>
            <td><%= link_to 'Destroy Post', [@shark, post], method: :delete, data: { confirm: 'Are you sure?' } %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    
    <br>
    
    <%= link_to 'New Post', new_shark_post_path(@shark) %>

Save and close the file when you are finished editing.

The other edits we will make to post views won’t be as numerous, since our other views use the `form` partial we have already edited. However, we will want to update the `link_to` references in the other post templates to reflect the changes we have made to our `form` partial.

Open `app/views/posts/new.html.erb`:

    nano app/views/posts/new.html.erb

Update the `link_to` reference at the bottom of the file to make use of the `shark_posts_path(@shark)` helper:

~/sharkapp/app/views/posts/new.html.erb

    . . . 
    <%= link_to 'Back', shark_posts_path(@shark) %>

Save and close the file when you are finished making this change.

Next, open the `edit` template:

    nano app/views/posts/edit.html.erb

In addition to the `Back` path, we’ll update `Show` to reflect our nested resources. Change the last two lines of the file to look like this:

~/sharkapp/app/views/posts/edit.html.erb

    . . . 
    <%= link_to 'Show', [@shark, @post] %> |
    <%= link_to 'Back', shark_posts_path(@shark) %>

Save and close the file.

Next, open the `show` template:

    nano app/views/posts/show.html.erb

Make the following edits to the `Edit` and `Back` paths at the bottom of the file:

~/sharkapp/app/views/posts/edit.html.erb

    . . .
    <%= link_to 'Edit', edit_shark_post_path(@shark, @post) %> |
    <%= link_to 'Back', shark_posts_path(@shark) %>

Save and close the file when you are finished.

As a final step, we will want to update the `show` view for our sharks so that posts are visible for individual sharks. Open that file now:

    nano app/views/sharks/show.html.erb

Our edits here will include adding a `Posts` section to the form and an `Add Post` link at the bottom of the file.

Below the `Facts` for a given shark, we will add a new section that iterates through each instance in the collection of posts associated with this shark, outputting the `body` of each post.

Add the following code below the `Facts` section of the form, and above the redirects at the bottom of the file:

~/sharkapp/app/views/sharks/show.html.erb

    . . .
    <p>
      <strong>Facts:</strong>
      <%= @shark.facts %>
    </p>
    
    <h2>Posts</h2>
    <% for post in @shark.posts %>
        <ul>
          <li><%= post.body %></li>
      </ul>
    <% end %>
    
    <%= link_to 'Edit', edit_shark_path(@shark) %> |
    . . . 

Next, add a new redirect to allow users to add a new post for this particular shark:

~/sharkapp/app/views/sharks/show.html.erb

    . . .
    <%= link_to 'Edit', edit_shark_path(@shark) %> |
    <%= link_to 'Add Post', shark_posts_path(@shark) %> |
    <%= link_to 'Back', sharks_path %>

Save and close the file when you are finished editing.

You have now made changes to your application’s models, controllers, and views to ensure that posts are always associated with a particular shark. As a final step, we can add some validations to our `Post` model to guarantee consistency in the data that’s saved to the database.

## Step 5 — Adding Validations and Testing the Application

In [Step 5](how-to-build-a-ruby-on-rails-application#step-5-%E2%80%94-adding-validations) of [How To Build a Ruby on Rails Application](how-to-build-a-ruby-on-rails-application), you added validations to your `Shark` model to ensure uniformity and consistency in the data that gets saved to the `sharks` database. We’ll now take a similar step to ensure guarantees for the `posts` database as well.

Open the file where your `Post` model is defined:

    nano app/models/post.rb

Here, we want to ensure that posts are not blank and that they don’t duplicate content other users may have posted. To achieve this, add the following line to the file:

~/sharkapp/app/models/post.rb

    class Post < ApplicationRecord
      belongs_to :shark
      validates :body, presence: true, uniqueness: true
    end

Save and close the file when you are finished editing.

With this last change in place, you are ready to run your migrations and test the application.

First, run your migrations:

    rails db:migrate

Next, start your server. If you’re working locally, you can do so by running:

    rails s

If you are working on a development server, run the following command instead:

    rails s --binding=your_server_ip

Navigate to your application’s root at `http://localhost:3000` or `http://your_server_ip:3000`.

The prerequisite Rails project tutorial walked you through adding and editing a **Great White** shark entry. If you have not added any further sharks, the application landing page will look like this:

![Shark App Landing Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rails_nested_resource/shark_post_landing_2.png)

Click on **Show** next to the **Great White** ’s name. This will take you to the `show` view for this shark. You will see the name of the shark and its facts, and a **Posts** header with no content. Let’s add a post to populate this part of the form.

Click on **Add Post** below the **Posts** header. This will bring you to the post `index` view, where you will have the chance to select **New Post** :

![Post Index View](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rails_nested_resource/new_post_landing.png)

Thanks to the authentication mechanisms you put in place in [Step 6](how-to-build-a-ruby-on-rails-application#step-6--%E2%80%94-adding-authentication) of [How To Build a Ruby on Rails Application](how-to-build-a-ruby-on-rails-application), you may be asked to authenticate with the username and password you created in that Step, depending on whether or not you have created a new session.

Click on **New Post** , which will bring you to your post `new` template:

![New Post](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rails_nested_resource/new_post_form.png)

In the **Body** field, type, “These sharks are scary!”

![New Shark Post](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rails_nested_resource/new_shark_post_2.png)

Click on **Create Post**. You will be redirected to the `index` view for all posts that belong to this shark:

![Post Success](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rails_nested_resource/post_success.png)

With our post resources working, we can now test our data validations to ensure that only desired data gets saved to the database.

From the `index` view, click on **New Post**. In the **Body** field of the new form, try entering “These sharks are scary!” again:

![Repeat Shark Post](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rails_nested_resource/new_shark_post_2.png)

Click on **Create Post**. You will see the following error:

![Unique Post Error](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rails_nested_resource/post_unique_error.png)

Click on **Back** to return to the main posts page.

To test our other validation, click on **New Post** again. Leave the post blank and click **Create Post**. You will see the following error:

![Blank Post Error](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rails_nested_resource/post_blank_error.png)

With your nested resources and validations working properly, you now have a working Rails application that you can use as a starting point for further development.

## Conclusion

With your Rails application in place, you can now work on things like styling and developing other front-end components. If you would like to learn more about routing and nested resources, the [Rails documentation](https://edgeguides.rubyonrails.org/routing.html) is a great place to start.

To learn more about integrating front-end frameworks with your application, take a look at [How To Set Up a Ruby on Rails Project with a React Frontend](how-to-set-up-a-ruby-on-rails-project-with-a-react-frontend).
