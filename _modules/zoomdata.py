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
}

PROPERTIES = {
    'zoomdata': '/etc/zoomdata/zoomdata.properties',
    'zoomdata-scheduler': '/etc/zoomdata/scheduler.properties',
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


def list_pkgs(include_edc=True, include_microservices=True, include_tools=True):
    '''
    List currently installed Zoomdata packages

    include_edc : True
        Include EDC packages as well

    include_microservices : True
        Include microservices packages as well

    include_tools : True
        Include tool packages as well

    CLI Example:

    .. code-block:: bash

        salt '*' zoomdata.list_pkgs include_tools=False
    '''
    # pylint: disable=undefined-variable
    zd_pkgs = [i for i in __salt__['pkg.list_pkgs']() if i.startswith(ZOOMDATA)]

    if not include_edc:
        zd_pkgs = list(set(zd_pkgs) - set(list_pkgs_edc()))

    if not include_microservices:
        zd_pkgs = list(set(zd_pkgs) - set(list_pkgs_microservices()))

    if not include_tools:
        zd_pkgs = list(set(zd_pkgs) - set(list_pkgs_tools()))

    return sorted(zd_pkgs)


def list_pkgs_edc():
    '''
    List only currently installed Zoomdata EDC (data connector) packages

    CLI Example:

    .. code-block:: bash

        salt '*' zoomdata.list_pkgs_edc
    '''
    # pylint: disable=undefined-variable
    edc_pkgs = [i for i in __salt__['pkg.list_pkgs']() if i.startswith(EDC)]

    return sorted(edc_pkgs)


def list_pkgs_microservices():
    '''
    List only currently installed Zoomdata microservice packages

    CLI Example:

    .. code-block:: bash

        salt '*' zoomdata.list_pkgs_microservices
    '''
    # pylint: disable=undefined-variable
    m_s = __salt__['defaults.get']('zoomdata:zoomdata:microservices:packages', [])
    m_s.extend(__salt__['pillar.get']('zoomdata:microservices:packages') or [])
    ms_pkgs = [i for i in __salt__['pkg.list_pkgs']() if i in list(set(m_s))]

    return sorted(ms_pkgs)


def list_pkgs_tools():
    '''
    List only currently installed Zoomdata tool packages

    CLI Example:

    .. code-block:: bash

        salt '*' zoomdata.list_pkgs_tools
    '''
    # pylint: disable=undefined-variable
    tools = [i for i in __salt__['pkg.list_pkgs']()
             if i.startswith(ZOOMDATA) and i not in __salt__['service.get_all']()]

    return sorted(tools)


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
    zd_pkgs = list_pkgs(include_tools=False)
    for pkg in zd_pkgs:
        # pylint: disable=undefined-variable
        zd_version = __salt__['pkg.version'](pkg)
        if not full:
            return zd_version.split('-')[0]
        break

    return zd_version


def version_edc(full=True):
    '''
    Display Zoomdata EDC (datasource connector) packages version

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
    Display Zoomdata microservice packages version

    CLI Example:

    full : True
        Return full version. If set False, return only short version (X.Y.Z).

    .. code-block:: bash

        salt '*' zoomdata.version_microservices
    '''
    ms_version = ''
    ms_pkgs = list_pkgs_microservices()
    for pkg in ms_pkgs:
        # pylint: disable=undefined-variable
        ms_version = __salt__['pkg.version'](pkg)
        if not full:
            return ms_version.split('-')[0]
        break

    return ms_version


def version_tools(full=True):
    '''
    Display Zoomdata tool packages version

    CLI Example:

    full : True
        Return full version. If set False, return only short version (X.Y.Z).

    .. code-block:: bash

        salt '*' zoomdata.version_tools
    '''
    t_version = ''
    tools = list_pkgs_tools()
    for pkg in tools:
        # pylint: disable=undefined-variable
        t_version = __salt__['pkg.version'](pkg)
        if not full:
            return t_version.split('-')[0]
        break

    return t_version


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
    repositories = []
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
            if repo_root == 'latest':
                release = repo_root
            else:
                repositories.append(repo_root)

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
            'release': str(release),
            'repositories': repositories,
            'components': components,
            'packages': list_pkgs(include_edc=False,
                                  include_microservices=False,
                                  include_tools=False),
            'edc': {
                'packages': list_pkgs_edc(),
            },
            'microservices': {
                'packages': list_pkgs_microservices(),
            },
            'tools': {
                'packages': list_pkgs_tools(),
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
            # so we strip it off
            'version': version_edc(full=False),
        })
        ret[ZOOMDATA]['microservices'].update({
            'version': version_microservices(full=full),
        })
        ret[ZOOMDATA]['tools'].update({
            'version': version_tools(full=full),
        })

    return ret
