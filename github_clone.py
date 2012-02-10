#!/usr/bin/env python

import os
import sys
import json
import urllib
import logging
import optparse
import subprocess

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s: %(message)s')

class Github(object):
    def __init__(self, options):
        self.api_url = "http://github.com/api/v2/json"
        self.opt = options

    def get(self, url):
        return urllib.urlopen(url).read()

    def user(self):
        return self.get("/".join([self.api_url, "user/show", self.opt.username]))

    def repos(self):
        return self.get("/".join([self.api_url, "repos/show", self.opt.username]))

    def url(self, repo):
        if self.opt.owner:
            return "git@github.com:%s/%s.git" % (self.opt.username, repo)
        else:
            return "git://github.com/%s/%s.git" % (self.opt.username, repo)

    def repo_names(self):
        repos = json.loads(self.repos())
        return [repo["name"] for repo in repos["repositories"]]

    def clone(self, repo, target):
        target_workdir = os.path.join(target, repo)
        repo_url = self.url(repo)
        logging.info("Working on %s" % target_workdir)
        logging.info(repo_url)
        if os.path.isdir(target_workdir):
            cur_dir = os.getcwd()
            os.chdir(target_workdir)
            subprocess.call(["git", "fetch", "origin"])
            subprocess.call(["git", "fetch", "origin", "--tags"])
            subprocess.call(["git", "merge", "master"])
            os.chdir(cur_dir)
        else:
            subprocess.call(["git", "clone", repo_url, target_workdir])


def main():
    parser = optparse.OptionParser()
    parser.add_option(
        "-o", "--owner", dest="owner",
        action="store_true",
        help="Checkout projects as the owner"
        )
    parser.add_option(
        "-u", "--username", dest="username",
        type="string", action="store",
        help="Github username"
        )
    (options, args) = parser.parse_args()
    if not args:
        parser.print_help()
        sys.exit(1)

    target = args[0]
    g = Github(options)
    for repo in g.repo_names():
        g.clone(repo, target)
        

if __name__ == "__main__":
    main()
