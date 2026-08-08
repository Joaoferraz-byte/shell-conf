p = "modules/default.nix"
s = open(p).read()
target = """    # DMS niri integration module (provides programs.dank-material-shell.niri options)
    # This module internally imports niri-flake home-manager module.
    inputs.dms.homeModules.niri
"""
if target not in s:
    raise SystemExit("block not found")
s = s.replace(target, "")
open(p, "w").write(s)
print(open(p).read())
