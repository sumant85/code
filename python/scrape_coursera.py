__author__ = 'sumant'

import argparse
import logging
import os
import requests
import time
import urllib


def main(args):
    directory = args.dest_dir
    if not os.path.exists(directory):
        os.makedirs(directory)

    headers = {'User-Agent':
                   'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) '
                   'Chrome/43.0.2357.124 Safari/537.36',
               'Origin': 'https://www.coursera.org',
               'Referer': 'https://www.coursera.org/?authMode=login'}
    s = requests.session()
    # dummy call to setup cookies
    s.get('https://www.coursera.org', headers=headers)
    token = s.cookies.get('CSRF3-Token')

    # complete auth steps
    s.post('https://www.coursera.org/api/login/v3Ssr?csrf3-token=' + token,
           data={'email': args.email, 'password': args.password}, headers=headers)
    auth = s.get('https://www.coursera.org/?authMode=login', headers=headers)
    if auth.status_code != 200:
        logging.error('Authentication failed')
        exit()

    URL_TEMPLATE = 'https://class.coursera.org/%(course_id)s/lecture/download.mp4?lecture_id=%(lecture_id)s'
    for i in range(args.start, args.end+1, 2):
        logging.info('Downloading lecture id : %s' % i)
        resp = s.get(URL_TEMPLATE % {'course_id': args.course_id, 'lecture_id': i}, headers=headers)
        if resp.status_code != 200:
            logging.error('Could not download lecture %s' % i)
            continue
        file_name = urllib.unquote(resp.headers['content-disposition'].split(';')[1].split('=')[1].split('"')[1])
        file_name = file_name.replace('/', '-')
        with open('%s/%s' % (directory, file_name), 'w') as fp:
            fp.write(resp.content)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--course_id', required=True)
    parser.add_argument('--email', required=True)
    parser.add_argument('--password', required=True)
    parser.add_argument('--start', required=True, type=int, help="Start lecture ID")
    parser.add_argument('--end', required=True, type=int, help="End lecture ID")
    parser.add_argument('--dest_dir', default='/tmp/%s' % (time.time()))
    args = parser.parse_args()
    main(args)
