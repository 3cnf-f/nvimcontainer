# nvimcontainer
### setup windsurf, to get the token from a container w no clipboard or browser capabilities
```
https://windsurf.com/profile?response_type=token&redirect_uri=vim-show-auth-token
```

```
podman build --no-cache \
  --build-arg TMP_GITUSER=your_tmp_github_email \
  -t nvim-kungfu .
```
