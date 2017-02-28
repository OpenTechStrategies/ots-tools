# ots-tools


# Troubleshooting note for csv2wiki

I had to run

    $ sudo apt-get install php7.0-mysql

to get MediaWiki's rebuildall.php script to run.  I needed that script
to make my categories work.


Sources for this solution:

- [Categories aren't working.](https://www.mediawiki.org/wiki/Topic:T6uzpn51mgb8n5sc)
- [Database connection fails.](https://www.mediawiki.org/wiki/Thread:Project:Support_desk/MediaWiki_upgrade_fails_with_Database_error/reply)


Note that the rebuildall.php script seems slow but takes less than 10
minutes (for me, on a small wiki, at any rate).