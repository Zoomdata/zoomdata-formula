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
    Parse ini-like files to a dictionary, which also could be
    Java Spring application properties or shell environment files
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


def list_pkgs(include_edc=False, include_microservices=False, include_tools=False):
    '''
    List Zoomdata packages currently installed as a list

    include_edc : False
        Include EDC packages as well

    include_microservices : False
        Include microservices packages as well

    include_tools : False
        Include tool packages as well

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
            elif not include_microservices and \
                    pkg in __salt__['pillar.get']('zoomdata:microservices:packages', []):
                pass
            elif not include_tools and __salt__['service.missing'](pkg):
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


def list_pkgs_ms():
    '''
    List only Zoomdata microservices packages currently installed as a list

    CLI Example:

    .. code-block:: bash

        salt '*' zoomdata.list_pkgs_ms
    '''
    ms_pkgs = []
    for pkg in list_pkgs(include_microservices=True):
        # pylint: disable=undefined-variable
        if pkg in __salt__['defaults.get']('zoomdata:zoomdata:microservices:packages', []):
            ms_pkgs.append(pkg)

    return ms_pkgs


def version(full=True):
    '''
    Display Zoomdata packages version

    full : True
        Return full version. If set False, return only short version (X.Y.Z).

    CLI Example:

    .. code-block:: bash

        salt '*' zoomdata.version
    '''
    zd_version = ''
    zd_pkgs = list_pkgs()
    for pkg in zd_pkgs:
        # pylint: disable=undefined-variable
        zd_version = __salt__['pkg.version'](pkg)
        if not full:
            return zd_version.split('-')[0]
        break

    return zd_version


def version_edc(full=True):
    '''
    Display Zoomdata EDC packages version

    CLI Example:

    full : True
        Return full version. If set False, return only short version (X.Y.Z).

    .. code-block:: bash

        salt '*' zoomdata.version_edc
    '''
    edc_version = ''
    edc_pkgs = list_pkgs_edc()
    for pkg in edc_pkgs:
        # pylint: disable=undefined-variable
        edc_version = __salt__['pkg.version'](pkg)
        if not full:
            return edc_version.split('-')[0]
        break

    return edc_version


def version_microservices(full=True):
    '''
    Display Zoomdata microservices packages version

    CLI Example:

    full : True
        Return full version. If set False, return only short version (X.Y.Z).

    .. code-block:: bash

        salt '*' zoomdata.version_microservices
    '''
    ms_version = ''
    ms_pkgs = list_pkgs_ms()
    for pkg in ms_pkgs:
        # pylint: disable=undefined-variable
        ms_version = __salt__['pkg.version'](pkg)
        if not full:
            return ms_version.split('-')[0]
        break

    return ms_version


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

    if ZOOMDATA in zd_services:
        # Put zoomdata service to the end of the list,
        # because it is better to be started last
        zd_services.remove(ZOOMDATA)
        zd_services.append(ZOOMDATA)

    return zd_services


# pylint: disable=too-many-locals,too-many-branches,too-many-statements
def inspect(limits=False,
            versions=False,
            full=True):
    '''
    Inspect Zoomdata installation and return info as dictionary structure

    limits : False
        Detect system limits. Currently not implemented, so this parameter
        just returns ``None`` for ``limits`` key.

    versions : False
        Include exact versions of Zoomdata and EDC installed

    full : True
        Return full version. If set False, return only short version (X.Y.Z).
        Has effect only when ``versions`` parameter set True.

    CLI Example:

    .. code-block:: bash

        salt --out=yaml '*' zoomdata.inspect
    '''
    baseurl = None
    gpgkey = None
    gpgcheck = False
    release = None
    components = []
    env = {}
    config = {}

    for params in list_repos().itervalues():
        url = urlparse.urlparse(params['baseurl'].strip())
        if baseurl is None:
            baseurl = urlparse.urlunparse((url.scheme, url.netloc, '', '', '', ''))
        try:
            if int(params.get('gpgcheck', '0')):
                gpgcheck = True
        except ValueError:
            pass
        if gpgkey is None and 'gpgkey' in params:
            gpgkey = params['gpgkey'].strip()

        repo_root = url.path.split('/')[1]
        try:
            release = float(repo_root) if not release or float(repo_root) > release else release
        except ValueError:
            pass

        component = url.path.rstrip('/').rsplit('/')[-1]
        if component not in components:
            components.append(component)

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
            'release': release,
            'components': components,
            'packages': list_pkgs(),
            'edc': {
                'packages': list_pkgs_edc(),
            },
            'microservices': {
                'packages': list_pkgs_ms(),
            },
            'environment': env,
            'config': config,
            'services': services(True),
        },
    }

    if not gpgcheck:
        ret[ZOOMDATA]['gpgkey'] = None
    elif gpgkey:
        # Return the key only when it is really used
        ret[ZOOMDATA]['gpgkey'] = gpgkey

    if limits:
        # TO DO: implement reading limits.
        # Just skip limits configuration for now to omit defaults.
        ret[ZOOMDATA].update({
            'limits': None,
        })

    if versions:
        ret[ZOOMDATA].update({
            'version': version(full=full),
        })
        ret[ZOOMDATA]['edc'].update({
            # Some EDC packages has different iteration (build number),
            # so we strip it off.
            'version': version_edc(full=False),
        })
        ret[ZOOMDATA]['microservices'].update({
            'version': version_microservices(full=full),
        })

    return ret
