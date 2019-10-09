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

Make backup of the Zoomdata installation state and metadata (PostgreSQL)
databases.

``zoomdata.backup.layout``
~~~~~~~~~~~~~~~~~~~~~~~~~~

Prepare a directory on local filesystem to store backups.

``zoomdata.backup.metadata``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Write compressed dumps of PostgreSQL databases.

``zoomdata.backup.retension``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Remove old backups. Keep last 10 by default.

``zoomdata.backup.state``
~~~~~~~~~~~~~~~~~~~~~~~~~

Write a Pillar SLS file that describes current Zoomdata installation state.

``zoomdata.remove``
-------------------

Disable the Zoomdata services and uninstall the Zoomdata packages.

``zoomdata.repo``
-----------------

Configure package repositories for installing the Zoomdata packages.

``zoomdata.restore``
--------------------

Restore the Zoomdata installation from previously made backup.

``zoomdata.restore.metadata``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Restore the Zoomdata databases in a PostgreSQL cluster.

``zoomdata.services``
---------------------

Install, configure, enable and start the Zoomdata services.

``zoomdata.services.install``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Install the Zoomdata packages and write the configuration files.

``zoomdata.services.start``
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Start the Zoomdata services.

``zoomdata.services.stop``
~~~~~~~~~~~~~~~~~~~~~~~~~~

Stop the Zoomdata services.

``zoomdata.setup``
------------------

Setup initial runtime parameters for the Zoomdata server.

``zoomdata.tools``
------------------

Install additional explicitly defined packages from ``tools`` repository.
