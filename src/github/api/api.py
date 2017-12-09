import os
import logging

import requests
from bottle import post, run, request, response

logging.basicConfig(
    format='%(asctime)s,%(msecs)d %(levelname)-8s [%(filename)s:%(lineno)d] %(message)s',
    datefmt='%d-%m-%Y:%H:%M:%S',
    level=logging.DEBUG
)

logger = logging.getLogger("github")

def get_env(name): # pragma: no cover
    if name not in os.environ:
        raise Exception("%s not set" % name)
    return os.environ[name]

def execute_api(url, token):
    headers = {
        "Authorization": "token " + token,
        "User-Agent": "InfraBox"
    }

    # TODO(ib-steffen): allow custom ca bundles
    url = get_env('INFRABOX_GITHUB_API_URL') + url
    return requests.get(url, headers, verify=False)

def error(status, message):
    response.status = status
    return {"message": message}

@post('/api/v1/commit')
def get_commit():
    query = dict(request.forms)

    if 'owner' not in query:
        return error(400, "owner not set")

    if 'token' not in query:
        return error(400, "token not set")

    if 'repo' not in query:
        return error(400, "repo not set")

    if 'branch' not in query and 'sha' not in query:
        return error(400, "either branch or sha must be set")

    if 'branch' in query:
        url = '/repos/%s/%s/git/refs/heads/%s' % (query['owner'], query['repo'], query['branch'])
        result = execute_api(url, query['token'])

        if result.status_code != 200:
            logger.warning(result.json())
            return error(500, "internal server error")

        result = result.json()[0]

        if not result:
            logger.warning('no result returned')
            return error(404, "Not Found")

        query['sha'] = result['object']['sha']

    url = '/repos/%s/%s/git/commits/%s' % (query['owner'], query['repo'], query['sha'])
    result = execute_api(url, query['token'])

    if result.status_code != 200:
        logger.warning(result.json())
        return error(500, "internal server error")

    result = result.json()

    return {
        "sha": result['sha'],
        "branch": query.get('branch', None),
        "url": result['html_url'],
        "author": {
            "name": result['author']['name'],
            "email": result['author']['email']
        },
        "message": result['message']
    }

def main(): # pragma: no cover
    get_env('INFRABOX_SERVICE')
    get_env('INFRABOX_VERSION')
    get_env('INFRABOX_GITHUB_API_URL')

    run(host='0.0.0.0', port=8081)

if __name__ == '__main__': # pragma: no cover
    main()
