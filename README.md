hobbit
======

Perl module for xymon checks development

installation
------------

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

To build a .deb package from this module:

    debuild --check-dirname-level 0 -i -us -uc -b

usage
-----

Usage is described in the module itself and can be accessed with perldoc.

example
-------

Examples are given in the sample directory :
* openPort checks connectivity to a given list of hosts:ports through network.

