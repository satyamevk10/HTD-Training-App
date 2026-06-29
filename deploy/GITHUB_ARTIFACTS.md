# Large deployment bundles and GitHub

Deployment tarballs from `npm run package:deploy` are often **50–100+ MB**. They should **not** live in normal Git history.

## Option A — GitHub Releases (recommended)

1. Install and authenticate [GitHub CLI](https://cli.github.com/) with a token that has **`repo`** scope (classic) or fine-grained access to **Contents** and **Releases** for this repository.
2. After `npm run package:deploy`, upload the outer archive:

   ```bash
   gh release create "deploy-YYYYMMDD-HHMMSS" \
     "dist/upg-platforms-portal-deploy-YYYYMMDD-HHMMSS.tar.gz" \
     --title "Deployment package" \
     --notes "Extract and follow INSTALL.txt inside the archive."
   ```

3. Share the **Releases** page URL. Downloaders get the asset without bloating `git clone`.

If `gh release create` returns **404**, fix token scopes or run `gh repo view` from this repo until it resolves.

## Option B — Git LFS

Use LFS only if you **must** version binaries in Git:

```bash
brew install git-lfs
git lfs install
# Track a pattern (example); prefer keeping dist/ out of commits instead.
git lfs track "*.tar.gz"
```

Then commit `.gitattributes` and the files you intend to track. **Clones require `git lfs pull`.** Large free LFS quotas are limited; Releases are usually simpler.

## Option C — Remove a tarball already committed + slim history

**Stop tracking** (file stays on disk; `dist/` remains gitignored):

```bash
git rm --cached dist/upg-platforms-portal-deploy-*.tar.gz
git commit -m "chore: stop tracking deployment tarball"
git push
```

The blob **remains in older commits**; clones still download it until history is rewritten.

**Rewrite history** (destructive; coordinate with anyone using this repo):

- Use [git-filter-repo](https://github.com/newren/git-filter-repo) (or BFG Repo-Cleaner) to strip paths like `dist/*.tar.gz` from all commits, then **`git push --force-with-lease`**.

Only do this if you understand **force-push** impact on collaborators and CI.
