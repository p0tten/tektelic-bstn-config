# LoRaWAN Infrastructure Deployment Kit

This repository contains a complete toolkit for deploying a LoRaWAN infrastructure using ChirpStack and Tektelic Gateways. **Please note, this script is highly experimental and all features has NOT been tested yet.**

The project is organized into two components:
1.  **Server Side:** Tools to build the ChirpStack IPK package. Mainly used for changing/updating the LNs server and Chirpstack certificates on a already configured gateway with Basic Station installed.
2.  **Gateway Side:** Tools for remote provisioning and configuration of Tektelic Basic Station. Used when doing a fresh Basic Station install.

You do **NOT** need to use both of these methods, use the tool accordingly!