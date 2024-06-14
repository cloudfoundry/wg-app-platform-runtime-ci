import pydriller


class Commits:
    def __init__(self, commits: [pydriller.Commit]) -> None:
        self.commits = commits

    def get_by_author(self, author_name: str):
        return [commit for commit in self.commits if commit.author.name == author_name]

    def get_not_by_author(self, author_name: str):
        return [commit for commit in self.commits if commit.author.name != author_name]

    @staticmethod
    def remove_merges(commits: pydriller.Commit) -> list[pydriller.Commit]:
        return [commit for commit in commits if "Merge" not in commit.msg]

    @staticmethod
    def extract_message(commit: pydriller.Commit, line_number_to_extract=0) -> str:
        return commit.msg.split('\n')[line_number_to_extract]

    @staticmethod
    def get_sorted_unique_messages(commits: list[pydriller.Commit], desired_message_line=0) -> list[str]:
        unique_commits = set()

        for commit in commits:
            desired_message = Commits.extract_message(commit, line_number_to_extract=desired_message_line)
            unique_commits.add(desired_message)

        return sorted(list(unique_commits))
