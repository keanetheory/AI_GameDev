"""Render stills of the lighthouse interior from house-frame coordinates (u, y, v) -> world, via shoot.sh.
usage: python shoot_house.py name  u y v  tu ty tv   [more name ... groups]
Each group renders one picture to GERFramework/shots/<name>.png with the interior lights on (SHOT_INTERIOR=1).
House frame: u along the front wall (door at 0), v inward from the door, y local height (ground floor 0.97, basement -2.0)."""
import math
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BASH = shutil.which("bash") if not shutil.which("bash") or "system32" not in shutil.which("bash").lower() else r"C:\Program Files\Git\bin\bash.exe"


def world(u, y, v):
    x = 1.506 + 0.9024 * u - 0.4309 * v
    z = 0.374 - 0.4309 * u - 0.9024 * v
    return x, y + 9.61, z


def main(argv):
    i = 0
    env = dict(os.environ, SHOT_INTERIOR="1")
    while i + 7 <= len(argv):
        name = argv[i]
        nums = [float(a) for a in argv[i + 1:i + 7]]
        f = world(*nums[0:3])
        t = world(*nums[3:6])
        args = [BASH, os.path.join(HERE, "shoot.sh"), name] + ["%.3f" % c for c in (*f, *t)]
        r = subprocess.run(args, env=env, capture_output=True, text=True)
        print(r.stdout.strip() or r.stderr.strip())
        i += 7


if __name__ == "__main__":
    main(sys.argv[1:])
