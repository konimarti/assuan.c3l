## Assuan for C3

C3 implementation of the Assuan IPC protocol.

The Assuan protocol is used in GnuPG for the communication between `gpg`,
`gpg-agent`, `pinentry`, `dirmngr`. All of them are running as separate
processes and need a way to talk with each other. Assuan solves this problem.

Using this library you can talk to `gpg-agent` or `dirmngr` directly, invoke
`pinentry` to get password prompt similar to GnuPG's one and even use Assuan
protocol for your own IPC needs.

Assuan is not, however, limited to use with GnuPG servers and clients: it was
designed to be flexible enough to meet the demands of many transaction-based
environments.


## pinentry-c3: A pinentry program in C3.

Build it from project directory with:

```
c3c build pinentry-c3
```

Set the pinentry-program to `pinentry-c3` in your `gpg-agent.conf` by
adding the following line:

```
pinentry-program pinentry-c3
```

The config file `gpg-agent.conf` is usually located in `~/.gnupg/`. If not,
create it.  Also make sure that the `pinentry-c3` is in your $PATH variable (or
use the full path in the config file).

Then, restart the gpg-agent.

```
gpg-connect-agent reloadagent /bye 
```


## Documentation

- <https://www.gnupg.org/documentation/manuals/assuan/Client-code.html>
- <https://www.gnupg.org/documentation/manuals/assuan.pdf>
