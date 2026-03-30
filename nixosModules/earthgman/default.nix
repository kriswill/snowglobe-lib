{ lib, ... }:
{
  imports = lib.autoImport ./. { };

  keyring = {
    ssh = {
      earthgman = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKNRHd6NLt4Yd9y5Enu54fJ/a2VCrRgbvfMuom3zn5zg";
    };

    openpgp = {
      earthgman = ''
        -----BEGIN PGP PUBLIC KEY BLOCK-----

        mDMEaLTOMBYJKwYBBAHaRw8BAQdAC1fsH2BhYY9VCMqkJwPekT32bcroQ+gBMe9N
        Hm/+JSm0L0VhcnRoR21hbiAoTWFpbiBrZXkpIDxFYXJ0aEdtYW5AcHJvdG9ubWFp
        bC5jb20+iJAEExYKADgWIQSgbB5yRiZ7TO4WzC5IYjHNvOOqMgUCaRCjywIbAwUL
        CQgHAgYVCgkICwIEFgIDAQIeAQIXgAAKCRBIYjHNvOOqMjt+AP0WThFKGwZ02nB7
        cOCaSkpqg3Pbhj4HpxQi92/qNemW7QEA+L1NoxCv71aR3usv+dC2PZczvdjBkA9V
        iU6GVszSLwi4OARotM4wEgorBgEEAZdVAQUBAQdAWV1n8dxP9+ttfvFnzhtQBwUn
        HHlCHFRChKYTmlTeIksDAQgHiHgEGBYKACAWIQSgbB5yRiZ7TO4WzC5IYjHNvOOq
        MgUCaLTOMAIbDAAKCRBIYjHNvOOqMgbGAPsG0x9ClE3Shl4Rr/GZv8/+h0gmNYS/
        3ERCquDYW/4sKwD6A1H8ShG4KK+6nzkIcfAeokIeRdaykZ7Ba4FN8DiKwg4=
        =JTSG
        -----END PGP PUBLIC KEY BLOCK-----
      '';
    };

  };
}
