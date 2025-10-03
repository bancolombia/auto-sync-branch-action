# Auto branch sync 🤖

A GitHub Action to syncs branches on your repo 🎉. Automatize yours merge to others branches and creates the Pull Request automatically.

## Features

- **Merge in other branches**: When a Pull Request is closed and merged, the action detect from the title of commit the destinies branches to sync.
- **Auto create a Pull Request**: When the syncs finish the action will create a new pull requests to syncs the target branches.
- **Multiple branch Support**: The action support max two branch to sync.
- **Flexible config**: This action provide multiple forms to config, especially for the files that you don't like to merge.
- **Message and log**: This action provide a clear log that allows you to see what happend when is running.
- **Easy to use**: Just works when a Pull Request is accepted.

## How it works

### Trigger

Actions will trigger when a Pull Request is completed and merged.

### Extraction of branches

The action takes the names of the branch to sync with you commit message of your Pull Request, for do that your commit message must have the next sentence:

**<namebranch1&namebranch2>**

![merge title](./docs/img/merge_image.png)

> [!IMPORTANT]
> It is recommended that the sentence is at the end of the commit message.

When the Pull Request is accepted, the action will be executed

**namebranch1**: The name of the first branch to sync.

**namebranch2**: The name of the seconds branch to sync.

> [!TIP]
> If you want a sync just one branch, your sentence must be: \<namebranch1>

### Notes

- When the Pull Request has complete and merge to the target branch, this action realize a merge between that target branch an the branches selected in the commit message of the Pull Request.
- The auto generate Pull Request has a tag called "automated-pr".

## Limitations

1. Sync branch action only works with max two branches to sync at the same time.
2. This actions only be executed when a Pull Request is completed.

## Exclude files

If you want to exclude files in your branch to be sync, you can create a txt file that contains those files, for example:

![exclude_file](./docs/img/exclude_files.png)

This file can selected in the ours_files_list input

## Usage

### Basic Setup

```yaml
- name: Auto branch sync
  uses: bancolombia/auto-branch-sync@v1
```

### Advanced Configuration

```yaml
- name: Auto branch sync
  uses: bancolombia/auto-branch-sync@v1
  with:
    github_token: ${{ secrets.PERSONAL_ACCESS_TOKEN_JF }}
    user_name: 'github-actions[bot]'
    user_email: 'github-actions[bot]@users.noreply.github.com'
    ours_files_list: '.github/merge_ours_files.txt'
```

### Complete Workflow Example

```yaml
name: Auto branch sync

on:
  pull_request:
    types: [closed]

jobs:
  test:
    runs-on: ubuntu-latest
    if: github.event.pull_request.merged == true
    steps:
      - uses: actions/checkout@v4   
      - name: Run auto branch sync
        uses: bancolombia/auto-branch-sync@v1
        with:
          github_token: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
          user_name: 'github-actions[bot]'
          user_email: 'github-actions[bot]@users.noreply.github.com'
          ours_files_list: '.github/merge_ours_files.txt'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `github_token` | GitHub token with permissions to create branches and PRs | Yes | - |
| `user_name` | Git username for commit history | Yes | - |
| `user_email` | Git user email for commit history | Yes | - |
| `ours_files_list` | Path to the file listing files to resolve as "ours" during conflicts | No | `.github/merge_ours_files.txt` |


## Contributing

We welcome contributions! Please see our [contributing guidelines](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:
- Open an issue in this repository
- Check existing issues for similar problems
- Review Flutter's official documentation

## Changelog

See [RELEASES](https://github.com/bancolombia/sync-branches-action/releases) for version history and changes.