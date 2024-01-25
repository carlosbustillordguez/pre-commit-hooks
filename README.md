# pre-commit hooks

A collection of git hooks intended for use with [pre-commit](https://pre-commit.com/) framework.

**Table of Contents:**

- [pre-commit hooks](#pre-commit-hooks)
  - [How to install](#how-to-install)
    - [Automatically enabling pre-commit on repositories (optional)](#automatically-enabling-pre-commit-on-repositories-optional)
  - [Available Hooks](#available-hooks)
  - [Hooks usage notes and examples](#hooks-usage-notes-and-examples)
    - [All hooks](#all-hooks)
      - [Set hooks arguments](#set-hooks-arguments)
      - [Usage of environment variables in `--args`](#usage-of-environment-variables-in---args)
      - [Set env vars inside hook at runtime](#set-env-vars-inside-hook-at-runtime)
      - [Disable color output](#disable-color-output)
    - [helmfilelint](#helmfilelint)
    - [biceplint](#biceplint)
    - [bicepfmt](#bicepfmt)
  - [License](#license)
  - [Author Information](#author-information)

## How to install

1. Install hook's dependencies. For further details, see [Available Hooks](#available-hooks) dependencies column.
2. [Install pre-commit](https://pre-commit.com/#install) framework in your local evironment.
3. Move to the directory (must be a git repository) you want to have installed the `pre-commit` hooks and issue:

    ```bash
    cat <<EOF > .pre-commit-config.yaml
    default_stages: [commit]

    repos:
    - repo: https://github.com/carlosbustillordguez/pre-commit-hooks
      rev: <VERSION> # Get the latest from: https://github.com/carlosbustillordguez/pre-commit-hooks/releases
      hooks:
        - id: helmfilelint
    EOF
    ```

4. Install the git hook scripts:

    ```bash
    pre-commit install
    ```

5. Now `pre-commit` will run automatically on `git commit`.

### Automatically enabling pre-commit on repositories (optional)

`pre-commit init-templatedir` can be used to set up a skeleton for git's `init.templateDir` option. This means that any newly or cloned repository will automatically have the hooks set up without the need to run `pre-commit install`. These steps must be executed one time before clone/create a git repository:

```bash
mkdir ~/.git-template
git config --global init.templateDir ~/.git-template
pre-commit init-templatedir ~/.git-template
```

Now whenever you clone/create a pre-commit enabled repository, the hooks will already be set up!

## Available Hooks

| Hook Name | Description | Dependencies  |
|-----------|-------------|---------------|
| `helmfilelint` | Lint `helmfile` files by executing `helmfile lint` command. | `helmfile` tool. See the [installation steps](https://helmfile.readthedocs.io/en/latest/#installation) from the official documentation. |
| `biceplint` | Lint `.bicep` files by executing `az bicep lint` command. | `az` CLI. See the [installation steps](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli) from the official documentation. |
| `bicepfmt` | Format `.bicep` files by executing `az bicep format` command. | `az` CLI. See the [installation steps](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli) from the official documentation. |

## Hooks usage notes and examples

### All hooks

Common configurations for all hooks.

#### Set hooks arguments

All hooks support the arguments of the underlying tool, for this set the `args` id in the hook configuration and define each argument by `--args=--arg1=value1`. For `helmfilelint` we can set the enviroment name by setting:

```yaml
- id: helmfilelint
  args:
    - --args=--environment=production
```

#### Usage of environment variables in `--args`

You can use environment variables for the `--args` section, e.g.:

```yaml
- id: helmfilelint
  args:
    - --args=--environment=${HELMFILE_ENV}
```

> **NOTE**: You *must* use the `${ENV_VAR}` definition, `$ENV_VAR` will not expand.

To make the above works, the `HELMFILE_ENV` environment variable must be set before the execution of `pre-commit run`, for instance:

```bash
export HELMFILE_ENV=production
pre-commit run
```

So, args will be expanded to `--environment=production`

#### Set env vars inside hook at runtime

You can specify environment variables that will be passed to the hook at runtime, e.g.:

```yaml
- id: helmfilelint
  args:
    - --env-vars=MYACR_USERNAME=00000000-0000-0000-0000-000000000000
    - --env-vars=MYACR_PASSWORD=$(az acr login --name "myacr" --only-show-errors --expose-token --output tsv --query accessToken)
```

#### Disable color output

To disable color output for all hooks, set PRE_COMMIT_COLOR=never var, e.g.:

```bash
PRE_COMMIT_COLOR=never pre-commit run
```

### helmfilelint

`helmfilelint` by default will only check for YAML files that are named `helmfile.d/*.{yaml,yml}` or `helmfile.yaml`. If you are using a helmfile with a custom name, set the `-f | --file` in the hook configuration arguments, e.g.:

```yaml
- id: helmfilelint
  args:
    - --file=helmfile-customs/components.yaml
```

> **NOTE**: the `-f | --file` arguments are also available as part of `--args=--file=foo.yaml` but is the only argument that cannot be used with `--args` because the hook doesn't expect custom files as part of arguments, but as part of `-f | file` does.

If you are using [Azure Container Registry](https://learn.microsoft.com/en-us/azure/container-registry/) to store private Helm chart as OCI artifacts, you will need to login into ACR first to lint the charts. The following approach export the needed environment variables to allow `helmfile` login into ACR:

```yaml
- id: helmfilelint
  args:
    - --env-vars=MYACR_USERNAME=00000000-0000-0000-0000-000000000000
    - --env-vars=MYACR_PASSWORD=$(az acr login --name "myacr" --only-show-errors --expose-token --output tsv --query accessToken)
```

### biceplint

`biceplint` will lint all files with `.bicep` extension. To enable it, add:

```yaml
- id: biceplint
```

**NOTE:**

- The `-f | --file` arguments cannot be used with `--args`.

### bicepfmt

`bicepfmt` will format all files with `.bicep` extension. To enable it, add:

```yaml
- id: bicepfmt
  args:
    - --args=--insert-final-newline
```

**NOTE:**

- The `-f | --file` arguments cannot be used with `--args`.

## License

MIT

## Author Information

By: [Carlos M Bustillo Rdguez](https://linkedin.com/in/carlosbustillordguez/)
