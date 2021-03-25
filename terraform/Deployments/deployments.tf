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
provider "kubernetes" {
  //config_path    = "${path.root}/kube_config_cluster.yml"
  config_path    = "<path>/kube_config_cluster.yml"
}
//CREATE NS FOR MONITORING
resource "kubernetes_namespace" "kube-mon" {
  metadata {
    labels = {
      mylabel = "kubernetes-monitoring"
    }
    name = "kube-mon"
  }
}
//CREATE CLUSTER ROLE FOR PROMETHEUS
resource "kubernetes_cluster_role" "prometheus" {
  metadata {
    name = "prometheus"
  }
  rule {
    api_groups = [""]
    resources  = ["nodes", "nodes/proxy", "services", "endpoints", "pods"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    non_resource_urls = ["/metrics"]
    verbs = ["get"]
  }
}
//CREATE CLUSTER ROLE BINDING FOR PROMETHEUS
resource "kubernetes_cluster_role_binding" "prometheus" {
  metadata {
    name = "prometheus"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "prometheus"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "kube-mon"
  }
}
//CREATE PROMETHEUS CONFIG MAP
resource "kubernetes_config_map" "prometheus-server-conf" {
  metadata {
    name = "prometheus-server-conf"
    namespace = "kube-mon"
  }
  data = {
    "prometheus.yml" = "${file("${path.root}/prometheus/prometheus.yml")}"
  }
}
//PROMETHEUS DEPLOYMENT
resource "kubernetes_deployment" "deployment" {
  metadata {
    name = "prometheus"
    namespace = "kube-mon"
    labels = {
      app = "prometheus-server"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "prometheus-server"
      }
    }
    template {
      metadata {
        labels = {
          app = "prometheus-server"
        }
      }
      spec {
        container {
          image = "prom/prometheus"
          name  = "prometheus"
          args  = ["--config.file=/etc/prometheus/prometheus.yml", "--storage.tsdb.path=/prometheus/"]
          port {
            container_port = "9090"
          }
          volume_mount {
            name  = "prometheus-config-volume"
            mount_path =  "/etc/prometheus/"
          }
          volume_mount {
            name  = "prometheus-storage-volume"
            mount_path =  "/prometheus/"
          }
        }
        volume {
          name = "prometheus-config-volume"
          config_map {
            name  = "prometheus-server-conf"
          }
        }
        volume {
          name = "prometheus-storage-volume"
          empty_dir {}
        }
      }
    }
  }
}
resource "kubernetes_service" "prometheus-service" {
  metadata {
    name = "prometheus-service"
    namespace = "kube-mon"
  }
  spec {
    selector = {
      app = "prometheus-server"
    }
    port {
      port        = 8080
      target_port = 9090
      node_port   = 30000
    }
    type = "NodePort"
  }
}
resource "kubernetes_ingress" "prometheus-ui" {
  metadata {
    name = "prometheus-ui"
    namespace = "kube-mon"
  }
  spec {
    backend {
      service_name = "prometheus-service"
      service_port = 8080
    }
    rule {
      http {
        path {
          backend {
            service_name = "prometheus-service"
            service_port = 8080
          }

          path = "/"
        }
      }
    }
  }
}
//CREATE GRAFANA CONFIG MAP
resource "kubernetes_config_map" "grafana-server-conf" {
  metadata {
    name = "grafana-datasources"
    namespace = "kube-mon"
  }
  data = {
    "prometheus-datasource.yml" = "${file("${path.root}/grafana/prometheus-datasource.yml")}"
  }
}
resource "kubernetes_config_map" "grafana-dashboard-conf" {
  metadata {
    name = "grafana-dashboards"
    namespace = "kube-mon"
  }
  data = {
    "kubernetes-cluster-cpu.json" = "${file("${path.root}/grafana/dashboard.json")}"
    "default.yaml"  = "${file("${path.root}/grafana/dashboard_def.yaml")}"
  }
}
//GRAFANA DEPLOYMENT
resource "kubernetes_deployment" "grafana_deployment" {
  metadata {
    name = "grafana"
    namespace = "kube-mon"
  //  labels = {
  //    app = "grafana"
  //  }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "grafana"
      }
    }
    template {
      metadata {
        name = "grafana"
        labels = {
          app = "grafana"
        }
      }
      spec {
        container {
          image = "grafana/grafana:latest"
          name  = "grafana"
          port {
            container_port = "3000"
          }
          resources {
            limits = {
              memory = "2Gi"
              cpu = "2000m" 
            }
            requests = {
              memory = "1Gi"
              cpu = "1000m"
            }
          }
          volume_mount {
            name  = "grafana-storage"
            mount_path =  "/var/lib/grafana"
          }
          volume_mount {
            name  = "grafana-datasources"
            mount_path =  "/etc/grafana/provisioning/datasources"
          }
          volume_mount {
            name  = "grafana-dashboards"
            mount_path =  "/etc/grafana/provisioning/dashboards"
          }
        }
        volume {
          name = "grafana-datasources"
          config_map {
            name  = "grafana-datasources"
          }
        }
        volume {
          name = "grafana-dashboards"
          config_map {
            name  = "grafana-dashboards"
          }
        }
        volume {
          name = "grafana-storage"
          empty_dir {}
        }
      }
    }
  }
}
resource "kubernetes_service" "grafana-svc" {
  metadata {
    name = "grafana"
    namespace = "kube-mon"
    annotations = {
      "prometheus.io/scrape" = "true"
      "prometheus.io/port"  = "3000"
    }
  }
  spec {
    selector = {
      app = "grafana"
    }
    port {
      port        = 3000
      target_port = 3000
      node_port   = 31000
    }
    type = "NodePort"
  }
}
resource "kubernetes_ingress" "grafana_ingress" {
  metadata {
    name = "grafana-ingress"
    namespace = "kube-mon"
  }
  spec {
    backend {
      service_name = "grafana-svc"
      service_port = 3000
    }
    rule {
      http {
        path {
          backend {
            service_name = "grafana-svc"
            service_port = 3000
          }
          path = "/grafana"
        }
      }
    }
  }
}