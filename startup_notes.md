# braindump on starting with pulp

## Turn off old repos

    # dnf repolist
    # sudo dnf config-manager --disable group_spacewalkproject-nightly-client --disable virtualbox

## Set up pre-req tools

    # sudo dnf install ansible vagrant vagrant-sshfs VirtualBox akmod-VirtualBox
    # mkdir ~/github/devel # DIRNAME IS IMPORTANT
    # cd !$
    # git clone git@github.com:ggainey/pulp.git
    # cd pulp
    # git remote add upstream https://github.com/pulp/pulp.git
    # git checkout 2-master
    # cd ..
    # git clone git@github.com:ggainey/pulp_rpm.git
    # cd pulp_rpm/
    # git remote add upstream https://github.com/pulp/pulp_rpm.git
    # git checkout 2-master
    # cd ..
    # git clone git@github.com:ggainey/devel.git
    # cd devel/
    # git remote add upstream https://github.com/pulp/devel.git
    # git checkout 2-master
    # cp Vagrantfile.example Vagrantfile
    # vagrant status
    # vagrant up
    # vagrant ssh -- -L 8000:localhost:443
    ## ON PULP-VAGRANT-BOX NOW
    ## vim ./.bashrc
    set -o vi
    export HISTSIZE=10000
    export HISTFILESIZE=100000
    alias h='history 25'
    ## . ./.bashrc
    ## pstop
    ## sudo dnf erase python2-nectar
    ## sudo dnf install https://repos.fedorapeople.org/repos/pulp/pulp/testing/automation/2-master/stage/7/x86_64/python-nectar-1.6.0-1.el7.noarch.rpm
    ## sudo pip install pydevd-pycharm
    ## sudo dnf install wget
    ## sudo vi /etc/pulp/server.conf
    [lazy]
    download_interval: 1
    ##  prestart

## test-env-setup on vagrant box

    ## cd /home/vagrant/devel/pulp_rpm
    ## sudo pip install -r test_requirements.txt
    ## sudo dnf install openssl-devel
    ## sudo pip install rhsm
    ## ./run-tests.py

## pycharm setup

    New Project
        Open pulp
        Attach devel
        Attach pulp_rpm

    Settings/Project Interpreter
        Add
        Vagrant

    get rid of escape-is-curr-editor in pycharm
        Settings/Keymap/Plug-ins/Terminal "Switch focus to editor"

    Edit Configurations
        Python Remote debugging
          Pick a port (eg, 3014)
          Set ip-adr of machine-running-pycharm
          Set up path-mappings:
            Local: /home/ggainey/github/devel
            Remote: /home/vagrant/devel

## Where are Important Files on pulp-box?

    # /var/lib/pulp/published/yum/master/yum_distributor/
    # /var/lib/pulp/content/units
    # /var/lib/pulp/published
    # /var/lib/pulp/uploads/
    # /var/lib/pulp/content
    # /var/cache/pulp/
    # /var/cache/httpd
    # /var/spool/squid/

## logs

    # /var/log/audit/audit.log
    # pjournal
    # /var/log/httpd/error_log
    # /var/log/httpd/ssl_error_log

## access published RPM via curl

    # curl -L -k -v -o wolf.rpm https://localhost/pulp/repos/4798/Packages/w/wolf-9.4-2.noarch.rpm

## code notes

* webservices/views is the server-side receiving-end of REST
* pulp_rpm/admin is CLIENT-SIDE - run -vvv to see set of REST calls being made
* Once endpt identified, add to incoming method:

    import pydevd_pycharm
    pydevd_pycharm.settrace('IP-ADR', port=CHOSEN-PORT, stdoutToServer=True, stderrToServer=True)
    ## prestart

# pulp-smash

https://pulp-2-tests.readthedocs.io/en/latest/installation.html

    [vagrant@pulp2 ~]$ python3 -m venv ~/.venvs/pulp-2-tests
    [vagrant@pulp2 ~]$ source ~/.venvs/pulp-2-tests/bin/activate
    (pulp-2-tests) [vagrant@pulp2 ~]$ pip install ipython
    (pulp-2-tests) [vagrant@pulp2 ~]$ pip install --upgrade pip
    ...
    Successfully installed pip-19.1.1
    (pulp-2-tests) [vagrant@pulp2 ~]$ pip install git+https://github.com/PulpQE/Pulp-2-Tests.git#egg=pulp-2-tests
    Collecting pulp-2-tests from git+https://github.com/PulpQE/Pulp-2-Tests.git#egg=pulp-2-tests
    ...
      Running setup.py install for pyrsistent ... done
      Running setup.py install for pulp-2-tests ... done
    Successfully installed attrs-19.1.0 certifi-2019.6.16 chardet-3.0.4 click-7.0 idna-2.8 jsonschema-3.0.1 packaging-19.0 plumbum-1.6.7 pulp-2-tests-2018.11.1 pulp-smash-1!0.4.0 pyparsing-2.4.0 pyrsistent-0.15.2 python-dateutil-2.8.0 pyxdg-0.26 requests-2.22.0 six-1.12.0 urllib3-1.25.3
    (pulp-2-tests) [vagrant@pulp2 ~]$ pulp-smash settings create  # declare information about Pulp
    Which version of Pulp is under test?: 2.20
    What is the Pulp administrative user's username? [admin]:
    What is the Pulp administrative user's password? [admin]:
    Is SELinux supported on the Pulp hosts? [Y/n]: n
    What is the Pulp host's hostname?: localhost
    What service backs Pulp's AMQP broker? (qpidd, rabbitmq) [qpidd]:
    What scheme should be used when communicating with Pulp's API? (https, http) [https]:
    Verify HTTPS? [Y/n]: n
    By default, Pulp Smash will communicate with Pulp's API on the port number implied by the scheme. For example, if Pulp's API is available over HTTPS, then Pulp Smash will communicate on port 443. If Pulp's API is available on a non-standard port, like 8000, then Pulp Smash needs to know about that.
    Pulp API port number [0]: 443
    What web server service backs Pulp's API? (httpd, nginx) [httpd]:
    Is Pulp Smash installed on the same host as Pulp? [y/N]: y
    Pulp Smash will access the Pulp host using a local shell.
    Settings written to /home/vagrant/.config/pulp_smash/settings.json.
    # Run ALL THE THINGS!!
    (pulp-2-tests) [vagrant@pulp2 ~]$ time python3 -m unittest discover pulp_2_tests.tests
    # Test pulp2 rpm
    (pulp-2-tests) [vagrant@pulp2 ~]$ time python3 -m unittest discover pulp_2_tests.tests.rpm.api_v2
    ...
    Ran 372 tests in 3892.744s
    FAILED (failures=4, errors=2, skipped=6)
    real	64m53.457s
    user	2m23.396s
    sys	0m23.057s

    # Run *A* test
    (pulp-2-tests) [vagrant@pulp2 ~]$ time python -m unittest pulp_2_tests.tests.rpm.api_v2.test_upload_publish

# cleaning up a busted vagrant

    <dkliban> maybe just do 'vagrant reload' ?
    <ggainey> too late :)
    <ggainey> but yeah, that prob would've worked as well
    <dkliban> reload will reconfigured the shared filesystem
    <dkliban> it will restart the box and in the process mount the filesystem
    <ggainey> ah, good to know - will save some time the next time I f'up my machine
    <dkliban> and then you still have to manually run 'sudo python pulp-dev.py -I'
    <dkliban> i think the filesystem disapears and then the OS just thinks everything got uninstalled

# My box fell over, and now my vagrant bos is all f'd up!!!!

Per dkliban:
    <dkliban> the shared file system (/home/vagrant/devel) go unmounted
    <dkliban> got
    <ggainey> ahhhhh, ok
    <dkliban> and all the stuff that was installed from there as symlinks and egg files disappeared

## How do you know it's busted?

    (2-master) ~/github/devel/devel $ vagrant up
    Bringing machine 'pulp2_dev' up with 'libvirt' provider...
    ...
    ==> pulp2_dev: Machine already provisioned. Run `vagrant provision` or use the `--provision`
    ==> pulp2_dev: flag to force provisioning. Provisioners marked to run always will still run.
    ==> pulp2_dev: Running provisioner: shell...
        pulp2_dev: Running: inline script
        pulp2_dev: Failed to restart pulp_celerybeat.service: Unit pulp_celerybeat.service not found.
        pulp2_dev: Failed to restart pulp_workers.service: Unit pulp_workers.service not found.
        pulp2_dev: Failed to restart pulp_resource_manager.service: Unit pulp_resource_manager.service not found.
    The SSH command responded with a non-zero exit status. Vagrant
    assumes that this means the command failed. The output for this command
    should be in the log above. Please read the output to determine what
    went wrong.

## How do you fixit?

    (2-master) ~/github/devel/devel $ vagrant ssh -- -L 8000:localhost:443
    Welcome to the Pulp dev environment!
    ...
    [vagrant@pulp2 ~]$ cd devel/pulp
    [vagrant@pulp2 pulp]$ sudo ./pulp-dev.py -I
    ...
    [vagrant@pulp2 pulp]$ cd ../pulp_rpm
    [vagrant@pulp2 pulp_rpm]$ sudo ./pulp-dev.py -I
    ...
    [vagrant@pulp2 pulp_rpm]$ prestart
    [vagrant@pulp2 pulp_rpm]$ pstatus

## Mongo is still pissed - now what?

    [vagrant@pulp2 ~]$ sudo systemctl stop mongod
    [vagrant@pulp2 ~]$ sudo rm /var/lib/mongodb/mongod.lock
    [vagrant@pulp2 ~]$ sudo rm /var/run/mongodb/mongod.pid
    [vagrant@pulp2 ~]$ sudo systemctl start mongod
    [vagrant@pulp2 ~]$ sudo systemctl status mongod
    [vagrant@pulp2 ~]$ prestart

## Playing with Pulp2 permissions
   18  sudo chmod -R g+rwX /var/lib/pulp/
   28  sudo chgrp -R pulp /var/lib/pulp/
   24  sudo find /var/lib/pulp/ -type d -perm -g-s -exec sudo chmod g+s {} \;

sudo systemctl restart goferd httpd pulp_workers pulp_celerybeat pulp_resource_manager pulp_streamer
