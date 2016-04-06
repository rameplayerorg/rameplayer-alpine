# RamePlayer Alpine
RamePlayer Alpine Linux Backend

## Building a new version

### git master firmware

You can build a new git master firmware by updating `ramepkg/<package>/APKBUILD` files and committing them. To get the right checksums for new packages you can use Docker image to get them for you.

1. Use Docker image https://hub.docker.com/r/rameplayerorg/rameplayer/ and mount `rameplayer-alpine` directory there. For example if you have rameplayer repositories cloned into `/home/user/projects/rame`:

  ```sudo docker run -v /home/user/projects/rame:/opt/rame -p 8022:22 rameplayerorg/rameplayer```

1. ssh into Docker image.

Do these for every updated package:

1. Update `pkgver` line in `/opt/rame/rameplayer-alpine/ramepkg/<package>/APKBUILD` file.
1. Run `abuild -F checksum`. It will update checksums in `APKBUILD` file.

Finally `git commit` all changes. After this git master firmware should be updated and available to be used in WebUI.
