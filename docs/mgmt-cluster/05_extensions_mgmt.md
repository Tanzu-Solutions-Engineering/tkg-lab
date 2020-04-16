# Retrieve TKG Extensions

The TKG Extensions are available at https://gitlab.eng.vmware.com/TKG/tkg-extensions.  You'll need to connect to VMware VPN to access this repo, and you may also need to add an SSH Key from your computer to your Gitlab Settings -> SSH Keys prior to cloning the repository.  We are going to retrieve the latest version and then commit them to this repo so that we can track changes.  In following sections we will be replacing some of the files form a folder in the tkg-extensions-mods/ folder.

```bash
git clone https://gitlab.eng.vmware.com/TKG/tkg-extensions
rm -rf tkg-extensions/.git
```
