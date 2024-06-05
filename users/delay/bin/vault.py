"""Utility script to manipulate personal vault and stored secrets.

# vault list-ssh-private-key

List supported SSH Private Keys.

These keys can be extracted with `vault read-ssh-private-key'.

# vault read-ssh-private-key

Extract, encrypt and save SSH private keys stored in 1Password.

A utility command to extract one or more SSH private keys from 1Password and store
them encrypted on the filesystem.

The 1Password `op` command-line script allows _reading_ a SSH private key, but
there's no easy way to read it pre-encrypted. In addition, `ssh-keygen` can add
passphrase to an existing key (via the `-p` command line option) but only takes
path as input, requiring the key to be stored unencrypted first on the
filesystem.

This command aims to streamline this process and encrypt the key(s) in memory
before saving them to the filesystem. For convenience, it can also read the
passphrase from a 1Password vault.

Private keys are stored in the PEM encoding, OpenSSH format and encrypted with
a passphrase. The passphrase is either read from the vault or user input.
"""

import argparse
import os
import subprocess
import sys
from cryptography.exceptions import UnsupportedAlgorithm
from cryptography.hazmat.primitives.serialization import (
    BestAvailableEncryption,
    Encoding,
    PrivateFormat,
    SSHPrivateKeyTypes,
    load_ssh_private_key,
)
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from pathlib import Path
from typing import NamedTuple
from urllib.parse import ParseResult, parse_qs, urlencode, urlparse, urlunparse


type VaultUri = str


def VaultUri(s: str) -> str:
    """Constructor function for ArgParse."""
    return s


class OpPrivateKeyEntry(NamedTuple):
    output_file: Path
    op_vault_uri: VaultUri

    @property
    def name(self) -> str:
        return os.path.basename(self.output_file)

    def __repr__(self) -> str:
        return '"{}"'.format(self.name)


_SUPPORTED_PRIVATE_KEYS = frozenset(
    (
        OpPrivateKeyEntry("~/.ssh/git-commit-signing", "op://Private/Git Commit Signing SSH Key/private key"),
        OpPrivateKeyEntry("~/.ssh/github", "op://Private/GitHub SSH Key/private key"),
        OpPrivateKeyEntry("~/.ssh/linode", "op://Private/Linode SSH Key/private key"),
        OpPrivateKeyEntry("~/.ssh/skullkid", "op://Private/SkullKid SSH Key/private key"),
        OpPrivateKeyEntry("~/.ssh/vm", "op://Private/VM SSH Key/private key"),
    )
)
_DEFAULT_PRIVATE_KEY_PASSPHRASE_OP_VAULT_URI: VaultUri = "op://Private/SSH Key Passphrase/password"


def OpPrivateKeyEntry(s: str) -> OpPrivateKeyEntry:
    return next((key for key in _SUPPORTED_PRIVATE_KEYS if key.name == s), s)


class ListSshPrivateKeyOptions(NamedTuple):
    verbose: bool


class ReadSshPrivateKeyOptions(NamedTuple):
    op_private_key_entries: list[OpPrivateKeyEntry]
    ask_for_passphrase: bool
    op_passphrase_vault_uri: VaultUri


def _parse_argv(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Utility script to manipulate personal vault and stored secrets")
    subparsers = parser.add_subparsers(title="Subcommands")
    list_ssh_private_keys = subparsers.add_parser("list-ssh-key", help="List supported SSH Private Keys")
    list_ssh_private_keys.set_defaults(func=_command_list_ssh_private_key)
    list_ssh_private_keys.add_argument("-v", "--verbose", action="store_true", help="Print additional details")
    read_ssh_private_keys = subparsers.add_parser(
        "read-ssh-key", help="Extract, encrypt and save SSH private keys stored in 1Password"
    )
    read_ssh_private_keys.set_defaults(func=_command_read_ssh_private_key)
    read_ssh_private_keys.add_argument(
        "-k",
        "--private-key",
        type=OpPrivateKeyEntry,
        nargs="*",
        choices=_SUPPORTED_PRIVATE_KEYS,
        default=_SUPPORTED_PRIVATE_KEYS,
        help="The list of private keys to extract and save to disk",
    )
    group = read_ssh_private_keys.add_mutually_exclusive_group()
    group.add_argument(
        "-a",
        "--ask-for-passphrase",
        action="store_true",
        help="Ask for the passphrase instead of reading it from the 1Password vault",
    )
    group.add_argument(
        "-p",
        "--passphrase-op-vault-uri",
        type=VaultUri,
        default=_DEFAULT_PRIVATE_KEY_PASSPHRASE_OP_VAULT_URI,
        help="The 1Password URI of the passphrase to use to encrypt the private key",
    )
    return parser.parse_args(argv)


def _op_read(op_vault_uri: VaultUri, params: dict[str, str] = None) -> bytes:
    # Unconditionally parse the URI to sorta validate its format.
    parts = urlparse(op_vault_uri)
    if params is not None:
        query = parse_qs(parts.query)
        query.update(params)
        parts = parts._replace(query=urlencode(query))
    process = subprocess.run(["op", "read", urlunparse(parts)], capture_output=True)
    return process.stdout.strip()


def _op_read_private_key_passphrase(op_vault_uri: VaultUri) -> bytes:
    return _op_read(op_vault_uri)


def _op_read_private_key(entry: OpPrivateKeyEntry) -> bytes:
    return _op_read(entry.op_vault_uri, params={"ssh-format": "openssh"})


def _load_openssh_private_key(entry: OpPrivateKeyEntry) -> SSHPrivateKeyTypes:
    key_data = _op_read_private_key(entry)
    try:
        return load_ssh_private_key(key_data, password=None)
    except (ValueError, UnsupportedAlgorithm) as e:
        print(f"Error: failed to load OpenSSH private key: {e}", file=sys.stderr)
        return None


def _encode_and_encrypt_private_key(entry: OpPrivateKeyEntry, key: SSHPrivateKeyTypes, passphrase: str) -> bytes:
    if not isinstance(key, Ed25519PrivateKey):
        print(f'Warning: key "{entry.name}" is not ed25519', file=sys.stderr)
    encoded_and_encrypted_private_key = key.private_bytes(
        encoding=Encoding.PEM,
        format=PrivateFormat.OpenSSH,
        encryption_algorithm=BestAvailableEncryption(passphrase),
    )
    return encoded_and_encrypted_private_key


def _get_private_key_passphrase(options: ReadSshPrivateKeyOptions) -> str:
    if options.ask_for_passphrase:
        return "dummy_passphrase"  # TODO: read from input.
    return _op_read_private_key_passphrase(options.op_passphrase_vault_uri)


def _command_list_ssh_private_key(args: argparse.Namespace):
    options = ListSshPrivateKeyOptions(verbose=args.verbose)
    for key in _SUPPORTED_PRIVATE_KEYS:
        if options.verbose:
            print(f"{key.name}:")
            print(f"  - save path: {key.output_file}")
            print(f"  - vault uri: {key.op_vault_uri}")
        else:
            print(key.name)


class ReadSshPrivateKeyOptions(NamedTuple):
    op_private_key_entries: list[OpPrivateKeyEntry]
    ask_for_passphrase: bool
    op_passphrase_vault_uri: VaultUri


def _command_read_ssh_private_key(args: argparse.Namespace):
    options = ReadSshPrivateKeyOptions(
        args.private_key or _SUPPORTED_PRIVATE_KEYS, args.ask_for_passphrase, args.passphrase_op_vault_uri
    )
    passphrase = _get_private_key_passphrase(options)
    for entry in options.op_private_key_entries:
        key = _load_openssh_private_key(entry)
        if key:
            private_bytes = _encode_and_encrypt_private_key(entry, key, passphrase)
            with open(os.path.expanduser(entry.output_file), "wb") as out:
                out.write(private_bytes)
            print(f"Wrote encrypted SSH private key to {entry.output_file}")


def main():
    args = _parse_argv(sys.argv[1:])
    args.func(args)


if __name__ == "__main__":
    sys.exit(main())
