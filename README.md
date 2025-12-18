# nvimcontainer


## before first run of NVIM in container
```
rm .config/nvim/lazy-lock.json
```

### setup windsurf, to get the token from a container w no clipboard or browser capabilities
```
https://windsurf.com/profile?response_type=token&redirect_uri=vim-show-auth-token
```

```
podman build -t nvim-kungfu .

```
You can generate a **Personal Access Token (Classic)** on GitHub's website.

**Step-by-Step Instructions:**

1.  **Go to the Token Settings Page:**
    Click this link: [https://github.com/settings/tokens](https://github.com/settings/tokens)
    *(Or manually: Settings → Developer settings → Personal access tokens → Tokens (classic))*

2.  **Generate New Token:**
    *   Click the button **"Generate new token"** → select **"Generate new token (classic)"**.
    *   **Note:** Give it a name like `nvim-container-token`.
    *   **Expiration:** Set to "No expiration" (for dev containers) or 30 days.

3.  **Select Scopes (Crucial):**
    You must check these boxes for the CLI (`gh`) to work correctly:
    *   [x] **`repo`** (Full control of private repositories)
    *   [x] **`read:org`** (Read org and team membership)
    *   [x] **`admin:public_key`** (Ideally, to allow `gh` to upload your SSH keys)
    *   [x] **`gist`** (If you plan to use Gists)

4.  **Copy the Token:**
    *   Scroll down and click **"Generate token"**.
    *   **COPY IT IMMEDIATELY.** You will never see it again.
    *   This string (starts with `ghp_...`) is your `GH_TOKEN`.

---

### Update your Run Command
Once you have the token, paste it into your run command:


```
podman run -it --rm \
  --name nvim-test \
  -e TMP_GITUSER="" \
  -e GH_TOKEN="" \
  nvim-kungfu
```
