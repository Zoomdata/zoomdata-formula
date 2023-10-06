zoomdata-formula
================

23.3.0 (2023-Oct-04)

- New quarter release (2023.3) no significant changes

23.2.0 (2023-Jul-13)

- New quarter release (2023.2) no significant changes

23.1.0 (2023-Apr-05)

- New quarter release (2023.1) no significant changes

22.4.0 (2022-Dec-26)

- New versioning schema - quarterly releases.

8.4.0 (2022-Nov-20)

- New rapid release.
- Last one in 8.X family - all upcoming Zoomdata/Composer formulas will be using quarterly release model with YY.Q version style.

8.3.0 (2022-Oct-23)

- New rapid release.
- Elasticsearch 6.0 was deprecated and removed from formula's defaults

8.2.0 (2022-Sep-12)

- New rapid release. No significant changes.

8.1.0 (2022-Aug-15)

- New rapid release. No significant changes.

8.0.0 (2022-Jul-18)

- New rapid release. No significant changes.

7.10.0 (2022-Jun-06) **The Composer (former Zoomdata) 7.10 has become Long Term Supported release**

- New rapid release. No significant changes.

7.9.0 (2022-May-14)

- New rapid release. No significant changes.

7.8.0 (2022-Apr-11)

- New rapid release. No significant changes.

7.7.0 (2022-Feb-28)

- New rapid release version bump

7.6.0 (2022-Jan-31)

- New rapid release version bump

7.5.0 (2022-Jan-04)

- New rapid release version bump

7.4.0 (2021-Dec-06)

- New rapid release version bump

7.3.0 (2021-Nov-08)

- New rapid release version bump

7.2.0 (2021-Sep-27)

- New rapid release version bump
- Default OS package repository links were changes to composer-repo.logianalytics.com

7.1.0 (2021-Aug-30)

- New rapid release version bump

7.0.0 (2021-Aug-02)

- New rapid release version bump

6.9.0 (2021-Jun-22) **The Zoomdata 6.9 has become Long Term Supported release**

- New LTS release 6.9
- Fixed bug with exact patch version required installations on CentOS/RHEL 7

6.8.0 (2021-May-19)

- New rapid release version bump

6.7.0 (2021-Apr-19)

- New Repid release version bump.
- Zoomdata-Formula will be soone renamed to Composerr-Formula to
  reflect latest Product rebranding.

6.6.0 (2021-Mar-22)

- New Rapid release version bump.

6.5.0 (2021-Feb-08)

- Next Rapid release version bump.
- Bootstrap is now uses internal SaltStack repo.

6.4.0 (2021-Jan-12)

- New Rapid Release version bump.

6.3.0 (2020-Dec-15)

- Support for CentOS 6 was completelly dropped.

6.2.0 (2020-Nov-03)

- New Rapid Release version bump.

6.1.0 (2020-Oct-06)

- New Rapid Release version bump.

6.0.0 (2020-Sep-09)

- New Rapid Release version bump.

5.9.0 (2020-Jul-08)

- New LTS version of Zoomdata.

5.5.0 (2020-Mar-09)

- New Rapid Release version bump.

5.3.0 (2020-Jan-14)

- Next RR version bump.

5.2.0 (2019-12-17)

- Next Rapid Release version bump.

5.1.0 (2019-11-18)

- Version bump in the examples to ensure compatibility with the Zoomdata 5.1.0

5.0.0 (2019-10-21) 

- New RR release with QE v2 as defaut engine

4.9.0 (2019-09-25) **The Zoomdata 4.9 has become Long Term Supported release**

- Added configurable probing of readiness for connector services after start
- Fixed removing of deprecated connector service packages
- Fixed setting the Query Engine service properties for connecting to external
  PostgreSQL metadata via environment variable
- Increase the timeout for running service post installation scripts, this
  fixes downloading from slow Ubuntu Archive repository
- Dropped default values for Zoomdata 3.7 due to its transition to *Passive
  Support* mode

4.8.0 (2019-08-27)

- Added Zoomdata Query Engine cache settings
- Fixed repository cache update for installing all connector packages
- ElasticSearch 5.0 connector was deprecated
- Added ElasticSearch 7.0 connector
- Fixed the upgrade when new connectors would be installed

4.7.0 (2019-07-29)

- Fixed recognition of configured custom Zoomdata Web server's port
- Made the Zoomdata Web server probe URI path configurable
- Added the Zoomdata Consul service configuration to the Pillar
- Allowed to connect to external Consul agent by providing
  ``ZOOMDATA_CONSUL_ADDRESS`` environment variable
- Allowed to install and run all available connectors
- Allowed to start all installed services
- Added environment variables to configure connection to PostgreSQL metadata

4.6.0 (2019-07-01)

- Version bump in the examples to ensure compatibility with the Zoomdata 4.6.0

4.5.0 (2019-05-03)

- Fixed detecting the Scheduler service configuration files in the Zoomdata LTS
  release 3.7
- Fixed enabling of Systemd units for new services on upgrades due to caching

4.4.0 (2019-04-08)

- Version bump in the examples to ensure compatibility with the Zoomdata 4.4.0

4.3.0 (2019-04-08)

- Removed HAproxy support and configuration example
- Removed the Zoomdata Scheduler and Upload services
- Renamed Stream Writer service to Data Writer for Zoomdata Rapid Release
- Fixed Stream Writer package name for Zoomdata 3.7 LTS release

4.2.0 (2019-03-07)

- Fixed ``zoomdata.backup`` state to save correct Pillar settings for later
  restoration
- Fixed ``zoomdata.inspect`` function to correctly parse Zoomdata repositories
  configuration
- Fixed detection of common version number for microservice packages

4.1.0 (2019-02-11)

- Added the Zoomdata Configuration Server to the Pillar example
- Added support for installation on Debian distributions via Ubuntu repository

4.0.0 (2019-01-14) **The Zoomdata 4.0 starts new Rapid Release cycle**

- Fixed branding setup
- Fixed creation of ``*.jvm`` files
- Allowed to configure post-installation commands
  (with an example for Screenshot Service)
- Fixed web user passwords initialization states
- Fixed obtaining Zoomdata Concurrent Session Count license V3
- Cleaned up and updated the Pillar example
- The Zoomdata Admin Server became "Core" service
- The Consul service is now a part of "microservices" packages group
- Fixed the Consul upgrade bug
- Fixed the states to use only Zoomdata API version 2
- Fixed documentation for custom modules and make them Python 3 compatible
- Fixed installation of the Zoomdata EDC JDBC drivers

3.7.0 (2018-11-20) **The Zoomdata 3.7 has become Long Term Supported release**

- Updated defaults to match the Zoomdata 3.7.0 recommended installation options
- Fixed ``zoomdata-consul`` service upgrade
- The ``zoomdata-edc-tez`` service has been deprecated and replaced with
  ``zoomdata-edc-hive`` (generic Hive datasource connector)
- Fixed the example of ``zoomdata-admin-server`` service properties
- Added the example of ElasticSearch backend configuration for
  ``zoomdata-tracing-server`` service
- Updated MySQL JDBC driver URL in the example

2.6.23 (2018-11-19) **The end of Active Support for the Zoomdata release 2.6**

- The Zoomdata 2.6 Long Term Support release has stopped receiving bugfixes.
  The last version of the Zoomdata Core service binaries is ``2.6.23``.
- The default variables were updated to reflect latest 2.6 release state
- Allowed downloading JDBC drivers for datasource connectors (EDC services)
  from URLs in package metadata file
- Fixed the Zoomdata packages, services and versions detection
- Cleaned up configuration file templates

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
