---
author: Heikki Vesanto
date: 2016-09-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-postgis-on-ubuntu-14-04
---

# How to Install and Configure PostGIS on Ubuntu 14.04

## Introduction

PostGIS is the spatial extension to the PostgreSQL relational database. PostGIS lets you store spatial data using geometry and geography data types, perform spatial queries with spacial functions to determine area, distance, length, and perimeter, and create spatial indexes on your data to speed up spatial queries.

In this guide, you’ll install PostGIS, configure PostgreSQL for spatial data, load some spatial objects into your database, and perform a basic query.

## Prerequisites

Before you begin this guide you’ll need the following:

- One Ubuntu 14.04 server
- A non-root user with sudo privileges. The tutorial [Initial server setup guide for Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04) explains how to set this up.
- A PostgreSQL database. Follow our guide on [How To Install and Use PostgreSQL on Ubuntu 14.04](how-to-install-and-use-postgresql-on-ubuntu-14-04). We will use the `test1` database and user that you’ll set up in that guide for this tutorial.

## Step 1 — Installing PostGIS

PostGIS is not included in the default repositories for Ubuntu, but we can get it through [UbuntuGIS](https://launchpad.net/%7Eubuntugis/), an external repository that maintains a number of open source GIS packages. While the PostGIS package in this repository might not always be the cutting edge release, it is well maintained, and it removes the need to compile PostGIS from source. So to install PostGIS, we’ll add this repository to our sources and then install it with our package manager.

Log into your server with your non-root user:

    ssh sammy@your_ip_address

Since we’re using Ubuntu 14.04 we’ll need the unstable branch of the repository. Execute the following command to add the repository to your sources:

    sudo add-apt-repository ppa:ubuntugis/ubuntugis-unstable

You’ll see the following output:

    OutputUnstable releases of Ubuntu GIS packages. These releases are more bleeding edge and while generally they should work well, they dont receive the same amount of quality assurance as our stable releases do.
    More info: https://launchpad.net/~ubuntugis/+archive/ubuntu/ubuntugis-unstable
    Press [ENTER] to continue or ctrl-c to cancel adding it
    

Press `ENTER` to accept the warning, and the source will be added:

    Outputgpg: keyring `/tmp/tmpintg192h/secring.gpg' created
    gpg: keyring `/tmp/tmpintg192h/pubring.gpg' created
    gpg: requesting key 314DF160 from hkp server keyserver.ubuntu.com
    gpg: /tmp/tmpintg192h/trustdb.gpg: trustdb created
    gpg: key 314DF160: public key "Launchpad ubuntugis-stable" imported
    gpg: Total number processed: 1
    gpg: imported: 1 (RSA: 1)
    OK

Before you can install PostGIS, update your list of available packages so the packages from the new repository are added to the list.

    sudo apt-get update

Once your sources update, install PostGIS.

    sudo apt-get install postgis

Enter `Y` when prompted to install PostGIS along with its necessary dependencies.

We can now connect to PostgreSQL and integrate PostGIS.

## Step 2 — Enabling Spacial Features With PostGIS

PostGIS’s features must be activated on a per-database basis before you can store spacial data. We’ll work with the `test1` database and the `postgres` user from the [How To Install and Use PostgreSQL on Ubuntu 14.04](how-to-install-and-use-postgresql-on-ubuntu-14-04) tutorial you followed before starting this tutorial.

Using the `sudo` command, switch to the `postgres` user:

    sudo -i -u postgres

Then connect to the `test1` database:

    psql -d test1

Next, enable the PostGIS extension on the database:

    CREATE EXTENSION postgis;

Let’s verify that everything worked correctly. Execute the following command:

    SELECT PostGIS_version();

You’ll see this output:

    Output postgis_version
    ---------------------------------------
     2.2 USE_GEOS=1 USE_PROJ=1 USE_STATS=1
    (1 row)

We’re all set. Type

    \q

to exit the SQL session and return to your terminal prompt.

Then switch back to your main user account:

    su sammy

We now have a database with PostGIS installed, but let’s tweak some PostgreSQL settings to make things run smoothly.

## Step 3 — Optimizing PostgreSQL for GIS Database Objects

PostgreSQL is designed to run on anything from integrated systems to large corporate databases, but out of the box it is configured very conservatively. GIS database objects are large in comparison to text data, so let’s configure PostgreSQL to work better with those objects.

We configure PostgreSQL by editing the `postgresql.conf` file. Open this file:

    sudo nano /etc/postgresql/9.3/main/postgresql.conf

There are a few changes we need to make to this file to support spatial data.

First, `shared_buffers` should be changed to around 75% of your server’s RAM. So `200MB` is a good value for a server with 512MB of RAM. Locate the `shared_buffers` line and modify it like this:

/etc/postgresql/9.3/main/postgresql.conf

    shared_buffers = 200MB # min 128kB

Next, locate the line starting with `#work_mem`. This line is commented out by default, so uncomment this line and increase its value to `16MB`:

/etc/postgresql/9.3/main/postgresql.conf

    work_mem = 16MB # min 64kB

Then locate `#maintenance_work_mem`, uncomment it, and increase its value to `128MB`:

/etc/postgresql/9.3/main/postgresql.conf

    maintenance_work_mem = 128MB # min 1MB

Find `checkpoint_segments`, then uncomment it and change its value to `6`:

/etc/postgresql/9.3/main/postgresql.conf

    checkpoint_segments = 6 # in logfile segments, min 1, 16MB each

Finally, look for `#random_page_cost`. When you find it, uncomment it and set its value to `2.0`:

/etc/postgresql/9.3/main/postgresql.conf

    random_page_cost = 2.0 # same scale as above

Press `CTRL+X` to exit, followed by `Y` and `ENTER` to save the changes to this file.

You can check out the tutorial [Tuning PostgreSQL for Spatial](http://workshops.boundlessgeo.com/postgis-intro/tuning.html) for more information on these settings.

Restart PostgreSQL for these changes to take place:

    sudo service postgresql restart

We now have PostGIS installed and PostgreSQL configured. Let’s get some data into the database so we can test things out.

## Step 4 — Loading Spatial Data

Let’s load some spatial data into our database so we can get familiar with the tools and the process for getting this data into PostgreSQL, and so we can do some spatial queries later.

[Natural Earth](http://www.naturalearthdata.com/) provides a great source of basic data for the whole world at various scales. Best of all, this data is in the public domain.

Navigate to your home folder and create a new folder called `nedata`. We’ll use this folder to hold the Natural Earth data we’ll download.

    cd ~

    mkdir nedata

Then navigate into this new folder:

    cd nedata

We will download the 1:110m Countries data set from Natural Earth. Use `wget` to pull that file down to your server:

    wget http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/110m/cultural/ne_110m_admin_0_countries.zip

The file you just downloaded is compressed, so you’ll need the `unzip` command which you can install through the package manager. Install it with the following command:

    sudo apt-get install unzip

Then unzip the file:

    unzip ne_110m_admin_0_countries.zip

You’ll have six additional files in the folder now:

- `ne_110m_admin_0_countries.README.html`
- `ne_110m_admin_0_countries.VERSION.txt`
- `ne_110m_admin_0_countries.dbf`
- `ne_110m_admin_0_countries.prj`
- `ne_110m_admin_0_countries.shp`
- `ne_110m_admin_0_countries.shx`

The **.dbf** , **.prj** , **.shp** , and **.shp** files make up a [ShapeFile](http://help.arcgis.com/en/arcgisdesktop/10.0/help/index.html#/Shapefile_file_extensions/005600000003000000/), a popular geospatial vector data format used by GIS software. We can load this into our `test1` database.

To do this, we’ll install [GDAL](http://www.gdal.org/), the Geospatial Data Abstraction Library. When we install GDAL, we’ll also get OGR (OpenGIS Simple Features Reference Implementation) and the command `ogr2ogr`. This is a vector data translation library which we’ll use to translate the Shapefile into data that PostGIS can use.

Install GDAL using the package manager:

    sudo apt-get install gdal-bin

Now switch to the `postgres` user again:

    sudo -i -u postgres

Now convert the Shapefile that you got from Natural Earth into a PostGIS table using `ogr2ogr`, like this:

    ogr2ogr -f PostgreSQL PG:dbname=test1 -progress -nlt PROMOTE_TO_MULTI /home/sammy/nedata/ne_110m_admin_0_countries.shp

Let’s break that command down and look at each option in detail. First, we specify this option:

    -f PostgreSQL

This switch states that the output file type is a PostgreSQL table.

Next, we have this option:

    PG:dbname=test1

This sets the connection string to our database. We’re just specifying the database name here, but if you wanted to use a different user, host, and port, you can specify those options like this:

    PG:"dbname='databasename' host='addr' port='5432' user='x' password='y'"

Next in our list of options is this:

    -progress

This option displays a progress bar so we can visualize the process.

Next, we pass this argument:

    -nlt PROMOTE_TO_MULTI

PostgreSQL is strict on object types. The `ogr2ogr` command will make an assumption on the geometry type based on the first few features in a file. The data we’re importing contains a mix of **Polygon** types and multi-part polygons, or **MultiPolygons**. These cannot be inserted into the same field, so we promote all the features to multi-part polygons, and the geometry field will be created as a **MultiPolygon**.

Finally, we specify the path to the input file:

    /home/sammy/nedata/ne_110m_admin_0_countries.shp

Visit the [ogr2ogr](http://www.gdal.org/ogr2ogr.html) website to see the full set of options.

When you run the full command, you’ll see the following output:

    Output0...10...20...30...40...50...60...70...80...90...100 - done.

We can check that the data was imported by using the `ogrinfo` command. Execute the following command:

    ogrinfo -so PG:dbname=test1 ne_110m_admin_0_countries

This will display the following output:

    OutputINFO: Open of `PG:dbname=test1'
          using driver `PostgreSQL' successful.
    
    Layer name: ne_110m_admin_0_countries
    Geometry: Multi Polygon
    Feature Count: 177
    Extent: (-180.000000, -90.000000) - (180.000000, 83.645130)
    Layer SRS WKT:
    GEOGCS["WGS 84",
        DATUM["WGS_1984",
            SPHEROID["WGS 84",6378137,298.257223563,
                AUTHORITY["EPSG","7030"]],
            AUTHORITY["EPSG","6326"]],
        PRIMEM["Greenwich",0,
            AUTHORITY["EPSG","8901"]],
        UNIT["degree",0.0174532925199433,
            AUTHORITY["EPSG","9122"]],
        AUTHORITY["EPSG","4326"]]
    FID Column = ogc_fid
    Geometry Column = wkb_geometry
    scalerank: Integer (4.0)
    featurecla: String (30.0)
    
    ...
    
    region_wb: String (254.0)
    name_len: Real (16.6)
    long_len: Real (16.6)
    abbrev_len: Real (16.6)
    tiny: Real (16.6)
    homepart: Real (16.6)

We now have spatial data in our database, so let’s look at how we can use it to solve problems.

## Step 5 — Querying Spatial Data

Suppose we’ve been asked to find the ten most northerly countries in the world. That’s easy using PostGIS and the data we’ve imported.

Log back in to the `test1` database.

    psql -d test1

List the tables in the database:

    \dt 

This will return two tables:

    Output List of relations
     Schema | Name | Type | Owner
    --------+---------------------------+-------+----------
     public | ne_110m_admin_0_countries | table | postgres
     public | spatial_ref_sys | table | postgres
    (2 rows)

We’ll use the`ne_110m_admin_0_countries` table, which contains the data that’ll help us answer our question. This table has an `admin` column that contains the name of the country, and a `wkb_gemoetry` column that contains geometric data. If you want to see all of the columns in the `ne_110m_admin_0_countries` table, you can issue the command:

    \d ne_110m_admin_0_countries

You’ll see the columns and their data types. The `wbk_geometry` column’s data type looks like this:

     wkb_geometry | geometry(MultiPolygon,4326) |

The `wbk_geometry` column contains polygons. We’re dealing with countries and their irregular borders, and thus each country in our database does not have a single value for latitude. So to get the latitude for each country we first find out the centroid of each country using PostGIS’s `ST_Centroid` function. We then extract the centroid’s Y value using the `ST_Y` function. We can use that value as the latitude.

Here’s the query we’ll run:

    SELECT admin, ST_Y(ST_Centroid(wkb_geometry)) as latitude 
    FROM ne_110m_admin_0_countries 
    ORDER BY latitude DESC 
    LIMIT 10;

We order the results in descending order because the most northerly country will have the highest latitude.

Execute that query and you’ll see the top ten most northerly countries:

    Output admin | latitude
    -----------+------------------
     Greenland | 74.7704876939899
     Norway | 69.1568563971328
     Iceland | 65.074276335291
     Finland | 64.5040939185674
     Sweden | 62.8114849680803
     Russia | 61.9808407507127
     Canada | 61.4690761453491
     Estonia | 58.643695240707
     Latvia | 56.8071751342793
     Denmark | 56.0639344617945
    (10 rows)

Now that you have your answer, you can exit the database with

    \q

You can find more information on the various PostGIS functions in the [PostGIS Reference](http://postgis.net/docs/reference.html) section of the PostGIS documentation.

## Conclusion

You now have a spatially enabled database configured for spatial queries, and you have some data in that database you can use for further exploration.

For a more in-depth guide to creating spatial queries, see the [Boundless PostGIS Tutorial](http://workshops.boundlessgeo.com/postgis-intro/index.html)
