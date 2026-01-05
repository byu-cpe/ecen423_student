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

# Script changes:
# * flag to do a remote check like the TAs would do (default is local)

class repo_test_suite_423(repo_test_suite):
    ''' 
    Represents a suite of tests to perform on a ECEN 423 repository. 
        repo: The git.Repo object that represents the local repository being tested.
        assignment_name: The name of the assignment (used for tagging, i.e. 'lab01')
        starter_check_date: A date object indicating the last date to check for starter code updates
    The tests are divided into several categories that are executed in a specific order:
        self.pre_build_tests: Tests that are run on the repository to check for integrity (before build)
        self.build_tests: Tests that are run involving a build process (generates temporary files, etc.)
        self.post_build_tests: Tests that are run after the build and before the clean (used for checking)
        self.clean_tests: Tests used to clean up and check the repository
    '''
    DEFAULT_REMOTE_NAME = "startercode"
    def __init__(self, repo, assignment_name, max_repo_files = 20, 
                 summary_log_filename = None, 

                 required_executables = None, submit = False,
                 starter_check_date = None, single_rule_run = None, due_date = None):
        super().__init__(repo, test_name = assignment_name, max_repo_files = max_repo_files,
                         starter_remote_name = repo_test_suite_423.DEFAULT_REMOTE_NAME,
                         summary_log_filename = summary_log_filename)
        # Information steps:
        # - list of required repo files
        # - list of makefile rules
        # - Due dates
        # Build Steps
        # - Check environment
        # - Ability to run a single rule
        # - Run all tests
        # Repo tests
        #  (list them)
        # Submission
        # - Check submission status and report
        # - Full Submission
        #   - Check environment
        #   - Run build steps
        #   - Clean
        #   - Check repository

        # Initialize the sets of tests
        # Repo tests (what is in and not in the repo)
        # - check for uncommitted files (files that should be ignored)
        # - Check remote origin exists and has been pushed (not newer than remote)
        # - Check for max number of files in the repo
        # - Check to see if a specific remote exists
        # - Check to see if a tag exists
        # Pre Build Tests
        # - execs_exist_test
        # Clean tests:
        # - check for untracked files
        # - Run make clean
        # - Check for ignored files
        # Other:
        # - execs_exist_test (Note: this in in the repo test but should be in pre-buld)
        # self.repo_tests = []
        # self.pre_build_tests = []
        # self.build_tests = []
        # self.post_build_tests = []
        # self.clean_tests = []
        # self.run_pre_build_tests = True
        # self.run_build_tests = True
        # self.run_post_build_tests = True
        # self.run_clean_tests = True
        self.single_rule_run = single_rule_run # Only run a single rule
        # self.copy_file_dir = None # Location to copy generated build files
        self.prepend_file_str = None # String to prepend to the file name when copying
        self.required_executables = required_executables
        self.perform_submit = submit
        self.force = False
        self.starter_check_date = starter_check_date
        self.due_date = due_date
        # Add tests
        # self.add_pre_build_tests()
        # self.add_clean_tests()
        # self.add_repo_tests(max_repo_files)

    def add_pre_build_tests(self, required_executables = None):
        """ Add default tests that should be executed before any building. """
        if required_executables is not None:
            self.add_pre_build_test(repo_test.execs_exist_test(required_executables))

    def add_clean_tests(self):
        """ Add three repo clean tests (untracked files, make clean, and ignored files) """
        self.add_clean_test(repo_test.check_for_untracked_files())
        self.add_clean_test(repo_test.make_test("clean"))
        self.add_clean_test(repo_test.check_for_ignored_files())

    def add_repo_test(self,test):
        self.repo_tests.append(test)

    def add_pre_build_test(self,test):
        self.pre_build_tests.append(test)

    def add_build_test(self,test):
        self.build_tests.append(test)

    def add_post_build_test(self,test):
        self.post_build_tests.append(test)

    def add_clean_test(self,test):
        self.clean_tests.append(test)

    # def add_required_files(self, file_list, check_files_not_tracked = False, check_tracked_files = False):
    #     ''' Add tests to see if a file exists.
    #     Optionally check to make sure it is not committed in the repo (for build files)
    #     optionally check to make sure it is committed in the repo (for required files) '''
    #     # Add test to see if the file was generated (in the current working directory)
    #     #check_file_test = repo_test.file_exists_test(file_list, copy_dir = self.copy_file_dir, prepend_file_str = self.prepend_file_str)
    #     check_file_test = repo_test.file_exists_test(file_list)   # Commented out copying. No need to copy existing files, only need to copy built files
    #     self.add_post_build_test(check_file_test)
    #     # Add test to make sure the file is not committed in the repository
    #     if check_files_not_tracked:
    #         non_committed_files_test = repo_test.file_not_tracked_test(file_list)
    #         self.add_post_build_test(non_committed_files_test)
    #     if check_tracked_files:
    #         committed_files_test = repo_test.files_tracked_test(file_list)
    #         self.add_post_build_test(committed_files_test)

    # def add_required_tracked_files(self, file_list):
    #     self.add_required_files(file_list, check_tracked_files = True)

    def run_tests(self):
        """ Run all the registered tests in the test suite.
        """
        self.print_test_start_message()
        self.top_test_set.perform_test()
        return

        test_num = 1
        final_result = True
        if self.single_rule_run is not None:
            # Only run a single makefile rule in the current directory
            test_to_run = None
            for test in self.build_tests:
                if isinstance(test, repo_test.make_test) and test.make_rule == self.single_rule_run:
                    test_to_run = test
                    break
            if test_to_run is None:
                self.print_error(f"Makefile rule '{self.single_rule_run}' not found in test suite")
                return
            self.print_test_status(f"Running single makefile rule '{self.single_rule_run}'")
            result = self.execute_test_module(test_to_run)
            # result = test_to_run.perform_test(self)
            return result
        if self.repo_tests:
            result = self.iterate_through_tests(self.repo_tests, start_step = test_num)
            test_num += len(self.repo_tests)
            final_result = final_result and result 
        if self.run_pre_build_tests:
            result = self.iterate_through_tests(self.pre_build_tests, start_step = test_num)
            test_num += len(self.pre_build_tests) 
            final_result = final_result and result 
        if self.run_build_tests:
            result = self.iterate_through_tests(self.build_tests, start_step = test_num)
            test_num += len(self.build_tests) 
            final_result = final_result and result 
        if self.run_post_build_tests:
            result = self.iterate_through_tests(self.post_build_tests, start_step = test_num)
            test_num += len(self.post_build_tests) 
            final_result = final_result and result 
        if self.run_clean_tests:
            result = self.iterate_through_tests(self.clean_tests, start_step = test_num)
            test_num += len(self.clean_tests) 
            final_result = final_result and result
        self.print_test_status(f"Test completed \'{self.test_name}\'")
        # Submission checks
        all_tests_run = self.run_pre_build_tests and self.run_build_tests \
            and self.run_post_build_tests and self.run_clean_tests
        if self.perform_submit:
            self.print_test_status(f"Attempting Submission for '{self.test_name}'")
            ready_for_submission = True
            # If performing a submit, the final messages will be related to the submission process
            if not all_tests_run:
                self.print_error("Cannot submit the lab: not all tests have been run")
                ready_for_submission = False
            if not final_result:
                self.print_error("Cannot submit the lab due to errors in the tests")
                ready_for_submission = False
            # See if the current date is before the start of the lab (can't sumbit until lab starts)
            # if self.starter_check_date is not None and datetime.now() < self.starter_check_date:
            #     self.print_error("Cannot submit the lab: submission before the lab start date")
            #     ready_for_submission = False
            if not ready_for_submission:
                self.print_test_summary()
                return
            # Perform lab submission
            submit_status = self.submit_lab(self.test_name)
            if not submit_status:
                return
            check_commit_date_status = self.check_commit_date(self.test_name)
            if not check_commit_date_status:
                return
        else: # Not performing a submit. Provide messages related to the status of the submit
            self.print_test_summary()
            self.print_test_status(f"\nSubmission status for '{self.test_name}'")
            # See if there is a lab tag already submitted
            lab_tag_commit = self.get_lab_tag_commit(self.test_name)
            if lab_tag_commit is not None: # there is a current submission
                commit_file_contents = self.get_commit_file_contents(lab_tag_commit)
                if commit_file_contents is None:
                    self.print_error("  Tag exists but there is no commit date")
                else: # Valid submission
                    self.print_test_status(" Valid Submission")
                    self.print(commit_file_contents)
                    # Check to see if the current directory is different from the tag commit
                    # (don't check other directories as they may change)
            else: # there is not a current submission
                self.print_error("  No submission exists")
        return

    def get_lab_tag_commit(self, lab_name, fetch_remote_tags = True):
        ''' Get the tag associated with a lab assignment. If the tag doesn't exist, return None. '''
        if fetch_remote_tags:
            result = repo_test.get_remote_tags()
        if not result:
            return False
        tag = next((tag for tag in self.repo.tags if tag.name == lab_name), None)
        if tag is None:
            return None
        return tag.commit
        # % git push --delete origin lab01
        # % git tag --delete lab01

    def get_commit_file_contents(self, tag_commit):
        if tag_commit is None:
            return None
        return repo_test.get_commit_file_contents(tag_commit, ".commitdate")

    def submit_lab(self, lab_name):
        ''' Submit a lab assignment. This involves tagging the current commit with the lab name and pushing it to the remote repository.
        It does not check if the any actions associated with the commit/push are successful. '''
        tag_commit = self.get_lab_tag_commit(lab_name)
        if tag_commit is not None:
            # - If there is a tag:
            #    - Check to see if the tag code is different from the current commit. If not, exit saying it is already tagged and ready to submit
            #    - If the code is different, ask for permission to retag and push the tag to the remote. (ask for permission first unless '--force' flag is given)
            current_commit = self.repo.head.commit
            commit_file_contents = self.get_commit_file_contents(tag_commit)
            # commit_file_contents = repo_test.get_commit_file_contents(tag_commit, ".commitdate")
            if current_commit.hexsha == tag_commit.hexsha:
                print(f"Tag '{lab_name}' exists and is already up-to-date with the current commit.")
                if commit_file_contents is not None:
                    print(commit_file_contents)
            else:
                print(f"Tag '{lab_name}' exists and is out-of-date with the current commit.")
                if commit_file_contents is not None:
                    print(commit_file_contents)
                if self.force:
                    print("Forcing tag update")
                else:
                    print("Do you want to update the tag? Updating the tag will change the submission date.")
                    response = input("Enter 'yes' to update the tag: ")
                    if response.lower()[0] != 'y':
                        print("Tag update cancelled")
                        return False
                # Tag is out of date
                self.repo.delete_tag(lab_name)
                new_tag = self.repo.create_tag(lab_name)
                remote = self.repo.remote("origin")
                remote.push(new_tag, force=True)
        else:
            # Tag doesn't exist
            print(f"Tag '{lab_name}' does not exist in the repository. New tag will be created.")
            new_tag = self.repo.create_tag(lab_name)
            remote = self.repo.remote("origin")
            remote.push(new_tag)
        return True

    def check_commit_date(self, lab_name, timeout = 2 * 60, check_sleep_time = 10):
        ''' Iteratively check the commit date associated with a tag lab submission. 
        This is called after committing the lab to the repository to see if the commit date is updated.'''
        initial_time = time.time()
        first_time = True
        while True:
            # Wait for a bit before checking again if it isn't the first iteration
            if not first_time:
                print(f"Waiting to check for commit file")
                time.sleep(check_sleep_time)
                first_time = False

            # Fetch the remote tags
            result = repo_test.get_remote_tags()
            if not result:
                return False
            # See if the tag exists
            tag = next((tag for tag in self.repo.tags if tag.name == lab_name), None)
            if tag is None:
                time.sleep(check_sleep_time)
                continue
            # Tag exists, fetch the remote to get all the files
            repo_test.fetch_remote(self.repo)
            # Get the commit associated with the tag
            tag_commit = tag.commit
            # See if the .commitdate file exists in root of repository
            # Access the file from the commit
            file_path = ".commitdate"
            file_content = repo_test.get_commit_file_contents(tag_commit, file_path)
            if file_content is not None:
                self.print(f"Commit file created - submission complete")
                self.print(file_content)
                return True

            # Check if the timeout has been reached
            if time.time() - initial_time > timeout:
                print(f"Timeout reached for checking tag '{lab_name}' commit date.")
                return False
            self.print_warning(f"Github Submission commit file '{file_path}' not yet created - waiting")
        return False

def create_423_arg_parser(labname):
    parser = repo_test_suite.create_arg_parser(description=f"Test suite for 423 Assignment: {labname}")
    return parser

def build_test_suite_423(assignment_name, max_repo_files = 20, start_date = None, due_date = None):
    """ A helper function used by 'main' functions to build a test suite based on command line arguments.
        assignment_name: the name of the assignment used for taggin (e.g. 'lab01')
        max_repo_files: the maximum number of files allowed in the lab directory of the repository
        start_date: the date when the lab officialy starts (used to prevent early submissions and to enforce startercode updating)
           This parameter is a string and is in the format "MM/DD/YYYY". If no parameter is given, None is used.
    """
    parser = argparse.ArgumentParser(description=f"Test suite for 520 Assignment: {assignment_name}")
    parser.add_argument("--submit",  action="store_true", help="Submit the assignment to the remote repository (tag and push)")
    parser.add_argument("--repo", help="Path to the local repository to test (default is current directory)")
    parser.add_argument("--run_rule", type=str, help="Run a single makefile rule")
    parser.add_argument("--force", action="store_true", help="Force submit (no prompt)")
    parser.add_argument("--norepo", action="store_true", help="Do not run Repo tests")
    parser.add_argument("--nobuild", action="store_true", help="Do not run build tests")
    parser.add_argument("--noclean", action="store_true", help="Do not run clean tests")
    parser.add_argument("--nocolor", action="store_true", help="Remove color tags from output")
    parser.add_argument("--log", type=str, help="Save output to a log file (relative file path)")
    parser.add_argument("--starterbranch", type=str, default = "main", help="Branch for starter code to check")
    parser.add_argument("--copy", type=str, help="Copy generated files to a directory")
    parser.add_argument("--copy_file_str", type=str, help="Customized the copy file by prepending filenames with given string")
    args=parser.parse_args()

    # Get repo
    if args.repo is None:
        path = os.getcwd()
    else:
        path = args.repo
    repo = git.Repo(path, search_parent_directories=True)

    # Log file
    summary_log_filename = None
    if args.log is not None:
        summary_log_filename = args.log

    # Create datetime object for starter code check if date is given
    if start_date is not None:
        start_date = datetime.strptime(start_date, "%m/%d/%Y")

    # Build test suite
    test_suite = repo_test_suite_423(repo, assignment_name,
        max_repo_files = max_repo_files, summary_log_filename = summary_log_filename, submit = args.submit,
        starter_check_date = start_date, due_date = due_date)
    test_suite.force = args.force

    # Decide which tests to run
    if args.run_rule is not None:
        test_suite.single_rule_run = args.run_rule
    if args.norepo:
        test_suite.run_pre_build_tests = False
    if args.nobuild:
        test_suite.run_build_tests = False
    if args.noclean:
        test_suite.run_clean_tests = False
    if args.nocolor:
        test_suite.test_color = None
        test_suite.error_color = None

    # See if a copy of the build files are needed and if so, customize the copy
    if args.copy:
        test_suite.copy_file_dir = args.copy
        print(f"Copying files to {args.copy}")
        if args.copy_file_str:
            test_suite.prepend_file_str = args.copy_file_str
    return test_suite
