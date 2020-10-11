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

## 2. Before using

The provided [`shell.nix`](./shell.nix) and [`image.nix`](./examples/basic/image.nix) will import the Nixpkgs repo](https://github.com/NixOS/nixpkgs)'s [`default.nix`](../../../../default.nix) (as the script has been part of that repo), and, as a consequence, depending on the current state of Nixpkgs, `nix-shell` and the Azure image may not build at all.

### 2.1 `nix-shell` won't build

1. Try using the channel of your system

```text
$ nix-shell --arg pkgs 'import <nixpkgs> {}'
```

2. or find a stable Nixpkgs version via commit hash (such 0c0fe6d for example)

```text
$ nix-shell --arg pkgs 'import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/0c0fe6d85b92c4e992e314bd6f9943413af9a309.tar.gz") {}'
```

### 2.2 Image build fails

[`system.nix`](./nixos/maintainers/scripts/azure-new/examples/basic/system.nix) (called by [`image.nix`](./nixos/maintainers/scripts/azure-new/examples/basic/image.nix)) relies on the `virtualisation.azureImage` (defined in [`azure-image.nix`](./nixos/modules/virtualisation/azure-image.nix)) attribute, that is not yet present in the 20.03 channel, ruling out option 1 in section 2.1 above.

See also [issue #86005](https://github.com/NixOS/nixpkgs/issues/86005) when getting `The option `virtualisation.azureImage` defined in ... does not exist`.

## 3. Usage

In short:

1. `nix-shell`

2. [`upload-image.sh`](./nixos/maintainers/scripts/azure-new/upload-image.sh)

3. (optional) [`boot-vm.sh`](./nixos/maintainers/scripts/azure-new/boot-vm.sh)

### 3.1 Enter `nix-shell`

```text
$ nix-shell
```

See section 2.1 on how to provide a specific Nixpkgs version to `nix-shell`.

### 3.2 Create and upload image ([`upload-image.sh`](./nixos/maintainers/scripts/azure-new/upload-image.sh))

```text
[..]$ ./upload-image.sh --resource-group "my-rg" --image-name "my-image"
```

or, to also boot up the new image, use:

```text
$ ./upload-image.sh -g "my-rg" -n "my-image" -b "
```

Other options and default values (`./upload-image.sh --help`):


```text
USAGE: (Every switch requires an argument)

-g --resource-group REQUIRED Created if does  not exist. Will
                             house a new disk and the created
                             image.

-n --image-name     REQUIRED The  name of  the image  created
                             (and also of the new disk).

-i --image-nix      Nix  expression   to  build  the
                    image. Default value:
                    "./examples/basic/image.nix".

-l --location       Values from `az account list-locations`.
                    Default value: "westus2".

-b --boot-sh-opts   Once  the image  is created  and uploaded,
                    run `./boot-vm.sh`  with arguments  in the
                    format of "opt1=val1;...;optn=valn".

                    + "vm-name=..." (or "n=...") is mandatory

                    + "--image" will  be  pre-populated  with
                      the created image's ID

                    + if  resource group  is omitted,  the one
                      for `./upload-image.sh` is used
```

### 3.3 Start virtual machine ([`boot-vm.sh`](./nixos/maintainers/scripts/azure-new/boot-vm.sh))

To create an existing virtual machine on Azure:

```text
$ ./boot-vm.sh -g "my-rg" -i "my-image" -n "my-new-vm"
```

Other options and default values (`./boot-vm.sh --help`):

```text
-g --resource-group REQUIRED Created if does  not exist. Will
                             house a new disk and the created
                             image.

-i --image          REQUIRED ID or name of an existing image.
                             (See `az image list --output table`)
                              or  `az image list --query "[].{ID:id, Name:name}"`.)

-n --vm-name        REQUIRED The name of the new virtual machine
                             to be created.

-n --vm-size        See https://azure.microsoft.com/pricing/details/virtual-machines/ for s
ize info.
                    Default value: "Standard_DS1_v2"

-d --os-size        OS disk size in GB to create.
                    Default value: "42"

-l --location       Values from `az account list-locations`.
                    Default value: "westus2".

NOTE: Brand new SSH  keypair is going to  be generated. To
      provide  your own,  edit  the very  last command  in
      `./boot-vm.sh`.
```

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
