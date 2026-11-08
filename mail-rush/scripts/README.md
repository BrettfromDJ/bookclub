# Mail Rush slice 1 scripts

Three Luau scripts for the first playable slice of Mail Rush, a Roblox mail delivery game.
The step-by-step build guide lives in the Slice 1 build guide tab of the design doc.

| File | Type in Studio | Where it goes |
| --- | --- | --- |
| Config.lua | ModuleScript named Config | ReplicatedStorage |
| MailRushServer.lua | Script named MailRushServer | ServerScriptService |
| MailRushClient.lua | LocalScript named MailRushClient | StarterPlayer > StarterPlayerScripts |

The server script expects a Folder named Mailboxes and a Model named PostOffice containing a Part named ClockInDesk, all in Workspace.
