import json
import os

from pydriller import RepositoryMining
from app.commits import Commits
from app.release_notes import DependencyNotes, FeatureNotes


def main():
    if "FROM_TAG" not in os.environ:
        raise TypeError("FROM_TAG env var is not set!")

    if "REPO_DIR" not in os.environ:
        raise TypeError("REPO_DIR env var is not set!")

    from_tag = os.environ.get("FROM_TAG")
    git_repo_dir = os.environ.get("REPO_DIR")

    all_commits = RepositoryMining(git_repo_dir, from_tag=from_tag).traverse_commits()

    commits = Commits(list(all_commits))
    automated_commits = commits.get_by_author("dependabot[bot]")
    manual_commits = commits.get_not_by_author("dependabot[bot]")

    automated_messages = DependencyNotes(automated_commits).generate_release_notes()
    feature_messages = FeatureNotes(manual_commits).generate_release_notes()

    with open("release-notes.json", "w") as f:
        json.dump({"dependencies": automated_messages, "changes": feature_messages}, f, indent=4)


if __name__ == '__main__':
    main()
