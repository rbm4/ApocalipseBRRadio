# Automatic Steam Workshop publishing

`.github/workflows/steam-workshop.yml` packages this Build 42 mod on pull requests
and pushes to **master**. Only a push to master or a manual dispatch on master
publishes existing Workshop item **3706460551**, using Steam App ID **108600**.
Merging this PR schedules publishing: provision the publisher before merging if
you want the first run to complete.

The shared workflow `.github/workflows/publish-workshop.yml` supports:

- `build-mode: ready`: use the existing Contents, preview.png, and workshop.txt.
  This is the radio repository's mode.
- `build-mode: pzstudio`: require package.json and project.json, install project
  dependencies and pzstudio 2.2.0, set an isolated output directory, run
  `npm run build`, and stage the generated Workshop directory. A caller for the
  farming example would use Workshop ID 3781972601.

Packaging runs on GitHub-hosted Ubuntu without Steam credentials. Only Contents,
preview.png, and a small manifest enter the artifact. Each mod must have mod.info,
the expected item ID must match workshop.txt, and symbolic links/special files
are rejected. Artifacts are retained for seven days.

The Linux Docker image installs SteamCMD from Valve, 32-bit runtime libraries,
and Python. A temporary VDF uses the staged **Contents** directory as contentfolder.
The publisher updates content, preview, and changenote with the source commit;
it preserves the item's existing title, description, tags, and visibility.

## Organization secrets

Create these at https://github.com/organizations/ApocalipseBr/settings/secrets/actions
and grant **ApocalipseBRRadio** access with the selected-repositories policy:

| Secret | Value and where to get it |
| --- | --- |
| `STEAM_USERNAME` | The Steam **account login name** for the account that owns Workshop item 3706460551. It is not the profile/display name or SteamID. |
| `STEAM_PASSWORD` | That Steam account's current login password. No API key is involved. |

The caller explicitly maps these organization secrets into the reusable workflow.
GitHub supplies GITHUB_TOKEN for checkout/artifacts; no GitHub App secret, personal
token, Steam Web API key, SteamID, or Workshop ID secret is needed.
Organization-secret availability for private repositories depends on the GitHub
plan. Confirm that this repository can access the secrets.

The Steam account must own the Workshop item, have the required Project Zomboid
access, and accept Steam's Workshop agreement. GitHub repository access does not
grant Steam item ownership.

## Dedicated Linux publisher

Provision a persistent **x86-64 Linux** host with Docker Engine and a self-hosted
GitHub Actions runner registered for this repository. Give it the custom label
**steam-workshop**, alongside `self-hosted`, `linux`, and `x64`. The runner account
needs Docker access and outbound Steam connectivity, including non-HTTP traffic.

Use this runner for trusted publishing jobs only. The workflow's job condition
prevents pull requests from scheduling on it or receiving Steam secrets. Passwords
are never put in the image, process arguments, published artifacts, or printed
Steam output. The host and Docker administrators can access the login state and
must be trusted.

### One-time Steam Guard login

On the publisher machine, check out this repository and run:

```sh
docker build -t pz-workshop-publisher docker/workshop
docker volume create pz-workshop-steam-state
docker run --rm -it \
  --mount type=volume,src=pz-workshop-steam-state,dst=/home/steam \
  pz-workshop-publisher login
```

At the **Steam>** prompt enter `login YOUR_STEAM_LOGIN_NAME`, then supply your
password when prompted. Complete Steam Guard using your Steam email or mobile
authenticator, or approve the mobile sign-in if requested. After successful login,
enter `quit`. Use the same account as the organization secrets.

The private volume persists the entire runtime SteamCMD installation, including
its adjacent config/ssfn files and home state. Keep it on this publisher machine;
never upload it to GitHub artifacts or public caches.

After setup, manually dispatch Steam Workshop on master and confirm the item's
update time/changenote. Development checks do not perform a live publish; this
first authenticated smoke run confirms SteamCMD support and account permissions
for your item.

Steam may request another Guard challenge after session expiry, machine/IP
changes, or account changes. Repeat the interactive login then. A one-time
Steam Guard code is not a permanent organization secret. This workflow does not
disable Guard or extract mobile-authenticator keys.

## Failure handling

Missing secrets fail before launching the container. A missing state volume
reports bootstrap instructions. SteamCMD has a 20-minute timeout and the publish
job a 30-minute limit. Both its exit status and explicit successful publication of
the expected item are required; exit zero alone is insufficient.

Raw Steam output is not printed/uploaded because it can contain account/session
information. Diagnose Steam login, item ownership, agreements, or connectivity
through the interactive container when publishing fails. A Workshop publish is
an external side effect: inspect the changenote before retrying an uncertain run.
There is no automatic rollback.

Publishing jobs share an account concurrency group without cancelling active
uploads. GitHub concurrency is per repository and not FIFO; pending commits can
be superseded by later pushes. When reusing one account across repositories,
use one dedicated runner or a shared host lock to avoid concurrent Steam sessions.
Cleanup deletes the staged package but retains the authentication volume.

## Reuse for pzstudio

Mod tests are optional: the reusable workflow's `test-command` input defaults
to an empty string, which skips mod tests. Set it to the repository's test command
(for example, `npm ci && npm test`) to run tests from `project-directory` before
building and staging. Node 22 is available when tests are configured. The command
must install any other required dependencies; a failure blocks packaging and
publishing. Publisher/packaging checks always run, even for mods without tests.

The radio caller enables `npm ci && npm test`. Its pinned npm dependencies run
the music and jukebox Lua simulations through `tests/run.lua` and both language
catalog checks through `tests/translations_spec.js`. Run the same command locally
when needed; these simulations do not replace an in-game smoke test.

A caller in another accessible repository can use:

```yaml
jobs:
  workshop:
    uses: ApocalipseBr/ApocalipseBRRadio/.github/workflows/publish-workshop.yml@master
    with:
      workshop-id: '3781972601'
      build-mode: pzstudio
      project-directory: '.'
    secrets:
      STEAM_USERNAME: ${{ secrets.STEAM_USERNAME }}
      STEAM_PASSWORD: ${{ secrets.STEAM_PASSWORD }}
```

Add the same triggers targeting master and contents: read permission as the radio
caller. External reuse requires permission to read this reusable workflow; a
public caller cannot consume an inaccessible private workflow. External callers
use publishing tools from the radio repository's master and source from their
own triggering commit.

Organization secrets can only be granted to repositories in that organization.
If the farming repository remains under rbm4, give it equivalent repository
secrets and its own trusted publishing-runner access, or transfer it to ApocalipseBr.
This PR does not change the farming repository.
