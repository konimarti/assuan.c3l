## Assuan for C3

C3 implementation of the Assuan IPC protocol.

Assuan protocol is used in GnuPG for the communication between gpg, gpg-agent,
pinentry, dirmngr. All of them are running as separate processes and need a
way to talk with each other. Assuan solves this problem.

Using this library you can talk to gpg-agent or dirmngr directly, invoke
pinentry to get password prompt similar to GnuPG's one and even use Assuan
protocol for your own IPC needs.

Assuan is not, however, limited to use with GnuPG servers and clients: it was
designed to be flexible enough to meet the demands of many transaction-based
environments.

Assuan documentation: https://www.gnupg.org/documentation/manuals/assuan/

