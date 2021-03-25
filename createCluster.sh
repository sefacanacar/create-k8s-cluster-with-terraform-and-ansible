#!/bin/bash

#RUN ANSIBLE PLAYBOOK TO INSTALL DOCKER TO REMOTE HOST(S)
/usr/local/bin/ansible-playbook -i <path-to-here>/ansible/inventory.ini <path-to-here>/ansible/install_docker.yml

sleep 1

#RUN TERRAFORM INIT
/usr/local/bin/terraform init <path-to-here>/terraform/createCluster/

if [ $? -ne 0 ];
then
    exit
fi

sleep 1

#RUN TERRAFORM VALIDATION
/usr/local/bin/terraform validate <path-to-here>/terraform/createCluster/

if [ $? -ne 0 ];
then
    exit
fi

sleep 1

#RUN TERRAFORM APPLY TO INSTALL K8S ON REMOTE HOSTS(S)
/usr/local/bin/terraform apply -auto-approve <path-to-here>/terraform/createCluster/

if [ $? -ne 0 ];
then
    exit
fi

if [ $? -ne 0 ];
then
    exit
else
    echo "K8s Cluster Succesfully Installed. Starting to deployments"
fi


#RUN TERRAFORM INIT
/usr/local/bin/terraform init <path-to-here>/terraform/Deployments/

if [ $? -ne 0 ];
then
    exit
fi

sleep 1

#RUN TERRAFORM VALIDATION
/usr/local/bin/terraform validate <path-to-here>/terraform/Deployments/

if [ $? -ne 0 ];
then
    exit
fi

sleep 1

#RUN TERRAFORM APPLY TO INSTALL K8S ON REMOTE HOSTS(S)
/usr/local/bin/terraform apply -auto-approve <path-to-here>/terraform/Deployments/

if [ $? -ne 0 ];
then
    exit
else
    echo "Deployments Completed Succesfully"
fi

sleep 1

#DEPLOY KUBE-STATE-METRICS FROM YAML
/usr/local/bin/kubectl --kubeconfig=<path-to-your-kubeconfig-file> apply -f <path-to-here>/ansible/kube-state-metrics/

if [ $? -ne 0 ];
then
    exit
else
    echo "kube-state-metrics deployed"
fi

sleep 1

#RUN ANSIBLE PLAYBOOK TO INSTALL CONSUL TO REMOTE HOST(S)
/usr/local/bin/ansible-playbook -i <path-to-here>/ansible/inventory.ini <path-to-here>/ansible/install_consul.yml

if [ $? -ne 0 ];
then
    exit
else
    echo "CONSUL INSTALLED SUCCESSFULY"
fi

sleep 1

#RUN ANSIBLE PLAYBOOK TO INSTALL PROMETHEUS TO REMOTE HOST(S)
/usr/local/bin/ansible-playbook -i <path-to-here>/ansible/inventory.ini <path-to-here>/ansible/install_prometheus.yml

if [ $? -ne 0 ];
then
    exit
else
    echo "PROMETHEUS INSTALLED SUCCESSFULY"
fi

sleep 1

#RUN ANSIBLE PLAYBOOK TO INSTALL ALERTMANAGER TO REMOTE HOST(S)
/usr/local/bin/ansible-playbook -i <path-to-here>/ansible/inventory.ini <path-to-here>/ansible/install_alertmanager.yml

if [ $? -ne 0 ];
then
    exit
else
    echo "ALERTMANAGER INSTALLED SUCCESSFULY"
fi

sleep 1

#RUN ANSIBLE PLAYBOOK TO INSTALL ELASTICSEARCH AND KIBANA TO REMOTE HOST(S)
/usr/local/bin/ansible-playbook -i <path-to-here>/ansible/inventory.ini <path-to-here>/ansible/install_elasticsearch_kibana.yml

if [ $? -ne 0 ];
then
    exit
else
    echo "ELASTICSEARCH AND KIBANA INSTALLED SUCCESSFULY"
fi

sleep 1

#DEPLOY FILEBEAT FROM YAML
/usr/local/bin/kubectl --kubeconfig=<path-to-your-kubeconfig-file> apply -f <path-to-here>/ansible/filebeat/filebeat-kubernetes.yaml

if [ $? -ne 0 ];
then
    exit
else
    echo "filebeat deployed"
fi

sleep 1

#RUN ANSIBLE PLAYBOOK TO INSTALL GITLAB TO REMOTE HOST(S)
/usr/local/bin/ansible-playbook -i <path-to-here>/ansible/inventory.ini <path-to-here>/ansible/install_gitlab.yml

if [ $? -ne 0 ];
then
    exit
else
    echo "GITLAB INSTALLED SUCCESSFULY"
fi

sleep 1

