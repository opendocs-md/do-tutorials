---
author: Oluyemi Olususi
date: 2019-05-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-build-a-customer-list-management-app-with-react-and-typescript
---

# How To Build a Customer List Management App with React and TypeScript

_The author selected the [Tech Education Fund](https://www.brightfunds.org/funds/tech-education) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[TypeScript](https://www.typescriptlang.org/) has brought a lot of improvement into how [JavaScript](https://www.javascript.com/) developers structure and write code for apps, especially web applications. Defined as a superset of JavaScript, TypeScript behaves identically to JavaScript but with extra features designed to help developers build larger and more complex programs with fewer or no bugs. TypeScript is increasingly gaining popularity; adopted by major companies like Google for the Angular web framework. The [Nest.js](https://nestjs.com/) back-end framework was also built with TypeScript.

One of the ways to improve productivity as a developer is the ability to implement new features as quickly as possible without any concern over breaking the existing app in production. To achieve this, writing statically typed code is a style adopted by many seasoned developers. Statically typed programming languages like TypeScript enforce an association for every variable with a data type; such as a string, integer, boolean, and so on. One of the major benefits of using a statically typed programming language is that type checking is completed at compile time, therefore developers can see errors in their code at a very early stage.

[React](https://reactjs.org/) is an open-source JavaScript library, which developers use to create high-end user interfaces for scalable web applications. The great performance and dynamic user interfaces built with React for single-page applications make it a popular choice among developers.

In this tutorial, you will create a customer list management application with a separate REST API backend and a frontend built with React and TypeScript. You will build the backend using a fake REST API named [`json-server`](https://github.com/typicode/json-server). You’ll use it to quickly set up a CRUD (Create, Read, Update, and Delete) backend. Consequently you can focus on handling the front-end logic of an application using React and TypeScript.

## Prerequisites

To complete this tutorial, you will need:

- A local installation of [Node.js](https://nodejs.org/en/) (at least v6) and [`npm`](https://www.npmjs.com/) (at least v5.2). Node.js is a JavaScript run-time environment that allows you to run your code outside of the browser. It comes with a pre-installed package manager called `npm`, which lets you install and update packages. To install these on macOS or Ubuntu 18.04, follow the steps in [How to Install Node.js and Create a Local Development Environment on macOS](how-to-install-node-js-and-create-a-local-development-environment-on-macos) or the “Installing Using a PPA” section of [How To Install Node.js on Ubuntu 18.04](how-to-install-node-js-on-ubuntu-18-04).

- A local installation of Yarn; [follow these steps](https://yarnpkg.com/en/docs/install#mac-stable) to install Yarn on your operating system.

- A basic understanding of TypeScript and [JavaScript](https://www.digitalocean.com/community/tutorial_series/how-to-code-in-javascript).

- A text editor installed; such as [Visual Studio Code](https://code.visualstudio.com/), [Atom](https://atom.io/), or [Sublime Text](https://www.sublimetext.com/).

## Step 1 — Installing TypeScript and Creating the React Application

In this step, you will install the TypeScript package globally on your machine by using the Node Package Manager (`npm`). After that, you will also install React and its dependencies, and check that your React app is working by running the development server.

To begin, open a terminal and run the following command to install TypeScript:

    npm install -g typescript

Once the installation process is complete, execute the following command to check your installation of TypeScript:

    tsc -v

You will see the current version installed on your machine:

    OutputVersion 3.4.5

Next, you will install the React application by using the [`create-react-app`](https://github.com/facebook/create-react-app) tool to set up the application with a single command. You’ll use the `npx` command, which is a package runner tool that comes with `npm` 5.2+. The `create-react-app` tool has built-in support for working with TypeScript without any extra configuration required. Run the following command to create and install a new React application named `typescript-react-app`:

    npx create-react-app typescript-react-app --typescript

The preceding command will create a new React application with the name `typescript-react-app`. The `--typescript` flag will set the default filetype for React components to `.tsx`.

Before you complete this section, the application will require moving from one port to another. To do that, you will need to install a routing library for your React application named [React Router](https://www.npmjs.com/package/react-router) and its corresponding TypeScript definitions. You will use `yarn` to install the library and other packages for this project. This is because `yarn` is faster, especially for installing dependencies for a React application. Move into the newly created project folder and then install React Router with the following command:

    cd typescript-react-app
    yarn add react-router-dom

You now have the React Router package, which will provide the routing functionality within your project. Next, run the following command to install the TypeScript definitions for React Router:

    yarn add @types/react-router-dom

Now you’ll install [`axios`](https://github.com/axios/axios), which is a promised-based HTTP client for browsers, to help with the process of performing HTTP requests from the different components that you will create within the application:

    yarn add axios

Once the installation process is complete, start the development server with:

    yarn start

Your application will be running on `http://localhost:3000`.

![React application homepage](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/reacttypescript/step1.png)

You have successfully installed TypeScript, created a new React application, and installed React Router in order to help with navigating from one page of the application to another. In the next section, you will set up the back-end server for the application.

## Step 2 — Creating a JSON Server

In this step, you’ll create a mock server that your React application can quickly connect with, as well as use its resources. It is important to note that this back-end service is not suitable for an application in production. You can use Nest.js, Express, or any other back-end technology to build a RESTful API in production. `json-server` is a useful tool whenever you need to create a prototype and mock a back-end server.

You can use either `npm` or `yarn` to install `json-server` on your machine. This will make it available from any directory of your project whenever you might need to make use of it. Open a new terminal window and run this command to install `json-server` while you are still within the project directory:

    yarn global add json-server

Next, you will create a JSON file that will contain the data that will be exposed by the REST API. For the objects specified in this file (which you’ll create), a CRUD endpoint will be generated automatically. To begin, create a new folder named `server` and then move into it:

    mkdir server
    cd server

Now, use `nano` to create and open a new file named `db.json`:

    nano db.json

Add the following content to the file:

/server/db.json

    {
        "customers": [
            {
                "id": 1,
                "first_name": "Customer_1",
                "last_name": "Customer_11",
                "email": "customer1@mail.com",
                "phone": "00000000000",
                "address": "Customer_1 Address",
                "description": "Customer_1 description"
            },
            {
                "id": 2,
                "first_name": "Customer_2",
                "last_name": "Customer_2",
                "email": "customer2@mail.com",
                "phone": "00000000000",
                "address": "Customer_2 Adress",
                "description": "Customer_2 Description"
            }
        ]
    }

The JSON structure consists of a customer object, which has two datasets assigned. Each customer consists of seven properties: `id`, `description`, `first_name`, `last_name`, `email`, `phone`, and `address`.

Save and exit the file.

By default, the `json-server` runs on port `3000`—this is the same port on which your React application runs. To avoid conflict, you can change the default port for the `json-server`. To do that, move to the root directory of the application:

    cd ~/typescript-react-app

Open the application with your preferred text editor and create a new file named `json-server.json`:

    nano json-server.json

Now insert the following to update the port number:

/json-server.json

    {
        "port": 5000
    }

This will act as the configuration file for the `json-server` and it will ensure that the server runs on the port specified in it at all times.

Save and exit the file.

To run the server, use the following command:

    json-server --watch server/db.json

This will start the `json-server` on port `5000`. If you navigate to `http://localhost:5000/customers` in your browser, you will see the server showing your customer list.

![Customer list shown by json-server](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/reacttypescript/step2.png)

To streamline the process of running the `json-server`, you can update `package.json` with a new property named `server` to the `scripts` object as shown here:

/package.json

    {
    ...
      "scripts": {
        "start": "react-scripts start",
        "build": "react-scripts build",
        "test": "react-scripts test",
        "eject": "react-scripts eject",
        "server": "json-server --watch server/db.json"
      },
    ...
    }

Save and exit the file.

Now anytime you wish to start the `json-server`, all you have to do is run `yarn server` from the terminal.

You’ve created a simple REST API that you will use as the back-end server for this application. You also created a customer JSON object that will be used as the default data for the REST API. Lastly, you configured an alternative port for the back-end server powered by `json-server`. Next, you will build reusable components for your application.

## Step 3 — Creating Reusable Components

In this section, you will create the required React components for the application. This will include components to create, display, and edit the details of a particular customer in the database respectively. You’ll also build some of the TypeScript interfaces for your application.

To begin, move back to the terminal where you have the React application running and stop the development server with `CTRL + C`. Next, navigate to the `./src/` folder:

    cd ./src/

Then, create a new folder named `components` inside of it and move into the new folder:

    mkdir components
    cd components

Within the newly created folder, create a `customer` folder and then move into it:

    mkdir customer
    cd customer

Now create two new files named `Create.tsx` and `Edit.tsx`:

    touch Create.tsx Edit.tsx

These files are React reusable components that will render the forms and hold all the business logic for creating and editing the details of a customer respectively.

Open the `Create.tsx` file in your text editor and add the following code:

/src/components/customer/Create.tsx

    import * as React from 'react';
    import axios from 'axios';
    import { RouteComponentProps, withRouter } from 'react-router-dom';
    
    export interface IValues {
        first_name: string,
        last_name: string,
        email: string,
        phone: string,
        address: string,
        description: string,
    }
    export interface IFormState {
        [key: string]: any;
        values: IValues[];
        submitSuccess: boolean;
        loading: boolean;
    }
    

Here you’ve imported `React`, `axios`, and other required components necessary for routing from the React Router package. After that you created two new interfaces named `IValues` and `IFormState`. [TypeScript _interfaces_](https://www.typescriptlang.org/docs/handbook/interfaces.html) help to define the specific type of values that should be passed to an object and enforce consistency throughout an application. This ensures that bugs are less likely to appear in your program.

Next, you will build a `Create` component that extends `React.Component`. Add the following code to the `Create.tsx` file immediately after the `IFormState` interface:

/src/components/customer/Create.tsx

    ...
    class Create extends React.Component<RouteComponentProps, IFormState> {
        constructor(props: RouteComponentProps) {
            super(props);
            this.state = {
                first_name: '',
                last_name: '',
                email: '',
                phone: '',
                address: '',
                description: '',
                values: [],
                loading: false,
                submitSuccess: false,
            }
        }
    }
    export default withRouter(Create)

Here you’ve defined a React component in Typescript. In this case, the `Create` class component accepts `props` (short for “properties”) of type `RouteComponentProps` and uses a state of type `IFormState`. Then, inside the constructor, you initialized the `state` object and defined all the variables that will represent the rendered values for a customer.

Next, add these methods within the `Create` class component, just after the constructor. You’ll use these methods to process customer forms and handle all changes in the input fields:

/src/components/customer/Create.tsx

    ...
              values: [],
              loading: false,
              submitSuccess: false,
          }
      }
    
      private processFormSubmission = (e: React.FormEvent<HTMLFormElement>): void => {
              e.preventDefault();
              this.setState({ loading: true });
              const formData = {
                  first_name: this.state.first_name,
                  last_name: this.state.last_name,
                  email: this.state.email,
                  phone: this.state.phone,
                  address: this.state.address,
                  description: this.state.description,
              }
              this.setState({ submitSuccess: true, values: [...this.state.values, formData], loading: false });
              axios.post(`http://localhost:5000/customers`, formData).then(data => [
                  setTimeout(() => {
                      this.props.history.push('/');
                  }, 1500)
              ]);
          }
    
          private handleInputChanges = (e: React.FormEvent<HTMLInputElement>) => {
              e.preventDefault();
              this.setState({
                  [e.currentTarget.name]: e.currentTarget.value,
          })
      }
    
    ...
    export default withRouter(Create)
    ...

The `processFormSubmission()` method receives the details of the customer from the application state and posts it to the database using `axios`. The `handleInputChanges()` uses `React.FormEvent` to obtain the values of all input fields and calls `this.setState()` to update the state of the application.

Next, add the `render()` method within the `Create` class component immediately after the `handleInputchanges()` method. This `render()` method will display the form to create a new customer in the application:

/src/components/customer/Create.tsx

    ...
      public render() {
          const { submitSuccess, loading } = this.state;
          return (
              <div>
                  <div className={"col-md-12 form-wrapper"}>
                      <h2> Create Post </h2>
                      {!submitSuccess && (
                          <div className="alert alert-info" role="alert">
                              Fill the form below to create a new post
                      </div>
                      )}
                      {submitSuccess && (
                          <div className="alert alert-info" role="alert">
                              The form was successfully submitted!
                              </div>
                      )}
                      <form id={"create-post-form"} onSubmit={this.processFormSubmission} noValidate={true}>
                          <div className="form-group col-md-12">
                              <label htmlFor="first_name"> First Name </label>
                              <input type="text" id="first_name" onChange={(e) => this.handleInputChanges(e)} name="first_name" className="form-control" placeholder="Enter customer's first name" />
                          </div>
                          <div className="form-group col-md-12">
                              <label htmlFor="last_name"> Last Name </label>
                              <input type="text" id="last_name" onChange={(e) => this.handleInputChanges(e)} name="last_name" className="form-control" placeholder="Enter customer's last name" />
                          </div>
                          <div className="form-group col-md-12">
                              <label htmlFor="email"> Email </label>
                              <input type="email" id="email" onChange={(e) => this.handleInputChanges(e)} name="email" className="form-control" placeholder="Enter customer's email address" />
                          </div>
                          <div className="form-group col-md-12">
                              <label htmlFor="phone"> Phone </label>
                              <input type="text" id="phone" onChange={(e) => this.handleInputChanges(e)} name="phone" className="form-control" placeholder="Enter customer's phone number" />
                          </div>
                          <div className="form-group col-md-12">
                              <label htmlFor="address"> Address </label>
                              <input type="text" id="address" onChange={(e) => this.handleInputChanges(e)} name="address" className="form-control" placeholder="Enter customer's address" />
                          </div>
                          <div className="form-group col-md-12">
                              <label htmlFor="description"> Description </label>
                              <input type="text" id="description" onChange={(e) => this.handleInputChanges(e)} name="description" className="form-control" placeholder="Enter Description" />
                          </div>
                          <div className="form-group col-md-4 pull-right">
                              <button className="btn btn-success" type="submit">
                                  Create Customer
                              </button>
                              {loading &&
                                  <span className="fa fa-circle-o-notch fa-spin" />
                              }
                          </div>
                      </form>
                  </div>
              </div>
          )
      }
    ...

Here, you created a form with the input fields to hold the values of the `first_name`, `last_name`, `email`, `phone`, `address`, and `description` of a customer. Each of the input fields have a method `handleInputChanges()` that runs on every keystroke, updating the React `state` with the value it obtains from the input field. Furthermore, depending on the state of the application, a boolean variable named `submitSuccess` will control the message that the application will display before and after creating a new customer.

You can see the complete code for this file in this [GitHub repository](https://github.com/yemiwebby/typescript-react-customer-app/blob/master/src/components/customer/Create.tsx).

Save and exit `Create.tsx`.

Now that you have added the appropriate logic to the `Create` component file for the application, you’ll proceed to add contents for the `Edit` component file.

Open your `Edit.tsx` file within the `customer` folder, and start by adding the following content to import `React`, `axios`, and also define TypeScript interfaces:

/src/components/customer/Edit.tsx

    import * as React from 'react';
    import { RouteComponentProps, withRouter } from 'react-router-dom';
    import axios from 'axios';
    
    export interface IValues {
        [key: string]: any;
    }
    export interface IFormState {
        id: number,
        customer: any;
        values: IValues[];
        submitSuccess: boolean;
        loading: boolean;
    }

Similarly to the `Create` component, you import the required modules and create `IValues` and `IFormState` interfaces respectively. The `IValues` interface defines the data type for the input fields’ values, while you’ll use `IFormState` to declare the expected type for the state object of the application.

Next, create the `EditCustomer` class component directly after the `IFormState` interface block as shown here:

/src/components/customer/Edit.tsx

    ...
    class EditCustomer extends React.Component<RouteComponentProps<any>, IFormState> {
        constructor(props: RouteComponentProps) {
            super(props);
            this.state = {
                id: this.props.match.params.id,
                customer: {},
                values: [],
                loading: false,
                submitSuccess: false,
            }
        }
    }
    export default withRouter(EditCustomer)

This component takes the `RouteComponentProps<any>` and an interface of `IFormState` as a parameter. You use the addition of `<any>` to the `RouteComponentProps` because whenever React Router parses path parameters, it doesn’t do any type conversion to ascertain whether the type of the data is `number` or `string`. Since you’re expecting a parameter for `uniqueId` of a customer, it is safer to use `any`.

Now add the following methods within the component:

/src/components/customer/Edit.tsx

    ...
        public componentDidMount(): void {
            axios.get(`http://localhost:5000/customers/${this.state.id}`).then(data => {
                this.setState({ customer: data.data });
            })
        }
    
        private processFormSubmission = async (e: React.FormEvent<HTMLFormElement>): Promise<void> => {
            e.preventDefault();
            this.setState({ loading: true });
            axios.patch(`http://localhost:5000/customers/${this.state.id}`, this.state.values).then(data => {
                this.setState({ submitSuccess: true, loading: false })
                setTimeout(() => {
                    this.props.history.push('/');
                }, 1500)
            })
        }
    
        private setValues = (values: IValues) => {
            this.setState({ values: { ...this.state.values, ...values } });
        }
        private handleInputChanges = (e: React.FormEvent<HTMLInputElement>) => {
            e.preventDefault();
            this.setValues({ [e.currentTarget.id]: e.currentTarget.value })
        }
    ...
    }
    
    export default withRouter(EditCustomer)

First, you add a `componentDidMount()` method, which is a lifecycle method that is being called when the component is created. The method takes the `id` obtained from the route parameter to identify a particular customer as a parameter, uses it to retrieve their details from the database and then populates the form with it. Furthermore, you add methods to process form submission and handle changes made to the values of the input fields.

Lastly, add the `render()` method for the `Edit` component:

/src/components/customer/Edit.tsx

    ...
        public render() {
            const { submitSuccess, loading } = this.state;
            return (
                <div className="App">
                    {this.state.customer &&
                        <div>
                            < h1 > Customer List Management App</h1>
                            <p> Built with React.js and TypeScript </p>
    
                            <div>
                                <div className={"col-md-12 form-wrapper"}>
                                    <h2> Edit Customer </h2>
                                    {submitSuccess && (
                                        <div className="alert alert-info" role="alert">
                                            Customer's details has been edited successfully </div>
                                    )}
                                    <form id={"create-post-form"} onSubmit={this.processFormSubmission} noValidate={true}>
                                        <div className="form-group col-md-12">
                                            <label htmlFor="first_name"> First Name </label>
                                            <input type="text" id="first_name" defaultValue={this.state.customer.first_name} onChange={(e) => this.handleInputChanges(e)} name="first_name" className="form-control" placeholder="Enter customer's first name" />
                                        </div>
                                        <div className="form-group col-md-12">
                                            <label htmlFor="last_name"> Last Name </label>
                                            <input type="text" id="last_name" defaultValue={this.state.customer.last_name} onChange={(e) => this.handleInputChanges(e)} name="last_name" className="form-control" placeholder="Enter customer's last name" />
                                        </div>
                                        <div className="form-group col-md-12">
                                            <label htmlFor="email"> Email </label>
                                            <input type="email" id="email" defaultValue={this.state.customer.email} onChange={(e) => this.handleInputChanges(e)} name="email" className="form-control" placeholder="Enter customer's email address" />
                                        </div>
                                        <div className="form-group col-md-12">
                                            <label htmlFor="phone"> Phone </label>
                                            <input type="text" id="phone" defaultValue={this.state.customer.phone} onChange={(e) => this.handleInputChanges(e)} name="phone" className="form-control" placeholder="Enter customer's phone number" />
                                        </div>
                                        <div className="form-group col-md-12">
                                            <label htmlFor="address"> Address </label>
                                            <input type="text" id="address" defaultValue={this.state.customer.address} onChange={(e) => this.handleInputChanges(e)} name="address" className="form-control" placeholder="Enter customer's address" />
                                        </div>
                                        <div className="form-group col-md-12">
                                            <label htmlFor="description"> Description </label>
                                            <input type="text" id="description" defaultValue={this.state.customer.description} onChange={(e) => this.handleInputChanges(e)} name="description" className="form-control" placeholder="Enter Description" />
                                        </div>
                                        <div className="form-group col-md-4 pull-right">
                                            <button className="btn btn-success" type="submit">
                                                Edit Customer </button>
                                            {loading &&
                                                <span className="fa fa-circle-o-notch fa-spin" />
                                            }
                                        </div>
                                    </form>
                                </div>
                            </div>
                        </div>
                    }
                </div>
            )
        }
    ...    

Here, you created a form to edit the details of a particular customer, and then populated the input fields within that form with the customer’s details that your application’s state obtained. Similarly to the `Create` component, changes made to all the input fields will be handled by the `handleInputChanges()` method.

You can see the complete code for this file in this [GitHub repository](https://github.com/yemiwebby/typescript-react-customer-app/blob/master/src/components/customer/Edit.tsx).

Save and exit `Edit.tsx`.

To view the complete list of customers created within the application, you’ll create a new component within the `./src/components` folder and name it `Home.tsx`:

    cd ./src/components
    nano Home.tsx

Add the following content:

/src/components/Home.tsx

    import * as React from 'react';
    import { Link, RouteComponentProps } from 'react-router-dom';
    import axios from 'axios';
    
    interface IState {
        customers: any[];
    }
    
    export default class Home extends React.Component<RouteComponentProps, IState> {
        constructor(props: RouteComponentProps) {
            super(props);
            this.state = { customers: [] }
        }
        public componentDidMount(): void {
            axios.get(`http://localhost:5000/customers`).then(data => {
                this.setState({ customers: data.data })
            })
        }
        public deleteCustomer(id: number) {
            axios.delete(`http://localhost:5000/customers/${id}`).then(data => {
                const index = this.state.customers.findIndex(customer => customer.id === id);
                this.state.customers.splice(index, 1);
                this.props.history.push('/');
            })
        }
    }

Here, you’ve imported `React`, `axios`, and other required components from React Router. You created two new methods within the `Home` component:

- `componentDidMount()`: The application invokes this method immediately after a component is mounted. Its responsibility here is to retrieve the list of customers and update the home page with it.
- `deleteCustomer()`: This method will accept an `id` as a parameter and will delete the details of the customer identified with that `id` from the database.

Now add the `render()` method to display the table that holds the list of customers for the `Home` component:

/src/components/Home.tsx

    ...
    public render() {
            const customers = this.state.customers;
            return (
                <div>
                    {customers.length === 0 && (
                        <div className="text-center">
                            <h2>No customer found at the moment</h2>
                        </div>
                    )}
                    <div className="container">
                        <div className="row">
                            <table className="table table-bordered">
                                <thead className="thead-light">
                                    <tr>
                                        <th scope="col">Firstname</th>
                                        <th scope="col">Lastname</th>
                                        <th scope="col">Email</th>
                                        <th scope="col">Phone</th>
                                        <th scope="col">Address</th>
                                        <th scope="col">Description</th>
                                        <th scope="col">Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {customers && customers.map(customer =>
                                        <tr key={customer.id}>
                                            <td>{customer.first_name}</td>
                                            <td>{customer.last_name}</td>
                                            <td>{customer.email}</td>
                                            <td>{customer.phone}</td>
                                            <td>{customer.address}</td>
                                            <td>{customer.description}</td>
                                            <td>
                                                <div className="d-flex justify-content-between align-items-center">
                                                    <div className="btn-group" style={{ marginBottom: "20px" }}>
                                                        <Link to={`edit/${customer.id}`} className="btn btn-sm btn-outline-secondary">Edit Customer </Link>
                                                        <button className="btn btn-sm btn-outline-secondary" onClick={() => this.deleteCustomer(customer.id)}>Delete Customer</button>
                                                    </div>
                                                </div>
                                            </td>
                                        </tr>
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            )
        }
    ...

In this code block, you retrieve the lists of customers from the application’s state as an array, iterate over it, and display it within an HTML table. You also add the `customer.id` parameter, which the method uses to identify and delete the details of a particular customer from the list.

Save and exit `Home.tsx`.

You’ve adopted a statically typed principle for all the components created with this application by defining types for the components and props through the use of interfaces. This is one of the best approaches to using TypeScript for a React application.

With this, you’ve finished creating all the required reusable components for the application. You can now update the app component with links to all the components that you have created so far.

## Step 4 — Setting Up Routing and Updating the Entry Point of the Application

In this step, you will import the necessary components from the React Router package and configure the `App` component to render different components depending on the route that is loaded. This will allow you to navigate through different pages of the application. Once a user visits a route, for example `/create`, React Router will use the path specified to render the contents and logic within the appropriate component defined to handle such route.

Navigate to `./src/App.tsx`:

    nano App.tsx

Then replace its content with the following:

/src/App.tsx

    import * as React from 'react';
    import './App.css';
    import { Switch, Route, withRouter, RouteComponentProps, Link } from 'react-router-dom';
    import Home from './components/Home';
    import Create from './components/customer/Create';
    import EditCustomer from './components/customer/Edit';
    
    class App extends React.Component<RouteComponentProps<any>> {
      public render() {
        return (
          <div>
            <nav>
              <ul>
                <li>
                  <Link to={'/'}> Home </Link>
                </li>
                <li>
                  <Link to={'/create'}> Create Customer </Link>
                </li>
              </ul>
            </nav>
            <Switch>
              <Route path={'/'} exact component={Home} />
              <Route path={'/create'} exact component={Create} />
              <Route path={'/edit/:id'} exact component={EditCustomer} />
            </Switch>
          </div>
        );
      }
    }
    export default withRouter(App);

You imported all the necessary components from the React Router package and you also imported the reusable components for creating, editing, and viewing customers’ details.

Save and exit `App.tsx`.

The `./src/index.tsx` file is the entry point for this application and renders the application. Open this file and import React Router into it, then wrap the `App` component inside a `BrowserRouter`:

/src/index.tsx

    import React from 'react';
    import ReactDOM from 'react-dom';
    import './index.css';
    import App from './App';
    import { BrowserRouter } from 'react-router-dom'; 
    import * as serviceWorker from './serviceWorker';
    ReactDOM.render(
        <BrowserRouter>
            <App />
        </BrowserRouter>
        , document.getElementById('root')
    );
    serviceWorker.unregister();

React Router uses the `BrowserRouter` component to make your application aware of the navigation, such as history and current path.

Once you’ve finished editing `Index.tsx`, save and exit.

Lastly, you will use Bootstrap to add some style to your application. [Bootstrap](https://getbootstrap.com/) is a popular HTML, CSS, and JavaScript framework for developing responsive, mobile-first projects on the web. It allows developers to build an appealing user interface without having to write too much CSS. It comes with a responsive grid system that gives a web page a finished look that works on all devices.

To include Bootstrap and styling for your application, replace the contents of `./src/App.css` with the following:

/src/App.css

    @import 'https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css';
    
    .form-wrapper {
      width: 500px;
      margin: 0 auto;
    }
    .App {
      text-align: center;
      margin-top: 30px;
    }
    nav {
      width: 300px;
      margin: 0 auto;
      background: #282c34;
      height: 70px;
      line-height: 70px;
    }
    nav ul li {
      display: inline;
      list-style-type: none;
      text-align: center;
      padding: 30px;
    }
    nav ul li a {
      margin: 50px 0;
      font-weight: bold;
      color: white;
      text-decoration: none;
    }
    nav ul li a:hover {
      color: white;
      text-decoration: none;
    }
    table {
      margin-top: 50px;
    }
    .App-link {
      color: #61dafb;
    }
    @keyframes App-logo-spin {
      from {
        transform: rotate(0deg);
      }
      to {
        transform: rotate(360deg);
      }
    }

You have used Bootstrap here to enhance the look and feel of the application by giving it a default layout, styles, and color. You have also added some custom styles, particularly to the navigation bar.

Save and exit `App.css`.

In this section, you have configured React Router to render the appropriate component depending on the route visited by the user and also added some styling to make the application more attractive to users. Next, you will test all the functionality implemented for the application.

## Step 5 — Running Your Application

Now that you have set up the frontend of this application with React and TypeScript by creating several reusable components, and also built a REST API with the `json-server`, you can run your app.

Navigate back to the project’s root folder:

    cd ~/typescript-react-app

Next run the following command to start your app:

    yarn start

**Note:** Make sure your server is still running in the other terminal window. Otherwise, start it with: `yarn server`.

Navigate to `http://localhost:3000` to view the application from your browser. Then proceed to click on the **Create** button and fill in the details of a customer.

![Create customer page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/reacttypescript/step5a.png)

After entering the appropriate values in the input fields, click on the **Create Customer** button to submit the form. The application will redirect you back to your homepage once you’re done creating a new customer.

![View customers page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/reacttypescript/step5b.png)

Click the **Edit Customer** button for any of the rows and you will be directed to the page that hosts the editing functionality for the corresponding customer on that row.

![Edit customer page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/reacttypescript/step5c.png)

Edit the details of the customer and then click on **Edit Customer** to update the customer’s details.

You’ve run your application to ensure all the components are working. Using the different pages of your application, you’ve created and edited a customer entry.

## Conclusion

In this tutorial you built a customer list management app with [React](https://reactjs.org/) and [TypeScript](https://www.typescriptlang.org/). The process in this tutorial is a deviation from using JavaScript as the conventional way of structuring and building applications with React. You’ve leveraged the benefits of using TypeScript to complete this front-end focused tutorial.

To continue to develop this project, you can move your mock back-end server to a production-ready back-end technology like [Express](https://expressjs.com/) or [Nest.js](https://nestjs.com/). Furthermore, you can extend what you have built in this tutorial by adding more features such as authentication and authorization with different tools like the [Passport.js](http://www.passportjs.org/) authentication library.

You can find the complete source code for the project [on GitHub](https://github.com/yemiwebby/typescript-react-customer-app).
