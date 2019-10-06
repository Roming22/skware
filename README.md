# SKWR - Kubernetes is great, but sometimes it's too much

SKWR (pronounced 'square') is a framework to manage applications bundled in a single docker container on a single node. Current features include:

* containers are deployed as systemd services (logs available through journalctl, auto-restart in case of failure)
* containers are automatically updated (including when a new base image is available)

The original goal of this project was to be able to manage one's own router, where each service (DNS, DHCP, etc) is a container, and centralize all of the common configuration/tooling. Ease of use is a strong focus, with modules providing a script to walk the user through the setup when necessary (e.g. to configure passwords, accounts, etc).

