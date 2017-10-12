// LSL Bot Client Script for Microsoft Bot Framework
// Author: Makopoppo(SL Name -> Mako Nozaki)
//
// This script converts the object in Second Life (or OpenSimulator)
// into the bot client for Microsoft Bot Framework.
// 
// https://dev.botframework.com/
// 
// You need a Bot Framework bot and enable Direct Line channel on it.
// For example, if you create a bot in C# with Visual Studio, 
// and deploy it on Azure, these documents will help.
// 
// https://docs.microsoft.com/en-us/bot-framework/dotnet/bot-builder-dotnet-quickstart
// https://docs.microsoft.com/en-us/bot-framework/deploy-dotnet-bot-visual-studio
// https://docs.microsoft.com/en-us/bot-framework/portal-register-bot
// https://docs.microsoft.com/en-us/bot-framework/channel-connect-directline
// 
// 1. Reveal "Secret keys" on Direct Line page and copy it to elsewhere.
// 2. In Second Life or OpenSimulator world, create a notecard named "SECRET".
// 3. Paste the secret key and save the notecard.
// 4. Create an arbitrary object, then put the notecard in it.
// 5. Create new script and copy-and-paste this script.
// 6. Save the script to activate the bot client.

string REQUEST_URL = "https://directline.botframework.com/v3/directline/conversations";
string TOKEN_REFRESH_URL = "https://directline.botframework.com/v3/directline/tokens/refresh";
string SECRET_NOTECARD_NAME = "SECRET";

key httpRequestId;
key notecardQueryId;

string secretStr; // from notecard

string conversationId;
string tokenId;
integer expiresIn;
float tokenAquiredTime;
string watermark = "0";

string utterance;

ResetConversation()
{
    llSay(0, "resetting ... ");
    llHTTPRequest(REQUEST_URL + "/" + conversationId + "/activities",
            [
                HTTP_METHOD, "POST",
                HTTP_CUSTOM_HEADER, "Authorization", "Bearer " + tokenId,
                HTTP_MIMETYPE, "application/json;charset=utf-8"
            ], 
            "{\"type\": \"endOfConversation\", \"from\": {\"id\": \"" + (string) llGetKey() + "\"} }");
    // I don't wait for this response 
    // since conversation will be automatically closed after some duration even if this call fail.
    llResetScript();
}

HandleError(integer status, string body)
{
    if(status > 399 && status < 600) // when 4XX or 5XX
    {
        string errorStr = llJsonGetValue(body, ["error"]);
        string errorCode = llJsonGetValue(errorStr, ["code"]);
        string errorMessage = llJsonGetValue(errorStr, ["message"]);

        llSay(0, "ERROR CONTACT TO THE OWNER [" + "HTTPStatus: " + 
            (string)status + ", code: " + errorCode + ", message: " + errorMessage + "]");

        ResetConversation();
    }
    // else: continue
}

default
{
    state_entry()
    {
        if (llGetInventoryKey(SECRET_NOTECARD_NAME) != NULL_KEY) {
            notecardQueryId = llGetNotecardLine(SECRET_NOTECARD_NAME, 0);
        }else{
            llSay(0, "\"" + SECRET_NOTECARD_NAME + "\"(NOTECARD) IS MISSING FROM OBJECT INVENTORY");
            // once you put a notecard in inventory you'll need to reset this object to activate
        }
    }
    
    dataserver(key queryid, string data) {
        if (queryid == notecardQueryId) {
            secretStr = data; // even if it is EOF
            httpRequestId = llHTTPRequest(REQUEST_URL, 
                [
                    HTTP_METHOD, "POST",
                    HTTP_CUSTOM_HEADER, "Authorization", "Bearer " + secretStr
                ], 
                "");
        }
    }

    http_response(key request_id, integer status, list metadata, string body)
    {
        // exit if unknown
        if (request_id != httpRequestId) return;

        HandleError(status, body);

        conversationId = llJsonGetValue(body, ["conversationId"]);
        tokenId = llJsonGetValue(body, ["token"]);
        expiresIn = (integer)llJsonGetValue(body, ["expires_in"]);
        tokenAquiredTime = llGetTime();
        llSay(0, "completed in initializing");
        state state_listening;
    }
}

state state_listening
{
    state_entry()
    {
        llListen(0, "", NULL_KEY, ""); // listen for first utterance
        llSetTimerEvent(10);
    }

    listen(integer channel, string name, key id, string message)
    {
        utterance = message;
        state state_send;
    }

    // listener will be automatically closed when move to another state.

    timer()
    {
        float duration = llGetTime() - tokenAquiredTime;
        if (duration > expiresIn * 0.9)
        {
            llOwnerSay("nearly expires, refreshing the token ...");
            state state_token_refresh;
        }
    }
}

state state_send
{
    state_entry()
    {
        string body = "{\"type\": \"message\",\"from\": {\"id\": \"" + (string)llGetKey() + "\"},\"text\": \"" + utterance + "\"}";

        httpRequestId = llHTTPRequest(REQUEST_URL + "/" + conversationId + "/activities",
            [
                HTTP_METHOD, "POST",
                HTTP_CUSTOM_HEADER, "Authorization", "Bearer " + tokenId,
                HTTP_MIMETYPE, "application/json;charset=utf-8"
            ], 
            body);
    }
 
    http_response(key request_id, integer status, list metadata, string body)
    {
        // exit if unknown
        if (request_id != httpRequestId) return;

        HandleError(status, body);

        // since this response is no use, just ignore it and move it on.
        state state_receive;
    }
}

state state_receive
{
    state_entry()
    {
        httpRequestId = llHTTPRequest(REQUEST_URL + "/" + conversationId + "/activities?watermark=" + watermark,
        [
            HTTP_METHOD, "GET",
            HTTP_CUSTOM_HEADER, "Authorization", "Bearer " + tokenId
        ], "");
    }
 
    http_response(key request_id, integer status, list metadata, string body)
    {
        // exit if unknown
        if (request_id != httpRequestId) return;

        HandleError(status, body);

        // refresh watermark
        watermark = llJsonGetValue(body, ["watermark"]);

        // just takes last activity
        list actList = llJson2List(llJsonGetValue(body, ["activities"]));
        string activity = llList2String(actList, llGetListLength(actList)-1);

        llSay(0, llJsonGetValue(activity, ["text"])); // chat out
        state state_listening;
   }
}

// see "Refresh a Direct Line token" 
// in https://docs.microsoft.com/en-us/bot-framework/rest-api/bot-framework-rest-direct-line-3-0-authentication

state state_token_refresh
{
    state_entry()
    {
        httpRequestId = llHTTPRequest(TOKEN_REFRESH_URL,
            [
                HTTP_METHOD, "POST",
                HTTP_CUSTOM_HEADER, "Authorization", "Bearer " + tokenId
            ], 
            "");
    }

    http_response(key request_id, integer status, list metadata, string body)
    {
        // exit if unknown
        if (request_id != httpRequestId) return;

        HandleError(status, body);

        conversationId = llJsonGetValue(body, ["conversationId"]);
        tokenId = llJsonGetValue(body, ["token"]);
        expiresIn = (integer)llJsonGetValue(body, ["expires_in"]);
        tokenAquiredTime = llGetTime();

        llOwnerSay("token refreshed.");

        state state_listening;
    }
}