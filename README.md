# LoRaWAN Infrastructure Deployment Kit

This repository contains a set of tools designed to automate the deployment of a LoRaWAN infrastructure using ChirpStack and Tektelic Gateways.

The project is organized into two main components:
1.  **Server Side:** Tools to build the ChirpStack IPK package.
2.  **Gateway Side:** Tools for remote provisioning and configuration of Tektelic Basic Station.

## Directory Structure

* `/server` - Scripts for building the ChirpStack `.ipk` package.
* `/gateway` - Scripts for deploying Basic Station to Tektelic gateways remotely.

---

## 1. Server Setup (ChirpStack)
Located in the `/server` directory.

Use the `build_ipk.sh` script to create a custom ChirpStack installation package. This script automates the retrieval of configuration files and builds an installable `.ipk` file for the server environment.

**Quick Start:**
```bash
cd server
./build_ipk.sh