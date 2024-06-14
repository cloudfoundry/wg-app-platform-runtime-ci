import pydriller
import unittest
import logging

from app.release_notes import DependencyNotes, FeatureNotes
from .fixtures import commit_messages
from unittest.mock import MagicMock


class TestDependencyNotes(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        logging.disable(logging.CRITICAL)

        cls.merge_commit = MagicMock(pydriller.Commit)
        cls.merge_commit.msg = commit_messages.EXAMPLE_MERGE_MESSAGE

        cls.bump_aws_commit = MagicMock(pydriller.Commit)
        cls.bump_aws_commit.msg = commit_messages.EXAMPLE_BUMP_AWS_MESSAGE

        cls.bump_commit_with_word_from_in_title = MagicMock(pydriller.Commit)
        cls.bump_commit_with_word_from_in_title.msg = commit_messages.EXAMPLE_BUMP_WITH_WORD_FROM_IN_THE_COMMIT_TITLE

        cls.transient_commit = MagicMock(pydriller.Commit)
        cls.transient_commit.msg = commit_messages.EXAMPLE_TRANSIENT_BUMP_MESSAGE

        cls.highest_transient_commit = MagicMock(pydriller.Commit)
        cls.highest_transient_commit.msg = commit_messages.EXAMPLE_HIGHEST_TRANSIENT_BUMP_MESSAGE

    def test_merge_commits_removed(self):
        """Given merge commits, return commits that are not a merge commit"""

        d = DependencyNotes([self.merge_commit, self.merge_commit, self.bump_aws_commit])
        result = d.generate_release_notes()

        self.assertTrue(self.merge_commit not in result)

    def test_aggregate_transient_bumps(self):
        """Given commits that bump the same module, return the lowest to latest bump

        e.g [bump x from 1.2.3 to 1.2.4, bump x from 1.2.4 to 1.2.5]
            it returns [Updated x to 1.2.5]
        """

        d = DependencyNotes([self.bump_aws_commit, self.highest_transient_commit, self.transient_commit])
        result = d.generate_release_notes()

        self.assertEqual(result, [  "**aws-sdk-go:** Updated to v1.38.18.<br>"
                                    "For more information, see [aws-sdk-go](https://github.com/aws/aws-sdk-go)."])

    def test_aggregate_transient_bumps_when_message_format_is_not_recognised(self):
        """Given a commit that does not follow the format we expect, skip without failing"""

        d = DependencyNotes([self.bump_commit_with_word_from_in_title, self.highest_transient_commit])
        result = d.generate_release_notes()

        self.assertEqual(result, [  "**aws-sdk-go:** Updated to v1.38.18.<br>"
                                    "For more information, see [aws-sdk-go](https://github.com/aws/aws-sdk-go)."])

    def test_aggregate_transient_bumps_with_psuedo_version(self):
        """Given commits with a 'pseudo version' (see ref) in golang, return the lowest to latest bump

        ref: https://golang.org/ref/mod#pseudo-versions
        """
        commit_with_pseudo_version = MagicMock(pydriller.Commit)
        commit_with_pseudo_version.msg = commit_messages.EXAMPLE_BUMP_PSEUDO_VERSION_GOLANG_MESSAGE

        highest_transient_commit = MagicMock(pydriller.Commit)
        highest_transient_commit.msg = commit_messages.EXAMPLE_BUMP_PSEUDO_VERSION_TRANSIENT_GOLANG_MESSAGE

        d = DependencyNotes([commit_with_pseudo_version, highest_transient_commit])
        result = d.generate_release_notes()

        self.assertEqual(result,  [ '**ginkgo:** Updated to v1.16.0-20201107100224-a5bc638849f6.<br>'
                                    'For more information, see [ginkgo](https://github.com/onsi/ginkgo).'])

    def test_all_use_case(self):
        """Given merge commits, multiple bump commits and unsorted commits, return correctly"""

        d = DependencyNotes([self.merge_commit, self.highest_transient_commit,
                             self.merge_commit, self.bump_aws_commit,
                             self.transient_commit])

        result = d.generate_release_notes()

        self.assertTrue(self.merge_commit not in result)
        self.assertEqual(result, ['**aws-sdk-go:** Updated to v1.38.18.<br>'
                                  'For more information, see [aws-sdk-go](https://github.com/aws/aws-sdk-go).']
)


class TestFeatureNotes(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.feature_a_commit = MagicMock(pydriller.Commit)
        cls.feature_a_commit.msg = "This is feature A that we added!"

    def test_feature_commit_message(self):
        """Given multiple commits with a feature each, return a list of features as one-line release notes"""

        feature_b_commit = MagicMock(pydriller.Commit)
        feature_b_commit.msg = "This is feature B that we added!"

        m = FeatureNotes([self.feature_a_commit, feature_b_commit])
        result = m.generate_release_notes()

        self.assertEqual(result, ["This is feature A that we added!", "This is feature B that we added!"])

    def test_feature_commit_message_in_order(self):
        """Given multiple commits with a feature each, return messages in sorted order"""

        apple = MagicMock(pydriller.Commit)
        apple.msg = "Fix: apple"

        banana = MagicMock(pydriller.Commit)
        banana.msg = "Fix: banana"

        m = FeatureNotes([self.feature_a_commit, banana, apple])
        result = m.generate_release_notes()

        self.assertEqual(result, ["Fix: apple", "Fix: banana", self.feature_a_commit.msg])


if __name__ == '__main__':
    unittest.main()
