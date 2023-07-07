/*
    This file is a part of OpenCollar.
    Copyright ©2021
    : Contributors :
    Phidoux (taya.Maruti)
        * June 3 2023   -   Created oc_ao_dialog
            this Script is based from oc_ao 2.0 Beta and oc_addon_template to create a stand alone menu system for addons.
*/

// stand alone dialog system based on oc_ao 2.0 beta and oc_addon_template.

integer DIALOG          = -9000;
integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT  = -9002;

list g_lMenuIDs;

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iAuth, string sName)
{
    integer iChannel = llRound(llFrand(10000000)) + 100000;
    while (~llListFindList(g_lMenuIDs, [iChannel]))
    {
        iChannel = llRound(llFrand(10000000)) + 100000;
    }
    integer iListener = llListen(iChannel, "",kID, "");
    integer iTime = llGetUnixTime() + 180;
    if(llGetListLength(g_lMenuIDs))
    {
        integer iIndex = llListFindList(g_lMenuIDs, [kID]);
        if (~iIndex)
        {
            g_lMenuIDs = llListReplaceList(g_lMenuIDs,[kID, iChannel, iListener, iTime, sName, iAuth],iIndex,iIndex+5);
        }
        else
        {
            g_lMenuIDs += [kID, iChannel, iListener, iTime, sName, iAuth];
        }
    }
    else
    {
            g_lMenuIDs += [kID, iChannel, iListener, iTime, sName, iAuth];
    }
    llSetTimerEvent(180);
    llDialog(kID,sPrompt,SortButtons(lChoices,lUtilityButtons),iChannel);
}

list SortButtons(list lButtons, list lStaticButtons)
{
    list lSpacers;
    list lAllButtons = lButtons + lStaticButtons;
    //cutting off too many buttons, no multi page menus as of now
    while (llGetListLength(lAllButtons)>12)
    {
        lButtons = llDeleteSubList(lButtons,0,0);
        lAllButtons = lButtons + lStaticButtons;
    }
    while (llGetListLength(lAllButtons) % 3 != 0 && llGetListLength(lAllButtons) < 12)
    {
        lSpacers += "-";
        lAllButtons = lButtons + lSpacers + lStaticButtons;
    }
    integer i = llListFindList(lAllButtons, ["BACK"]);
    if (~i)
    {
        lAllButtons = llDeleteSubList(lAllButtons, i, i);
    }
    list lOut = llList2List(lAllButtons, 9, 11);
    lOut += llList2List(lAllButtons, 6, 8);
    lOut += llList2List(lAllButtons, 3, 5);
    lOut += llList2List(lAllButtons, 0, 2);
    if (~i)
    {
        lOut = llListInsertList(lOut, ["BACK"], 2);
    }
    lAllButtons = [];
    lButtons = [];
    lSpacers = [];
    lStaticButtons = [];
    return lOut;
}

default
{
    timer()
    {
        integer n = llGetListLength(g_lMenuIDs) - 5;
        integer iNow = llGetUnixTime();
        for ( n; n>=0; n=n-5 )
        {
            integer iDieTime = llList2Integer(g_lMenuIDs,n+3);
            if ( iNow > iDieTime )
            {
                llInstantMessage(llList2Key(g_lMenuIDs,n-1),"Menu Timed out!");
                llListenRemove(llList2Integer(g_lMenuIDs,n+2));
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs,n,n+5);
            }
        }
        if(!llGetListLength(g_lMenuIDs))
        {
            llSetTimerEvent(0.0);
        }
    }

    listen(integer iChannel, string sName, key kID, string sMsg)
    {
        if (llListFindList(g_lMenuIDs,[kID,iChannel]) != -1)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            integer iAuth = llList2Integer(g_lMenuIDs,iMenuIndex+5);
            string sMenu = llList2String(g_lMenuIDs, iMenuIndex+4);
            llListenRemove(llList2Integer(g_lMenuIDs,iMenuIndex+2));
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs,iMenuIndex, iMenuIndex+5);

            // Return the output.
            llMessageLinked( LINK_SET, DIALOG_RESPONSE, (string)iAuth+","+sMenu+","+sMsg, kID);
        }
    }

    link_message(integer iLink, integer iNum,string sMsg, key kID)
    {
        if( iNum == DIALOG )
        {
            // Process and display menu.
            list lPar = llParseString2List(sMsg,[","],[]);
            string sPrompt = llList2String(lPar,0);
            list lButtons = llParseString2List(llList2String(lPar,1),["`"],[]);
            list lUtilityButtons = llParseString2List(llList2String(lPar,2),["`"],[]);
            integer iAuth = llList2Integer(lPar,3);
            string sName = llList2String(lPar,4);
            Dialog( kID, sPrompt, lButtons, lUtilityButtons, iAuth, sName);
        }
    }
}
