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

Install the Zoomdata packages. Configure, enable and start Zoomdata services.

``zoomdata.repo``
-----------------

Configure package repositories for installing Zoomdata.

``zoomdata.tls``
----------------

Install TLS (SSL) certificate with a private key into Java keystore and
configure https endpoint in the Zoomdata server.
