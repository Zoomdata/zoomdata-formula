# -*- coding: utf-8 -*-
'''
Manage and inspect Zoomdata installation

:maintainer:    Denys Havrysh <denis.gavrysh@zoomdata.com>
:maturity:      new
:depends:       urlparse
:platform:      GNU/Linux

'''


import urlparse


ENVIRONMENT = {
    'zoomdata': '/etc/zoomdata/zoomdata.env',
    'zoomdata-scheduler': '/etc/zoomdata/scheduler.env',
    'zoomdata-spark-proxy': '/etc/zoomdata/spark-proxy.env',
}

PROPERTIES = {
    'zoomdata': '/etc/zoomdata/zoomdata.properties',
    'zoomdata-scheduler': '/etc/zoomdata/scheduler.properties',
    'zoomdata-spark-proxy': '/etc/zoomdata/spark-proxy.properties',
}

ZOOMDATA = 'zoomdata'
EDC = 'zoomdata-edc'


def _parse_ini(path, chars=(' \'"')):
    '''
    Parse ini-like files to a dictionary, which also could be Spring
    application properties or shell environment files
    '''
    ret = {}

    # pylint: disable=undefined-variable
    if __salt__['file.access'](path, 'f'):
        contents = __salt__['file.grep'](path, r'^[^#]\+=.\+$')['stdout']
        for line in contents.splitlines():
            key, value = line.split('=', 1)
            # Strip whitespaces and quotes by default
            key = key.strip(chars)
            value = value.strip(chars)
            ret[key] = value

    if ret:
        return ret

    return None


def environment(path=ENVIRONMENT['zoomdata']):
    '''
    Display Zoomdata environment variables as dictionary

    Returns ``None`` if environment file cannot be read.

    path
        Full path to the environment file

    CLI Example:

    .. code-block:: bash

        salt '*' zoomdata.environment
    '''
    return _parse_ini(path)


def environment_scheduler(path=ENVIRONMENT['zoomdata-scheduler']):
    '''
    Display Zoomdata Scheduler environment variables as dictionary

    Returns ``None`` if environment file cannot be read.

    path
        Full path to the environment file

    CLI Example:

    .. code-block:: bash

        salt '*' zoomdata.environment_scheduler
    '''
    return _parse_ini(path)


def environment_spark_proxy(path=ENVIRONMENT['zoomdata-spark-proxy']):
    '''
    Display Zoomdata Spark Proxy environment variables as dictionary

    Returns ``None`` if environment file cannot be read.

    path
        Full path to the property file

    CLI Example:

    .. code-block:: bash

        salt '*' zoomdata.environment_spark_proxy
    '''
    return _parse_ini(path)


def properties(path=PROPERTIES['zoomdata']):
    '''
    Display Zoomdata properties as dictionary

    Returns ``None`` if property file cannot be read.

    path
        Full path to the property file

    CLI Example:

    .. code-block:: bash

        salt '*' zoomdata.properties
    '''
    return _parse_ini(path)


def properties_scheduler(path=PROPERTIES['zoomdata-scheduler']):
    '''
    Display Zoomdata Scheduler properties as dictionary

    Returns ``None`` if property file cannot be read.

    path
        Full path to the property file

    CLI Example:

    .. code-block:: bash

        salt '*' zoomdata.properties_scheduler
    '''
    return _parse_ini(path)


def properties_spark_proxy(path=PROPERTIES['zoomdata-spark-proxy']):
    '''
    Display Zoomdata Spark Proxy properties as dictionary

    Returns ``None`` if property file cannot be read.

    path
        Full path to the property file

    CLI Example:

    .. code-block:: bash

        salt '*' zoomdata.properties_spark_proxy
    '''
    return _parse_ini(path)


def list_repos():
    '''
    List Zoomdata repositories which are locally configured

    CLI Example:

    .. code-block:: bash

        salt '*' zoomdata.list_repos
    '''
    # pylint: disable=undefined-variable
    repos = __salt__['pkg.list_repos']()
    zd_repos = {}
    for repo in repos.keys():
        if repo.startswith(ZOOMDATA):
            zd_repos.update({repo: repos[repo]})

    return zd_repos


def list_pkgs(include_edc=False):
    '''
    List Zoomdata packages currently installed as a list

    include_edc : False
        Include EDC packages as well

    CLI Example:

    .. code-block:: bash

        salt '*' zoomdata.list_pkgs true
    '''
    # pylint: disable=undefined-variable
    pkg_versions = __salt__['pkg.list_pkgs']()
    pkg_names = pkg_versions.keys()
    zd_pkgs = []
    for pkg in sorted(pkg_names):
        if pkg.startswith(ZOOMDATA):
            if not include_edc and pkg.startswith(EDC):
                pass
            else:
                zd_pkgs.append(pkg)

    return zd_pkgs


def list_pkgs_edc():
    '''
    List only Zoomdata EDC packages currently installed as a list

    CLI Example:

    .. code-block:: bash

        salt '*' zoomdata.list_pkgs_edc
    '''
    edc_pkgs = []
    for pkg in list_pkgs(include_edc=True):
        if pkg.startswith(EDC):
            edc_pkgs.append(pkg)

    return edc_pkgs


def version():
    '''
    Display Zoomdata packages version

    CLI Example:

    .. code-block:: bash

        salt '*' zoomdata.version
    '''
    zd_version = ''
    zd_pkgs = list_pkgs()
    for pkg in zd_pkgs:
        # pylint: disable=undefined-variable
        zd_version = __salt__['pkg.version'](pkg)
        break

    return zd_version


def version_edc():
    '''
    Display Zoomdata EDC packages version

    CLI Example:

    .. code-block:: bash

        salt '*' zoomdata.version_edc
    '''
    edc_version = ''
    edc_pkgs = list_pkgs_edc()
    for pkg in edc_pkgs:
        # pylint: disable=undefined-variable
        edc_version = __salt__['pkg.version'](pkg)
        break

    return edc_version


def services(running=False):
    '''
    Return a list of available Zoomdata services

    running : False
        Return only running services

    CLI Example:

    .. code-block:: bash

        salt '*' zoomdata.services true
    '''
    # pylint: disable=undefined-variable
    zd_services = []
    for srv in __salt__['service.get_all']():
        if srv.startswith(ZOOMDATA):
            if running:
                if __salt__['service.status'](srv):
                    zd_services.append(srv)
            else:
                zd_services.append(srv)

    return zd_services


def inspect(limits=False,  # pylint: disable=too-many-locals,too-many-branches
            versions=False):
    '''
    Inspect Zoomdata installation and return info as dictionary structure

    versions : False
        Include exact versions of Zoomdata and EDC

    CLI Example:

    .. code-block:: bash

        salt --out=yaml '*' zoomdata.inspect
    '''
    baseurl = None
    gpgkey = None
    release = None
    components = []
    env = {}
    config = {}

    for params in list_repos().itervalues():
        url = urlparse.urlparse(params['baseurl'])
        if baseurl is None:
            baseurl = urlparse.urlunparse((url.scheme, url.netloc, '', '', '', ''))
        if gpgkey is None:
            gpgkey = params['gpgkey']
        if release is None:
            release = url.path.split('/')[1]
        components.append(url.path.rsplit('/')[-1])

    for service, env_file in ENVIRONMENT.iteritems():
        parsed_env = environment(env_file)
        if parsed_env is None:
            env[service] = None
        else:
            # file with environment is present
            env[service] = {
                'path': env_file,
                'variables': parsed_env,
            }

    for service, config_file in PROPERTIES.iteritems():
        config[service] = {}
        configuration = {}

        legacy_file = config_file.rsplit('.', 1)[0] + '.conf'
        legacy_config = properties(legacy_file)
        if legacy_config:
            config[service].update({
                'old_path': legacy_file,
            })
            configuration.update(legacy_config)

        new_config = properties(config_file)
        if new_config:
            configuration.update(new_config)
        elif not configuration:
            config[service] = None
            continue

        config[service].update({
            # Disable merging with defaults is mandatory here
            'merge': False,
            'path': config_file,
            'properties': configuration,
        })

    ret = {
        ZOOMDATA: {
            'base_url': baseurl,
            'gpgkey': gpgkey,
            'release': release,
            'components': components,
            'packages': list_pkgs(),
            'edc': {
                'packages': list_pkgs_edc(),
            },
            'environment': env,
            'config': config,
            'services': services(True),
        },
    }

    if limits:
        # TO DO: implement reading limits.
        # Just skip limits configuration for now to omit defaults.
        ret[ZOOMDATA].update({
            'limits': None,
        })

    if versions:
        ret[ZOOMDATA].update({
            'version': version(),
        })
        ret[ZOOMDATA]['edc'].update({
            'version': version_edc(),
        })

    return ret
