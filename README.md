# OneacctExport
Exporting OpenNebula accounting data.

[![Build Status](https://secure.travis-ci.org/EGI-FCTF/oneacct_export.png)](http://travis-ci.org/EGI-FCTF/oneacct_export)
[![Dependency Status](https://gemnasium.com/EGI-FCTF/oneacct_export.png)](https://gemnasium.com/EGI-FCTF/oneacct_export)
[![Gem Version](https://fury-badge.herokuapp.com/rb/oneacct-export.png)](https://badge.fury.io/rb/oneacct-export)
[![Code Climate](https://codeclimate.com/github/EGI-FCTF/oneacct_export.png)](https://codeclimate.com/github/EGI-FCTF/oneacct_export)


##Requirements
* Ruby >= 2.0
* Rubygems
* Redis server (doesn't have to be present on the same machine)
* OpenNebula >= 4.4 (doesn't have to be present on the same machine)

##Installation
###From distribution specific packages
Distribution specific packages can be created with [omnibus packaging for OneacctExport](https://github.com/EGI-FCTF/omnibus-oneacct-export). When installing via packages you don't have to install neither ruby nor 
rubygems. Packages contain embedded ruby and all the necessary gems and libraries witch will not effect your system ruby, gems and libraries. 

Currently supported distributions:

* Ubuntu 10.04
* Ubuntu 12.04
* Ubuntu 14.04
* Debian 6.0.10
* Debian 7.6
* CentOS 5.10
* CentOS 6.5

###From RubyGems.org
To install the most recent stable version
```bash
gem install oneacct-export
```

###From source (dev)
**Installation from source should never be your first choice! Especially, if you are not familiar with RVM, Bundler, Rake and other dev tools for Ruby!**

**However, if you wish to contribute to our project, this is the right way to start.**

To build and install the bleeding edge version from master

```bash
git clone git://github.com/EGI-FCTF/oneacct_export.git
cd oneacct_export
gem install bundler
bundle install
bundle exec rake spec
rake install
```
##Configuration
###Create a configuration file for OneacctExport
Configuration file can be read by OneacctExport from these three locations:

* ~/.oneacct-export/conf.yml
* /etc/oneacct-export/conf.yml
* &lt;PATH_TO_GEM_DIR&gt;/config/conf.yml
 
The example configuration file can be found at the last location &lt;PATH_TO_GEM_DIR&gt;/config/conf.yml. When editing a configuration file you have to follow the division into three environments: production, 
development and test. All the configuration options are described in the example configuration file.
 
###Create a configuration file for Sidekiq
Sidekiq configuration file can be placed anywhere you want since you will provide path to the configuration later during the Sidekiq start. How the Sidekiq configuration should look like and what options you can use 
can be found on its [wiki page](https://github.com/mperham/sidekiq/wiki/Advanced-Options).
 
The important thing is to set the same queue name in both OneacctExport and Sidekiq configuration files. OneacctExport is currently supporting adding jobs to only one queue.
 
###Configure RPC connection
RPC connection for OpenNebula can be configured in two ways:

* Via OneacctExport configuration file, option xml_rpc and its suboptions
* Via Opennebula configuration mechanism:
 
 System environment variable ONE_AUTH contains path to the file containing string in format username:password to authenticate against OpenNebula. If the variable is empty, default file location is ~/.one/one_auth.
 
 System environment variable ONE_XMLRPC contains URL of OpenNebula RPC gate. If empty, the same information can be stored in ~/.one/one_endpoint
 
###Set Rails environment variable according to your environment
You have to set system environment variable RAILS_ENV to one of the values production, development or test. OneacctExport is not a Rails application but we chose the Rails variable for easier possible integration in 
the future.

##Usage

**Both Opennebula and Redis server must be running prior the next steps.**

###Start sidekiq
First you have to start Sidekiq so it can run the jobs from the queue. Since OneacctExport is not a Rails application Sidekiq has to be started with OneacctExport's worker class as an argument. For example:

```bash
sidekiq -r <PATH_TO_GEM_DIR>/lib/one_worker.rb -C <PATH_TO_SIDEKIQ_CONF>/sidekiq.yml
```

###Start OneacctExport

OneacctExport is run with executable `oneacct-export`. For a list of all available options run `oneacct-export -h`:

```
$ oneacct-export -h

Usage oneacct-export [options]

        --records-from TIME          Retrieves only records newer than TIME
        --records-to TIME            Retrieves only records older than TIME
        --include-groups GROUP1[,GROUP2,...]
                                     Retrieves only records of virtual machines which belong to the specified groups
        --exclude-groups GROUP1[,GROUP2,...]
                                     Retrieves only records of virtual machines which don't belong to the specified groups
        --group-file FILE            If --include-groups or --exclude-groups specified, loads groups from file FILE
    -b, --[no-]blocking              Run in a blocking mode - wait until all submitted jobs are processed
    -t, --timeout N                  Timeout for blocking mode in seconds. Default is 1 hour.
    -c, --[no-]compatibility-mode    Run in compatibility mode - supports OpenNebula 4.4.x
    -h, --help                       Shows this message
    -v, --version                    Shows version
```

##Code Documentation
[Code Documentation for OneacctExport by YARD](http://rubydoc.info/github/EGI-FCTF/oneacct_export/)

##Continuous integration
[Continuous integration for OneacctExport by Travis-CI](http://travis-ci.org/EGI-FCTF/oneacct_export/)

## Contributing
1. Fork it ( https://github.com/EGI-FCTF/oneacct_export/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
