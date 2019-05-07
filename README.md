# spacewalk
script to add client to spacewalk server

Requirement:

1. Spacewalk server already created (of course...)
2. IP address and hostname of spacewalk server
3. User and password to connect to spacewalk server

Once finish it will have default channel. Use this command to view, add, or delete channel
1. spacewalk-channel -l (view available channel in local)
2. spacewalk-channel -L (view available channel in remote)
3. spacewalk-channel -a -c "channel name" (to add certain channel)
4. spacewalk-channel -d -c "channel name" (to delete certain channel)


The End
