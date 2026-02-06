#
# Monitoring - healthchecks.io (Optional)
#
# Enabled when healthchecks_api_key is set
#

resource "healthchecksio_check" "app" {
  count = var.healthchecks_api_key != "" ? 1 : 0

  name = var.server_name

  tags = [
    var.project_name,
    "production"
  ]

  # Check every 5 minutes (300 seconds)
  timeout = 300
  grace   = 60

  # Alerts will be sent to all channels configured in healthchecks.io dashboard
  # (channels attribute omitted = default behavior sends to all channels)

  # Optional: Add more specific configuration
  desc = "Health check for ${var.github_repository} deployed on ${var.server_name}"
}
