import json
import select
import urllib

import psycopg2
import paramiko

from pyinfraboxutils import get_logger, get_env, print_stackdriver
from pyinfraboxutils.db import connect_db
from pyinfraboxutils.leader import elect_leader, is_leader

logger = get_logger("gerrit")

def main():
    get_env('INFRABOX_SERVICE')
    get_env('INFRABOX_VERSION')
    get_env('INFRABOX_DATABASE_DB')
    get_env('INFRABOX_DATABASE_USER')
    get_env('INFRABOX_DATABASE_PASSWORD')
    get_env('INFRABOX_DATABASE_HOST')
    get_env('INFRABOX_DATABASE_PORT')
    get_env('INFRABOX_GERRIT_PORT')
    get_env('INFRABOX_GERRIT_HOSTNAME')
    get_env('INFRABOX_GERRIT_USERNAME')
    get_env('INFRABOX_GERRIT_KEY_FILENAME')
    get_env('INFRABOX_ROOT_URL')

    conn = connect_db()
    conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
    logger.info("Connected to database")

    elect_leader(conn, "gerrit-review")

    curs = conn.cursor()
    curs.execute("LISTEN job_update;")

    logger.info("Waiting for job updates")

    while True:
        is_leader(conn, "gerrit-review")
        if select.select([conn], [], [], 5) != ([], [], []):
            conn.poll()
            while conn.notifies:
                notify = conn.notifies.pop(0)
                handle_job_update(conn, json.loads(notify.payload))

def handle_job_update_retry(conn, update):
    for _ in xrange(0, 3):
        try:
            handle_job_update(conn, update)
            return
        except:
            logger.exception()

    logger.error('Failed to set review multiple times. Restarting')


def execute_ssh_cmd(client, cmd):
    _, stdout, stderr = client.exec_command(cmd)
    err = stderr.read()
    if err:
        logger.error(err)

    out = stdout.read()
    if out:
        logger.error(out)


def handle_job_update(conn, event):
    if event['type'] != 'UPDATE':
        return

    job_id = event['job_id']

    c = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    c.execute('''
        SELECT id, state, name, project_id, build_id
        FROM job
        WHERE id = %s
    ''', [job_id])

    job = c.fetchone()
    c.close()

    if not job:
        return

    project_id = job['project_id']
    build_id = job['build_id']

    c = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    c.execute('''
        SELECT id, name, type
        FROM project
        WHERE id = %s
    ''', [project_id])
    project = c.fetchone()
    c.close()

    if not project:
        return

    if project['type'] != 'gerrit':
        return

    c = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    c.execute('''
        SELECT id, build_number, restart_counter, commit_id
        FROM build
        WHERE id = %s
    ''', [build_id])
    build = c.fetchone()
    c.close()

    project_name = project['name']
    job_state = job['state']
    job_name = job['name']
    commit_sha = build['commit_id']
    build_id = build['id']
    build_number = build['build_number']
    build_restart_counter = build['restart_counter']

    if job_state in ('queued', 'scheduled', 'running'):
        return

    gerrit_port = int(get_env('INFRABOX_GERRIT_PORT'))
    gerrit_hostname = get_env('INFRABOX_GERRIT_HOSTNAME')
    gerrit_username = get_env('INFRABOX_GERRIT_USERNAME')
    gerrit_key_filename = get_env('INFRABOX_GERRIT_KEY_FILENAME')
    dashboard_url = get_env('INFRABOX_ROOT_URL')

    client = paramiko.SSHClient()
    client.load_system_host_keys()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(username=gerrit_username,
                   hostname=gerrit_hostname,
                   port=gerrit_port,
                   key_filename=gerrit_key_filename)
    client.get_transport().set_keepalive(60)

    project_name = urllib.quote_plus(project_name).replace('+', '%20')
    build_url = "%s/dashboard/#/project/%s/build/%s/%s" % (dashboard_url,
                                                           project_name,
                                                           build_number,
                                                           build_restart_counter)

    c = conn.cursor()
    c.execute('''SELECT state, count(*) FROM job WHERE build_id = %s GROUP BY state''', [build_id])
    states = c.fetchall()
    c.close()

    vote = None
    if len(states) == 1 and states[0][0] == 'finished':
        # all finished
        vote = "+1"
        message = "Build finished: %s" % build_url
    else:
        for s in states:
            if s[0] in ('running', 'scheduled', 'queued'):
                # still some running
                vote = "0"
                message = "Build running: %s" % build_url
                break
            elif s[0] != 'finished':
                # not successful
                vote = "-1"
                message = "Build failed: %s" % build_url


    if (job_name == 'Create Jobs' and vote == '0') or vote in ('-1', '+1'):
        logger.info('Setting InfraBox=%s for sha=%s', vote, commit_sha)
        cmd = 'gerrit review --project %s -m "%s" --label InfraBox=%s %s' % (project_name,
                                                                             message,
                                                                             vote,
                                                                             commit_sha)
        execute_ssh_cmd(client, cmd)

    client.close()

if __name__ == "__main__":
    try:
        main()
    except:
        print_stackdriver()
