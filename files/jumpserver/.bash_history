ls -la
hostname
systemctl status sshd.service 
ls .ssh/
ssh-keygen
cat .ssh/buildbox_id.pub 
ssh -i ~/.ssh/buildbox_id root@buildbox
