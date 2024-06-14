import pydriller
import logging
import re

from abc import abstractmethod
from app.commits import Commits


class ReleaseNotes:
    @abstractmethod
    def generate_release_notes(self):
        pass


class DependencyNotes(ReleaseNotes):
    """
    This class builds release notes based on commit messages that were generated through automation

    - It assumes that the format of commit messages follows 'dependabots' format, (see tests/fixtures/EXAMPLE_BUMP_AWS_MESSAGE)
    """
    def __init__(self, commits: [pydriller.Commit]):
        self.commits = commits

    def generate_release_notes(self) -> list[str]:
        commits_without_merges = Commits.remove_merges(self.commits)
        unique_commits = Commits.get_sorted_unique_messages(commits_without_merges, desired_message_line=2)

        return self.__aggregate_transient_bumps(unique_commits)

    @staticmethod
    def __aggregate_transient_bumps(commit_messages: list[str]) -> list[str]:
        """
        Builds a dictionary of commit messages to their version bumps
            { "commit_message": ["1.2.3", "1.2.4", "1.2.5"] }

        :param commit_messages:
        :return:
        """

        bumps = {}

        class Bump:
            def __init__(self, name, link, version):
                self.name = name
                self.link = link
                self.version = version

            def __str__(self):
                return f"**{self.name}:** Updated to v{self.version}.<br>For more information, see [{self.name}]({self.link})."

        for commit_message in commit_messages:
            match = re.search("Bumps (\\[(.+)\\]\\((.+)\\)) from (.+) to (.+)\\.", commit_message)

            if match is None:
                logging.warning(f"Could not parse commit '{commit_message}'. This commit won't appear in the release notes.")
                continue

            library_full_name = match.group(2)
            library = re.split('/', library_full_name)[-1] 
            library_link = match.group(3)
            to_version = match.group(5)

            bumps[library] = Bump(library, library_link, to_version)

        return [str(bump) for bump in bumps.values()]

class FeatureNotes(ReleaseNotes):
    """
     This class builds release notes based on commit messages that were created by humans

     - It assumes that the format of commit messages does not follow any particular style, other than the first line
        contains the message we want to show in the release notes
    """
    def __init__(self, commits: [pydriller.Commit]):
        self.commits = commits

    def generate_release_notes(self) -> list[str]:
        return sorted([Commits.extract_message(commit) for commit in self.commits])
