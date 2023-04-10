# Cloudflare IPs to Firewalld 

Add/Allow ipv4, ipv6 Cloudflare IP ranges to specified firewalld zone.

* Create zone `cloudflare`
* Add services to `cloudflare` zone `http`, `https`
* Add CF lists to newest zone
* Checking differences between previous downloaded list and currently downloaded

## For automation

Copy `cf-update` to `/etc/cron.hourly/` or `/etc/cron.daily/`

## Cludflare IP lists

Downloading according for reference: https://www.cloudflare.com/ips/