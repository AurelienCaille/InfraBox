import os
import ntpath
import requests
import eventlet

from pyinfraboxutils import get_env


eventlet.monkey_patch()

def upload_policies(policy_url):
    files = get_files()

    for p in files:
        file_name = get_filename(p)
        f_data = open(p, 'rb')
        url = policy_url+file_name[:-5]
        try:
            rsp = requests.put(url, data=f_data)
            if rsp:
                print("Pushed %s to %s (Status %s)" % (file_name, url, str(rsp.status_code)))
            else:
                print("Failed pushing %s to %s (Status %s):" % (file_name, url, str(rsp.status_code)))
                print(rsp.content)
        except requests.exceptions.RequestException as e:
            print("Failed pushing %s to %s:" % (file_name, url))
            print(e)

def get_files():
    dir_path = os.path.dirname(os.path.realpath(__file__))
    policy_path = os.path.join(dir_path, 'policies')

    files = [f for f in os.listdir(policy_path) if os.path.isfile(os.path.join(policy_path, f))]

    return [os.path.join(policy_path, f) for f in files]

def get_filename(path):
    head, tail = ntpath.split(path)
    return tail or ntpath.basename(head)

def main():
    upload_policies('http://%s:%s/v1/policies/infrabox/api/' % (get_env('INFRABOX_OPA_HOST'), get_env('INFRABOX_OPA_PORT')))

if __name__ == "__main__": # pragma: no cover
    main()
