/*
    A minimal re write of the AO System to use Linkset Data
    this script is intended to be a stand alone ao managed from linkset storage
    which would allow it to be populated by any interface script.
    Created: Febuary 5 2023
    By: Phidoux (taya.Maruti)
    ------------------------------------
    | Contributers  and updates below  |
    ------------------------------------
    | Name | Date | comment            |
    ------------------------------------
*/
integer API_CHANNEL = 0x60b97b5e;

//list g_lCollars;
string g_sAddon = "ao";
string g_sVersion = "3.0.5";

//integer CMD_ZERO            = 0;
integer CMD_OWNER           = 500;
integer CMD_TRUSTED         = 501;
//integer CMD_GROUP           = 502;
integer CMD_WEARER          = 503;
//integer CMD_EVERYONE        = 504;
//integer CMD_BLOCKED         = 598; // <--- Used in auth_request, will not return on a CMD_ZERO
//integer CMD_RLV_RELAY       = 507;
//integer CMD_SAFEWORD        = 510;
//integer CMD_RELAY_SAFEWORD  = 511;
//integer CMD_NOACCESS        = 599;

//integer LINK_CMD_RESTRICTIONS = -2576;
//integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
//integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.
//integer RLV_VERSION = 6003; //RLV Plugins can recieve the used RLV viewer version upon receiving this message..
//integer RLVA_VERSION = 6004; //RLV Plugins can recieve the used RLVa viewer version upon receiving this message..
//integer RLV_CMD_OVERRIDE=6010; //RLV Plugins can send one-shot (force) commands with a list of restrictions to temporarily lift if required to ensure that the one-shot commands can be executed
//integer AUTH_REQUEST = 600;
//integer AUTH_REPLY = 601;

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer LM_SETTING_SAVE     = 2000; //scripts send messages on this channel to have settings saved, <string> must be in form of "token=value"
integer LM_SETTING_REQUEST  = 2001; //when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002; //the settings script sends responses on this channel
//integer LM_SETTING_DELETE   = 2003; //delete token from settings
//integer LM_SETTING_EMPTY    = 2004; //sent when a token has no value

//integer DIALOG          = -9000;
//integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT  = -9002;
integer MENU_REQUEST    = -9003;

/*
 * Since Release Candidate 1, Addons will not receive all link messages without prior opt-in.
 * To opt in, add the needed link messages to g_lOptedLM = [], they'll be transmitted on
 * the initial registration and can be updated at any time by sending a packet of type `update`
 * Following LMs require opt-in:
 * [ALIVE, READY, STARTUP, CMD_ZERO, MENUNAME_REQUEST, MENUNAME_RESPONSE, MENUNAME_REMOVE, SAY, NOTIFY, DIALOG, SENSORDIALOG]
 */
list g_lOptedLM     = [];

//integer g_iStandTime = 120; // Default Stand timer.
// State related Animation List.
string g_sCard = "Default";
//

UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum<CMD_OWNER || iNum>CMD_WEARER)
    {
        return;
    }
    if (llSubStringIndex(llToLower(sStr), llToLower(g_sAddon)) && llToLower(sStr) != "menu " + llToLower(g_sAddon))
    {
        return;
    }
    if (iNum == CMD_OWNER && llToLower(sStr) == "runaway")
    {
        llLinksetDataReset();
        return;
    }
    if (llToLower(sStr) == llToLower(g_sAddon) || llToLower(sStr) == "menu "+llToLower(g_sAddon))
    {
        //Menu(kID, iNum);
        //llMessageLinked(LINK_SET,iNum,"Menu",kID);
        llMessageLinked(LINK_SET, MENU_REQUEST, (string)iNum+"|MenuMain", kID);
    }
    else
    {
        if(iNum == CMD_WEARER && (integer)llLinksetDataRead("ao_noaccess") && iNum == CMD_WEARER)
        {
            Notify("Sorry your permission to access the ao has been revoked!", kID);
            return;
        }
        list lCommands = llParseString2List(sStr,[" "],[g_sAddon,llToLower(g_sAddon)]);
        string sToken = llToLower(llList2String(lCommands,1));
        string sVal = llList2String(lCommands,2);
        if ( sToken == "power")
        {
            if(llLinksetDataRead("ao_card") == "")
            {
                //g_iDefault = TRUE;
                UserCommand(iNum,g_sAddon+" load "+g_sCard, kID);
            }
            else
            {
                llLinksetDataWrite("ao_power",(string)(!(integer)llLinksetDataRead("ao_power")));
            }
        }
        else if ( sToken == "on")
        {
            if(llLinksetDataRead("ao_card") == "")
            {
                //g_iDefault = TRUE;
                UserCommand(iNum,g_sAddon+" load "+g_sCard, kID);
            }
            else
            {
                llLinksetDataWrite("ao_power",(string)TRUE);
            }
        }
        else if ( sToken == "off")
        {
            llLinksetDataWrite("ao_power",(string)FALSE);
        }
        else if (sToken == "lock")
        {
            llLinksetDataWrite("ao_lock",(string)TRUE);
        }
        else if (sToken == "unlock")
        {
            llLinksetDataWrite("ao_lock",(string)FALSE);
        }
        else if ( sToken == "load")
        {
            if(llLinksetDataRead("ao_card") != sVal)
            {
                if(llGetInventoryType(sVal) == INVENTORY_NOTECARD)
                {
                    llLinksetDataWrite("ao_loaded",(string)FALSE);
                    llLinksetDataWrite("ao_card",sVal);
                }
                else if (kID != "" && kID != NULL_KEY)
                {
                    llInstantMessage(kID,"that card does not seem to exist!");
                    llMessageLinked(LINK_SET, MENU_REQUEST, (string)iNum+"|MenuLoad",kID);
                }
            }
            else if (kID != "" && kID != NULL_KEY)
            {
                llInstantMessage(kID,"Card is already loaded try a different one or clear memory");
                llMessageLinked(LINK_SET, MENU_REQUEST, (string)iNum+"|MenuLoad", kID);
            }
        }
        else if( sToken == "reset")
        {
            llInstantMessage(kID,"Cearing data and restarting the ao");
            llLinksetDataReset();
        }
        else if( sToken == "connect")
        {
            llLinksetDataWrite("ao_online",(string)TRUE);
        }
        else if( sToken == "disconnect")
        {
            llLinksetDataWrite("ao_online",(string)FALSE);
        }
        lCommands = [];
        sToken = "";
        sVal = "";
    }
    sStr = "";
}

Link(string packet, integer iNum, string sStr, key kID)
{
    list packet_data = [ "pkt_type", packet, "iNum", iNum, "addon_name", g_sAddon, "bridge", FALSE, "sMsg", sStr, "kID", kID ];

    if (packet == "online" || packet == "update")
    {
        // only add optin if packet type is online or update
        packet_data += [ "optin", llDumpList2String(g_lOptedLM, "~") ];
    }

    string pkt = llList2Json(JSON_OBJECT, packet_data);
    if ((key)llLinksetDataRead("collar_uuid") != "" && (key)llLinksetDataRead("collar_uuid") != NULL_KEY)
    {
        llRegionSayTo((key)llLinksetDataRead("collar_uuid"), API_CHANNEL, pkt);
    }
    else
    {
        llRegionSay(API_CHANNEL, pkt);
    }

    // Sanitation to keep memory usage low.
    packet_data = [];
    pkt = "";
    packet = "";
    sStr = "";
}
NotifyOwner()
{
    if((integer)llLinksetDataRead("ao_noaccess") || (integer)llLinksetDataRead("ao_lock"))
    {
        list lOwner = llParseString2List(llLinksetDataRead("auth_owner"),[","],[]);
        integer i;
        integer iEnd = llGetListLength(lOwner)-1;
        for(i; i<iEnd; i++)
        {
            llInstantMessage(llList2Key(lOwner,i),"Allert the settings on secondlife:///app/agent/"+(string)llGetOwner()+"/about's ao are being reset");
        }
    }
}


Notify(string sMsg,key kID)
{
    llInstantMessage(kID,sMsg);
    if(kID != llGetOwner())
    {
        llOwnerSay(sMsg);
    }
    sMsg ="";
    kID = "";
}

doLock()
{
    if((integer)llLinksetDataRead("global_rlv"))
    {
        if((integer)llLinksetDataRead("ao_lock"))
        {
            llOwnerSay("@detach=n");
        }
        else
        {
            llOwnerSay("@detach=y");
        }
    }
}

goOnline()
{
    llLinksetDataWrite("collar_uuid",(string)NULL_KEY);
    if((integer)llLinksetDataRead("ao_listen"))
    {
        llListenRemove((integer)llLinksetDataRead("ao_listen"));
    }
    API_CHANNEL = ((integer)("0x" + llGetSubString((string)llGetOwner(), 0, 8))) + 0xf6eb - 0xd2;
    llLinksetDataWrite("ao_listen",(string)llListen(API_CHANNEL, "", "", ""));
    Link("online", 0, "", llGetOwner()); // This is the signal to initiate communication between the addon and the collar
    llSetTimerEvent(10);
    llLinksetDataWrite("ao_LMLastRecv",(string)llGetUnixTime());
    llLinksetDataWrite("ao_LMLastSent",(string)llGetUnixTime());
}

check_settings(string sToken, string sDefaulVal)
{
    if(!~llListFindList(llLinksetDataListKeys(0,0),[sToken])) // token/key doesn't exist in the list of keys
    {
        llLinksetDataWrite(sToken, sDefaulVal);
    }
    else if(llLinksetDataRead(sToken) == "")
    {
        llLinksetDataWrite(sToken, sDefaulVal);
    }
}

default // in this state we check if the collar is availble and we can connect.
{
    state_entry()
    {
        llLinksetDataWrite("ao_ver",g_sVersion); //may be needed for update systems.
        llLinksetDataWrite("addon_name",g_sAddon); // needed for other scripts.
        llLinksetDataWrite("auth_wearer",(string)llGetOwner()); // could be usefull.
        check_settings("ao_prefix",llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1))); // sets up prefix for stand alone mode.
        check_settings("ao_online",(string)TRUE); // we want to default to collar connection.
        llOwnerSay("Initializing Please Wait!");
        if(llGetAttached())
        {
            if((integer)llLinksetDataRead("ao_online"))
            {
                llLinksetDataWrite("ao_rezzed",(string)TRUE);
                //g_iJustRezzed = TRUE;
                llSetTimerEvent(30);
                goOnline();
            }
            else
            {
                state offline;
            }
        }
    }
    attach(key kID)
    {
        if(kID != NULL_KEY)
        {
            if(kID != llGetOwner())
            {
                llLinksetDataReset();
            }
            else
            {
                llLinksetDataWrite("auth_wearer",(string)llGetOwner());
                check_settings("ao_prefix",llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1)));
            }
        }
    }

    listen(integer iChannel, string sName, key kID, string sMsg)
    {
        if(llGetOwnerKey(kID) != llGetOwner())
        {
            // this check only works on addons owned by the collar wearer, like clothing or personal furnature.
           return;
        }
        string sPacketType = llJsonGetValue(sMsg, ["pkt_type"]);
        if (sPacketType == "approved")
        {
            // if we get responce disconnect then set ao to online mode.
            llListenRemove((integer)llLinksetDataRead("ao_listen"));
            Link("offline", 0, "", llGetOwnerKey((key)llLinksetDataRead("collar_uuid")));
            llLinksetDataDelete("collar_uuid");
            llLinksetDataDelete("collar_name");
            llSetTimerEvent(0);
            sMsg = "";
            sName = "";
            iChannel = 0;
            state online;
        }
        sMsg = "";
        sName = "";
        iChannel = 0;
    }

    timer()
    {
        llSetTimerEvent(0);
        llListenRemove((integer)llLinksetDataRead("ao_listen"));
        state offline;
    }

    linkset_data(integer iAction, string sName, string sValue)
    {
        if(iAction == LINKSETDATA_UPDATE)
        {
            if(sName == "global_rlv" && (integer)sValue)
            {
                doLock();
            }
            else if(sName == "ao_lock")
            {
                doLock();
            }
        }
        else if(iAction == LINKSETDATA_RESET)
        {
            NotifyOwner();
            llResetScript();
        }
    }
}

state online
{
    state_entry()
    {
        llLinksetDataWrite("auth_wearer",(string)llGetOwner());
        llLinksetDataWrite("addon_name",g_sAddon);
        check_settings("ao_prefix",llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1)));
        goOnline();
        llSetTimerEvent(1);
        llOwnerSay(" Connected to collar satus online");
    }
    attach(key kID)
    {
        if(kID != NULL_KEY)
        {
            llLinksetDataWrite("auth_wearer",(string)llGetOwner());
            check_settings("ao_prefix",llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1)));
        }
    }

    changed(integer change)
    {
        if(change & CHANGED_REGION)
        {
            Link("update", 0, "", (key)llLinksetDataRead("collar_uuid"));
        }
        else if(change & CHANGED_OWNER)
        {
            // we want to ensure the ao resets its data for a new user to prevent ao abuse or bugs.
            llLinksetDataReset();
        }
    }

    timer()
    {
        if (llGetUnixTime() >= ((integer)llLinksetDataRead("ao_LMLastSent") + 30))
        {
            llLinksetDataWrite("ao_LMLastSent",(string)llGetUnixTime());
            Link("ping", 0, "", (key)llLinksetDataRead("collar_uuid"));
            Link("from_addon", LM_SETTING_REQUEST, "ao_card", "");
        }
        if (llGetUnixTime() > ((integer)llLinksetDataRead("ao_LMLastRecv") + (5 * 60)) && llLinksetDataRead("collar_uuid") != NULL_KEY)
        {
            state default;
        }
        if ((key)llLinksetDataRead("collar_uuid") == NULL_KEY)
        {
            state default;
        }
    }

    link_message(integer iLink, integer iNum,string sMsg, key kID)
    {
        if (iNum <= CMD_WEARER && iNum >= CMD_OWNER)
        {
            if(sMsg == "CollarMenu")
            {
                Link("from_addon", iNum, "menu Addons", kID);
            }
        }
    }

    listen(integer iChannel, string sName, key kID, string sMsg)
    {
        if(llLinksetDataRead("collar_name") == sName && llGetOwnerKey(kID) != llGetOwner())
        {
            // this check only works on addons owned by the collar wearer, like clothing or personal furnature.
            return;
        }
        string sPacketType = llJsonGetValue(sMsg, ["pkt_type"]);
        if ((key)llLinksetDataRead("collar_uuid") == NULL_KEY)
        {
            if (sPacketType == "approved")
            {
                // This signal, indicates the collar has approved the addon and that communication requests will be responded to if the requests are valid collar LMs.
                if((integer)llLinksetDataRead("ao_rezzed"))
                {
                    llLinksetDataDelete("ao_rezzed");
                }
                llLinksetDataWrite("collar_uuid",(string)kID);
                llLinksetDataWrite("collar_name",(string)sName);
                llListenRemove((integer)llLinksetDataRead("ao_listen"));
                llLinksetDataWrite("ao_listen",(string)llListen(API_CHANNEL, sName, kID, ""));
                llLinksetDataWrite("ao_LMLastRecv",(string)llGetUnixTime());
                Link("from_addon", LM_SETTING_REQUEST, "ALL", "");
                llLinksetDataWrite("ao_LMLastSent",(string)llGetUnixTime());
                llSetTimerEvent(10);// move the timer here in order to wait for collar responce.
            }
        }
        else
        {
            if (sPacketType == "dc" && (key)llLinksetDataRead("collar_uuid") == kID )
            {
                sMsg = "";
                sName = "";
                iChannel = 0;
                state default;
            }
            else if (sPacketType == "pong" && (key)llLinksetDataRead("collar_uuid") == kID)
            {
                if(llGetUnixTime() > ((integer)llLinksetDataRead("ao_LMLastRecv")+30))
                {
                    llLinksetDataWrite("ao_LMLastRecv",(string)llGetUnixTime());
                }
            }
            else if(sPacketType == "from_collar")
            {
                if(llGetUnixTime() > ((integer)llLinksetDataRead("ao_LMLastRecv")+30))
                {
                    llLinksetDataWrite("ao_LMLastRecv",(string)llGetUnixTime());
                }
                // process link message if in range of addon
                if (llVecDist(llGetPos(), llList2Vector(llGetObjectDetails(kID, [OBJECT_POS]), 0)) <= 10.0)
                {
                    integer iNum = (integer) llJsonGetValue(sMsg, ["iNum"]);
                    string sStr  = llJsonGetValue(sMsg, ["sMsg"]);
                    key kAv      = (key) llJsonGetValue(sMsg, ["kID"]);
                    if (iNum >= CMD_OWNER && iNum <= CMD_WEARER)
                    {
                        UserCommand(iNum, sStr, kAv);
                    }
                    else if (iNum == LM_SETTING_RESPONSE)
                    {
                        list lPar     = llParseString2List(sStr, ["_","="], []);
                        string sToken = llList2String(lPar, 0);
                        string sVar   = llList2String(lPar, 1);
                        string sVal   = llList2String(lPar, 2);
                        if( sToken == "ao")
                        {
                            if( sVar == "card" && sVal != llLinksetDataRead("ao_card") && (integer)llLinksetDataRead("ao_plugins"))
                            {
                                if(llGetInventoryType(sVal) == INVENTORY_NOTECARD)
                                {
                                    llLinksetDataWrite("ao_loaded",(string)FALSE);
                                    llLinksetDataWrite("ao_card",sVal);
                                }
                                else if (kID != "" && kID != NULL_KEY)
                                {
                                    llInstantMessage(llGetOwner(),"the card loaded from collar does not seem to exist!");
                                }
                            }
                        }
                        else if(sToken == "auth") // pupluate authorization lists for offline mode.
                        {
                            if(sVar == "owner")
                            {
                                if(sVal != "" && sVal != llLinksetDataRead("auth_owner"))
                                {
                                    llLinksetDataWrite("auth_owner",sVal);
                                }
                            }
                            else if(sVar == "trust")
                            {
                                if(sVal != "" && sVal != llLinksetDataRead("auth_trust"))
                                {
                                    llLinksetDataWrite("auth_trust",sVal);
                                }
                            }
                        }
                        else if( sToken == "global")
                        {
                            if(sVar == "prefix")
                            {
                                // we can use the prefix defined by the collar.
                                llLinksetDataWrite("ao_prefix",sVal);
                            }
                        }
                        lPar = [];
                        sToken = "";
                        sVar = "";
                        sVal = "";
                    }
                    sStr = "";
                }
            }
        }
        sPacketType = "";
        sMsg = "";
        sName = "";
        iChannel = 0;
    }

    linkset_data(integer iAction,string sName,string sValue)
    {
        if(iAction == LINKSETDATA_UPDATE)
        {
            if(sName == "ao_online")
            {
                llListenRemove((integer)llLinksetDataRead("ao_listen"));
                state default;
            }
            else if(sName == "ao_card")
            {
                Link("from_addon", LM_SETTING_SAVE, "ao_card="+sValue, "");
            }
            else if(sName == "global_rlv" && (integer)sValue)
            {
                doLock();
            }
            else if(sName == "ao_lock")
            {
                doLock();
            }
        }
        else if(iAction == LINKSETDATA_RESET)
        {
            NotifyOwner();
            llListenRemove((integer)llLinksetDataRead("ao_listen"));
            llResetScript();
        }
    }
}

state offline
{
    state_entry()
    {
        llLinksetDataWrite("auth_wearer",(string)llGetOwner());
        llLinksetDataWrite("addon_name",g_sAddon);
        check_settings("ao_prefix",llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1)));
        llLinksetDataWrite("ao_online",(string)FALSE);
        llSetTimerEvent(0);
        llOwnerSay("ao in offline mode, you can still use /1"+llLinksetDataRead("ao_prefix")+"ao commands");
        llLinksetDataWrite("ao_listen",(string)llListen(1,"",NULL_KEY,""));
    }
    attach(key kID)
    {
        if(kID != NULL_KEY)
        {
            if(kID != llGetOwner())
            {
                llLinksetDataReset();
            }
            else
            {
                llLinksetDataWrite("auth_wearer",(string)llGetOwner());
                check_settings("ao_prefix",llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1)));
            }
        }
    }
    listen (integer iChan, string sName, key kID,string sMsg)
    {
        if(~llSubStringIndex(llToLower(sMsg),llLinksetDataRead("ao_prefix")))
        {
            // determine authorization of the user and allow access.
            sMsg = llDeleteSubString(sMsg,0,1);
            if(kID == llGetOwner())
            {
                UserCommand(CMD_WEARER, sMsg, kID);
            }
            else if(llListFindList(llParseString2List(llLinksetDataRead("auth_owners"),[","],[]),[(string)kID]) != -1)
            {
                UserCommand(CMD_OWNER, sMsg, kID);
            }
            else if(llListFindList(llParseString2List(llLinksetDataRead("auth_trust"),[","],[]),[(string)kID]) != -1)
            {
                UserCommand(CMD_TRUSTED, sMsg, kID);
            }
            else
            {
                llInstantMessage(kID,"Sorry you are not authorized to use this");
            }
        }
    }

    linkset_data(integer iAction,string sName,string sValue)
    {
        if(iAction == LINKSETDATA_UPDATE)
        {
            if(sName == "ao_online")
            {
                // the listen will be used for online mode if available
                llListenRemove((integer)llLinksetDataRead("ao_listen"));
                state default;
            }
            else if(sName == "global_rlv" && (integer)sValue)
            {
                doLock();
            }
            else if(sName == "ao_lock")
            {
                doLock();
            }
        }
        else if(iAction == LINKSETDATA_RESET)
        {
            // we want to remove the listen to help clear the way for a restart.
            NotifyOwner();
            llListenRemove((integer)llLinksetDataRead("ao_listen"));
            llResetScript();
        }
    }
}
