# VMNET: Customizing Libvirt nat networks.

This package aims at customizing libvirt nat networks. When using libvirt, I ran into many issues with masquerading and iptables rules. In addition, firewalld would sometimes silently fail when it collided with my own iptables rules (this was very painful). I also had the issue of libvirt destroying my firewall rules. So I endeavored to manage my own nat networks instead.

Note, this setup worked on Arch Linux. You may (and should) customize the scripts for your distro if you plan on using these scripts/services.

Regardless of distro, you still need to customize each network manually as it can't be done through the cli (yet). You can reference the "example" and "template" folders for how to do this.

## Decisions

### Firewalld

Libvirt uses firewalld by default. I didn't want to override the main libvirtd service file to remove the firewalld dependencies. So I opted to continue using firewalld. Overall, I enjoyed the experience and didn't mind using it. It addition, it was trivial to setup my previous firewall rules using it in order to have consolidated control over the firewall. Note that I did use iptables as backend for firewalld (set in firewalld.conf) as opposed to nftables. I haven't tested with nftables but I can't see why it would't work.

Each network gets its own zone which is nice. However, zones cannot be created with refreshing the daemon. Refreshing the daemon loses all rules. Therefore, all zones need to be created before any actual rules are applied. This is done in vmfwzones. Hopefully I'll be able to work around this later.

### Brctl

Libvirt required brctl anyways and I opted to continue using it when creating bridges. Again, the target of this package is simple nat networks.

### DHCPD / Dnsmasq

One of the issues I ran into was dnsmasq's dhcp service that ships with libvirt. When I manually set it up with dhcpcd instead, it ended up working. This does mean that you need to configure the dhcpcd conf file for each network.

### Systemd

To be honest, I don't mind systemd. Sure, I'm not fan of some the services in manages on Ubuntu, but on Arch, it's pretty straight forward to work with.

## TODO

[ ] Add the ability to create new networks to vmnetctl
[ ] Make it better

## Resources:
- https://jamielinux.com/docs/libvirt-networking-handbook/custom-nat-based-network.html
- https://www.rootusers.com/how-to-use-firewalld-rich-rules-and-zones-for-filtering-and-nat/
- https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-using-firewalld-on-centos-7
- https://www.freedesktop.org/software/systemd/man/systemd.service.html
- https://www.digitalocean.com/community/tutorials/understanding-systemd-units-and-unit-files


## Usage
```
Usage: vmnetctl COMMAND [BRIDGE]
    Start All Systemd Services: vmnetctl systemd-start-all
    Stop All Systemd Services: vmnetctl systemd-stop-all
    Enable All Systemd Services: vmnetctl systemd-enable-all
    Disable All Systemd Services: vmnetctl systemd-disable-all
    Start: vmnetctl start BRIDGE
    Stop: vmnetctl stop BRIDGE
    Systemd Start: vmnetctl systemd-start BRIDGE
    Systemd Stop: vmnetctl systemd-stop BRIDGE
    Apply Firewall Rules: vmnetctl apply-firewall BRIDGE
    Remove firewall: vmnetctl remove-firewall BRIDGE
    Clear DHCP History: vmnetctl clear-dhcpd BRIDGE
    Create Zones: vmnetctl systemd-start-zones (calls create-zones)
    Create Zones: vmnetctl systemd-stop-zones (calls delete-zones)
    Create Zones: vmnetctl create-zones
    Delete Zones: vmnetctl delete-zones
    Make Mac Address: vmnetctl make-mac
    Help: vmnetctl help
```
