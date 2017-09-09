![shot of my setuo](images/tablet.jpg?raw=true "My setup")

```

                  .,::::::    .,::      .::::::::::::::::::::::::::::.     :::::::.
                  ;;;;''''    `;;;,  .,;; ;;;;;;;;'''';;;;;;;;'''';;`;;     ;;;'';;'
                   [[cccc       '[[,,[['       [[          [[    ,[[ '[[,   [[[__[[\.
                   $$""""        Y$$$P         $$          $$   c$$$cc$$$c  $$""""Y$$
                   888oo,__    oP"``"Yo,       88,         88,   888   888,_88o,,od8P
                   """"YUMMM,m"       "Mm,     MMM         MMM   YMM   ""` ""YUMMMP"

```

exttab
====

Script for using devices as external monitors over vnc


Usage
----
Base usage:
```
git clone git@github.com:cbodden/exttab.git
cd exttab
./exttab.sh
```
If using one tablet, now you connect via vnc port 5900, if two tablets
then the second one connects via port 5901

Usage explained:
```
NAME
    exttab.sh - enables tablets as external monitors

SYNOPSIS
    exttab.sh [-1, -2, -h, -H, --help]
            [-p passwd ,-P passwd ,--password=<passwd>]
            [-l or -L <####x####>, --left=<####x####>]
            [-r or -R <####x####>, --right=<####x####>]
            [-m or -M <####x####>, --resolution=<####x####>]
            [-x,-X,-q,-Q,--exit,--quit,--stop]
            [-s <side>, -S <side>, --side=<side>]

DESCRIPTION
    This script will convert either one or two devices into external
    monitors using xrandr, x11vnc, and a vnc client.

    This was tested with linux on a couple of different tablets (android)
    and cell phones (android also).

    This script can be called with no options for interactive or run with
    options on the command line.

OPTIONS
    -1
        This option specifies one tablet. Has to be used in conjunction
        with:
            [-m <####x####>, -M <####x####>, --resolution=<####x####>]
        and:
            [-s <side>, -S <side>, --side=<side>]

    -2
        This option specifies two tablets. Has to be used in conjunction
        with:
            [-l <####x####>, -L <####x####>, --left=<####x####>]
        and:
            [-r <####x####>, -R <####x####>, --right=<####x####>]

    -p <passwd>, -P <passwd>, --password=<passwd>
        This option sets a password to be used in the VNC client. Does
        not need to be used but should be so you don't get stray
        connections.

    -l <####x####>, -L <####x####>, --left=<####x####>
        This option sets the resolution for the left tablet in the format
        of "####x####". Needed when the [-2] option specified.

    -r <####x####>, -R <####x####>, --right=<####x####>
        This option sets the resolution for the right tablet in the format
        of "####x####". Needed when the [-2] option specified.

    -m <####x####>, -M <####x####>, --resolution=<####x####>
        This option sets the resolution for the tablet in the format
        of "####x####". Needed when the [-1] option specified.

    -s <side>, -S <side>, --side=<side>
        This option specifies which side the individual tablet will
        display on.
        This option is only used with [-1]

    -x, -X, -q, -Q, --exit --quit, --stop
        This option stops the running processes.
        They are all the same option.

    -h, -H, --help
        This help file.

NOTES

EXAMPLES

```


Requirements
----

- Bash (https://www.gnu.org/software/bash/)
- xrandr (https://www.x.org/wiki/)
- x11vnc (https://libvnc.github.io/)


License and Author
----

Author:: Cesar Bodden (cesar@pissedoffadmins.com)

Copyright:: 2017, Pissedoffadmins.com

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
