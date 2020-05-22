# Dotzo

This is my home directory management tool. It handles dotfiles and other home directory configuration in accordance with my own peculiar aesthetics. I wrote it in `bash` because I wanted to use it to bootstrap things on any machine I happen to encounter in my work. I have another tool called `bash-dance` that I use to inline `dotzo` into a single script, so I can `curl/wget` this script from the internet then run it to set everything else up.

Although I am not currently using a mac, because *macos* machines usually have `bash 3.*` as the default available, I wrote everything without using `bash 4+` features such as associative arrays. Since the vast majority of significant `Linux` distros have more recent versions than this, supporting `bash 3` covers most of my bases.

## System Setup

I like to keep my home directory pretty clean and would like to minimize the load of what I back up there. Consequently, I have decided on a structure that looks like the following:
```
  <home>/
    _/             -- intentional space
    coding/        -- project involving coding and writing
    Downloads/     -- initial, high-entropy space for downloaded files
    Desktop/       -- a cluster of symbolically loaded items
    Documents/     -- legal documents, receipts, forms, etc...
    Uploads/       -- a transient staging area for uploading stuff
    < ... >/       -- any other top-level stuff
```

The first of these, the `_` directory, will be used for all of the managed configuration and state:
```
  <home>/_/
    bin/           -- my utility/config scripts
    etc/           -- configuration
    lib/           -- dependencies
    lib/tools      -- submodules of tools or libraries for setup
    lib/distros    -- distros of local languages (cabal, ocaml, rust, etc...)
    var/           -- state
    var/repos      -- repositories symlinked to project spaces
    var/secure     -- secure config
    temp/          -- transient/caches
```
this may expand in the future.

The `_` directory will itself be a *git* repository with only the static parts included. State and transient data are never synced via git; backing them up requires a different mechanism. They are excluded and managed via scripts.

The tooling will generate/manage the additional spaces in `<home>`:
```
  <home>/
    .config/   -- standard config files (will be created if not there)
    .ssh/      -- ssh config
    .cache/    -- caches/temp
    ._/        -- static back link to the "$DOT_ROOT" that can be refd in configs
```
and generate individual dotfiles and dot directories as symlinks into the `_` tree. 

Symlinked paths will point through the `_` path to their location. As a rule this will be located at `~/_`. Otherwise, the linking would be more complex.

For instance,
```
  ~/.config/sway --> ../_/etc/dot.config.sway
```
will be created.

## Dotzo

The `dotzo` utility manages this setup. On a blank environment use
```
dotzo setup
```
to download/check/clone the dotfiles repo, pull associated tools, and create a config file. This step, itself, does not modify things outside of the `_` path (or alternate if given). However, it does ask if you would like to proceed to the `sync-secure` and `sync` steps.

The `sync` step runs via
```
dotzo sync
```
and performs tasks to construct/update the environment in the `~` (home) directory. This includes symlinking all of the dotfiles into their appropriate locations; often either in `~` itself or in `~/.config`.
