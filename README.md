YaST Migration Module
=======================
[![Workflow Status](https://github.com/yast/yast-migration/workflows/CI/badge.svg?branch=master)](
https://github.com/yast/yast-migration/actions?query=branch%3Amaster)
[![Jenkins Status](https://ci.opensuse.org/buildStatus/icon?job=yast-yast-migration-master)](
https://ci.opensuse.org/view/Yast/job/yast-yast-migration-master/)
[![Travis Build](https://travis-ci.org/yast/yast-migration.svg?branch=master)](https://travis-ci.org/yast/yast-migration)
[![Jenkins Build](http://img.shields.io/jenkins/s/https/ci.opensuse.org/yast-migration-master.svg)](https://ci.opensuse.org/view/Yast/job/yast-migration/)
[![Coverage Status](https://img.shields.io/coveralls/yast/yast-migration.svg)](https://coveralls.io/r/yast/yast-migration?branch=master)
[![Code Climate](https://codeclimate.com/github/yast/yast-migration/badges/gpa.svg)](https://codeclimate.com/github/yast/yast-migration)
[![Inline docs](http://inch-ci.org/github/yast/yast-migration.svg?branch=master)](http://inch-ci.org/github/yast/yast-migration)

Description
============

This YaST module allows online migration for major and service pack releases.

### Features ###

- respect package locks
- allow resolve software conflicts
- adapt repositories
- show summary of proposed migration

### Limitations ###

- TBD

Development
===========

This module is developed as part of YaST. See the
[development documentation](http://yastgithubio.readthedocs.org/en/latest/development/).


Getting the Sources
===================

To get the source code, clone the GitHub repository:

    $ git clone https://github.com/yast/<repository>.git

If you want to contribute into the project you can
[fork](https://help.github.com/articles/fork-a-repo/) the repository and clone your fork.


Development Environment
=======================

The module is developed only for SLE.

Testing Environment
===================

> *Here describe (or link the docu, man pages,...) how to setup a specific environment
> needed for running and testing the module.*

> *Example: for iSCSI client you might describe (or link) how to setup an iSCSI server
> so it could be used by the client module.*


Troubleshooting
===============

> *Here you can describe (or link) some usefull hints for common problems when <b>developing</b> the module.
> You should describe just tricky solutions which need some deep knowledge about the module or
> the system and it is difficult to figure it out.*

> *Example: If the module crashes after compiling and installing a new version remove `/var/cache/foo/`
> content and start it again.*


Contact
=======

If you have any question, feel free to ask at the [development mailing
list](http://lists.opensuse.org/yast-devel/) or at the
[#yast](https://webchat.freenode.net/?channels=%23yast) IRC channel on freenode.
