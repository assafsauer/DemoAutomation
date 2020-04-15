provider "nsxt" {
  host                     = "192.168.1.170"
  username                 = "admin"
  password                 = "xxxxx"
  allow_unverified_ssl     = true
  max_retries              = 10
  retry_min_delay          = 500
  retry_max_delay          = 5000
  retry_on_status_codes    = [429]
}


# Configure the VMware vSphere Provider
provider "vsphere" {
    user           = "administrator@vsphere.local"
    password       = "xxxxx"
    vsphere_server = "192.168.1.40"
    allow_unverified_ssl = true
}

# data source for my vSphere Data Center
data "vsphere_datacenter" "dc" {
  name = "PKS-DC"
}

data "vsphere_virtual_machine" "lampvm" {
  name          = "Lamp-stack"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

##### GET VM ID #######



##### TAG VM #######
# Tag the newly created VM, so it will becaome a member of my NSGroup
# that way all fw rules we have defined earlier will be applied to it
resource "nsxt_vm_tags" "vm1_tags" {
    instance_id = "${data.vsphere_virtual_machine.lampvm.id}"
    tag {
	scope = "LAMP"
	tag = "app"
    }
    tag {
	scope = "tier"
	tag = "app"
    }
}

##### create GROUP #######

resource "nsxt_ns_group" "group2" {
  description  = "NG provisioned by Terraform"
  display_name = "LAMPGRP"

  membership_criteria {
    target_type = "VirtualMachine"
    scope       = "LAMP"
    tag         = "app"
  }

}


# Create a Firewall Section
# All rules of this section will be applied to the VMs that are members of the NSGroup we created earlier
resource "nsxt_firewall_section" "firewall_section" {
  description  = "FS provisioned by Terraform"
  display_name = "Terraform Demo FW Section"
  applied_to {
    target_type = "NSGroup"
    target_id   = "${nsxt_ns_group.group2.id}"
  }

  section_type = "LAYER3"
  stateful     = true


# Allow communication to my VMs only on the ports we defined earlier as NSService
  rule {
    display_name = "Allow HTTP"
    description  = "In going rule"
    action       = "ALLOW"
    logged       = false
    ip_protocol  = "IPV4"
    destination {
      target_type = "NSGroup"
      target_id   = "${nsxt_ns_group.group2.id}"
    }
  }

  rule {
    display_name = "Allow SSH"
    description  = "In going rule"
    action       = "ALLOW"
    logged       = false
    ip_protocol  = "IPV4"
    destination {
      target_type = "NSGroup"
      target_id   = "${nsxt_ns_group.group2.id}"

    }
}
  rule {
    display_name = "Allow HTTPS"
    description  = "In going rule"
    action       = "ALLOW"
    logged       = false
    ip_protocol  = "IPV4"
    destination {
      target_type = "NSGroup"
      target_id   = "${nsxt_ns_group.group2.id}"

    }

}

}
