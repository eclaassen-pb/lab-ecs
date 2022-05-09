#!/bin/bash
set -x

## Set proxy
# export https_proxy=http://us-west-2-proxy.lendingcloud.us:8080
# export HTTPS_PROXY=http://us-west-2-proxy.lendingcloud.us:8080
# export http_proxy=http://us-west-2-proxy.lendingcloud.us:8080
# export HTTP_PROXY=http://us-west-2-proxy.lendingcloud.us:8080
# export no_proxy=127.0.0.0/8,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,169.254.169.254

# ###### Needed for non-LC AMI ######
# ## Install PIP
# curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py
# python get-pip.py

# ## Install LCDO
# curl -o get-lcdo.py https://artifactory.tlcinternal.com/artifactory/thirdparty-software/python/get-lcdo.py
# python get-lcdo.py
# pip install -I lcdo boto3
# ###################################

# ## Install Packages
# yum install -y git
#yum install -y NetworkManager   # not sure if needed, cloud-init errored on final step without it, only on amznlnx2

# Run LC bootstrap
#sed -i 's/{region}/us-west-2/g' /etc/lcdo/resolvers.config   # only on amznlnx2

export HOSTNAME_PREFIX=${hostname_prefix}
# export LC_PROFILE=${lc_profile}
# export S3_SECRETS_PATH=s3://lc-security-ev-lendingclub-com-us-west-2/keysecure/access/artifactory/
# export LC_SUB_PROFILE=default
# export HATFIELD_BRANCH=master

# lcdo run --branch master aws/bootstrap.py >> /var/log/aws_bootstrap.log 2>&1

# Configure SSHD
# sed -i '/^AllowGroups/d' /etc/ssh/sshd_config
# %{ if sshd_ad_groups != [] }
# %{ for i in sshd_ad_groups ~}
# echo 'AllowGroups ${i}' >> /etc/ssh/sshd_config
# %{ endfor ~}
# service sshd restart
# service sssd restart
# %{ else }
# echo "Skipping sshd config.."
# %{ endif }

# service sshd restart
# service sssd restart

# %{ if sudoers != [] }
# %{ for i in sudoers ~}
# echo '%${i} ALL=(ALL)       ALL' >> /etc/sudoers.d/91-jenkins
# %{ endfor ~}
# %{ else }
# echo "Skipping sudoers config.."
# %{ endif }

# Stream instance logs to CloudWatch Logs
grep '/var/log/cfn-hup.log' /etc/awslogs/awslogs.conf
if [ $? -ne 0 ]; then

    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    LOG_GROUP="${log_group}"
    REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep '\"region\"' | cut -d\" -f4)

    # install the awslogs package
    yum install -y aws-cli awslogs

    # update awscli.conf with regions where logs to be sent
    grep 'region = ' /etc/awslogs/awscli.conf
    if [ $? -ne 0 ]; then
        echo "region = $${REGION}" >> /etc/awslogs/awscli.conf
    else
        sed -i "s/region = .*/region = $${REGION}/g" /etc/awslogs/awscli.conf
    fi
    sed -i '/^\[\/var\/log\/messages\]/,+6 s/^/#/' /etc/awslogs/awslogs.conf

    # include app log file section in the awslogs.conf
    logfiles=("/var/log/cfn-hup.log" "/var/log/cfn-init.log" "/var/log/cfn-init-cmd.log" "/var/log/cloud-init.log" "/var/log/cloud-init-output.log" "/var/log/docker-events.log" "/var/log/docker"  "/var/log/healthd/daemon.log" "/var/log/cron" "/var/log/messages" "/var/log/yum.log")
    for logfile in "$${logfiles[@]}";
    do
        echo -e "\n[$${logfile}]\
        \nfile = $${logfile}\
        \nlog_group_name = $${LOG_GROUP}\
        \nlog_stream_name = $${INSTANCE_ID}_$${logfile}\
        \ninitial_position = start_of_file\
        \ndatetime_format = %b %d %H:%M:%S\
        \nbuffer_duration = 5000" >> /etc/awslogs/awslogs.conf
    done

    # Handle rotated files - filename with wildcard
    echo -e "\n[/var/log/ecs/ecs-init.log]\
    \nfile = /var/log/ecs/ecs-init.log.*\
    \nlog_group_name = $${LOG_GROUP}\
    \nlog_stream_name = $${INSTANCE_ID}_/var/log/ecs/ecs-init.log\
    \ninitial_position = start_of_file\
    \ndatetime_format = %b %d %H:%M:%S\
    \nbuffer_duration = 5000" >> /etc/awslogs/awslogs.conf

    echo -e "\n[/var/log/ecs/ecs-agent.log]\
    \nfile = /var/log/ecs/ecs-agent.log.*\
    \nlog_group_name = $${LOG_GROUP}\
    \nlog_stream_name = $${INSTANCE_ID}_/var/log/ecs/ecs-agent.log\
    \ninitial_position = start_of_file\
    \ndatetime_format = %b %d %H:%M:%S\
    \nbuffer_duration = 5000" >> /etc/awslogs/awslogs.conf

    # restart awslogs service
    service awslogs restart
    # enable awslogs service to start on system boot
    chkconfig awslogs on
fi

# Configure system
echo 'net.ipv4.conf.all.route_localnet = 1' >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

iptables -t nat -A PREROUTING -p tcp -d 169.254.170.2 --dport 80 -j DNAT --to-destination 127.0.0.1:51679
iptables -t nat -A OUTPUT -d 169.254.170.2 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 51679
iptables --insert FORWARD 1 --in-interface docker+ --destination 169.254.169.254/32 --jump DROP
iptables-save > /etc/sysconfig/iptables

# Install efs-utils
yum -y install rpm-build make git
git clone https://github.com/aws/efs-utils
cd efs-utils/
make rpm
yum -y install ./build/amazon-efs-utils*rpm
cd ..

yum install -y gcc openssl-devel tcp_wrappers-devel
curl -o stunnel-5.61.tar.gz https://www.stunnel.org/downloads/stunnel-5.61.tar.gz
tar xvfz stunnel-5.61.tar.gz
cd stunnel-5.61/
./configure
make
rm -f /bin/stunnel
make install
ln -s /usr/local/bin/stunnel /bin/stunnel

# # Make EFS directories
# mkdir -p /mnt
# mount -t efs ${efs_id} /mnt
# mkdir -p /mnt/var/lib/jenkins /mnt/data/workspace
# umount /mnt

# Mount EFS for local access
mkdir -p /mnt/var/lib/jenkins /mnt/data/workspace
chown -R 1000:1000 /mnt

cat >> /etc/fstab << EOF
${efs_id} /mnt/var/lib/jenkins efs _netdev,nofail,tls,iam,accesspoint=${efs_jenkins_home_ap_id} 0 0
${efs_id} /mnt/data/workspace efs _netdev,nofail,tls,iam,accesspoint=${efs_workspace_data_ap_id} 0 0
EOF
mount -a

# Download Jenkins CASC config
# if [[ ! -f /mnt/usr/share/jenkins/ref/casc.yaml ]]; then
#     mkdir -p /mnt/usr/share/jenkins/ref
#     aws s3 cp s3://$${config_bucket}/${hostname_prefix}/casc/casc.yaml /mnt/usr/share/jenkins/ref/casc.yaml
# fi

#add cron to backup locally
# echo -e 'cp /mnt/usr/share/jenkins/ref/casc.yaml /mnt/usr/share/jenkins/ref/casc-$(date +%Y%m%d).yaml' > /etc/cron.daily/backup-casc
# chmod +x /etc/cron.daily/backup-casc
# echo -e 'find /mnt/usr/share/jenkins/ref/casc* -mtime +30 -delete' > /etc/cron.daily/cleanup-casc
# chmod +x /etc/cron.daily/cleanup-casc

# Set permissions
# chown -R 1001:1001 /mnt   # docker image uid should match
# chown -R 500:500 /mnt   # docker image uid should match

# Config ECS agent
mkdir -p /etc/ecs
touch /etc/ecs/ecs.config

mkdir -p /var/log/ecs /var/lib/ecs/data

cat > /etc/ecs/ecs.config << EOF
ECS_CLUSTER=${ecs_cluster}
ECS_DATADIR=/data
ECS_ENABLE_TASK_IAM_ROLE=true
ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true
ECS_LOGFILE=/log/ecs-agent.log
ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs","splunk"]
ECS_LOGLEVEL=info
# ECS_VOLUME_PLUGIN_CAPABILITIES=["efsAuth"]
# HTTP_PROXY=us-west-2-proxy.lendingcloud.us:8080
# NO_PROXY=169.254.169.254,169.254.170.2,/var/run/docker.sock
EOF

# Configure docker daemon
mkdir -p /etc/systemd/system/docker.service.d
echo -e "\n[Service]\
\nEnvironment=\"HTTP_PROXY=us-west-2-proxy.lendingcloud.us:8080\" \"HTTPS_PROXY=us-west-2-proxy.lendingcloud.us:8080\" \"NO_PROXY=localhost,127.0.0.1,.corp,.tlcinternal.com\"" >> /etc/systemd/system/docker.service.d/proxy.conf
systemctl daemon-reload

echo "HTTP_PROXY=http://us-west-2-proxy.lendingcloud.us:8080" >> /etc/sysconfig/docker
echo "HTTPS_PROXY=http://us-west-2-proxy.lendingcloud.us:8080" >> /etc/sysconfig/docker

# Restart docker
systemctl restart docker
systemctl enable docker

# Add system users to docker group
gpasswd -a centos docker
gpasswd -a ec2-user docker
gpasswd -a lcapp docker

# # Install docker plugins
# docker plugin install rexray/ebs --grant-all-permissions HTTP_PROXY=us-west-2-proxy.lendingcloud.us:8080
# docker plugin enable rexray/ebs

# Download and run ecs-agent
curl -o ecs-agent.tar https://s3.us-west-2.amazonaws.com/amazon-ecs-agent-us-west-2/ecs-agent-latest.tar
docker load --input ./ecs-agent.tar
docker run --name ecs-agent \
  --detach=true \
  --restart=always \
  --volume=/var/run:/var/run \
  --volume=/var/log/ecs/:/log \
  --volume=/var/lib/ecs/data:/data \
  --volume=/etc/ecs:/etc/ecs \
  --net=host \
  --env-file=/etc/ecs/ecs.config \
  amazon/amazon-ecs-agent:latest

# Reclaim unused Docker disk space
cat << "EOF" > /usr/local/bin/claimspace.sh
#!/bin/bash
# Run fstrim on the host OS periodically to reclaim the unused container data blocks
docker ps -q | xargs docker inspect --format='{{ .State.Pid }}' | xargs -IZ sudo fstrim /proc/Z/root/
exit $?
EOF

chmod +x /usr/local/bin/claimspace.sh
echo "0 0 * * * root /usr/local/bin/claimspace.sh" > /etc/cron.d/claimspace

# Additional user data
# ${additional_user_data_script}
