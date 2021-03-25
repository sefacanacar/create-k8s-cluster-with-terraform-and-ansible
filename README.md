# create-k8s-cluster-with-terraform-and-ansible

This repo needs ansible and terraform on your local machine or bastion server. Also because of a bug on redhat/centos beside root user certificate of remote server(s) you need your another rsa key pair of your own to install docker-ce with ansible. Please do not forget to edit neccessary parts in both .tf and yaml's. You may use createCluster.sh script to automate all process or run scripts and playbooks one by one. 

If all the steps folowed you will get:
  
- 1 prometheus server inside k8s
- 1 grafana server inside k8s
- 1 external prometheus server
- 1 external consul server
- 1 external alertmanager
- 1 external gitlab server
- 1 external elasticsearch and kibana server
