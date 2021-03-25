terraform {
  required_providers {
    rke = {
      source = "rancher/rke"
      version = "1.2.1"
    }
    rancher2 = {
      source = "rancher/rancher2"
      version = "1.12.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.0.3"
    }
  }
}

//CREATE K8S CLUSTER
resource "rke_cluster" "cluster" {
  cluster_name = "your-cluster-name"
  nodes {
    address = "<remote-host-ip>"
    user    = "<user-created-in-docker-installation"
    role    = ["controlplane", "worker", "etcd"]
    ssh_key = <<EOL
-----BEGIN OPENSSH PRIVATE KEY-----
PRIVATE PAIR OF COPIED TO REMOTE HOST WHILE DOCKER INSTALLATION
-----END OPENSSH PRIVATE KEY-----
EOL
    internal_address  = "local-ip"
    labels  = {
      app = "prometheus"
    }
  }
  nodes { 
    address = "<remote-host-ip>"
    user    = "<user-created-in-docker-installation"
    role    = ["worker"]
    ssh_key = <<EOL
-----BEGIN OPENSSH PRIVATE KEY-----
PRIVATE PAIR OF COPIED TO REMOTE HOST WHILE DOCKER INSTALLATION
-----END OPENSSH PRIVATE KEY-----
EOL
    internal_address  = "local-ip"
  }
  dns {
    provider = "coredns"
    upstream_nameservers = ["1.1.1.1", "8.8.4.4"]
  }
  ingress {
    provider = "nginx"
  }
  
}
//GET THE KUBCE_CONFIG FILE TO LOCAL
resource "local_file" "kube_cluster_yaml" {
  //filename = "${path.root}/kube_config_cluster.yml"
  ilename = "<path>/kube_config_cluster.yml"
  content  = rke_cluster.cluster.kube_config_yaml
}