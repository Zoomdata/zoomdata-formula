zoomdata-formula
================

3.6.0 (2018-10-24)

- Added new ``zoomdata.setup`` SLS that allows setting up initial passwords,
  UI branding, adjust supervisor settings and install license for the Zoomdata
  server
- If the ``zoomdata`` service is configured to start (that's by default), it
  will be queried for successful response on REST API call for 900 seconds,
  when no other value specified in the ``zoomdata:setup:timeout`` Pillar value.
- Added examples of security related configuration parameters
- Added support for configuring ``*.jvm`` files (JVM command line options)
- Fixed detection of core Zoomdata packages during upgrades
- Fixed invoking backup state if no backup configured or nothing to upgrade
- Cleaned up legacy stuff

3.5.0 (2018-09-24)

- The tracing service (OpenZipkin) was renamed to ``zoomdata-tracing-server``
- Added optional ``zoomdata-admin-server`` service (Spring Boot Admin) to the
  Pillar example
- Disabled setting operating system limits by default
- Updated links to the Zoomdata Knowledge Base

3.4.0 (2018-08-23)

- Disabled (re)setting environment variables for services by default
- Added optional ``zoomdata-tracing`` service (OpenZipkin) to the Pillar example

3.3.0 (2018-07-30)

- Fixed state run when ``backup:destination`` Pillar is unset

3.2.0 (2018-07-02)

- Deprecated the ``zoomdata-xvfb`` service
- The service ``zoomdata-stream-writer`` has been renamed to
  ``zoomdata-stream-writer-postgresql``

3.1.0 (2018-06-11)

- Fixed upgrades and installation state detection
- Made ``zoomdata.tls`` SLS separated from the Zoomdata services installation
- Deprecated ``http.redirect.port`` setting in the Zoomdata Server
- Dropped legacy service (``zoomdata-spark-proxy``) from execution module
- Added new ``zoomdata-screenshot-service`` package

3.0.0 (2018-05-08)

- Fixed compatibilities with Salt versions between 2016.11 and 2018.3
- Do backup of the state when repository settings would be changed
- Fixed PostgreSQL related default settings and states
- Stop services before upgrade or manually initiated backup
- Added support for new Rapid Release of Zoomdata 3.0!

2.6.6 (2018-04-11)

- Added ``zoomdata.remove`` states
- Added ``zoomdata.tools`` states
- Removed deprecated Amazon Aurora connector from the example
- Removed "microservices" repository
- Zoomdata 2.6 became Long Term Support (LTS) release!

2.6.5 (2018-03-14)

- Removed deprecated ElasticSearch 2.0 connector from the example
- Recognize new environment variables: ``ZOOMDATA_PACKAGES``,
  ``ZOOMDATA_EDC_PACKAGES``, ``ZOOMDATA_SERVICES``
- Temporarily disabled ``zoomdata-zdmanage`` package in the example,
  it would break versions pinning. This should be fixed.
- Fixed parsing release number if multiple repos configured in an OS
- Bypass core packages detection when doing release upgrade (from 2.5)
- Fixed few regressions

2.6.4 (2018-02-13)

- Added ability to preserve local changes in property files (like passwords)
- Added backup and restore states for metadata in PostgreSQL
- Implemented support for new ``zoomdata-keyset`` database
- Added example how to utilize remote PostgreSQL server
- Added ElasticSearch 6.0 connector

2.6.3 (2018-01-22)

- Moved to public GitHub repo
- Updated Pillar example to cover Zoomdata 2.6.X (rapid) releases
- Allowed to preserve local modifications in property files
