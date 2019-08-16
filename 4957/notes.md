##  SETUP PULP-DEB:
    sudo dnf install \
      pulp-deb-plugins \
      python-debian \
      python-pulp-deb-common \
      python2-debpkgr \
      pulp-deb-admin-extensions
      pulp-manage-db
      pulp-admin deb repo create --repo-id 'bionic-amd64' --relative-url 'ubuntu/bionic-amd64' --feed 'http://us.archive.ubuntu.com/ubuntu' --releases bionic --components 'main,restricted' --architectures 'amd64'
      pulp-admin deb repo sync run --repo-id 'bionic-amd64'

## SETUP UBUNTU CLIENT:
    sudo vi /etc/apt/apt.conf.d/05https
    Acquire::https {
            Verify-Peer "false";
            Verify-Host "false";
    }
    sudo vi /etc/apt/sources.list
    deb [trusted=yes, arch=amd64] https://<vagrant-ip-adr>/pulp/deb/ubuntu/bionic-amd64 bionic main restricted
    # IP-ADR of vagrant box changes

## CLIENT ERRORS:
### bionic-to-fedora28-pulp:
    vagrant@ubuntu1804:~$ sudo apt-get update
    Ign:1 https://192.168.122.236/pulp/deb/ubuntu/bionic-amd64 bionic InRelease
    Get:2 https://192.168.122.236/pulp/deb/ubuntu/bionic-amd64 bionic Release [3,604 B]
    Ign:3 https://192.168.122.236/pulp/deb/ubuntu/bionic-amd64 bionic Release.gpg
    Reading package lists... Done
    E: The repository 'https://192.168.122.236/pulp/deb/ubuntu/bionic-amd64 bionic Release' is not signed.
    N: Updating from such a repository can't be done securely, and is therefore disabled by default.
    N: See apt-secure(8) manpage for repository creation and user configuration details.

### bionic-to-centos7.6-pulp:
    Err:3 https://192.168.122.132/pulp/deb/ubuntu/bionic-amd64 bionic/main amd64 Packages
      gnutls_handshake() failed: Unexpected message
    Reading package lists... Done
    W: The repository 'https://192.168.122.132/pulp/deb/ubuntu/bionic-amd64 bionic Release' does not have a Release file.
    N: Data from such a repository can't be authenticated and is therefore potentially dangerous to use.
    N: See apt-secure(8) manpage for repository creation and user configuration details.
    E: Failed to fetch https://192.168.122.132/pulp/deb/ubuntu/bionic-amd64/dists/bionic/main/binary-amd64/Packages  gnutls_handshake() failed: Unexpected message
    E: Some index files failed to download. They have been ignored, or old ones used instead.

## PULP-SERVER-CHANGE in /etc/httpd/conf.d/ssl.conf:
    LogLevel debug

## OPENSSL COMMANDS:
    openssl ciphers -v
    openssl s_client -connect 192.168.122.132:443
    nmap --script ssl-enum-ciphers -p 443 192.168.122.132

## MAKE REPO HTTP-ACCESSIBLE
    pulp-admin deb repo update --repo-id bionic-amd64 --serve-http=true --relative-url ubuntu/bionic-amd64
    pulp-admin deb repo publish run --repo-id bionic-amd64

## RELATED UBUNTU BUGS?
    https://bugs.launchpad.net/ubuntu/+source/apache2/+bug/1802630
    https://bugs.launchpad.net/ubuntu/+source/apache2/+bug/1833039
