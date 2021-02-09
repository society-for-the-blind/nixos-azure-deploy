# Deploy custom images and NixOS VMs to Azure

## 0. Background

Wanted to use [NixOps](https://github.com/NixOS/nixops) to deploy NixOS virtual machines to the Azure cloud, but apparently [the Azure backend has been removed](https://github.com/NixOS/nixops/pull/1131). [Cole Mickens](https://github.com/colemickens) wrote a script called [`azure-new`](https://github.com/NixOS/nixpkgs/tree/master/nixos/maintainers/scripts/azure-new), and shared it in the [Nixpkgs repo](https://github.com/NixOS/nixpkgs), which is basically a replacement for the missing [NixOps](https://github.com/NixOS/nixops).  backend. (There was already a script called `azure`, hence the name.) The notion is that once the NixOS machines are deployed, they can be managed with [NixOps](https://github.com/NixOS/nixops). (TODO: Prove this statement.)

Created a [pull request](https://github.com/NixOS/nixpkgs/pull/95279) with some changes that made a script more straightforward for myself, but [Cole](https://github.com/colemickens) already started working on a more modern alternative, [`flake-azure-demo`](https://github.com/colemickens/flake-azure-demo/tree/dev). (For help and more info see IRC channel #nixos-azure, with [logs](https://logs.nix.samueldr.com/nixos-azure/).)

Not being up to date with flakes and not wanting to lose my changes (or have them embedded in thousands of Nixpkgs repo branches), I moved all related commits into this repo. (Stackoverflow threads that helped: [How to show git log history (i.e., all the related commits) for a sub directory of a git repo?](https://stackoverflow.com/questions/16343659/how-to-show-git-log-history-for-a-sub-directory-of-a-git-repo) and [How to copy commits from one Git repo to another?](https://stackoverflow.com/questions/37471740/how-to-copy-commits-from-one-git-repo-to-another).)

## 1. Demo

<sup>This has been part of the original script, and it may be relevant still.</sup>

Here's a demo of this being used: https://asciinema.org/a/euXb9dIeUybE3VkstLWLbvhmp

This is meant to be an example image that you can copy into your own
project and modify to your own needs. Notice that the example image
includes a built-in test user account, which by default uses your
`~/.ssh/id_ed25519.pub` as an `authorized_key`.

## 2. Usage

0. `git clone https://github.com/society-for-the-blind/azure-new.git`

1. `cd azure-new/nixos/maintainers/scripts/azure-new/`

2. Create Nix expression(s) (or modify the existing ones) to build an Azure image (See [**2.1**](#21-create-nix-expressions))

3. `nix-shell` (See [**2.2**](#22-enter-nix-shell))

4. Create and upload an image with [`upload-image.sh`](./nixos/maintainers/scripts/azure-new/upload-image.sh)

5. Create and boot up a virtual machine from a NixOS image with [`boot-vm.sh`](./nixos/maintainers/scripts/azure-new/boot-vm.sh)

Again, the reason behind the weird directory paths is that this script has been pulled out from the main [Nixpkgs repo](https://github.com/NixOS/nixpkgs) and didn't feel the urgent need to do any changes to them (yet).

### 2.0 Examples

The examples below assume that you have started the `nix-shell` with

```
$ nix-shell --arg pkgs 'import <nixpkgs> {}'
```

or similar.


#### 2.0.1 Create and upload image, then create a NixOS virtual machine and boot it up

```text
$ ./upload-image.sh --resource-group sftb-custom-images-rg --image-name sftb-nixos-tr2 --image-nix tr2-image/image

$ ./boot-vm.sh --resource-group sftb-vms-rg --image sftb-nixos-tr2 --vm-name tr2-backup-test
```

> **Note**
> The options `--image-name` for [`upload-image.sh`](./nixos/maintainers/scripts/azure-new/upload-image.sh) and `--image` for [`boot-vm.sh`](./nixos/maintainers/scripts/azure-new/boot-vm.sh) are different on purpose, even though many times they would accept the same value. The reason is that the former script _creates_ the image and you supply the name, whereas the latter refers to an already existing object.

#### 2.0.2 Same as above but combine image creation with booting up the VM

```text
$ ./upload-image.sh -g sftb-custom-images-rg -n sftb-nixos-tr2 -i tr2-image/image.nix -l  westus2 --boot-sh-opts "vm-name=tempnixos"
```

At this point the only mandatory argument to `--boot-sh-opts` is `vm-name`; it will call [`boot-vm.sh`](./nixos/maintainers/scripts/azure-new/boot-vm.sh) behind the scenes with the provided `--vm-name` argument and the resource group and image name supplied to [`upload-image.sh`](./nixos/maintainers/scripts/azure-new/upload-image.sh).

To avoid the image and the VM ending up in the same resource group, just supply a different resource group to `--boot-sh-opts`. For example:


```text
$ ./upload-image.sh \
> -g sftb-custom-images-rg \
> -n sftb-nixos-tr2 \
> -i tr2-image/image.nix \
> -l  westus2 \
> --boot-sh-opts "vm-name=tempnixos;resource-group=new-rg"
```

#### 2.0.3 Create and boot up VM from existing image

```text
$ ./boot-vm.sh -g sftb-vms-rg -i sftb-nixos-tr2 -n tr2-backup-test
```

where `sftb-nixos-tr2` is an existing image in your Azure account. The resource group will be created if not present.

### 2.1 Create Nix expression(s)

Following Cole's original setup, `image.nix` will create an Azure image and will call `system.nix` in the process, where the latter will end up becoming the new system's `configuration.nix`.

 + The original examples are in [`./nixos/maintainers/scripts/azure-new/examples`](./nixos/maintainers/scripts/azure-new/examples) and they still refer to paths as they were in the [Nixpkgs](https://github.com/NixOS/nixpkgs) repo.

 + The ones in the `./nixos/maintainers/scripts/azure-new/tr2-image` will work out of the box and up-to-date, but they are specific to our services.

```text
.
├── COPYING
├── nixos
│   ├── maintainers
│   │   └── scripts
│   │       └── azure-new
│   │           ├── azure -> /nix/store/1p5naccsxq55xlk9g6c8yajm89nrg1ag-azure-image
│   │           ├── boot-vm.sh
│   │           ├── examples
│   │           │   └── basic
│   │           │       ├── image.nix
│   │           │       └── system.nix
│   │           ├── shell.nix
│   │           ├── tr2-image
│   │           │   ├── image.nix
│   │           │   └── system.nix
│   │           └── upload-image.sh
│   └── modules
│       └── virtualisation
│           └── azure-image.nix
└── README.md

10 directories, 10 files
```

### 2.2 Enter `nix-shell`

The provided [`shell.nix`](./nixos/maintainers/scripts/azure-new/shell.nix) and [`image.nix`](./nixos/maintainers/scripts/azure-new/examples/basic/image.nix) will import the [Nixpkgs repo](https://github.com/NixOS/nixpkgs)'s `default.nix` (as the script has been part of that repo) if no arguments are provided, therefore to avoid `nix-shell` erroring out, either change `shell.nix` towards your own package set or define the `pkgs` when invoking it:

```text
$ nix-shell --arg pkgs 'import <nixpkgs> {}'
```
You may have to look further though as [`system.nix`](./nixos/maintainers/scripts/azure-new/examples/basic/system.nix) (called by [`image.nix`](./nixos/maintainers/scripts/azure-new/examples/basic/image.nix)) relies on the `virtualisation.azureImage` (defined in [`azure-image.nix`](./nixos/modules/virtualisation/azure-image.nix)) attribute that, at the time of writing this, is not yet present in the 20.03 channel and you will need to find a Nixpkgs commit that works, mostly using trial and error.

This commit works, but I try to update this archive URL whenever I can:

```text
$ nix-shell --arg pkgs 'import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/8e78c2cfbae.tar.gz") {}'
```

Some helpful stuff:

 + A helpful [NixOS discourse thread](https://discourse.nixos.org/t/how-to-see-what-commit-is-my-channel-on/4818) (or [Stackoverflow thread](https://stackoverflow.com/questions/66124085/how-to-pin-an-import-nixpkgs-call-to-a-specific-commit/66124086#66124086)) on how to construct the `fetchTarball` URL

 + See also [issue #86005](https://github.com/NixOS/nixpkgs/issues/86005) when getting `The option `virtualisation.azureImage` defined in ... does not exist`.

## 4. Limitations, quirks, etc.

### 4.1 Ancillary artifacts

#### 4.1.1 Disks

A new disk (with the same name as the image) is generated every time [`upload-image.sh`](./nixos/maintainers/scripts/azure-new/upload-image.sh) is used to avoid using storage accounts and to be able to upload images directly.

The disk is not deleted automatically, and re-use is not included in the script at the moment; to allow uplad, disks have to be in a specific state, and it is error-prone to get it right. Please see notes in [`upload-image.sh`](./nixos/maintainers/scripts/azure-new/upload-image.sh).

#### 4.1.2 Resource groups

Both [`upload-image.sh`](./nixos/maintainers/scripts/azure-new/upload-image.sh) and [`boot-vm.sh`](./nixos/maintainers/scripts/azure-new/boot-vm.sh) have a `--resource-group` (or `-g`) switch to provide additional granularity of organizing resources.

Some [Best practices for naming your Microsoft Azure resources](https://techcommunity.microsoft.com/t5/itops-talk-blog/best-practices-for-naming-your-microsoft-azure-resources/ba-p/294480).

#### 4.1.3 Identities

Aside from creating and booting up a VM, [`boot-vm.sh`](./nixos/maintainers/scripts/azure-new/boot-vm.sh) also creates a [managed service identity](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview), with the same name as the provided resource group. (See also [`az identity` Azure CLI command](https://docs.microsoft.com/en-us/cli/azure/identity?view=azure-cli-latest#az-identity-create).)

> TODO/QUESTION: Why? What are the benefits? This step is entirely optional, and [ `az vm create` ](https://docs.microsoft.com/en-us/cli/azure/vm?view=azure-cli-latest#az-vm-create) doesn't require it. If not need it, just rip out the relevant parts in [`boot-vm.sh`](./nixos/maintainers/scripts/azure-new/boot-vm.sh).

#### 4.1.4 New SSH keypair by default for each VM

Seemed like a sensible default. If you want to provide your own keys, please take a look at the very end of [`boot-vm.sh`](./nixos/maintainers/scripts/azure-new/boot-vm.sh) (and maybe [`system.nix`](./examples/basic/system.nix) as well).

## 5. Future Work

1. If the user specifies a hard-coded user, then the agent could be removed.
   Probably has security benefits; definitely has closure-size benefits.
   (It's likely the VM will need to be booted with a special flag. See:
   https://github.com/Azure/azure-cli/issues/12775 for details.)
