# [Cozy](http://cozy.io) Notes

Cozy Notes makes your photo management easy. Main features are: 

* Structured notes
* Note search
* File attachment
* Todo-list
* Contact linking

## Install

We assume here that the Cozy platform is correctly [installed](http://cozy.io/host/install.html)
 on your server.

You can simply install the Notes application via the app registry. Click on ythe *Chose Your Apps* button located on the right of your Cozy Home.

From the command line you can type this command:

    cozy-monitor install notes


## Contribution

You can contribute to the Cozy Notes in many ways:

* Pick up an [issue](https://github.com/mycozycloud/cozy-notes/issues?state=open) and solve it.
* Translate it in [a new language](https://github.com/mycozycloud/cozy-notes/tree/master/client/app/locales).
* Note tagging
* Note sharing
* Collaboration writing


## Hack

Hacking the Notes app requires you [setup a dev environment](http://cozy.io/hack/getting-started/). Once it's done you can hack Cozy Notes just like it was your own app.

    git clone https://github.com/mycozycloud/cozy-notes.git

Run it with:

    node server.js

Each modification of the server requires a new build, here is how to run a
build:

    cake build

Each modification of the client requires a specific build too.

    cd client
    brunch build

## Tests

![Build
Status](https://travis-ci.org/mycozycloud/cozy-notes.png?branch=master)

To run tests type the following command into the Cozy Notes folder:

    cake tests

In order to run the tests, you must only have the Data System started.

## Icons

by [iconmonstr](http://iconmonstr.com/)

## License

Cozy Notes is developed by Cozy Cloud and distributed under the AGPL v3 license.

## What is Cozy?

![Cozy Logo](https://raw.github.com/mycozycloud/cozy-setup/gh-pages/assets/images/happycloud.png)

[Cozy](http://cozy.io) is a platform that brings all your web services in the
same private space.  With it, your web apps and your devices can share data
easily, providing you
with a new experience. You can install Cozy on your own hardware where no one
profiles you.

## Community

You can reach the Cozy Community by:

* Chatting with us on IRC #cozycloud on irc.freenode.net
* Posting on our [Forum](https://groups.google.com/forum/?fromgroups#!forum/cozy-cloud)
* Posting issues on the [Github repos](https://github.com/mycozycloud/)
* Mentioning us on [Twitter](http://twitter.com/mycozycloud)
