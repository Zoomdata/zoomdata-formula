# -*- coding: utf-8 -*-

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
        - password: Secure_Pass
        - css: http://example.com/custom.css
        - json_file: salt://zoomdata/files/custom-ui-payload-sample.json

Licensing
=========

Example:

.. code-block:: yaml

    zoomdata-license:
      zoomdata.licensing:
        - name: http://localhost:8080/zoomdata/
        - username: supervisor
        - password: Secure_Pass
        - url: http://licensing.server/api
        - expire: '2018-10-02'
        - type: ZD
        - users: 5
        - sessions: 2
        - concurrency: AT
"""


from datetime import datetime, timedelta
from urlparse import urljoin
import json
import salt.utils.http as http


HEADERS = {
    'Accept': '*/*',
    'Content-Type': 'application/vnd.zoomdata.v2+json',
}


def _file_data_encode(filename):
    """Encode file as multipart form data."""
    # pylint: disable=undefined-variable
    content = __salt__['cp.get_file_str'](filename)
    boundary = '----' + __salt__['random.get_str']().replace('_', '')
    lines = [
        '--{}'.format(boundary),
        'Content-Disposition: form-data; name="fileData"; filename="{}"'.format(
            __salt__['file.basename'](filename)),
        'Content-Type: application/octet-stream',
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


def branding(name,
             username,
             password,
             json_file=None,
             css=None):
    """
    Upload custom content files into the Zoomdata server.

    name
        The Zoomdata server URL to install licence into. Must contain a context
        path ending with slash ``/``. For example:
        ``http://localhost:8080/zoomdata/``

    username
        The Zoomdata server user authorized to inject files, i.e. ``supervisor``

    password
        The password

    json_file
        The URI to the JSON file with branding settings to apply on the
        Zoomdata UI

    css
        The URI to the file containing custom CSS to apply on the Zoomdata UI
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
        ret['comment'] = 'The state will set custom branding for Zoomdata at {0}'.format(name)
        ret['result'] = None
        return ret

    res = {'error': 'Need to supply either ``json_file`` or ``css`` parameter.'}

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

    if json_file:
        zoomdata_api = urljoin(name, 'api/branding')
        res = http.query(
            zoomdata_api,
            method='POST',
            username=username,
            password=password,
            header_dict=HEADERS,
            data_file=__salt__['cp.cache_file'](json_file)
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
        The password

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
        'concurrentUserCount': sessions,
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
