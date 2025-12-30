# ==========================================
# GCP Compute
# ==========================================


resource "google_compute_instance" "k3s_vm" {
  name         = "k3s-gitops-node"
  machine_type = "e2-medium"
  zone         = "${var.gcp_region}-a"

  metadata = {
    ssh-keys = "vicram:${file("~/.ssh/lighthouse_key.pub")}"
  }

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10 # Free Tier disk limit is usually 30GB total
    }
  }

  network_interface {
    network = "default"
    access_config {
      # This gives the VM a public IP
    }
  }

  # This links the script above to the VM creation
  metadata_startup_script = file("./scripts/k3s-install.sh")

  tags = ["http-server", "https-server"]
}

# Firewall to allow us to access our apps later
resource "google_compute_firewall" "allow-http" {
  name    = "allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "allow-nodeport" {
  name    = "allow-nodeport"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["30080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"] # This matches the tag on your VM
}
