# -*- coding: utf-8 -*-

"""
Zoomdata states.

Licensing
=========

Example:

.. code-block:: yaml

    zoomdata-license:
      zoomdata.licensing:
        - name: http://localhost:8080
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

    url
        The URL of licensing server endpoint to get a license key

    expire
        Expiration date as sting in ``YYYY-MM-DD`` format. If not given, assume
        one year from now.

    licence_type : TRIAL
        License type. It could be either ``TRIAL`` (default) or ``ZD`` (purchased).

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
        header_dict={
            'Accept': '*/*',
            'Content-Type': 'application/vnd.zoomdata.v2+json',
        },
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
