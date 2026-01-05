#!/usr/bin/python3

from html import parser
import pathlib
import os
import git
import repo_test
import argparse
from datetime import datetime
import sys
import repo_test
from repo_test import repo_test_result, result_type

class TermColor:
    """ Terminal codes for printing in color """
    PURPLE = "\033[95m"
    BLUE = "\033[94m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    RED = "\033[91m"
    END = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"

class repo_test_suite():
    ''' This class is used to manage the execution of "tests" within a specific directories
    of a GitHub repository for the purpose of evaluating code within github repositories.

    A key function of this class is to manage the output of the test suite.
    There are two kinds of output generated during the test suite:
    - Command output: The actual output of commands executed as part of a test
    - Test summary: Text that summarizes the test status and results.
    There are three three output targets for this text:
    - stdout: The console output of the test suite. 
    - summary log file: A file that contains the summary of the test output.
    - Command specific log files: Files for a specific test output to isolate the output from other tests

    repo: This is the git.Repo object that represents the local repository being tested.
          This class is not involved in preparing or changing the repository and an existing
          valid repository is assumed. The repository is used to find the repo directory
          (repo.working_tree_dir) and find individual files within the repo.
    tests_to_perform: A list of "repo_test" objects that represent a specific test to perform.
    working_dir: The directory in which the tests should be executed. Note that the execution
                 directory can be anywhere and not necessarily within the repository.
    log_dir: the directory where logs generated during the test will be generated.
            This can be None if no output file logging is wanted.
    summary_log_filename: The name of the file where a summary of the test output will be written.

    '''

    def __init__(self, repo, args, test_name = None,
                 #working_dir = None,
                 #print_to_stdout = True, 
                 #verbose = False, 
                 #summary_log_filename = None,
                 #log_dir = None, 
                 max_repo_files = None,
                 starter_remote_name = None,
                #  copy_build_files_dir = None,
                 ):
        # Reference to the Git repository (default is the current directory)
        self.repo = repo
        self.run_time_args = args
        #self.parser = parser
        self.repo_root_path = pathlib.Path(repo.git.rev_parse('--show-toplevel'))
        # The path to the directory where the top-level script has been run
        self.script_path = os.getcwd()
        # Directory where tests should be completed. This may be different from the script_path
        # if working_dir is not None:
        #     self.working_path = pathlib.Path(working_dir)
        # else:
        self.working_path = pathlib.Path(self.script_path)
        # Relative repo path
        self.relative_repo_path = self.working_path.relative_to(self.repo_root_path)        
        # Directory where logs are placed
        self.log_dir = None 
        # This contains the list of makefile tests specified by the lab
        self.makefile_tests = repo_test_group(self, "Build Steps")
        # This is contains the list of tests that will be run by the script. Its contents are generated at runtime
        self.repo_tests = repo_test_group(self, "Repository Tests")
        self.print_to_stdout = True
        self.verbose = False
        self.test_log_fp = None
        # Members for repo tests
        self.required_repo_files = set() # Files that must be present in the repo (only one instance of each)
        self.excluded_repo_file = set()  # Files that must not be present in the repo (only one instance of each)
        self.max_repo_files = max_repo_files
        self.starter_remote_name = starter_remote_name
        self.copy_build_files_dir = None
        self.copy_prefix_str = None # Prefice string added to copied files
        self.test_name = test_name
        self.result_dict = {}
        # Colors
        self.test_color = TermColor.YELLOW
        self.warning_color = TermColor.YELLOW
        self.error_color = TermColor.RED

    def add_required_repo_files (self, list_of_files):
        ''' Add required files to the set '''
        for file in list_of_files:
            self.required_repo_files.add(file)

    def add_excluded_repo_files (self, list_of_files):
        ''' Add files that can't be in the repo '''
        for file in list_of_files:
            self.excluded_repo_file.add(file)

    def print_color(self, color, *msg):
        """ Print a message in color """
        msg_str = " ".join(str(item) for item in msg)
        if self.test_log_fp is not None:
            # Don't print color codes to the log file, just plain message
            self.test_log_fp.write(msg_str + "\n")
        if color is not None:
            msg_str = color + msg_str + TermColor.END
        print(msg_str)

    def print_verbose(self, message):
        self.print(message, verbose_message = True)

    def print(self, message, verbose_message = False):
        """ Prints a string to the appropriate locations. """
        # Print to std_out?
        if not verbose_message or self.verbose:
            if self.print_to_stdout:
                print(message)
            if self.test_log_fp is not None:
                self.test_log_fp.write(message + '\n')

    def print_error(self, message):
        """ Prints a message using the 'error_color' """
        self.print_color(self.error_color,message)

    def print_warning(self, message):
        """ Prints a message using the 'warning_color' """
        self.print_color(self.warning_color,message)

    def print_test_status(self, message):
        self.print_color(self.test_color,message)

    def test_cleanup(self):
        ''' Close the log file '''
        # self.top_test_set.cleanup()
        # for test in self.tests_to_perform:
        #     test.cleanup()
        if self.test_log_fp:
            self.test_log_fp.close()

    def create_test_logfile(self, log_filename):
        if self.log_dir is None:
            self.log_dir = pathlib.Path(".")
        if not self.log_dir.exists():
            self.log_dir.mkdir(parents=True, exist_ok=True)
        summary_log_filepath = self.log_dir / log_filename
        self.test_log_fp = open(summary_log_filepath, "w")
        if not self.test_log_fp:
            self.print_error("Error opening file for writing:", summary_log_filepath)

    def add_clean_test(self):
        self.repo_tests.add_test(repo_test.make_test(self, "clean"))

    def add_makefile_tests(self):
        self.repo_tests.add_group(self.makefile_tests)

    def run_all_tests(self):
        # Perform an initial clean
        self.add_clean_test()
        # Run all of the makefile tests
        self.add_makefile_tests()
        # Perform a post build clean
        self.add_clean_test()
        # Check the repository
        self.add_repo_tests()

    def run_tests(self):
        self.print_test_start_message()
        result = self.repo_tests.initiate_test()
        self.repo_tests.print_test_summary()
        # self.test_cleanup()
        # self.print_test_end_message()
        return result

    def run_build_test(self, build_rule):
        """ Run a single build test """
        build_test = self.makefile_tests.getTest(build_rule)
        if build_test is None:
            self.print_error(f"Build rule '{build_rule}' not found")
            return
        build_test.initiate_test()

    def print_test_start_message(self):
        """ Start message at start of test """
        self.print_test_status(f"Running test \'{self.test_name}\'")
        self.print_test_status("")

    def add_repo_tests(self, check_start_code = True, tag_str = None):
        """ Create tests that check the state of the repo """
        #rp_tests = repo_test.repo_test_set(self, "Repository Tests")
        self.repo_tests.add_test(repo_test.check_for_uncommitted_files(self))
        if self.max_repo_files is not None:
            self.repo_tests.add_test(repo_test.check_for_max_repo_files(self, self.max_repo_files))
        if len(self.excluded_repo_file) > 0:
            self.repo_tests.add_test(repo_test.file_not_tracked_test(self, self.excluded_repo_file))
        if len(self.required_repo_files) > 0:
            self.repo_tests.add_test(repo_test.files_tracked_test(self, self.required_repo_files))
        self.repo_tests.add_test(repo_test.check_remote_origin(self)) # uncommitted files
        if check_start_code and self.starter_remote_name is not None:
            self.repo_tests.add_test(repo_test.check_remote_starter(self, self.starter_remote_name,
                    last_date_of_remote_commit = self.starter_check_date))
        # Taggging is not necesary for the repo check - it is used for passoffs
        # if tag_str is not None:
        #     self.add_repo_test(repo_test.check_for_tag(tag_str))
        # Required executables are not necessary for the repo check
        # if required_executables is not None:
        #     self.add_repo_test(repo_test.execs_exist_test(required_executables))
        return self.repo_tests

    # def add_repo_tests(self, check_start_code = True, tag_str = None):
    #     """ Create tests that check the state of the repo """
    #     self.add_test(self.create_repo_tests(check_start_code, tag_str))

    def add_makefile_test(self, make_rule, required_input_files = [], required_build_files = [],
                          timeout_seconds = 10 * 60):
        ''' Add a makefile rule test '''
        # Create a test set for the rule
            # makefile_group = repo_test.repo_test_set(self, make_rule)
            # # Add the rule to the build steps
            # self.makefile_tests.add_test(makefile_group)
        # Create the makefile test and add it to the test set
        makefile_test = repo_test.make_test(self, make_rule, required_input_files = required_input_files, 
                                        required_build_files = required_build_files,
                                        timeout_seconds=timeout_seconds)
        self.makefile_tests.add_test(makefile_test)
        # self.add_build_test(make_test)
        return makefile_test

    def summarize_repo_files(self):
        ''' Summarize the required/excluded files '''
        self.print_test_status("Repository Requirements Summary:")
        print(" Required files in repository:",end="")
        if len(self.required_repo_files) == 0:
            print(" None")
        else:
            print("")
            for required_file in self.required_repo_files:
                self.print(f"  {required_file}")
        print("Files that should NOT be included in the repository:",end="")        
        if len(self.excluded_repo_file) == 0:
            print(" None")
        else:
            print("")
            for excluded_file in self.excluded_repo_file:
                print(f"  {excluded_file}")

    def summarize_makefile_tests(self):
        ''' Summarize the makefile build steps '''
        self.print_test_status("Makefile Build Steps Summary:")
        for test in self.makefile_tests.sub_tests:
            if not isinstance(test, repo_test.make_test):
                break
            print(test.rule_summary())

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

    def check_submission(self):
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

    def run_main(self):
        """ This function will perform the 'main' operation based on the
        run-time arguments. """
        # If no arguments are given, provide the help message
        # if len(sys.argv) == 1:
        #     self.parser.print_help()
        #     sys.exit(1)

        # Test environmnt arguments
        if self.run_time_args.nocolor:
            self.test_color = None
            self.error_color = None
        if self.run_time_args.log_dir:
            self.log_dir = pathlib.Path(self.run_time_args.log_dir)
        if self.run_time_args.log:
            self.create_test_logfile(self.run_time_args.log)
        # Information based arguments
        if self.run_time_args.required_files:
            self.summarize_repo_files()
        if self.run_time_args.makefile_rules:
            self.summarize_makefile_tests()
        # Build argumets
        if self.run_time_args.make_rule:
            self.run_build_test(self.run_time_args.make_rule)
        if self.run_time_args.build:
            if not self.run_time_args.noclean:
                self.print_test_status("Running 'make clean' before build")
                self.add_clean_test()
                # self.makefile_tests.add_test(repo_test.make_test(self, "clean"), position = 0)
            self.add_makefile_tests()
            self.run_tests()
        # Repo arguments
        if self.run_time_args.check_repo:
            self.add_repo_tests()
            self.run_tests()
        # Submission arguments
        if self.run_time_args.submission_status:
            self.check_submission()
        if self.run_time_args.submit:
            # Perform an initial clean
            self.add_clean_test()
            # Run all of the makefile tests
            self.add_makefile_tests()
            # Perform a post build clean
            self.add_clean_test()
            # Check the repository
            self.add_repo_tests()
            result = self.run_tests()
            if result.result == result_type.SUCCESS:
                # repo_test.perform_submission(self, force = self.run_time_args.force)
                print("ready for submission")
            else:
                self.print_error("Submission not performed due to test errors.")
        # Cleanup test
        self.test_cleanup()

class repo_test_group():
    """
    Represents a set of repo tests to be performed as a group.
    """
    def __init__(self, rts, name):
        self.repo_test_suite = rts
        self.name = name
        self.sub_tests = []
        self.result_dict = {}

    def getName(self):
        """ get the name of the test set """
        return self.name

    def add_test(self, rtest, position = None):
        """ add a repo_test to the set of tests """
        if position is not None and position >= 0 and position < len(self.sub_tests):
            self.sub_tests.insert(position, rtest)
        else:
            self.sub_tests.append(rtest)

    def add_group(self, rtest_group):
        """ add a repo_test_group to the set of tests """
        for test in rtest_group.sub_tests:
            self.sub_tests.append(test)

    def getTest(self, test_name):
        """ get a test by name """
        for test in self.sub_tests:
            if test.getName() == test_name:
                return test
        return None

    def getResult(self):
        """ create a result object based on the results """
        cur_result = result_type.SUCCESS
        cur_msg = ""
        for test, result in self.result_dict.items():
            if result.result == result_type.ERROR:
                cur_result = result_type.ERROR
            elif result.result == result_type.WARNING and cur_result != result_type.ERROR:
                cur_result = result_type.WARNING
            cur_msg += f"{str(result)}\n"
        return repo_test_result(self, cur_result, cur_msg)

    def initiate_test(self):
        """ Perform all of the tests in the test set"""
        self.repo_test_suite.print_test_status(f"Executing Test Set: {self.getName()}")
        for test in self.sub_tests:
            self.repo_test_suite.print_test_status(f' Executing Test: {test.getName()}')
            result = test.initiate_test()
            self.result_dict[test] = result
            self.repo_test_suite.print_test_status(result)
        return self.getResult()

    def cleanup(self):
        """ Cleanup any files that were created by the test. """
        for test in self.sub_tests:
            test.cleanup()

    def print_test_summary(self):
        ''' Print a summary of the test results '''
        warnings = []
        errors = []
        success = []
        for test in self.result_dict.keys():
            result = self.result_dict[test]
            if result.result == result_type.SUCCESS:
                success.append(result)
            elif result.result == result_type.WARNING:
                warnings.append(result)
            else:
                errors.append(result)
        if len(warnings) == 0 and len(errors) == 0:
            self.repo_test_suite.print_test_status("  No errors or warnings")
        else:
            if len(warnings) != 0:
                self.repo_test_suite.print_error(f" {len(warnings)} Warnings")
                for warning in warnings:
                    self.repo_test_suite.print_error(f"  {warning.test.module_name()}")
                    if warning.msg is not None:
                        self.repo_test_suite.print_error(f"   {warning.msg}")
            if len(errors) != 0:
                self.repo_test_suite.print_error(f" {len(errors)} Errors")
                for error in errors:
                    self.repo_test_suite.print_error(f"  {error.test.module_name()}")
                    if error.msg is not None:
                        self.repo_test_suite.print_error(f"   {error.msg}")

def create_arg_parser(description):

    parser = argparse.ArgumentParser(description=description)
    # Information arguments
    information_group = parser.add_argument_group('Test Information Options')
    information_group.add_argument("--required_files", action="store_true", help="List the files required witin the repository")
    information_group.add_argument("--makefile_rules", action="store_true", help="Lists the required makefile rules and their files")
    # Build arguments
    build_group = parser.add_argument_group('Build Options')
    build_group.add_argument("--make_rule", type=str, help="Run a single makefile rule")
    build_group.add_argument("--build", action="store_true", help="Run all build rules")
    parser.add_argument("--noclean", action="store_true", help="Do not run 'make clean' before building")
    # Repo arguments
    repo_group = parser.add_argument_group('Repo Options')
    repo_group.add_argument("--check_repo", action="store_true", help="Check the repository state")
    # Test environment arguments
    env_group = parser.add_argument_group('Test Environment Options')
    env_group.add_argument("--nocolor", action="store_true", help="Remove color tags from output")
    env_group.add_argument("--log", type=str, help="Save output to a log file (relative file path)")
    env_group.add_argument("--log_dir", type=str, help="Target location for logs")
    env_group.add_argument("--starterbranch", type=str, default = "main", help="Branch for starter code to check")
    env_group.add_argument("--copy", type=str, help="Copy generated files to a directory")
    env_group.add_argument("--copy_file_str", type=str, help="Customized the copy file by prepending filenames with given string")
    env_group.add_argument("--repo", help="Path to the local repository to test (default is current directory)")
    # Submission options
    submission_group = parser.add_argument_group('Submission Options')
    submission_group.add_argument("--submit",  action="store_true", help="Submit the assignment to the remote repository (tag and push)")
    submission_group.add_argument("--force", action="store_true", help="Force submit (no prompt)")
    submission_group.add_argument("--submission_status", action="store_true", help="Show submission status")
    # Other
    # parser.add_argument("--norepo", action="store_true", help="Do not run Repo tests")
    # parser.add_argument("--nobuild", action="store_true", help="Do not run build tests")
    return parser

def build_test_suite(assignment_name, max_repo_files = 20, start_date = None):
    parser = create_arg_parser(description=f"Test suite for Assignment: {assignment_name}")
    args = parser.parse_args()

    # Get repo
    if args.repo is None:
        path = os.getcwd()
    else:
        path = args.repo
    repo = git.Repo(path, search_parent_directories=True)

    # # Create datetime object for starter code check if date is given
    # if start_date is not None:
    #     start_date = datetime.strptime(start_date, "%m/%d/%Y")

    # Build test suite
    test_suite = repo_test_suite(repo, args, assignment_name, max_repo_files = max_repo_files)
    return test_suite

