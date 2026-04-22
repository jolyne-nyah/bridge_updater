<!-- Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3. -->
<!-- This program comes with ABSOLUTELY NO WARRANTY. -->
<!-- See <https://gnu.org> for details. -->

# bridge_updater

## About the Project

`bridge_updater` is a Go utility for automatic updating and writing Tor bridges. It downloads data from two sources:

- `direct` — direct URLs downloaded using `curl`
- `repos` — local git repositories from which bridge files are updated using `git pull`

The file contents are then transformed and written to output files in the format expected by Tor.

Also: partially compatible with Zapret and almost compatible with VLESS clients. It is recommended to switch the VLESS client from TUN/VPN mode to proxy mode (this way the tor-proxy of bridge_updater will work faster). About Zapret: see the details below.

## DISCLAIMER

- This is a pet project for demonstration author's skills in working with `golang` (including goroutines usage), `git`, `bash`, and `vagrant`.
- The author is not responsible for the use of this utility for malicious purposes or for bypassing blocks, and they do not welcome usage of the program this way.
- The Vagrant virtual environment is provided for comfortable testing of `bridge_updater` exclusively, because it was developed for usage on Linux systems natively.
- Yggdrasil bridges are used to provide stable connection to Tor for testing and demonstration of correct work of function `checkInternetReachabilityOneshot` from module `actions/checker.go` through the proxy, and functions from module `actions/fetcher.go` (through the proxy).
- Usage cases of the program to get an access to public resources are listed to make testing more comfortable and to demonstrate corerct work of Tor, and, as a consequence, to demonstrate that `actions/writer.go` module works fine with Tor configuration.
- The case of this program usage to make the Tor Browser get an access to the Tor is given to demonstrate the correct processing the bridges fetched by the program.

## Cases of usage

Almost all the apps that are compatible with custom proxy settings can use this `SOCKS5` proxy with address `127.0.0.1` and port `6969`. All listed below cases are relevant for usage with provided Vagrant virtual environment.

### Exact examples

- Telegram: yes. But notice that calls will not work. To set it up: Settings -> Advanced settings -> Connection type -> Add proxy -> type `SOCKS5`, host `127.0.0.1`, port `6969`
- Discord: no. Use another instruments to get an access (for example, [zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube))
- Keybase: yes. Add as a proxy in advanced settings like in Telegram.
- Internet white lists bypass: no. Use VLESS client with specified configs instead.
- Browser: yes. Install the FoxyProxy extension and add the `SOCKS5` proxy, host `127.0.0.1`, port `6969`, allow proxy DNS. Don't use Yandex Browser.
  - ChatGPT: yes.
  - Google Gemini: yes.
  - Anthropic: yes.
  - TikTok: yes.
  - Youtube: yes. Important: if you use [zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube), then turn off the tor proxy for the browser where you're going to watch Youtube, or turn off zapret, or use two different browsers: one for Youtube (with no proxy) and another one for other resources (with proxy).
  - Tor Browser: yes. Just enter the machine via `vagrant ssh` or `enter.bat`, type command `bridges`, then copy and paste some of them into the bridges section in connection settings (check the Vagrant Machine Management Guide topic below). Don't use `127.0.0.1:6969` as a proxy in Tor Browser!
  - .onion addresses: possible, but strongly discouraged. Use Tor Browser instead.
  - Spotify, Soundcloud: possible, but not comfortable. Better use any VLESS client in proxy mode (to keep this proxy fast) instead.
  - Any russian service (Ozon, Wildberries, Yandex,..): no.

## Virtualization

The project includes a Vagrant-based virtual environment for easy deployment and operation, which automatically deploys a working Ubuntu machine with Tor proxy installed and everything needed for the program.

### Additional Details

- Tor proxy IPv6 support is enabled by default. If necessary, you can disable it by commenting out the necessary lines in vagrant/torrc.
- If you need to manually edit the configuration for `bridge_updater` before starting the machine, it is located in: `vagrant/brupd_conf.json`. By default, several sources for obfs4 bridges are configured there.
- Currently, webtunnel bridges are not supported for the Vagrant machine.
- It is not recommended to use vanilla bridges.
- In the very worst case, when all the fetched bridges are unacessible, the bridges in Yggdrasil network support is also provided. You can disable it by: `ygg off`
- Bridges are updated every hour by default.
- Tor proxy will be available from the host at: `127.0.0.1:6969` (SOCKS5).
- If you have Windows, the `win_install_deps.ps1` script will **DISABLE** Hyper-V and Windows Sandbox to avoid conflicts with VirtualBox.

## System Requirements

### Vagrant

- Vagrant
- VirtualBox
- Minimum 2 CPU threads and 1 GB RAM for the virtual machine

### Linux (native)

- git
- curl
- go 1.26.1
- tor

## Quick Start (via Vagrant)

### Windows

1. Install Vagrant and VirtualBox manually or run `install.bat` in the project root folder with administrator rights.
2. Reboot the computer (if necessary).
3. Run `up.bat` to bring up the virtual machine.
4. Connect to it by running `enter.bat`.
5. Done.

### Linux

1. Install Vagrant and VirtualBox for your distribution.
2. In the terminal, navigate to the project folder.
3. Start the virtual machine: `vagrant up`
4. Connect to it: `vagrant ssh`
5. Done.

## Commands

The utility supports the following commands:

- `update` — full update and writing of bridges
- `fetch` — only data download (`git pull` and/or `curl`)
- `write` — only writing already fetched files to output files
- `check` — configuration check, required tools and internet connection

### Flags

- `-c, --config` — path to the configuration file
- `-l, --loglevel` — log level: `debug`, `info`, `warn`, `error` (default `info`)
- `-r, --repos-only` — execute only the `repos` section
- `-d, --direct-only` — execute only the `direct` section
- `-i, --ignore-internet-reachability-tests` — skip internet reachability tests
- `-t, --no-tor-reload` — do not reload Tor after `write` or `update` command.

> The `--repos-only` and `--direct-only` flags cannot be used simultaneously. Also they are ignored automatically, if the `check` command is run.
> The `--no-tor-reload` flag is ignored automatically if one of the following commands is run: `check`, `fetch`.

## Manual Configuration

The configuration file must comply with the JSON schema embedded in the project. An example configuration is in `config/conf_example.json`.

### `direct`

In the `direct` section, URLs and paths for saving the source file are specified, as well as a list of output files.

```json
"direct": {
  "https://example.com/bridge.txt": {
    "dest": "/tmp/bridge.txt",
    "outputs": ["/etc/tor/bridge.conf"]
  }
}
```

Each `direct` object contains:

- `dest` — local path for downloading the source file
- `outputs` — array of files where the result will be written

### `repos`

In the `repos` section, the path to the local git repository and a set of files within the repository with corresponding output files are specified.

```json
"repos": {
  "/path/to/repo": {
    "relative/path/to/source.txt": ["/etc/tor/bridge1.conf", "/etc/tor/bridge2.conf"]
  }
}
```

Rules for `repos`:

- repository path should not end with a slash `/`
- file path within the repository should be relative
- repository must be a valid git repository

Also:

- Files in the configuration (both output and for download) should not be duplicated

### Bridge Files Format

Example of a correct input file with bridges:

```properties
#comment line
#comment line

obfs4 example.com:443 0123456789ABCDEF0123456789ABCDEF01234567 cert=ABCDEFG iat-mode=0
webtunnel example.com:443 0123456789ABCDEF0123456789ABCDEF01234567

```

## Manual Usage Examples

### Native

```bash
sudo ./bridge_updater check
sudo ./bridge_updater fetch
sudo ./bridge_updater write
sudo ./bridge_updater update
sudo ./bridge_updater update --repos-only
sudo ./bridge_updater update --direct-only
sudo ./bridge_updater update --ignore-internet-reachability-tests
```

## Vagrant Machine Management Guide

It is assumed that the main work with the program will be carried out in the Vagrant virtual environment.

### Managing the Machine on Linux

Use standard Vagrant commands in the terminal:

- `vagrant up` — start the virtual machine
- `vagrant halt` — stop the virtual machine
- `vagrant destroy` — delete the virtual machine
- `vagrant status` — check the machine status
- `vagrant ssh` — connect to the machine via SSH

### Managing the Machine on Windows

For convenience on Windows, .bat scripts are provided:

- `up.bat` — start the virtual machine
- `halt.bat` — stop the virtual machine
- `destroy.bat` — delete the virtual machine
- `enter.bat` — connect to the machine via SSH
- `manage.bat` — open the interactive management menu (English and Russian support)
- `service.bat` — manage auto-start (create a task to start on login)

### Commands Inside the Virtual Machine

Useful aliases and functions for working with the program are automatically configured inside the machine:

#### Main Alias: `brupd`

Runs the `bridge_updater` program with pre-configured configuration and logging level:

```bash
brupd check
brupd fetch
brupd write
brupd update
brupd update --repos-only
brupd update --direct-only
brupd update --ignore-internet-reachability-tests
```

#### Function: `brupd-tor`

Runs the program through the Tor proxy (all network utilities used by the program go through the Tor proxy):

```bash
brupd-tor update
brupd-tor fetch -d
```

#### Help: `brupd-info`

Displays help in Russian or English and a list of useful commands:

```bash
brupd-info ru
brupd-info en
```

#### Function: `reconfigure-daemon`

Allows switching the `brupd` service between Tor and direct modes. Accepts `tor` or `std` argument:

```bash
reconfigure-daemon tor
reconfigure-daemon std
```

#### Function: `print-service-mode`

Shows the current mode of the `brupd` service (via Tor or direct):

```bash
print-service-mode ru
print-service-mode en
```

#### Function: `ygg`

Allows enabling or disabling support for bridges in the yggdrasil network or using yggdrasil bridges only. Accepts `on`, `off` or `only` argument:

```bash
ygg on
ygg off
ygg only
```

#### Function `journal`

Allows you to view the logs of the Tor service. The first argument can be `bootstrap` (only view bootstrap logs) or `all` (view all logs). Also, you can use additional flag `-i` to view the logs in interactive mode:

```bash
journal bootstrap
journal all
journal bootstrap -i
journal all -i
```

#### Function `brupd-tor-onfailure`

Allows you to control `brupd-tor.service` behavior. Accepts `brupd`, `none` or `status` argument. `brupd` will enable trying to perform `brupd.service` on `brupd-tor.service` failure and try to fetch bridges from sourcces not using tor (behavior by default). `none` will disable this feature. `status` will print current behavior of the `brupd-tor.service`.

```bash
brupd-tor-onfailure brupd
brupd-tor-onfailure none
brupd-tor-onfailure status
```

#### Additional Commands

- `ipcheck` — check the current IP address of the Tor exit node
- `status` — check the Tor service status
- `restart` — restart the Tor service
- `bridges` — show all currently configured bridges
- `sudo nyx` — launch the Tor network monitor

## Tor bridges sources used in the standard configuration

- [igareck's vpn-configs-for-russia](https://github.com/igareck/vpn-configs-for-russia)
- [Delta-Kronecker's Tor Bridges Collector](https://github.com/Delta-Kronecker/Tor-Bridges-Collector)
