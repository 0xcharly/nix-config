"""Utility script to manipulate personal vault and stored secrets.

# sekrets list-ssh-keys

List supported SSH Private Keys.

These keys can be extracted with `sekrets read-ssh-private-key'.

# sekrets read-ssh-key

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

from pathlib import Path
from typing import IO, NamedTuple, Optional
from urllib.parse import parse_qs, urlencode, urlparse, urlunparse

from cryptography.exceptions import UnsupportedAlgorithm
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives.serialization import (
    BestAvailableEncryption,
    Encoding,
    NoEncryption,
    PrivateFormat,
    SSHPrivateKeyTypes,
    load_ssh_private_key,
)
from rich.prompt import Confirm, Prompt


type VaultUri = str


_DEFAULT_PRIVATE_KEY_PASSPHRASE_OP_VAULT_URI: VaultUri = (
    "op://Private/SSH Key Passphrase/password"
)


def vault_uri(s: str) -> VaultUri:
    """Constructor function for ArgParse."""
    return s


class OpPrivateKeyEntry(NamedTuple):
    """Represents a 1Password SSH Private Key entry."""

    output_file: Path
    op_vault_uri: VaultUri

    @property
    def name(self) -> str:
        """Returns the name of the entry."""
        return os.path.basename(self.output_file)

    def __repr__(self) -> str:
        return f'"{self.name}"'


_SUPPORTED_PRIVATE_KEYS = frozenset(
    (
        OpPrivateKeyEntry("~/.ssh/bitbucket", "op://Private/Bitbucket SSH Key/private key"),
        OpPrivateKeyEntry(
            "~/.ssh/git-commit-signing",
            "op://Private/Git Commit Signing SSH Key/private key",
        ),
        OpPrivateKeyEntry("~/.ssh/github", "op://Private/GitHub SSH Key/private key"),
        OpPrivateKeyEntry("~/.ssh/linode", "op://Private/Linode SSH Key/private key"),
        OpPrivateKeyEntry(
            "~/.ssh/skullkid", "op://Private/SkullKid SSH Key/private key"
        ),
        OpPrivateKeyEntry("~/.ssh/vm", "op://Private/VM SSH Key/private key"),
    )
)


def op_private_key_entry(s: str) -> OpPrivateKeyEntry:
    """Constructor function for ArgParse."""
    return next((key for key in _SUPPORTED_PRIVATE_KEYS if key.name == s), s)


class ListSshPrivateKeyOptions(NamedTuple):
    """List of command line options of the `list-ssh-key` subcommand."""

    verbose: bool


class ReadSshPrivateKeyOptions(NamedTuple):
    """List of command line options of the `read-ssh-key` subcommand."""

    dry_run: bool
    op_private_key_entry: OpPrivateKeyEntry
    output_file: Optional[IO[bytes]]
    skip_passphrase: bool
    ask_for_passphrase: bool
    passphrase_op_vault_uri: VaultUri


def _parse_argv(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Utility script to manipulate personal vault and stored secrets"
    )
    subparsers = parser.add_subparsers(title="Subcommands")
    list_ssh_private_keys = subparsers.add_parser(
        "list-ssh-keys", help="List supported SSH Private Keys"
    )
    list_ssh_private_keys.set_defaults(func=_command_list_ssh_private_key)
    list_ssh_private_keys.add_argument(
        "-v", "--verbose", action="store_true", help="increase verbosity"
    )
    read_ssh_private_keys = subparsers.add_parser(
        "read-ssh-key",
        help="Extract, encrypt and save SSH private keys stored in 1Password",
    )
    read_ssh_private_keys.set_defaults(func=_command_read_ssh_private_key)
    read_ssh_private_keys.add_argument(
        "-n",
        "--dry-run",
        action="store_true",
        help="show what would have been written",
    )
    read_ssh_private_keys.add_argument(
        "-k",
        "--private-key",
        type=op_private_key_entry,
        required=True,
        choices=_SUPPORTED_PRIVATE_KEYS,
        help="the private key to save to disk",
    )
    read_ssh_private_keys.add_argument(
        "-o",
        "--output-file",
        type=argparse.FileType("wb"),
        help="path on the local filesystem to save the key to",
    )
    group = read_ssh_private_keys.add_mutually_exclusive_group()
    group.add_argument(
        "-a",
        "--ask-for-passphrase",
        action="store_true",
        help="use provided passphrase over the one in 1Password vault",
    )
    group.add_argument(
        "-p",
        "--passphrase-op-vault-uri",
        type=vault_uri,
        default=_DEFAULT_PRIVATE_KEY_PASSPHRASE_OP_VAULT_URI,
        help="1Password URI of the passphrase to use to encrypt the private key",
    )
    group.add_argument(
        "-s",
        "--skip-passphrase",
        action="store_true",
        help="outputs the unencrypted key (WARNING: only do this is you know what you're doing)",
    )
    return parser.parse_args(argv)


def _op_read(op_vault_uri: VaultUri, params: dict[str, str] = None) -> bytes:
    # Unconditionally parse the URI to sorta validate its format.
    parts = urlparse(op_vault_uri)
    if params is not None:
        query = parse_qs(parts.query)
        query.update(params)
        parts = parts._replace(query=urlencode(query))
    process = subprocess.run(
        ["op", "read", urlunparse(parts)], capture_output=True, check=True
    )
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


def _encode_and_encrypt_private_key(
    entry: OpPrivateKeyEntry, key: SSHPrivateKeyTypes, passphrase: Optional[str]
) -> bytes:
    if not isinstance(key, Ed25519PrivateKey):
        print(f'Warning: key "{entry.name}" is not ed25519', file=sys.stderr)
    private_key = key.private_bytes(
        encoding=Encoding.PEM,
        format=PrivateFormat.OpenSSH,
        encryption_algorithm=(
            BestAvailableEncryption(passphrase) if passphrase else NoEncryption()
        ),
    )
    return private_key


def _get_private_key_passphrase(options: ReadSshPrivateKeyOptions) -> Optional[str]:
    if options.skip_passphrase:
        return None
    if options.ask_for_passphrase:
        return Prompt.ask("Enter your passphrase", password=True).encode("ascii")
    return _op_read_private_key_passphrase(options.passphrase_op_vault_uri)


def _command_list_ssh_private_key(args: argparse.Namespace):
    options = ListSshPrivateKeyOptions(verbose=args.verbose)
    for key in _SUPPORTED_PRIVATE_KEYS:
        if options.verbose:
            print(f"{key.name}:")
            print(f"  - save path: {key.output_file}")
            print(f"  - vault uri: {key.op_vault_uri}")
        else:
            print(key.name)


def _write_private_bytes(out: IO[bytes], private_bytes: bytes, dry_run: bool):
    if not dry_run:
        out.write(private_bytes)
        print(f"Wrote encrypted SSH private key to {out.name}", file=sys.stderr)
    else:
        print(f"Would write encrypted SSH private key to {out.name}", file=sys.stderr)


def _command_read_ssh_private_key(args: argparse.Namespace):
    options = ReadSshPrivateKeyOptions(
        dry_run=args.dry_run,
        op_private_key_entry=args.private_key,
        output_file=args.output_file,
        skip_passphrase=args.skip_passphrase,
        ask_for_passphrase=args.ask_for_passphrase,
        passphrase_op_vault_uri=args.passphrase_op_vault_uri,
    )
    passphrase = _get_private_key_passphrase(options)
    entry = options.op_private_key_entry
    key = _load_openssh_private_key(entry)
    if key:
        private_bytes = _encode_and_encrypt_private_key(entry, key, passphrase)
        if options.output_file is not None:
            _write_private_bytes(options.output_file, private_bytes, options.dry_run)
        else:
            output_file = os.path.expanduser(entry.output_file)
            if os.path.isfile(output_file) and not Confirm.ask(
                f'File "{output_file}" already exists. Overwrite?'
            ):
                return
            with open(os.path.expanduser(entry.output_file), "wb") as out:
                _write_private_bytes(out, private_bytes, options.dry_run)


def _main():
    args = _parse_argv(sys.argv[1:])
    args.func(args)


if __name__ == "__main__":
    sys.exit(_main())
