# LSL Bot Client Script for Microsoft Bot Framework

Author: Makopoppo(SL Name -> Mako Nozaki)

This script converts the object in Second Life (or OpenSimulator)
into the bot client for [Microsoft Bot Framework](https://dev.botframework.com/).

### Prerequisites

You need a Bot Framework bot and enable Direct Line channel on it.
For example, if you create a bot in C# with Visual Studio, 
and deploy it on Azure, these documents will help.

https://docs.microsoft.com/en-us/bot-framework/dotnet/bot-builder-dotnet-quickstart
https://docs.microsoft.com/en-us/bot-framework/deploy-dotnet-bot-visual-studio
https://docs.microsoft.com/en-us/bot-framework/portal-register-bot
https://docs.microsoft.com/en-us/bot-framework/channel-connect-directline

### How to use it

1. Reveal "Secret keys" on Direct Line page and copy it to elsewhere.
2. In Second Life or OpenSimulator world, create a notecard named "SECRET".
3. Paste the secret key and save the notecard.
4. Create an arbitrary object, then put the notecard in it.
5. Create new script and copy-and-paste this script.
6. Save the script to activate the bot client.
