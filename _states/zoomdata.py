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
        - name: http://localhost:8080/zoomdata/
        - username: supervisor
        - password: Secure_Pas5
        - css: http://example.com/custom.css
        - login_logo: salt://branding/files/Zoomdata.svg
        - json_file: salt://zoomdata/files/custom-ui-payload-sample.json

Licensing
=========

Example:

.. code-block:: yaml

    zoomdata-license:
      zoomdata.licensing:
        - name: http://localhost:8080/zoomdata/
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
from urlparse import urljoin
import json
import mimetypes
import salt.utils.http as http


HEADERS = {
    'Accept': '*/*',
    'Content-Type': 'application/vnd.zoomdata.v2+json',
}


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

    body = '\r\n'.join(lines)
    headers = {
        'Content-Type': 'multipart/form-data; boundary={}'.format(boundary),
        'Content-Length': str(len(body)),
    }

    return headers, body


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
        The Zoomdata server URL to install licence into. Must contain a context
        path ending with slash ``/``. For example:
        ``http://localhost:8080/zoomdata/``

    username
        The Zoomdata server user authorized to inject files, i.e. ``supervisor``

    password
        User password

    css
        The URI to the file containing custom CSS to apply on the Zoomdata UI

    login_logo
        The URI to the file containing PNG or SVG image to use as Zoomdata
        login screen logo

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
        ret['comment'] = 'The state will set custom branding for Zoomdata at {0}'.format(name)
        ret['result'] = None
        return ret

    res = {'error': 'Need to supply either ``css`` or ``login_logo`` or ``json_file`` parameter.'}

    if css:
        headers, data = _file_data_encode(css)
        zoomdata_api = urljoin(name, 'api/branding/customCss')
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
        zoomdata_api = urljoin(name, 'api/branding/loginLogo')
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
        zoomdata_api = urljoin(name, 'api/branding')
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
            header_dict=HEADERS,
            data=jf_
        )

    if 'error' in res:
        ret['comment'] = res
    else:
        ret['comment'] = res['body']
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
        The Zoomdata server URL to install licence into. Must contain a context
        path ending with slash ``/``. For example:
        ``http://localhost:8080/zoomdata/``

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
        ret['comment'] = 'The state will retrive license for Zoomdata at {0}'.format(name)
        ret['result'] = None
        return ret

    # Retrive Zoomdata instance ID and current license type
    zoomdata_api = urljoin(name, 'api/license')
    res = http.query(
        zoomdata_api,
        username=username,
        password=password,
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

    data = {
        'instanceId': instance['instanceId'],
        'expirationDate': expire,
        'licenseType': license_type,
        'userCount': users,
        'concurrentSessionCount': sessions,
        'enforcementLevel': concurrency,
    }

    res = http.query(
        url,
        method='POST',
        data=data,
        text=True
    )

    if 'error' in res:
        ret['comment'] = res
        return ret

    # Install license key
    data = json.dumps({'licenseKey': res['body']})
    res = http.query(
        zoomdata_api,
        method='POST',
        username=username,
        password=password,
        header_dict=HEADERS,
        data=data,
        decode=True,
        decode_type='json'
    )

    if 'error' in res:
        ret['comment'] = res
    else:
        ret['changes'] = res['dict']
        ret['result'] = True

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
        'result': False,
        'comment': 'No library URLs found in the metadata file and no URLs given.',
        'pchanges': {},
    }

    # pylint: disable=undefined-variable
    if __opts__['test']:
        ret['comment'] = 'The state will download libraries for {0} service'.format(name)
        ret['result'] = None
        return ret

    prefix = __salt__['pillar.get'](
        'zoomdata:prefix',
        __salt__['defaults.get']('zoomdata:zoomdata:prefix')
    )

    if not prefix:
        ret['comment'] = ('Unable to read Zoomdata installation directory neither from '
                          '``zoomdata:prefix`` Pillar nor defaults.')
        return ret

    libs = {}
    service = name.replace('zoomdata-', '', 1)

    if urls:
        for i, url in enumerate(urls):
            libs.update({'url{0}'.format(i + 1): url})
    else:
        meta_file = __salt__['file.join'](prefix, metadata_path, service, 'PACKAGE-METADATA')
        if __salt__['file.file_exists'](meta_file):
            libs = __salt__['ini.get_section'](meta_file, 'libs')
        else:
            ret['comment'] = 'The metadata file not found.'

    if not libs:
        ret['result'] = True
        return ret

    comments = []
    res = {}
    for key in libs:
        if not key.startswith('url'):
            continue
        target = __salt__['file.join'](
            __salt__['file.join'](prefix, install_path, service),
            __salt__['file.basename'](libs[key]))
        res = __states__['file.managed'](
            target,
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

    if res:
        ret = res
        ret['comment'] = '\n'.join(comments)
        return ret

    ret['result'] = True
    return ret
