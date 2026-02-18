#!/usr/bin/python3

'''
A set of classes for performing a specific test within a git repo.
Base classes can be created for performing tool-specific tests.
Several generic test classes are included that could be used in any
type of repository.
'''

import subprocess
import os
import sys
from enum import Enum
from git import Repo
import datetime
import time
import threading
import queue
import pathlib
import shutil
import re

##########################################################
# Useful static functions for manipulating and querying git repos
# These functions are independent of the repo_test classes.
##########################################################

def fetch_remote(repo, remote_name = None):
    ''' Fetch updates from the remote repository.
    This function may raise an Exception. '''
    try:
        # Ensure the local repository is not in a detached HEAD state
        # TODO: provide a flat to check for detached state? No problems with fetch
        # if repo.head.is_detached:
        #     raise Exception("The repository is in a detached HEAD state.")
        if remote_name is not None:
            if remote_name not in repo.remotes:
                raise Exception(f"Remote {remote_name} not found in repository")
            remote = repo.remotes[remote_name]
        else:
            remote = repo.remotes.origin
        remote.fetch()
        return True
    except Exception as e:
        raise Exception(f"Error fetching updates from remote: {e}")

def get_unpushed_commits(repo, remote_name = None, remote_branch_name = None):
    ''' Get a list of unpushed commits in the local repository. '''
    # Fetch the remote before doing the compare
    fetch_remote(repo, remote_name)
    # Get the remote branch reference
    if remote_name is None:
        remote_name = "origin"
    if remote_branch_name is None:
        # Try to get the current branch name; if in detached HEAD state, check for tag
        try:
            remote_branch_name = repo.active_branch.name
        except TypeError:
            # Detached HEAD state (e.g., on a tag)
            # Check if current commit matches a tag
            current_commit = repo.head.commit
            tag_found = False
            for tag in repo.tags:
                if tag.commit == current_commit:
                    remote_branch_name = tag.name
                    tag_found = True
                    break
            if not tag_found:
                remote_branch_name = "main"
    remote_branch = f"{remote_name}/{remote_branch_name}"  #repo.active_branch.name
    # Commit is used instead of branch name since tags don't have branch names (but they have commits)
    # local_branch = repo.active_branch.name
    local_commit = repo.head.commit
    # Check for unpushed local commits
    # unpushed_commits = list(repo.iter_commits(f"{remote_branch}..{local_branch}"))
    unpushed_commits = list(repo.iter_commits(f"{remote_branch}..{local_commit}"))
    return unpushed_commits
    # if unpushed_commits:
    #     print(f"Local branch '{current_branch}' has unpushed commits:")
    #     for commit in unpushed_commits:
    #         print(f"  - {commit.hexsha[:7]}: {commit.message.strip()}")
    # else:
    #     print(f"No unpushed commits in local branch '{current_branch}'.")

def get_unpulled_commits(repo,  remote_name = None, remote_branch_name = None, date_limit = None):
    ''' Get a list of unpulled commits in the local repository.  '''
    # Fetch the remote before doing the compare
    fetch_remote(repo, remote_name)
    # Get the remote branch reference
    if remote_name is None:
        remote_name = "origin"
    if remote_branch_name is None:
        remote_branch_name = "main"
    # Create branch names
    remote_branch = f"{remote_name}/{remote_branch_name}"
    # Commit is used instead of branch name since tags don't have branch names (but they have commits)
    # local_branch = repo.active_branch.name
    local_commit = repo.head.commit
    # unpulled_commits = list(repo.iter_commits(f"{local_branch}..{remote_branch}"))
    unpulled_commits = list(repo.iter_commits(f"{local_commit}..{remote_branch}"))
    # Remove those commits that are after the date limit
    if date_limit is not None:
        unpulled_commits = [commit for commit in unpulled_commits if datetime.datetime.fromtimestamp(commit.committed_date) <= date_limit]
    return unpulled_commits
    # if unpulled_commits:
    #     print(f"Remote branch '{remote_branch}' has unpulled commits:")
    #     for commit in unpulled_commits:
    #         print(f"  - {commit.hexsha[:7]}: {commit.message.strip()}")
    # else:
    #     print(f"No unpulled commits from remote branch '{remote_branch}'.")

def get_uncommitted_tracked_files(repo):
    ''' Get a list of uncommitted files in the local repository.  '''
    uncommitted_changes = repo.index.diff(None)
    modified_files = [item.a_path for item in uncommitted_changes if item.change_type == 'M']
    return modified_files

def get_remote_tags():
    try:
        result = subprocess.run(["git fetch --tags --force"], shell=True, capture_output=True, text=True)
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        return False
    return True

def get_commit_file_contents(commit, file_path):
    try:
        file_content = (commit.tree / file_path).data_stream.read().decode("utf-8")
        if len(file_content) > 0:
            return file_content
    except KeyError:
        return None
    return None

#########################################################3
# Base repo test classes
#########################################################3

# TODO:
# - all classes defined from repo_test to set name / parent on construction
# - get rid of "module name" and just use name
# - implement getResult() for all tests

class result_type(Enum):
    SUCCESS = 1
    WARNING = 2
    ERROR = 3

class repo_test_result():
    """ Class for indicating the result of a repo test
    test: the repo_test_unit that was executed
    result: the restult_type
    msg: optional message associated with the result
    """
    def __init__(self, test, result = result_type.SUCCESS, msg = None):
        self.test = test
        self.result = result
        self.msg = msg

    def __str__(self):
        if self.result == result_type.SUCCESS:
            return f"Success: {self.test.getName()}"
        elif self.result == result_type.WARNING:
            return f"Warning: {self.test.getName()}"
        else:
            return f"Error: {self.test.getName()}"

    def merged_result(self, other_result):
        if other_result is None:
            return repo_test_result(self.test, self.result, self.msg)
        new_msg = self.msg
        if other_result.msg is not None:
            new_msg += "\n" + other_result.msg if new_msg is not None else other_result.msg
        new_error = result_type.SUCCESS
        if self.result == result_type.ERROR or other_result.result == result_type.ERROR:
            new_error = result_type.ERROR
        elif self.result == result_type.WARNING or other_result.result == result_type.WARNING:
            new_error = result_type.WARNING
        return repo_test_result(self.test, new_error, new_msg)

class repo_test_unit():
    """ Base class for repo tests. """
    def __init__(self, rts, name):
        self.repo_test_suite = rts
        self.name = name

    def getName(self):
        return self.name

    def perform_test(self):
        """ This function should be overridden by a subclass. It performs the *single* test using
        the repo_test_suite object to obtain test-specific information. 
        Return an object of type repo_test_result. """ 
        return None
    
    def initiate_test(self):
        """
        Like the perform_test function, this function is used to initiate tests. Unlike the
        perform_test function, this function can be overrident to perform multiple tests 
        (for cascading tests). The default implementation simply calls perform_test.
        """
        return self.perform_test()

    def getResult(self):
        """ Return the result of the last executed test. None if it has
        not been run yet. """
        return None

class repo_test(repo_test_unit):
    """ Class for performing a test on files within a repository.
    Each instance of this class represents a _single_ test with a single
    executable. Multiple tests can be performed by creating multiple instances
    of this test class.
    This is intended as a super class for custom test modules.
    """

    def __init__(self, rts, name, abort_on_error=True, process_output_filename = None, timeout_seconds = 0):
        """ Initialize the test module with a repo object """
        super().__init__(rts, name)
        self.abort_on_error = abort_on_error
        self.process_output_filename = process_output_filename
        # List of files that should be deleted after the test is done (i.e., log files)
        self.files_to_delete = []
        self.timeout_seconds = timeout_seconds
        self.execute_lines = []

    def module_name(self):
        """ returns a string indicating the name of the module. Used for logging. """
        return "BASE MODULE"

    def perform_test(self):
        """ This function should be overridden by a subclass. It performs the test using
        the repo_test_suite object to obtain test-specific information. """ 
        return False
    
    def success_result(self, msg=None):
        return repo_test_result(self, result_type.SUCCESS, msg)

    def warning_result(self, msg=None):
        return repo_test_result(self, result_type.WARNING, msg)

    def error_result(self, msg=None):
        return repo_test_result(self, result_type.ERROR, msg)

    def read_stdout_to_queue_thread(proc, output_queue):
        while True:
            line = proc.stdout.readline()
            if line:
                output_queue.put(line.strip())
            else:
                break

    def execute_command(self, repo_test_suite, proc_cmd, process_output_filename = None):
        """ Completes a sub-process command. and print to a file and stdout.
        Args:
            proc_cmd -- The string command to be executed.
            proc_wd -- The directory in which the command should be executed. Note that the execution directory
                can be anywhere and not necessarily within the repository. If this is None, the self.working_path
                will be used.
            print_to_stdout -- If True, the output of the command will be printed to stdout.
            print_message -- If True, messages will be printed to stdout about the command being executed.
            process_output_filepath -- The file path to which the output of the command should be written.
                This can be None if no output file is wanted.
        Returns: the sub-process return code
        """
        
        fp = None
        if repo_test_suite.log_dir is not None and process_output_filename is not None:
            if not os.path.exists(self.repo_test_suite.log_dir):
                os.makedirs(self.repo_test_suite.log_dir)
            process_output_filepath = self.log_dir + '/' + process_output_filename
            fp = open(process_output_filepath, "w")
            if not fp:
                repo_test_suite.print_error("Error opening file for writing:", process_output_filepath)
                return -1
            repo_test_suite.print("Writing output to:", process_output_filepath)
            self.files_to_delete.append(process_output_filepath)
        cmd_str = " ".join(proc_cmd)
        message = "Executing the following command in directory:"+str(repo_test_suite.working_path)+":"+str(cmd_str)
        repo_test_suite.print(message)
        if fp:
            fp.write(message+"\n")
        # Execute command
        start_time = time.time()
        proc = subprocess.Popen(
            proc_cmd,
            cwd=repo_test_suite.working_path,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            universal_newlines=True,
        )
        output_queue = queue.Queue()
        output_thread = threading.Thread(target=repo_test.read_stdout_to_queue_thread, args=(proc, output_queue))
        output_thread.start()

        while proc.poll() is None and output_thread.is_alive():
            try:
                line = output_queue.get(timeout=1.0)
                self.execute_lines.append(line)
                line = line + "\n"
                if repo_test_suite.print_to_stdout:
                    sys.stdout.write(line)
                    sys.stdout.flush()
                if repo_test_suite.test_log_fp:
                    repo_test_suite.test_log_fp.write(line)
                    repo_test_suite.test_log_fp.flush()
                if fp:
                    fp.write(line)
                    fp.flush()
            except queue.Empty:
                # If the queue is empty, just move on: we waited for output and will try again
                pass
            if self.timeout_seconds > 0:
                elapsed_time = time.time() - start_time
                if elapsed_time > self.timeout_seconds:
                    # Timeout exceeded, terminate the process
                    repo_test_suite.print_error(f"Process exceeded {self.timeout_seconds} seconds and was terminated.")
                    proc.terminate()
                    return 1
        proc.communicate()
        return proc.returncode

    def cleanup(self):
        """ Cleanup any files that were created by the test. """
        for file in self.files_to_delete:
            if os.path.exists(file):
                os.remove(file) 

class repo_test_linked_list(repo_test):
    """ 
    This is intended as a super class for custom test modules.
    """

    def __init__(self, rts, name, abort_on_error=True, process_output_filename = None, timeout_seconds = 0):
        """ Initialize the test module with a  object """
        super().__init__(rts, name, abort_on_error=abort_on_error, process_output_filename=process_output_filename,
                         timeout_seconds=timeout_seconds)
        self.previous = None
        self.next = None

    def add_next_test(self, next_test):
        """ Add the next test in the linked list """
        self.next = next_test
        next_test.previous = self

    def initiate_test(self):
        cur_test = self
        new_result = None
        while cur_test is not None:
            result = cur_test.perform_test()
            new_result = result.merged_result(new_result)
            cur_test = cur_test.next
        return new_result

class repo_test_follow(repo_test):

    def __init__(self, rts, name, abort_on_error=True, process_output_filename = None, timeout_seconds = 0):
        """ Initialize the test module with a  object """
        super().__init__(rts, name, abort_on_error=abort_on_error, process_output_filename=process_output_filename,
                         timeout_seconds=timeout_seconds)
        self.sub_tests = []

    def add_test(self, next_test):
        self.sub_tests.append(next_test)

    def initiate_test(self):
        own_result = self.perform_test()
        for sub_test in self.sub_tests:
            sub_result = sub_test.perform_test()
            own_result = own_result.merged_result(sub_result)
        return own_result

#########################################################3
# Generic, non-repo test classes
#########################################################3

class file_exists_test(repo_test):
    ''' Checks to see if files exist in a repo directory. Note that this is a file system
    check and not a git check. The intent of this test is to see if the given file is
    created after executing some other command.

    This test also has the option of copying the files to a directory after the file check
    for later review.
    '''

    def __init__(self, repo_file_list, abort_on_error=True, copy_dir = None, prepend_file_str = None, force_copy = True):
        ''' repo_file_list is a list of files that should exist in the repo directory. 
        copy_dir : the directory to copy the file should the file exist
        prepend_file_str : a string to prepend to the file name when copying '''
        super().__init__(abort_on_error)
        self.repo_file_list = repo_file_list
        self.copy_dir = copy_dir
        self.prepend_file_str = prepend_file_str
        self.force_copy = force_copy

    def module_name(self):
        name_str = "Files Exist: "
        for repo_file in self.repo_file_list:
            name_str += f'{repo_file}, '
        return name_str[:-2] # Remove the last two characters (', ')

    def perform_test(self, repo_test_suite):
        return_val = True
        existing_files = []
        for repo_file in self.repo_file_list:
            file_path = repo_test_suite.working_path / repo_file
            if not os.path.exists(file_path):
                repo_test_suite.print_error(f'File does not exist: {file_path}')
                return_val = False
            else:
                repo_test_suite.print(f'File exists: {file_path}')
                existing_files.append(file_path)
        if self.copy_dir is not None:
            # Copy files to the copy directory
            if not os.path.exists(self.copy_dir):
                repo_test_suite.print_error(f'Copy directory does not exist: {self.copy_dir}')
            else:
                for orig_filepath in existing_files:
                    orig_filename = orig_filepath.name
                    if self.prepend_file_str is not None:
                        new_filename = f'{self.prepend_file_str}{orig_filename}'
                    else:
                        new_filename = orig_filename
                    new_file_path = pathlib.Path(self.copy_dir) / new_filename
                    try:
                        # see if target file already exists
                        if os.path.exists(new_file_path):
                            if self.force_copy:
                                os.remove(new_file_path)
                            else:
                                repo_test_suite.print_error(f'File already exists in copy directory: {new_file_path}')
                                continue
                        shutil.copy2(orig_filename, new_file_path)
                        repo_test_suite.print(f'Copied {orig_filename} to {new_file_path}')
                    except Exception as e:
                        repo_test_suite.print_error(f'Error copying file {orig_filename} to {new_file_path}: {e}')
        return self.perform_following_tests(return_val)

class file_regex_check(repo_test):
    ''' Checks to see if a given file has a given regular expression match.
    '''

    def __init__(self, rts, filename, regex_str, 
                 module_name = None, error_msg = None, 
                 error_on_match = True, abort_on_error=True):
        ''' filename: name of file to check
         regex_str: regular expression string to match
         error_on_match: if True, an error will be thrown if the regex does match, 
            otherwise an error is thrown if the regex does not match
        module_name: name to print for module (to override default)
            '''
        super().__init__(rts, file_regex_check.make_name(filename, regex_str, error_on_match), abort_on_error)
        self.filename = filename
        self.regex_str = regex_str
        self.error_on_match = error_on_match
        self.module_name_str = module_name
        self.error_msg = error_msg

    def make_name(filename,regex_str, error_on_match):
        ''' Static method to make a name string '''
        return f"File Regex Check: {filename} - {regex_str} - Error on match: {error_on_match}"

    def module_name(self):
        if self.module_name_str is not None:
            return self.module_name_str
        return f"File Regex Check: {self.filename} - {self.regex_str} - Error on match: {self.error_on_match}"
 
    def perform_test(self):
        file_path = self.repo_test_suite.working_path / self.filename
        if not os.path.exists(file_path):
            self.repo_test_suite.print_error(f'File does not exist: {file_path}')
            return self.error_result()
        # Check to see if there is a match
        regex_match = False
        with open(file_path, 'r') as file:
            file_contents = file.read()
            regex_match = re.search(self.regex_str, file_contents)
        if self.error_on_match and regex_match:
            # Error if there is a match
            self.repo_test_suite.print_error(f'Regex \'{self.regex_str}\' matches in file {self.filename}')
            if self.error_msg is not None:
                self.repo_test_suite.print_error(self.error_msg)
            return self.error_result()
        if not self.error_on_match and not regex_match:
            self.repo_test_suite.print_error(f'Regex \'{self.regex_str}\' does not match in file {self.filename}')
            if self.error_msg is not None:
                self.repo_test_suite.print_error(self.error_msg)
            return self.error_result()
        self.repo_test_suite.print(f'Regex \'{self.regex_str}\' check passed in file {self.filename}')
        return self.success_result()


class file_not_tracked_test(repo_test):
    ''' Checks to see if a given file is 'not tracked' in the repository.
    This is usually used to test for files that are created during the
    build and not meant for tracking in the repository.
    '''

    def __init__(self, rts, files_not_tracked_list):
        super().__init__(rts, "Files Not Tracked")
        self.files_not_tracked_list = files_not_tracked_list

    def module_name(self):
        name_str = "Files Not Tracked: "
        for repo_file in self.files_not_tracked_list:
            name_str += f'{repo_file}, '
        return name_str[:-2] # Remove the last two characters (', ')

    def perform_test(self):
        return_val = True
        test_dir = self.repo_test_suite.working_path
        tracked_dir_files = self.repo_test_suite.repo.git.ls_files(test_dir).splitlines()
        # Get the filenames from the full path
        tracked_dir_filenames = [pathlib.Path(file).name for file in tracked_dir_files]
        #print(tracked_dir_filenames)
        for not_tracked_file in self.files_not_tracked_list:
            #file_path = repo_test_suite.working_path / repo_file
            #print("checking",not_tracked_file)
            # Check to make sure this file is not tracked
            if not_tracked_file in tracked_dir_filenames:
                self.repo_test_suite.print_error(f'File should NOT be tracked in the repository: {not_tracked_file}')
                #print(repo_test_suite.repo.untracked_files)
                return_val = False
        if return_val:
            return self.success_result()
        return self.error_result()

class files_tracked_test(repo_test):
    ''' Checks to see if a given file is 'not tracked' in the repository.
    This is usually used to test for files that are created during the
    build and not meant for tracking in the repository.
    '''

    def __init__(self, rts, files_tracked_list):
        super().__init__(rts, "Files Tracked")
        self.files_tracked_list = files_tracked_list

    def module_name(self):
        name_str = "Files Tracked: "
        for repo_file in self.files_tracked_list:
            name_str += f'{repo_file}, '
        return name_str[:-2] # Remove the last two characters (', ')

    def perform_test(self):
        return_val = True
        path_of_test_relative_to_repo = self.repo_test_suite.relative_repo_path
        # Dictionary of all files tracked in each directory. Key is pathlib.Path object relative to repo root
        repo_files_dict = {}
        for tracked_file in self.files_tracked_list:
            # Convert string of path to pathlib.Path object 
            file_path = self.repo_test_suite.repo.working_tree_dir / self.repo_test_suite.relative_repo_path / tracked_file
            file_path_resolve = file_path.resolve() # resolve to get rid of any ../ or ./ in path
            file_path_relative_to_repo = file_path_resolve.relative_to(self.repo_test_suite.repo.working_tree_dir)
            # print(file_path, file_path_resolve, file_path_relative_to_repo)
            # Determine the path of this file relative to the repo
            repo_dir_path = file_path.parent 
            # If this is the first time seeing this directory, get the list of tracked files in it
            if repo_dir_path not in repo_files_dict:
                repo_files_dict[repo_dir_path] = self.repo_test_suite.repo.git.ls_files(repo_dir_path).splitlines()
            # Is file in the list of tracked files for this directory?
            if str(file_path_relative_to_repo) not in repo_files_dict[repo_dir_path]:
                self.repo_test_suite.print_error(f'*** File should be tracked in the repository: {tracked_file}')
                return_val = False
        if return_val:
            return self.success_result()
        return self.error_result()

class make_test(repo_test_follow):
    ''' Executes a Makefile rule in the repository.
    '''

    def __init__(self, rts, make_rule, required_input_files = None, required_build_files = None, 
                 generate_output_file = True, make_output_filename=None,
                 abort_on_error=True, timeout_seconds = 60,
                 copy_build_files_dir = None, copy_prefice_str = None):
        ''' - make_rule: the string makefile rule that is executed. 
            - required_input_files: list of files that should exist before the make rule is executed.
            - required_build_files: list of files that should be created after the make rule is executed.
            - generate_output_file: if True, an output file will be generated with the make output.
            - make_output_filename: the name of the output file. If None, a default name will be generated.
            - copy_build_files_dir: the directory to copy the build files to after the make rule is executed
              (default is None in which case no files are copied)
            - copy_prefice_str: string to prepend to the copied file name
        '''
        if generate_output_file and make_output_filename is None:
            # default makefile output filename
            make_output_filename = "make_" + make_rule.replace(" ", "_") + '.log'
        super().__init__(rts, make_rule, abort_on_error=abort_on_error, process_output_filename=make_output_filename,
            timeout_seconds=timeout_seconds)
        self.make_rule = make_rule
        self.required_input_files = required_input_files
        # # add required input files to the github required files
        # if required_input_files is not None:
        #     rts.add_required_repo_files(required_input_files)
        self.required_build_files = required_build_files
        # add required build files to the github excluded files (should not be tracked)
        if required_build_files is not None:
            rts.add_excluded_repo_files(required_build_files)
        self.copy_build_files_dir = copy_build_files_dir
        self.copy_prefice_str = copy_prefice_str

    def module_name(self):
        ''' Generates custom module name string '''
        name_str = f"Makefile: 'make {self.make_rule}'"
        if self.required_input_files is not None and len(self.required_input_files) > 0:
            name_str += " required: "
            for required_file in self.required_input_files:
                name_str += f'{required_file}, '
            name_str = name_str[:-2]
        if self.required_build_files is not None and len(self.required_build_files) > 0:  
            name_str += " ["
            for build_file in self.required_build_files:
                name_str += f'{build_file}, '
            name_str = name_str[:-2]
            name_str += "]"
        return name_str

    def perform_test(self):
        # Check to see if the required input files exist
        if self.required_input_files is not None and len(self.required_input_files) > 0:
            for file in self.required_input_files:
                if not os.path.exists(file):
                    self.repo_test_suite.print_error(f" Required file for Makefile rule '{self.make_rule}' does not exist: {file}")
                    return self.error_result()
        # Run the rule
        cmd = ["make", self.make_rule]
        make_return_val = self.execute_command(self.repo_test_suite, cmd)
        # Check to see if the make rule was successful
        if make_return_val != 0:
            return self.error_result()
        result = self.success_result()
        # Check to see if the required build files exist.
        missing_build_files = []
        if self.required_build_files is not None and len(self.required_build_files) > 0:
            for file in self.required_build_files:
                if not os.path.exists(file):
                    missing_build_files.append(file)
                    # repo_test_suite.print_error(f' Expected build file does not exist: {file}')
                    # result = self.warning_result()
        if len(missing_build_files) > 0: # there are missing build files
            missing_files_str = ""
            for file in missing_build_files:
                missing_files_str += f'{file} '
            error_msg = f'Missing build files: {missing_build_files}'
            self.repo_test_suite.print_error(error_msg)
            result = self.warning_result(msg = error_msg)
        elif self.repo_test_suite.copy_build_files_dir is not None and self.required_build_files is not None: # all the files exist
            #  If the build files are to be copied, copy them to the copy directory
            for build_file in self.required_build_files:
                self.copy_build_file(self.repo_test_suite, build_file)
        return result

    def rule_summary(self):
        ''' Returns a summary string for the make rule '''
        summary_str = f"{self.name}:"
        if self.required_input_files is not None and len(self.required_input_files) > 0:
            summary_str += "\n   Required Input Files: "
            for required_file in self.required_input_files:
                summary_str += f'{required_file}, '
            summary_str = summary_str[:-2]
        if self.required_build_files is not None and len(self.required_build_files) > 0:  
            summary_str += "\n   Required Build Files: "
            for build_file in self.required_build_files:
                summary_str += f'{build_file}, '
            summary_str = summary_str[:-2]
        return summary_str

    def copy_build_file(self, repo_test_suite, build_file):
        ''' Copies the build file to the copy directory '''
        build_file_path = pathlib.Path(build_file)
        dest_filename = f'{build_file_path.name}'
        if self.copy_prefice_str is not None:
            dest_filename = f'{self.copy_prefice_str}_{dest_filename}'
        dest_path = pathlib.Path(self.copy_build_files_dir) / dest_filename
        repo_test_suite.print(f"Copying {build_file_path} to {dest_path}")
        try: 
            shutil.copyfile(build_file_path, dest_path)
        except Exception as e:
            repo_test_suite.print(f"Error copying file {build_file_path} to {dest_path}")
            repo_test_suite.print(f"Error: {e}")
            return False

class execs_exist_test(repo_test):
    ''' Determines whether an executable exists in the path (like unix).
    This is done to provide a more clear error message when trying to
    run an executable that does not exist.
    '''

    def __init__(self, executables, abort_on_error=True):
        super().__init__(abort_on_error=abort_on_error)
        self.executables = executables

    def module_name(self):
        name_str = "Executables Exist: "
        for executable in self.executables:
            name_str += f'{executable}, '
        return name_str[:-2] # Remove the last two characters (', ')

    def perform_test(self, repo_test_suite):
        return_val = True
        for executable in self.executables:
            cmd = ["which", self.self.executable]
            which_val = self.execute_command(repo_test_suite, cmd)
            if which_val != 0:
                return_val = False
        if not return_val:
            return self.error_result()
        return self.success_result()

#########################################################3
# Git repo test classes
#########################################################3

class check_for_untracked_files(repo_test):
    ''' This tests the repo for any untracked files in the repository.
    '''
    def __init__(self, rts, ignore_ok = True):
        '''  '''
        super().__init__(rts, "Check for untracked GIT files")
        self.ignore_ok = ignore_ok

    def module_name(self):
        return "Check for untracked GIT files"

    def perform_test(self):
        # TODO: look into using repo.untracked_files instead of git command
        untracked_files = self.repo_test_suite.repo.git.ls_files("--others", "--exclude-standard")
        if untracked_files:
            self.repo_test_suite.print_error('Untracked files found in repository:')
            files = untracked_files.splitlines()
            for file in files:
                self.repo_test_suite.print_error(f'  {file}')
            # return False
            return self.warning_result()
        self.repo_test_suite.print('No untracked files found in repository')
        # return True
        return self.success_result()

class check_for_tag(repo_test):
    ''' This tests to see if the given tag exists in the repository.
    '''
    def __init__(self, tag_name):
        '''  '''
        super().__init__()
        self.tag_name = tag_name

    def module_name(self):
        return f"Check for tag \'{self.tag_name}\'"

    def perform_test(self, repo_test_suite):
        if self.tag_name in repo_test_suite.repo.tags:
            commit = repo_test_suite.repo.tags[self.tag_name].commit
            commit_date = datetime.datetime.fromtimestamp(commit.committed_date).strftime('%Y-%m-%d %H:%M:%S')
            repo_test_suite.print(f'Tag \'{self.tag_name}\' found in repository (commit date: {commit_date})')
            return self.success_result()
        repo_test_suite.print_error(f'Tag {self.tag_name} not found in repository')
        return self.warning_result()

class check_for_max_repo_files(repo_test):
    ''' Check to see if the repository has more than a given number of files.
    '''
    def __init__(self, rts, max_dir_files):
        '''  '''
        super().__init__(rts, f"Check for max tracked repo files:{max_dir_files}")
        self.max_dir_files = max_dir_files

    # def module_name(self):
    #     return "Check for max tracked repo files"

    def perform_test(self):
        tracked_files = self.repo_test_suite.repo.git.ls_files(self.repo_test_suite.relative_repo_path).split('\n')
        n_tracked_files = len(tracked_files)
        self.repo_test_suite.print(f"{n_tracked_files} Tracked git files in {self.repo_test_suite.relative_repo_path}" +
                                   f" (max allowed: {self.max_dir_files})")
        if n_tracked_files > self.max_dir_files:
            self.repo_test_suite.print_error("  Too many tracked files")
            return self.warning_result()
        return self.success_result()

class check_for_ignored_files(repo_test):
    ''' Checks to see if there are any ignored files in the repo directory.
    The intent is to make sure that these ignore files are removed through a clean
    operation. Returns true if there are no ignored files in the directory.
    '''
    def __init__(self, rts, check_path = None):
        '''  '''
        super().__init__(rts, "Check for ignored GIT files")
        self.check_path = check_path

    def module_name(self):
        return "Check for ignored GIT files"

    def perform_test(self):
        if self.check_path is None:
            self.check_path = self.repo_test_suite.working_path
        # TODO: look into using repo.untracked_files instead of git command
        self.repo_test_suite.print(f'Checking for ignored files at {self.check_path}')
        ignored_files = self.repo_test_suite.repo.git.ls_files(self.check_path, "--others", "--ignored", "--exclude-standard")
        if ignored_files:
            self.repo_test_suite.print_error('Ignored files found in repository (update your \'clean\' rule):')
            files = ignored_files.splitlines()
            for file in files:
                self.repo_test_suite.print_error(f'  {file}')
            # return False
            return self.warning_result()
        self.repo_test_suite.print('No ignored files found in repository')
        # return True
        return self.success_result()

class check_for_uncommitted_files(repo_test):
    ''' Checks for uncommitted files in the repo directory.
    '''

    def __init__(self, rts):
        '''  '''
        super().__init__(rts, "Check for uncommitted git files")

    def module_name(self):
        return "Check for uncommitted git files"
    
    def find_uncommitted_tracked_files(repo, dir = None):
        ''' Static function that finds uncommitted files in the repo. '''
        uncommitted_changes = repo.index.diff(None)
        modified_files = [item.a_path for item in uncommitted_changes if item.change_type == 'M']
        return modified_files

    def perform_test(self):
        modified_files = get_uncommitted_tracked_files(self.repo_test_suite.repo)
        if modified_files:
            self.repo_test_suite.print_error('Uncommitted files found in repository:')
            for file in modified_files:
                self.repo_test_suite.print_error(f'  {file}')
            # return False
            return self.warning_result()
        self.repo_test_suite.print('No uncommitted files found in repository')
        # return True
        return self.success_result()

class check_number_of_files(repo_test):
    ''' Counts the number of files in the repo directory.
    '''

    def __init__(self, max_files=sys.maxsize):
        '''  '''
        super().__init__()
        self.max_files = max_files

    def module_name(self):
        return "Count files in repo dir"

    def perform_test(self, repo_test_suite):
        uncommitted_files = repo_test_suite.repo.git.status("--suno")
        if uncommitted_files:
            repo_test_suite.print_error('Uncommitted files found in repository:')
            files = uncommitted_files.splitlines()
            for file in files:
                repo_test_suite.print_error(f'  {file}')
            # return False
            return self.warning_result()
        repo_test_suite.print('No uncommitted files found in repository')
        # return True
        return self.success_result()

class list_git_commits(repo_test):
    ''' Prints the commits of the given directory in the repo.
    '''
    def __init__(self, check_path = None):
        '''  '''
        super().__init__()
        self.check_path = check_path

    def module_name(self):
        return "List Git Commits"

    def perform_test(self, repo_test_suite):
        if self.check_path is None:
            self.check_path = repo_test_suite.working_path
        relative_path = self.check_path.relative_to(repo_test_suite.repo_root_path)
        repo_test_suite.print(f'Checking for commits at {relative_path}')
        commits = list(repo_test_suite.repo.iter_commits(paths=relative_path))
        for commit in commits:
            commit_hash = commit.hexsha[:7]
            commit_message = commit.message.strip()
            commit_date = commit.committed_datetime.strftime('%Y-%m-%d %H:%M:%S')
            print(f"{commit_hash} - {commit_date} - {commit_message}")
        # return True
        return self.success_result()

class check_remote_origin(repo_test):
    ''' Checks to see if the remote origin matches the local.
    '''
    def __init__(self, rts, check_for_unpushed = True, check_for_unpulled = True):
        '''  '''
        super().__init__(rts, "Compare local repository to remote")

    def module_name(self):
        return "Compare local repository to remote"

    def perform_test(self):
        try:
            # 1. Check for unpushed commits
            unpushed_commits = get_unpushed_commits(self.repo_test_suite.repo)
            if unpushed_commits:
                self.repo_test_suite.print_error('Local branch has unpushed commits:')
                for commit in unpushed_commits:
                    self.repo_test_suite.print_error(f'  - {commit.hexsha[:7]}: {commit.message.strip()}')
                return self.warning_result()
            # 2. Check for unpulled commits
            unpulled_commits = get_unpulled_commits(self.repo_test_suite.repo)
            if unpulled_commits:
                self.repo_test_suite.print_error('Local branch has unpulled commits:')
                for commit in unpulled_commits:
                    self.repo_test_suite.print_error(f'  - {commit.hexsha[:7]}: {commit.message.strip()}')
                return self.warning_result()
        except Exception as e:
            self.repo_test_suite.print_error(f"Error checking remote origin: {e}")
            return self.error_result()
        return self.success_result()

class check_remote_starter(repo_test):
    ''' Checks to see if a remote starter repository has been updated.
    Also checks to see if the local repository has been modified differently
    from this remote starter.
    '''
    def __init__(self, rts, remote_name, remote_branch = "main", last_date_of_remote_commit = None):
        '''  
        remote_name: the name of the remote repository to check
        remote_branch: the branch of the remote repository to check (if None, defaults to 'main')
        last_date_of_remote_commit: the date of the last commit to check for updates (if None, defaults to currenttime)
          This parameter will only check to see if there are commits on the remote before or at this time.
        '''
        super().__init__(rts, f"Check for updates from remote: {remote_name}/{remote_branch}")
        self.remote_name = remote_name
        self.remote_branch = remote_branch
        if self.remote_branch is None:
            self.remote_branch = "main"
        self.last_date_of_remote_commit = last_date_of_remote_commit
        if self.last_date_of_remote_commit is None:
            self.last_date_of_remote_commit = datetime.datetime.now()

    # def module_name(self):
    #     module_str = f"Check for updates from remote: {self.remote_name}/{self.remote_branch}"
    #     return module_str

    def perform_test(self):
        try:
            # 1. Check for unpulled commits from starter
            unpulled_commits = get_unpulled_commits(self.repo_test_suite.repo, 
                self.remote_name, self.remote_branch, self.last_date_of_remote_commit)
            if unpulled_commits:
                self.repo_test_suite.print_error('Remote Branch has unpulled commits:')
                for commit in unpulled_commits:
                    self.repo_test_suite.print_error(f'  - {commit.hexsha[:7]}: {commit.message.strip()}')
                return self.warning_result()
        except Exception as e:
            self.repo_test_suite.print_error(f"Error: {e}")
            return self.error_result()
        return self.success_result()
