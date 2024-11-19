# CloudFlare DDoS Protection Script

A bash script that automatically manages CloudFlare's DDoS protection based on your server's CPU load. The script monitors system resources and dynamically adjusts CloudFlare's security level through their API.

## Features

- Automatic DDoS protection based on CPU load
- Secure configuration handling
- Logging
- Email notifications
- Temporary file management
- Automatic cleanup

## Prerequisites

### Required Software

- curl (for API requests)
- jq (for JSON parsing)
- mailutils/mailx (for notifications)

### Installation on Debian/Ubuntu

```bash
sudo apt-get update
sudo apt-get install -y curl jq mailutils
```

### Installation on RedHat/CentOS/Rocky Linux

```bash
sudo yum install -y curl jq mailx
```

### CloudFlare Requirements

- CloudFlare account
- CloudFlare API token with the following permissions:
  - Zone - Zone Settings - Read
  - Zone - Zone Settings - Edit
- CloudFlare Zone ID

## Installation

1. Clone or download the script:

```bash
curl -o protection.sh https://raw.githubusercontent.com/bobbyiliev/cloudflare-ddos-protection/main/protection.sh
```

2. Make the script executable:
```bash
chmod +x protection.sh
```

## Configuration

### Method 1: Environment Variables

Set your CloudFlare credentials as environment variables:
```bash
export CF_ZONE_ID="your_zone_id"
export CF_EMAIL_ADDRESS="your_email"
export CF_API_TOKEN="your_api_token"
```

### Method 2: Direct Script Configuration

Edit the script and update the following variables:
```bash
CF_ZONE_ID="your_zone_id"
CF_EMAIL_ADDRESS="your_email"
CF_API_TOKEN="your_api_token"
```

### Optional Settings

- `NOTIFICATIONS_ENABLED`: Set to 1 to enable email notifications (default: 1)
- You can modify the CPU load thresholds by adjusting the calculation in the `get_allowed_cpu_load` function

## Usage

### Manual Execution

Run the script directly:

```bash
./protection.sh
```

### Automated Execution (Recommended)

Set up a cron job to run the script every 30 seconds:

1. Open your crontab:

```bash
crontab -e
```

2. Add the following lines:

```bash
* * * * * /full/path/to/protection.sh
* * * * * ( sleep 30 ; /full/path/to/protection.sh )
```

## Logging

The script logs all activities to `~/.cloudflare/ddos.log`. Each log entry includes:
- Timestamp
- Action taken (enabled/disabled DDoS protection)
- Current CPU load
- Any errors encountered

Example log entry:

```
2024-11-19 14:30:00 - Enabled DDoS protection (Load: 8)
```

## Email Notifications

When `NOTIFICATIONS_ENABLED` is set to 1, you'll receive email notifications for:
- DDoS protection enabled/disabled
- Error conditions
- Configuration issues

Note that the email notifications require a working `mail` command on your system and do not support SMTP authentication. This may require additional configuration for some mail servers as you might not be able to send emails directly from your server.

## Security Considerations

- The configuration directory is created with restricted permissions (700)
- Temporary files are securely created and automatically cleaned up
- API credentials are protected from exposure in logs
- Input validation is performed on all variables

If you encounter any security issues, please report them to [@bobbyiliev_](https://x.com/bobbyiliev_).

## Troubleshooting

Add `set -x` at the beginning of the script for verbose output:

```bash
#!/bin/bash
set -x
# rest of the script...
```

## CloudFlare API Reference

For more information about the CloudFlare API endpoints used in this script, visit:
- [CloudFlare API Documentation](https://developers.cloudflare.com/api)
- [Security Level Settings](https://developers.cloudflare.com/api/operations/zone-settings-change-security-level-setting)

## Contributing

Feel free to submit issues and enhancement requests!
