import pydriller
import unittest

from app.commits import Commits
from unittest.mock import MagicMock
from .fixtures import commit_messages


class TestCommits(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.merge_commit = MagicMock(pydriller.Commit)
        cls.merge_commit.msg = commit_messages.EXAMPLE_MERGE_MESSAGE

        cls.bump_aws_commit = MagicMock(pydriller.Commit)
        cls.bump_aws_commit.msg = commit_messages.EXAMPLE_BUMP_AWS_MESSAGE

        cls.commit_bob = MagicMock(pydriller.Commit)
        cls.commit_bob.author.name = "bob ross"

        cls.commit_david = MagicMock(pydriller.Commit)
        cls.commit_david.author.name = "david attenborough"

    def test_get_author(self):
        """Given an author, return commits from that author only"""

        commits = Commits([self.commit_bob, self.commit_david])
        self.assertEqual(commits.get_by_author("david attenborough"), [self.commit_david])

    def test_get_author_nonexistent(self):
        """Given a non-existent author, return nothing"""

        commits = Commits([self.commit_bob, self.commit_david])
        self.assertEqual(commits.get_by_author("freddy mercury"), [])

    def test_not_get_author(self):
        """Given an author, return commits from all other authors"""

        commit_a = MagicMock(pydriller.Commit)
        commit_a.author.name = "bob ross"

        commit_b = MagicMock(pydriller.Commit)
        commit_b.author.name = "david attenborough"

        commits = Commits([commit_a, commit_b])
        self.assertEqual(commits.get_not_by_author("david attenborough"), [commit_a])

    def test_removes_duplicates(self):
        """Given duplicate commits, return the unique commit messages"""

        bump_commit = MagicMock(pydriller.Commit)
        bump_commit.msg = commit_messages.EXAMPLE_BUMP_AWS_MESSAGE

        result = Commits.get_sorted_unique_messages([bump_commit, bump_commit], desired_message_line=2)

        self.assertEqual(result, ["Bumps [github.com/aws/aws-sdk-go](https://github.com/aws/aws-sdk-go) from 1.38.12 "
                                  "to 1.38.13."])

    def test_returns_unique_messages(self):
        """Given duplicate commits and singular commits, return the unique commit messages"""

        bump_golang_commit = MagicMock(pydriller.Commit)
        bump_golang_commit.msg = commit_messages.EXAMPLE_BUMP_GOLANG_MESSAGE

        result = Commits.get_sorted_unique_messages([self.bump_aws_commit, bump_golang_commit,
                                                                 self.bump_aws_commit], desired_message_line=2)

        self.assertEqual(result, ["Bumps [github.com/aws/aws-sdk-go](https://github.com/aws/aws-sdk-go) from 1.38.12 "
                                  "to 1.38.13.", 'Bumps [github.com/onsi/ginkgo](https://github.com/onsi/ginkgo) from '
                                                 '1.16.0 to 1.16.1.'])

    def test_only_merge_commits(self):
        """Given only 'merge' commits, return nothing"""

        result = Commits.remove_merges([self.merge_commit, self.merge_commit, self.merge_commit])

        self.assertEqual(result, [])

    def test_one_line_commit_message(self):
        """Given a one-line commit message, it is extracted correctly"""

        commit = MagicMock(pydriller.Commit)
        commit.msg = "Apple"

        try:
            result = Commits.extract_message(commit)
            self.assertEqual(result, "Apple")
        except IndexError:
            self.fail("extract_commit_message failed unexpectedly!")

    def test_mutliline_commit_message(self):
        """Given a multiline commit message, it is extracted correctly"""

        commit = MagicMock(pydriller.Commit)
        commit.msg = "Apple\nBanana\nOrange"

        try:
            result = Commits.extract_message(commit, line_number_to_extract=1)
            self.assertEqual(result, "Banana")

            result = Commits.extract_message(commit, line_number_to_extract=2)
            self.assertEqual(result, "Orange")
        except IndexError:
            self.fail("extract_commit_message failed unexpectedly!")


if __name__ == '__main__':
    unittest.main()
