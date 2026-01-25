#!/usr/bin/python3

import argparse
import os
import git
import time

import repo_test
from repo_test_suite import repo_test_suite
from datetime import datetime

# ToDo:
# - Lab check script:
#   - The summaries at the end do not have enough information. Provide an option that givs more feedbak on what whet wrong and what to do (the log is so long i is hard to scroll back to see what happened)
#   - Fix up the error reporting (return error object instead of printing)
#   - Provide a link to the web page for instructions on how to address this problem
#   - Check to see if the student has changed the starter code locally
#   - For uncommitted files, should we only check for the current directory or the entire repo?
# * flag to do a remote check like the TAs would do (default is local)

class repo_test_suite_423(repo_test_suite):
    DEFAULT_REMOTE_NAME = "startercode"

    def __init__(self, repo, args, test_name = None,
                 max_repo_files = None,
                 starter_remote_name = None,
                 copy_build_files_dir = None,
                 copy_prefix_str = None,
                 starter_check_date = None
                 ):
        super().__init__(repo, args, test_name,
                         max_repo_files,
                         copy_build_files_dir,
                         copy_prefix_str,
                         starter_check_date)
        self.starter_remote_name = repo_test_suite_423.DEFAULT_REMOTE_NAME
