# a-design.ch CMS (a-design-cms-php & a-design-cms-nginx)

This project is specifically for the company [a-design](https://www.a-design.ch). It's built using CraftCMS inside Docker for easy development, testing and deployment.

Project

[![License](https://img.shields.io/github/license/d3strukt0r/a-design-cms)][license]
[![Docker Stars](https://img.shields.io/docker/stars/d3strukt0r/a-design-cms-nginx.svg?label=docker%20stars%20(nginx))][docker-nginx]
[![Docker Pulls](https://img.shields.io/docker/pulls/d3strukt0r/a-design-cms-nginx.svg?label=docker%20pulls%20(nginx))][docker-nginx]
[![Docker Stars](https://img.shields.io/docker/stars/d3strukt0r/a-design-cms-php.svg?label=docker%20stars%20(php))][docker-php]
[![Docker Pulls](https://img.shields.io/docker/pulls/d3strukt0r/a-design-cms-php.svg?label=docker%20pulls%20(php))][docker-php]

master-branch (alias stable, latest)

[![GH Action CI/CD](https://github.com/D3strukt0r/a-design-cms/workflows/CI/CD/badge.svg?branch=master)][gh-action]
[![Codacy grade](https://img.shields.io/codacy/grade/96966fb63138492e9657bafc6adefa2b/master)][codacy]

<!--
develop-branch (alias nightly)

[![GH Action CI/CD](https://github.com/D3strukt0r/a-design-cms/workflows/CI/CD/badge.svg?branch=develop)][gh-action]
[![Codacy grade](https://img.shields.io/codacy/grade/96966fb63138492e9657bafc6adefa2b/develop)][codacy]
-->

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

In order to run this container you'll need docker installed.

-   [Windows](https://docs.docker.com/docker-for-windows/install/)
-   [OS X](https://docs.docker.com/docker-for-mac/install/)
-   [Linux](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

### Usage

#### Container Parameters

```shell
docker run \
    -v $PWD/cpresources:/app/web/cpresources \
    -v $PWD/cms-logs:/app/storage/logs \
    -v $PWD/craftcms-license.key:/app/config/license.key \
    -e APP_ID="CraftCMS--!changeme!" \
    -e SECURITY_KEY="!changeme!" \
    -e DEFAULT_SITE_URL="https://localhost" \
    d3strukt0r/a-design-cms-php
```

```shell
docker run \
    -p 80:80 \
    -v $PWD/cpresources:/app/web/cpresources:ro \
    d3strukt0r/a-design-cms-nginx
```

#### Environment Variables

##### PHP Envs

###### PHP settings

-   `PHP_MAX_EXECUTION_TIME` - The maximum time php can run per request (Default: `100M`)
-   `PHP_MEMORY_LIMIT` - The memory limit that php can use (Default: `256M`)
-   `PHP_POST_MAX_SIZE` - The maximum size for sending POST requests (maximum upload size) (has to be the same on nginx) (Default: `100M`)
-   `PHP_UPLOAD_MAX_FILESIZE` - The maximum size per file for uploading (Default: `100M`)

###### Database settings

-   `DB_DRIVER` - The database driver that will be used (mysql or pgsql) (Default: `mysql`)
-   `DB_SERVER` - The database server name or IP address (Default: `db`)
-   `DB_PORT` - The port to connect to the database with (Default: `3306` (mysql) or `5432` (pgsql))
-   `DB_DATABASE` - The name of the database to select (Default: `craft`)
-   `DB_USER` - The database username to connect with (Default: `root`)
-   `DB_PASSWORD` - The database password to connect with (Default: )
-   `DB_SCHEMA` - The database schema that will be used (PostgreSQL only) (Default: `public`)
-   `DB_TABLE_PREFIX` - The prefix that should be added to generated table names (only necessary if multiple things are sharing the same database) (Default: )

###### CraftCMS settings

-   `ENVIRONMENT` - The environment Craft is currently running in (dev, staging, production, etc.) (Default: `prod`)
-   `APP_ID` - The application ID used to to uniquely store session and cache data, mutex locks, and more (Default: `CraftCMS`) (Required)
-   `SECURITY_KEY` - The secure key Craft will use for hashing and encrypting data (Default: ) (Required)
-   `DEFAULT_SITE_URL` - The URL the site will use mainly (Default: ) (Required)

##### Nginx Envs

-   `NGINX_CLIENT_MAX_BODY_SIZE` - The maximum size for sending POST requests (maximum upload size) (has to be the same on php) (Default: `100M`)
-   `USE_HTTPS` - Enables https. (Not recommeded, rather use Traefik) (Default: `false`)

#### Volumes

-   `/app` - All the data
-   `/app/config/license.key` - A license key (if needed)
-   `/app/storage/logs` - The logs created by CraftCMS
-   `/app/web/cpresources` - The frontend resources (should be syncronized between the php and nginx environment)

#### Useful File Locations

##### PHP Files

-   `/app/craft` - The craft command line tool

## Built With

-   [PHP](https://www.php.net/) - Main Programming Language
-   [Composer](https://getcomposer.org/) - Dependency Management
-   [CraftCMS](https://craftcms.com) - The web framework used
-   [Github Actions](https://github.com/features/actions) - Automatic CI (Testing) / CD (Deployment)
-   [Docker](https://www.docker.com) - Building a Container for the Server

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/Generation-2/a-design-website/tags).

## Authors

-   **Manuele Vaccari** - [D3strukt0r](https://github.com/D3strukt0r) - _Initial work_

See also the list of [contributors](https://github.com/Generation-2/a-design-website/contributors) who participated in this project.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE.txt](LICENSE.txt) file for details

## Acknowledgments

-   Hat tip to anyone whose code was used
-   Inspiration
-   etc

[license]: https://github.com/D3strukt0r/docker-spigot/blob/master/LICENSE.txt
[docker-nginx]: https://hub.docker.com/repository/docker/d3strukt0r/a-design-cms-nginx
[docker-php]: https://hub.docker.com/repository/docker/d3strukt0r/a-design-cms-php
[gh-action]: https://github.com/D3strukt0r/docker-spigot/actions
[codacy]: https://www.codacy.com/manual/D3strukt0r/a-design-cms
