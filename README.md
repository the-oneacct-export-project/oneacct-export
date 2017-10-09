# OneacctExport
Exporting OpenNebula accounting data.

[![Travis](https://img.shields.io/travis/the-oneacct-export-project/oneacct-export.svg?style=flat-square)](http://travis-ci.org/the-oneacct-export-project/oneacct-export)
[![Gemnasium](https://img.shields.io/gemnasium/the-oneacct-export-project/oneacct-export.svg?style=flat-square)](https://gemnasium.com/the-oneacct-export-project/oneacct-export)
[![Gem](https://img.shields.io/gem/v/oneacct-export.svg?style=flat-square)](https://rubygems.org/gems/oneacct-export)
[![Code Climate](https://img.shields.io/codeclimate/github/the-oneacct-export-project/oneacct-export.svg?style=flat-square)](https://codeclimate.com/github/the-oneacct-export-project/oneacct-export)
[![DockerHub](https://img.shields.io/badge/docker-ready-blue.svg?style=flat-square)](https://hub.docker.com/r/oneacctexport/oneacct-export/)


## Requirements
* Ruby >= 2.0
* Rubygems
* Redis server (doesn't have to be present on the same machine)
* OpenNebula >= 4.4 (doesn't have to be present on the same machine)

## Installation
### From distribution specific packages
Distribution specific packages can be created with
[omnibus packaging for OneacctExport](https://github.com/the-oneacct-export-project/omnibus-oneacct-export).
When installing via packages you don't have to install neither ruby
nor rubygems. Packages contain embedded ruby and all the necessary gems
and libraries witch will not effect your system ruby, gems and libraries.

Currently supported distributions:

* Ubuntu 10.04
* Ubuntu 12.04
* Ubuntu 14.04
* Debian 6.0.10
* Debian 7.6
* CentOS 5.10
* CentOS 6.5

### From RubyGems.org
To install the most recent stable version
```bash
gem install oneacct-export
```

### From source (dev)
**Installation from source should never be your first choice! Especially, if you are not
familiar with RVM, Bundler, Rake and other dev tools for Ruby!**

**However, if you wish to contribute to our project, this is the right way to start.**

To build and install the bleeding edge version from master

```bash
git clone git://github.com/the-oneacct-export-project/oneacct_export.git
cd oneacct_export
gem install bundler
bundle install
bundle exec rake spec
rake install
```
## Configuration
### Create a new user account
Create or use an existing `apel` user account which will be used to run
the export process. This account must be the same as the user account
used by the APEL SSM client.

### Create a configuration file for OneacctExport
Configuration file can be read by OneacctExport from these
three locations:

* `~/.oneacct-export/conf.yml`
* `/etc/oneacct-export/conf.yml`
* `PATH_TO_GEM_DIR/config/conf.yml`

The example configuration file can be found at the last location
`PATH_TO_GEM_DIR/config/conf.yml`. When editing a configuration
file you have to follow the division into three environments: `production`,
`development` and `test`. All the configuration options are described
in the example configuration file.

### Create a configuration file for Sidekiq
Sidekiq configuration file can be placed anywhere you want since you will provide
path to the configuration later during the Sidekiq start. How the Sidekiq
configuration should look like and what options you can use
can be found on its [wiki page](https://github.com/mperham/sidekiq/wiki/Advanced-Options).
An example is provided in `PATH_TO_GEM_DIR/config/sidekiq.yml`.

The important thing is to set the same queue name in both
OneacctExport and Sidekiq configuration files. OneacctExport
is currently supporting adding jobs to only one queue.

### Create required directories
```bash
mkdir -p /var/run/oneacct-export
chown apel:apel /var/run/oneacct-export

mkdir -p /var/log/oneacct-export
chown apel:apel /var/log/oneacct-export
```

### Configure RPC connection
RPC connection for OpenNebula can be configured in two ways:

* Via OneacctExport configuration file, option xml_rpc and its suboptions
* Via OpenNebula configuration mechanism:

 System environment variable `ONE_AUTH` contains path to the file containing
 string in format `username:password` to authenticate against OpenNebula.
 If the variable is empty, default file location is `~/.one/one_auth`.

 System environment variable `ONE_XMLRPC` contains URL of OpenNebula RPC
 gate. If empty, the same information can be stored in `~/.one/one_endpoint`.

### Configure vmcatcher IMAGE attribute inheritance in OpenNebula
In `oned.conf`:
~~~
INHERIT_IMAGE_ATTR = "VMCATCHER_EVENT_AD_MPURI"
INHERIT_IMAGE_ATTR = "VMCATCHER_EVENT_DC_IDENTIFIER"
INHERIT_IMAGE_ATTR = "VMCATCHER_EVENT_IL_DC_IDENTIFIER"
INHERIT_IMAGE_ATTR = "VMCATCHER_EVENT_SL_CHECKSUM_SHA512"
INHERIT_IMAGE_ATTR = "VMCATCHER_EVENT_HV_VERSION"
~~~

### Configure benchmark host attributes in OpenNebula
In order to recognize and fill `BenchmarkType` and `Benchmark` APEL v0.4 fields,
two attributes have to be set for every host in OpenNebula:
* `BENCHMARK_TYPE` - represents benchmark's type. For example: `HEP-SPEC06`
* `BENCHMARK_VALUE` - represents a per-core measured value of said benchmark.
For example: `84.46`

Both attributes can be set both for clusters and hosts in OpenNebula with hosts'
attributes taking precedence. If attributes are set only for cluster, all hosts
within the cluster will be assigned these values.

### Set Rails environment variable according to your environment
You have to set system environment variable `RAILS_ENV` to one of the
values production, development or test. OneacctExport is not a Rails
application but we chose the Rails variable for easier possible integration in
the future.

## Usage

**Both OpenNebula and Redis server must be running prior the next steps.**

### Start sidekiq
First you have to start Sidekiq so it can run the jobs from the queue. Since
OneacctExport is not a Rails application Sidekiq has to be started with
OneacctExport's worker class as an argument. For example:

```bash
sidekiq -r $PATH_TO_GEM_DIR/lib/one_worker.rb -C $PATH_TO_GEM_DIR/config/sidekiq.yml
```

### Start OneacctExport

OneacctExport is run with executable `oneacct-export`. For a list of all
available options run `oneacct-export -h`:

```
$ oneacct-export -h

Usage oneacct-export [options]

        --records-from TIME          Retrieves only records newer than TIME
        --records-to TIME            Retrieves only records older than TIME
        --records-for PERIOD         Retrieves only records within the time PERIOD
        --include-groups [GROUP1,GROUP2,...]
                                     Retrieves only records of virtual machines which belong to the specified groups
        --exclude-groups [GROUP1,GROUP2,...]
                                     Retrieves only records of virtual machines which don't belong to the specified groups
        --group-file FILE            If --include-groups or --exclude-groups specified, loads groups from file FILE
    -b, --[no-]blocking              Run in a blocking mode - wait until all submitted jobs are processed
    -t, --timeout N                  Timeout for blocking mode in seconds. Default is 1 hour.
    -c, --[no-]compatibility-mode    Run in compatibility mode - supports OpenNebula 4.4.x
    -h, --help                       Shows this message
    -v, --version                    Shows version
```

### Package specific scripts
When installed from packages build via [omnibus packaging for OneacctExport](https://github.com/the-oneacct-export-project/omnibus-oneacct-export),
both Sidekiq and OneacctExport are automatically registered as cron jobs to run
periodically. Cron job managing OneacctExport uses a bash script which is
simplifying OneacctExport interface for most common use cases. After the installation,
script can be found in `/usr/bin/oneacct-export-cron`. Script can accept command line options
`--week|-w` (default), `--two-weeks`, `--month|-m`, `--two-months`, `--six-months`, `--year|-y` and `--all|-a`
which sets age of retrieved records accordingly. There is also a set of files
which when present in `/opt/oneacct-export/` directory serves as a configuration shortcut:
* `compat.one` - turns on compatibility mode (same as OneacctExport option `--compatibility-mode`)
* `groups.include` - contains list of groups to include (same as combination of OneacctExport options `--include-groups` and `--group-file`)
* `groups.exclude` - contains list of groups to exclude (same as combination of OneacctExport options `--exclude-groups` and `--group-file`)

## Code Documentation
[Code Documentation for OneacctExport by YARD](http://rubydoc.info/github/the-oneacct-export-project/oneacct-export/)

## Continuous integration
[Continuous integration for OneacctExport by Travis-CI](http://travis-ci.org/the-oneacct-export-project/oneacct-export/)

## Development
### Contributing
1. Fork it ( https://github.com/the-oneacct-export-project/oneacct-export/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

### Debugging
To change the log level of `oneacct-export` and `sidekiq` you have to set the environment variable **ONEACCT_EXPORT_LOG_LEVEL** to log level you need. Supported log levels are `DEBUG`, `INFO`, `WARN` and `ERROR`.
```bash
export ONEACCT_EXPORT_LOG_LEVEL=DEBUG
```
