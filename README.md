# Cloudflare DDoS Protection Script

Cloudflare offers free DDoS protection and they have a cool API that you could use to enable and disable their DDoS protection easily.

You can use this CLI script to enable and disable the CloudFlare DDOS protection for your website automatically based on the CPU load of your server.

## Prerequisites

* A Cloudflare account
* Cloudflare API key
* Cloudflare Zone ID
* Make sure curl is installed on your server: `curl --version`

If curl is not installed you need to run the following:

For RedHat/CentOs:

```
yum install curl
```
For Debian/Ubuntu

```
apt-get install curl
```

## Setup

All you need to do is to download the script and save it on your server.

Make the script executable:

```
chmod +x ~/protection.sh
```

Setup 2 Cron jobs to run every 30 seconds. To edit your crontab run:

```
crontab -e
```

And add the following content:

```
* * * * * /path-to-the-script/cloudflare/protection.sh
* * * * * ( sleep 30 ; /path-to-the-script/cloudflare/protection.sh )
```