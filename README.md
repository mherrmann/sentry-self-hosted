# Sentry self-hosted
[Sentry](https://sentry.io) is a popular error tracking solution.
They have a free tier, but it is rather limited. Prices for the
hosted tier currently start at $26/mo.

This repository lets you set up a self-hosted instance of Sentry
on
[Linode](https://www.linode.com/?r=03c98ce370ba6c626d40c900c8f6f316ccb808f2),
for only $5/mo. You need a (sub-)domain such as `sentry.example.com`.
Installation is mostly automatic and takes a little over 30 minutes
in total.

## 1. Create a Linode account
If you don't already have one,
[create a Linode account](https://www.linode.com/?r=03c98ce370ba6c626d40c900c8f6f316ccb808f2).
Use the promo code **DOCS10** for a $10 credit.

## 2. Add a Linode
[Create a Linode](https://manager.linode.com/linodes/add?group=) in
Linode's Management interface. (If you haven't used them before:
Linodes are simply private Linux servers.) For small projects, a
Nanode for $5/mo is enough.

## 3. Update your DNS
The Linode management interface should now show the IP of your
server. Update your domain's DNS settings so a new `A` record points
to this IP. Typically, you'd use a subdomain such as
`sentry.myapp.com`.

## 4. Install Debian 9
Open the management page for your new Linode. Click on *Rebuild* at
the top. Select *Debian 9* as the image and pick a password. Click
*Rebuild*.

## 5. Increase swap size (if necessary)
Installing Sentry requires about 4GB of RAM. If you chose a Nanode
instance above, it only has 1GB. Go to the main management page for
your Linode. You should see two disks:

 * Debian 9 Disk
 * 256MB Swap Image

First, click on *Edit* next to *Debian 9 Disk*. Reduce its size by
5GB. Once this process is complete, *In*crease the size of the Swap
Image by 5GB.

## 6. Install Sentry
Connect to your server via SSH. Clone this repository:

    apt-get update
    apt-get install git -y
    git clone https://github.com/mherrmann/sentry-self-hosted.git

Use an editor such as `vi` to change the settings at the top of
`install.sh`. Then, make the file executable and run it:

    chmod +x sentry-self-hosted/install.sh
    sentry-self-hosted/install.sh

The first time you do this, the script will ask you to log out and
back in again. Do this but **don't yet run the script again**.

Invoking `install.sh` for a second time takes about 30 minutes.
We don't want this process to be interrupted in case your internet
connection drops. So it is highly recommended to install the
`screen` tool at this point. This keeps your terminal session alive
in case there are problems with your internet.

To install screen, log into the server and type the following:

    apt-get install screen -y

Then, launch `screen`:

    screen

This shows some information. Press <kbd>ENTER</kbd>. You are now in
a virtual terminal session hosted by `screen`. Now execute

    sentry-self-hosted/install.sh

again. You can detach from this terminal session by pressing
<kbd>Ctrl</kbd>+<kbd>A</kbd> followed by <kbd>D</kbd>. To attach to
the session again (either because you detached from it or because
your connection dropped), type `screen -r` on the command line.

The installation will prompt you to create a super user at some
point. Provide it with some values.

Once the installation is complete, the server will automatically
reboot. You can now log into it with the user credentials you
created.

## 7. Decrease swap size
Once installation is complete, it's a good idea to decrease the swap
size again (in case you increased it). Just follow the same steps as
in 5.

## 8. (Optional) enable backups
Linode can automatically back up your server for an extra $2 per
month. You can enable this in the management interface for your
Linode.

Enjoy!
