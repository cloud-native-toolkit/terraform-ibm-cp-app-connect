locals {
  tmp_dir           = "${path.cwd}/.tmp"
  gitops_dir        = var.gitops_dir != "" ? "${var.gitops_dir}/app-connect" : "${path.cwd}/gitops/app-connect"
  instance_dir      = "${local.gitops_dir}/instances"

  storage_class_file = "${local.tmp_dir}/default_storage_class.out"
  default_storage_class = data.local_file.default_storage_class.content
  storage_class     = var.storage_class != "" ? var.storage_class : local.default_storage_class

  subscription_file = "${local.gitops_dir}/subscription.yaml"

  integration-server_file = "${local.instance_dir}/integration-server.yaml"
  switch-server_file = "${local.instance_dir}/switch-server.yaml"
  designer_file = "${local.instance_dir}/designer.yaml"
  dashboard_file = "${local.instance_dir}/dashboard.yaml"

  subscription      = {
    apiVersion = "operators.coreos.com/v1alpha1"
    kind = "Subscription"
    metadata = {
      name = "ibm-appconnect"
      namespace = "openshift-operators"
    }
    spec = {
      channel = "v1.2"
      installPlanApproval = "Automatic"
      name = "ibm-appconnect"
      source = var.catalog_name
      sourceNamespace = "openshift-marketplace"
    }
  }

  integration-server_instance = {
    apiVersion = "appconnect.ibm.com/v1beta1"
    kind = "IntegrationServer"
    metadata = {
      name = "is-01-toolkit"
    }
    spec = {
      license = {
        accept = true
        license = "L-APEH-BSVCHU"
        use = "CloudPakForIntegrationProduction"
      }
      pod = {
        containers = {
          runtime = {
            resources = {
              limits = {
                cpu = "300m"
                memory = "300Mi"
              }
              requests = {
                cpu = "300m"
                memory = "300Mi"
              }
            }
          }
        }
      }
      adminServerSecure = true
      router = {
        timeout = "120s"
      }
      useCommonServices = true
      designerFlowsOperationMode = "disabled"
      service = {
        endpointType = "http"
      }
      version = "11.0.0"
      replicas = 1
    }
  }
  switch-server_instance = {
    apiVersion = "appconnect.ibm.com/v1beta1"
    kind = "SwitchServer"
    metadata = {
      name = "ss-01-quickstart"
    }
    spec = {
      license = {
        accept = true
        license = "L-APEH-BSVCHU"
        use = "CloudPakForIntegrationProduction"
      }
    }
    useCommonServices = true
    version = "11.0.0"
  }
  designer_instance = {
    apiVersion = "appconnect.ibm.com/v1beta1"
    kind = "DesignerAuthoring"
    metadata = {
      name = "des-01-quickstart"
      namespace = "app-connect"
    }
    spec = {
      couchdb = {
        replicas = 1
        storage = {
          class = local.storage_class
          size = "10Gi"
          type = "persistent-claim"
        }
      }
      designerFlowsOperationMode = "local"
      license = {
        accept = true
        license = "L-APEH-BSVCHU"
        use = "CloudPakForIntegrationNonProduction"
      }
      replicas = 1
      useCommonServices = true
      version = "11.0.0"
    }
  }
  dashboard_instance = {
    apiVersion = "appconnect.ibm.com/v1beta1"
    kind = "Dashboard"
    metadata = {
      name = "db-01-quickstart"
      namespace = "app-connect"
    }
    spec = {
      license = {
        accept = true
        license = "L-APEH-BSVCHU"
        use = "CloudPakForIntegrationNonProduction"
      }
      pod = {
        containers = {
          content-server = {
            resources = {
              limits = {
                cpu = "250m"
              }
            }
          }
          control-ui = {
            resources = {
              limits = {
                cpu = "250m"
                memory = "250Mi"
              }
            }
          }
        }
      }
      replicas = 1
      storage = {
        class = local.storage_class
        size = "5Gi"
        type = "persistent-claim"
      }
      useCommonServices = true
      version = "11.0.0"
    }
  }

  instance_files = [
    local.integration-server_file,
    local.switch-server_file,
    local.designer_file,
    local.dashboard_file
  ]
  instances      = [
    local.integration-server_instance,
    local.switch-server_instance,
    local.designer_instance,
    local.dashboard_instance
  ]
}

resource null_resource create_dirs {
  provisioner "local-exec" {
    command = "mkdir -p ${local.tmp_dir}"
  }

  provisioner "local-exec" {
    command = "mkdir -p ${local.instance_dir}"
  }

  provisioner "local-exec" {
    command = "echo ${var.platform-navigator-name}"
  }
}

resource null_resource default_storage_class {
  depends_on = [null_resource.create_dirs]

  provisioner "local-exec" {
    command = "${path.module}/scripts/get-default-storage-class.sh ${local.storage_class_file}"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

data local_file default_storage_class {
  depends_on = [null_resource.default_storage_class]

  filename = local.storage_class_file
}

resource local_file subscription_yaml {
  depends_on = [null_resource.create_dirs]

  filename = local.subscription_file

  content = yamlencode(local.subscription)
}

resource null_resource create_subscription {
  depends_on = [local_file.subscription_yaml]

  triggers = {
    KUBECONFIG = var.cluster_config_file
    namespace = var.namespace
    file = local.subscription_file
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${self.triggers.file} && ${path.module}/scripts/wait-for-csv.sh ${self.triggers.namespace} ibm-integration-platform-navigator"

    environment = {
      KUBECONFIG = self.triggers.KUBECONFIG
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "kubectl delete -n ${self.triggers.namespace} -f ${self.triggers.file}"

    environment = {
      KUBECONFIG = self.triggers.KUBECONFIG
    }
  }
}

resource local_file instance_yaml {
  depends_on = [null_resource.create_dirs]
  count = length(local.instance_files)

  filename = local.instance_files[count.index]

  content = yamlencode(local.instances[count.index])
}

resource null_resource create_instances {
  depends_on = [local_file.instance_yaml]

  triggers = {
    KUBECONFIG = var.cluster_config_file
    namespace = var.namespace
    dir = local.instance_dir
  }

  provisioner "local-exec" {
    command = "kubectl apply -n ${self.triggers.namespace} -f ${self.triggers.dir}"

    environment = {
      KUBECONFIG = self.triggers.KUBECONFIG
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "kubectl delete -n ${self.triggers.namespace} -f ${self.triggers.dir}"

    environment = {
      KUBECONFIG = self.triggers.KUBECONFIG
    }
  }
}
