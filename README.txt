--- Certificate tool for tektelic gateways with basic station ---


1. Generate TLS certificate on the chirpstack server for the desired gateway.
2. Run "./build_ipk.sh" in git bash or double click the file.
3. Follow the steps and paste the chirpstack certificates you generated from step one.
4. A new ipk file will be created in the folder. Transfer over the file called "bstn-config-chirpstack.ipk" to the gateway via OAM (transfer file tool) or ssh (scp)
5. SSH to gateway, run "opkg install /dev/shm/bstn-config-chirpstack.ipk"
6. Reboot the gateway!