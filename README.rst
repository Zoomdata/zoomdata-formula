================
zoomdata-formula
================

Install, configure and run the Zoomdata services.

**IMPORTANT!**

This code is experimental and still in development. It is not officially
supported by Zoomdata, Inc. and provided for evaluation purposes only.

**NOTE**

See the full `Salt Formulas installation and usage instructions
<https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

Available states
================

.. contents::
    :local:

``zoomdata``
------------

Bootstrap the Zoomdata services from scratch or upgrade existing installation.

``zoomdata.backup``
-------------------

Make backup of the Zoomdata (PostgreSQL) databases and installation state.

``zoomdata.install``
--------------------

Install the Zoomdata packages. Configure, enable and start the services.

``zoomdata.repo``
-----------------

Configure package repositories for installing the Zoomdata packages.

``zoomdata.restore``
--------------------

Restore the Zoomdata databases in a PostgreSQL cluster.

``zoomdata.tls``
----------------

Install a TLS (SSL) certificate with a private key into a Java keystore file.
