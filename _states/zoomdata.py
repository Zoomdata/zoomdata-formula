# -*- coding: utf-8 -*-

# pylint: disable=line-too-long
"""
Zoomdata states.

Branding
========

Example:

.. code-block:: yaml

    zoomdata-branding:
      zoomdata.branding:
        - name: http://localhost:8080/zoomdata/api/
        - username: supervisor
        - password: Secure_Pas5
        - css: http://example.com/custom.css
        - login_logo: salt://branding/files/Zoomdata.svg
        - json_file: salt://zoomdata/files/custom-ui-payload-sample.json

Initial Passwords
=================

Example:

.. code-block:: yaml

    zoomdata-setup-passwords:
      zoomdata.init_users:
        - name: http://localhost:8080/zoomdata/api/
        - users:
            admin: Admin_Pas5
            supervisor: Super_Pas5

Licensing
=========

Example:

.. code-block:: yaml

    zoomdata-license:
      zoomdata.licensing:
        - name: http://localhost:8080/zoomdata/api/
        - username: supervisor
        - password: Secure_Pas5
        - url: http://licensing.server/api
        - expire: '2018-10-02'
        - type: ZD
        - users: 5
        - sessions: 2
        - concurrency: AT

External Libraries
==================

Example:

.. code-block:: yaml

    zoomdata-edc-mysql-libs:
      zoomdata.libraries:
        - name: zoomdata-edc-mysql
        - urls:
          - 'https://repo1.maven.org/maven2/org/mariadb/jdbc/mariadb-java-client/1.3.2/mariadb-java-client-1.3.2.jar'
"""
# pylint: enable=line-too-long


from datetime import datetime, timedelta
import json
import mimetypes

try:
    from urlparse import urljoin
except ImportError:
    # Py3
    from urllib.parse import urljoin

from salt.utils import http  # pylint: disable=import-error,no-name-in-module


def _file_data_encode(filename):
    """Encode file as multipart form data."""
    mimetypes.init()
    mimetypes.add_type('image/svg+xml', '.svg')
    content_type = mimetypes.guess_type(filename)[0] or 'application/octet-stream'

    # pylint: disable=undefined-variable
    content = __salt__['cp.get_file_str'](filename)
    boundary = '----' + __salt__['random.get_str']().replace('_', '')

    lines = [
        '--{}'.format(boundary),
        'Content-Disposition: form-data; name="fileData"; filename="{}"'.format(
            __salt__['file.basename'](filename)),
        'Content-Type: {}'.format(content_type),
        '',
        content,
        '--{}--'.format(boundary),
        ''
    ]
    # pylint: enable=undefined-variable

    body = '\r\n'.join(lines)
    headers = {
        'Content-Type': 'multipart/form-data; boundary={}'.format(boundary),
        'Content-Length': str(len(body)),
    }

    return headers, body


def _urljoin(prefix, document):
    """Wrap around the function from urlparse."""
    if not prefix.endswith('/'):
        prefix = "{}/".format(prefix)
    return urljoin(prefix, document)


# pylint: disable=too-many-arguments
def branding(name,
             username,
             password,
             css=None,
             login_logo=None,
             json_file=None):
    """
    Upload custom content files into the Zoomdata server.

    name
        The Zoomdata server API URL to install licence into. For example:
        ``http://localhost:8080/zoomdata/api/``

    username
        The Zoomdata server user authorized to inject files, i.e. ``supervisor``

    password
        User password

    css
        The URI to the file containing custom CSS to apply on the Zoomdata UI

    login_logo
        The URI to the file containing PNG or SVG image to use as login screen
        logo for the Zoomdata server

    json_file
        The URI to the JSON file with branding settings to apply on the
        Zoomdata UI
    """
    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': '',
        'pchanges': {},
    }

    logo_id = None

    # pylint: disable=undefined-variable
    if __opts__['test']:
        ret['comment'] = 'The state will set custom branding for the Zoomdata at {0}'.format(name)
        ret['result'] = None
        return ret

    res = {'error': 'Need to supply either ``css`` or ``login_logo`` or ``json_file`` parameter.'}

    if css:
        headers, data = _file_data_encode(css)
        zoomdata_api = _urljoin(name, 'branding/customCss')
        res = http.query(
            zoomdata_api,
            method='POST',
            username=username,
            password=password,
            header_dict=headers,
            data=data
        )
        if 'error' in res:
            ret['comment'] = res
            return ret

    if login_logo:
        headers, data = _file_data_encode(login_logo)
        zoomdata_api = _urljoin(name, 'branding/loginLogo')
        res = http.query(
            zoomdata_api,
            method='POST',
            username=username,
            password=password,
            header_dict=headers,
            data=data,
            text=True
        )
        if 'error' in res:
            ret['comment'] = res
            return ret
        logo_id = res['text']

    if json_file:
        zoomdata_api = _urljoin(name, 'branding')
        jf_ = __salt__['cp.get_file_str'](json_file)
        if logo_id:
            payload = json.loads(jf_)
            payload.update({'loginLogo': logo_id})
            jf_ = json.dumps(payload)
        res = http.query(
            zoomdata_api,
            method='POST',
            username=username,
            password=password,
            header_dict=__salt__['defaults.get']('zoomdata:zoomdata:setup:headers'),
            data=jf_
        )
    # pylint: enable=undefined-variable

    if 'error' in res:
        ret['comment'] = res
    else:
        ret['comment'] = res['body']
        ret['result'] = True

    return ret


def init_users(name,
               users):
    """
    Intialize default users for the Zoomdata server.

    name
        The Zoomdata server API URL to install licence into. For example:
        ``http://localhost:8080/zoomdata/api/``

    users
        A dictionary with usernames as keys and passwords as respective values
    """
    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': '',
        'pchanges': {},
    }

    # pylint: disable=undefined-variable
    if __opts__['test']:
        ret['comment'] = \
            'The state will init default passwords for the Zoomdata at {0}'.format(name)
        ret['result'] = None
        return ret

    init = __salt__['defaults.get']('zoomdata:zoomdata:setup:init')
    headers = __salt__['defaults.get']('zoomdata:zoomdata:setup:headers')
    # pylint: enable=undefined-variable

    user_api = _urljoin(name, 'user')
    res = http.query(
        user_api,
        username=init['username'],
        password=init['password']
    )

    if 'error' in res:
        if res['status'] == 401:
            ret['comment'] = 'The passwords already have been set.'
            # This is a success and we have nothing to do
            ret['result'] = True
        else:
            ret['comment'] = res['error']
        return ret

    init_api = _urljoin(name, 'user/initUsers')
    data = json.dumps([{'user': i, 'password': users[i]} for i in users])
    res = http.query(
        init_api,
        method='POST',
        header_dict=headers,
        username=init['username'],
        password=init['password'],
        data=data,
        decode=True,
        decode_type='json'
    )

    if 'error' in res:
        ret['comment'] = 'Failed to set up initial passwords for default users.'
        ret['changes'] = res
    else:
        ret['changes'] = res['dict']
        ret['comment'] = 'Successfully set initial passwords for default users.'
        ret['result'] = True

    return ret


# pylint: disable=too-many-arguments
def licensing(name,
              username,
              password,
              url,
              expire=None,
              license_type='TRIAL',
              users=1,
              sessions=1,
              concurrency='PS',
              force=False):
    """
    Retrieve and install license into the Zoomdata server.

    name
        The Zoomdata server URL to install licence into. For example:
        ``http://localhost:8080/zoomdata/api/``

    username
        The Zoomdata server user authorized to inject files, i.e. ``supervisor``

    password
        User password

    url
        The URL of licensing server endpoint to get a license key

    expire
        Expiration date as sting in ``YYYY-MM-DD`` format. If not given, assume
        one year from now.

    licence_type : TRIAL
        License type. It could be either ``TRIAL`` (default) or ``ZD``
        (purchased).

    users
        User count

    sessions
        Concurrent session count

    concurrency
        Concurrency enforcement type. It could be ``PS`` or ``AT``.

    force
        Forcibly install new licence if set ``True``. Works only for ``TRIAL``
        licenses.
    """
    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': '',
        'pchanges': {},
    }

    # pylint: disable=undefined-variable
    if __opts__['test']:
        ret['comment'] = 'The state will retrive license for the Zoomdata at {0}'.format(name)
        ret['result'] = None
        return ret

    headers = __salt__['defaults.get']('zoomdata:zoomdata:setup:headers')
    # pylint: enable=undefined-variable

    # Retrive Zoomdata instance ID and current license type
    zoomdata_api = _urljoin(name, 'license')
    res = http.query(
        zoomdata_api,
        username=username,
        password=password,
        header_dict=headers,
        decode=True,
        decode_type='json'
    )

    if 'error' in res:
        ret['comment'] = res
        return ret

    instance = res['dict']
    if instance['type'] == license_type and not instance['expired'] and not force:
        ret['comment'] = 'The licence of requested type is already installed.'
        ret['result'] = True
        return ret

    # Get license key
    if not expire:
        expire = (datetime.now() + timedelta(days=365)).strftime('%Y-%m-%d')

    res = http.query(
        url,
        method='POST',
        data={
            'instanceId': instance['instanceId'],
            'expirationDate': expire,
            'licenseType': license_type,
            'userCount': users,
            'concurrentSessionCount': sessions,
            'enforcementLevel': concurrency,
        },
        text=True
    )

    if 'error' in res:
        ret['comment'] = res
        return ret

    # Install license key
    res = http.query(
        zoomdata_api,
        method='POST',
        username=username,
        password=password,
        header_dict=headers,
        data=json.dumps({'licenseKey': res['body']}),
        decode=True,
        decode_type='json'
    )

    if 'error' in res:
        ret['comment'] = res
    else:
        ret['changes'] = res['dict']
        ret['result'] = True

    return ret


def edc_installed(name, **kwargs):
    """
    Install all connector packages available from repository.

    name
        The name of the state

    All other keyword arguments will be passed to ``pkg.installed`` state.
    """
    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ('Getting available package versions is not supported on ',
                    'your operating system and/or Salt version'),
        'pchanges': {},
    }

    # pylint: disable=undefined-variable
    supported_by_salt = 'pkg.list_repo_pkgs' in __salt__

    if __opts__['test']:
        if supported_by_salt:
            ret['comment'] = 'The state will install all connector packages'
            ret['result'] = None
        return ret

    # This will not work on Salt earlier than 2017.7 for APT-based distros
    if supported_by_salt:
        __salt__['pkg.refresh_db']()
        pkgs = __salt__['zoomdata.list_pkgs_edc'](from_repo=True)
        ret = __states__['pkg.installed'](name, pkgs=pkgs, **kwargs)
    # pylint: enable=undefined-variable

    return ret


def service_probe(name, url_path, timeout=None):
    """
    Probe if service has been started successfully.

    name
        The name of the Zoomdata service package

    url_path
        The URL path to service health HTTP endpoint. Used to check if the
        service is available.

    timeout
        Wait for specified amount of time (in seconds) for service to come up
        and respond to requests. Works only if ``url_path`` has been provided.
    """
    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': 'The service {} not found.'.format(name),
        'pchanges': {},
    }

    # pylint: disable=undefined-variable
    if __opts__['test']:
        ret['comment'] = 'The state will probe service of readiness'
        ret['result'] = None
        return ret

    service = name.replace('zoomdata-', '', 1)
    prefix = __salt__['defaults.get']('zoomdata:zoomdata:prefix')
    port = __salt__['zoomdata.properties'](
        __salt__['file.join'](prefix, 'conf', '{}.properties'.format(service))
    )['server.port']

    url = urljoin('http://localhost:{}/'.format(port), url_path)
    if timeout:
        res = __salt__['http.wait_for_successful_query'](
            url,
            wait_for=timeout,
            status=200)
    # pylint: enable=undefined-variable
    else:
        res = http.query(url)

    if res and not res.get('error'):
        ret['result'] = True

    ret['comment'] = res['body']

    return ret


def edc_running(name, url_path=None, timeout=None, **kwargs):
    """
    Run all installed connector services.

    name
        The name of the state

    url_path
        The URL path to service health HTTP endpoint. Used to check if the
        service is available.

    timeout
        Wait for specified amount of time (in seconds) for service to come up
        and respond to requests. Works only if ``url_path`` has been provided.

    All other keyword arguments will be passed to ``service.running`` state.
    """
    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': 'No installed connector services found.',
        'pchanges': {},
    }

    res = {}
    comments = []

    # pylint: disable=undefined-variable
    if __opts__['test']:
        ret['comment'] = 'The state will start all connector services'
        ret['result'] = None
        return ret

    services = [i for i in __salt__['zoomdata.services']() if i.startswith('zoomdata-edc-')]
    for service in services:
        res = __states__['service.running'](service, **kwargs)
        # pylint: enable=undefined-variable
        if not res['result']:
            return res
        if url_path:
            probe = service_probe(service, url_path, timeout)
            if not probe['result']:
                res['comment'] = probe['comment']
                res['result'] = probe['result']
                return res
        comments.append(res['comment'])

    if res:
        ret = res
        ret['name'] = name
        ret['comment'] = '\n'.join(comments)

    return ret


def libraries(name,
              urls=None,
              metadata_path='docs',
              install_path='lib'):
    """
    Retrieve and install external jar files for Zoomdata service.

    name
        The name of the Zoomdata service

    urls
        List of URL links to download library files from. If not provided,
        try to read package metadata file and obtain the URLs from there.

    metadata_path
        The subdirectory relative to the Zoomdata installation path where the
        metadata file installed

    install_path
        The subdirectory relative to the Zoomdata installation path where the
        library files will be downloaded
    """
    ret = {
        'name': name,
        'changes': {},
        'result': True,
        'comment': 'No library URLs found in the metadata file and no URLs given.',
        'pchanges': {},
    }

    # pylint: disable=undefined-variable
    if __opts__['test']:
        ret['comment'] = 'The state will download libraries for {0} service'.format(name)
        ret['result'] = None
        return ret

    prefix = __salt__['defaults.get']('zoomdata:zoomdata:prefix')

    services = [name]

    if 'zoomdata-edc-all' in services:
        services = __salt__['zoomdata.list_pkgs_edc']()

    services = [i.replace('zoomdata-', '', 1) for i in services]

    comments = []
    res = {}

    for service in services:
        libs = {}
        if urls:
            for i, url in enumerate(urls):
                libs.update({'url{0}'.format(i + 1): url})
        else:
            meta_file = __salt__['file.join'](prefix, metadata_path, service, 'PACKAGE-METADATA')
            if __salt__['file.file_exists'](meta_file):
                libs.update(__salt__['ini.get_section'](meta_file, 'libs'))
            else:
                ret['comment'] = 'The metadata file not found.'

        for key in libs:
            if not key.startswith('url'):
                continue
            res = __states__['file.managed'](
                __salt__['file.join'](
                    __salt__['file.join'](prefix, install_path, service),
                    __salt__['file.basename'](libs[key])
                ),
                source=libs[key],
                skip_verify=True,
                user='root',
                group='root',
                mode=644,
                makedirs=True,
                dir_mode=755,
                show_changes=False
            )
            if not res['result']:
                return res
            comments.append(res['comment'])
    # pylint: enable=undefined-variable

    if res:
        ret = res
        ret['name'] = name
        ret['comment'] = '\n'.join(comments)

    return ret
