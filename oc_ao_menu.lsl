integer CMD_WEARER      = 503;

integer DIALOG          = -9000;
integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT  = -9002;
integer MENU_REQUEST    = -9003;

//integer g_iMenuStride;
integer g_iPage = 0;
integer g_iNumberOfPages;

string UPMENU = "BACK";
//string b_sLock;
//string b_sAccess;
string b_sPower;
string b_sTyping;
string b_sSitAny;
// these buttons will be used for making loops.
string b_sSitAO;
string b_sShuffle;
string b_sLock;
string b_sAccess;
string b_sPlugins;
list g_lCheckBoxes = ["▢","▣"];
list g_lCustomCards = [];
list g_lAnims2Choose = [];

list g_lAnimStates = [ //http://wiki.secondlife.com/wiki/LlSetAnimationOverride
    "Crouching","CrouchWalking","Falling Down","Flying","FlyingSlow",
    "Hovering","Hovering Down","Hovering Up","Jumping","Landing",
    "PreJumping","Running","Standing","Sitting","Sitting on Ground","Standing Up",
    "Striding","Soft Landing","Taking Off","Turning Left","Turning Right","Walking"
];

list g_lSwimStates = ["Swim Forward","Swim Hover","Swim Slow","Swim Up","Swim Down"];
//

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName)
{
    llMessageLinked( LINK_SET, DIALOG, sPrompt+","+llDumpList2String(lChoices,"`")+","+llDumpList2String(lUtilityButtons,"`")+","+(string)iAuth+","+sName, kID);
    iPage = 0;
}

Menu(key kID, integer iAuth)
{
    string sPrompt = "|====="+llLinksetDataRead("ao_addon")+" Main=====|"+
        "\n Version: "+llLinksetDataRead("ao_ver");
    // load toggle buttons.
    b_sPower    = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead("ao_power"))+"Power";
    b_sTyping   = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead("ao_typingctl"))+"Typing AO";
    b_sSitAny   = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead("ao_sitanywhere"))+"Sit Anywhere";
    b_sSitAO    = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead("ao_sitctl"))+"Sit AO";
    // set status information.
    sPrompt +=  "\nNotecard:"+llLinksetDataRead("ao_card")+
                "\n"+llList2String(g_lCheckBoxes,(integer)llLinksetDataRead("ao_loaded"))+"Loaded"+
                "\n"+llList2String(g_lCheckBoxes,(integer)llLinksetDataRead("ao_online"))+"Collar Addon"+
                "\n"+b_sPower+
                "\n"+b_sTyping+
                "\n"+b_sSitAny
    ;
    // Populate Buttons list.
    list lButtons = [];
    if(iAuth == CMD_WEARER && (integer)llLinksetDataRead("ao_noaccess"))
    {
        lButtons = ["-"];
    }
    else
    {
        lButtons  = [b_sPower,"Load",b_sTyping,b_sSitAny,b_sSitAO,"Anims"];
    }
    // Start dialog.
    Dialog(kID, sPrompt, lButtons, ["Admin"], 0, iAuth, "Menu~Main");
}

MenuLoad(key kID, integer iPage, integer iAuth)
{
    if (!iPage)
    {
        g_iPage = 0;
    }
    string sPrompt = "\nLoad an animation set!";
    list lButtons;
    g_lCustomCards = [];
    integer iEnd = llGetInventoryNumber(INVENTORY_NOTECARD);
    integer iCountCustomCards;
    string sNotecardName;
    integer i;
    while (i < iEnd)
    {
        sNotecardName = llGetInventoryName(INVENTORY_NOTECARD, i++);
        if (llSubStringIndex(sNotecardName,".") && sNotecardName != "")
        {
            if (!llSubStringIndex(sNotecardName,"SET"))
            {
                g_lCustomCards += [sNotecardName,"Wildcard "+(string)(++iCountCustomCards)];// + g_lCustomCards;
            }
            else if(llStringLength(sNotecardName) < 24)
            {
                lButtons += sNotecardName;
            }
            else
            {
                llOwnerSay(sNotecardName+"'s name is too long to be displayed in menus and cannot be used.");
            }
        }
    }
    i = 1;
    while (i <= 2*iCountCustomCards)
    {
        lButtons += llList2List(g_lCustomCards,i,i);
        i += 2;
    }
    list lStaticButtons = [UPMENU];
    if (llGetListLength(lButtons) > 11)
    {
        lStaticButtons = ["◄","►",UPMENU];
        g_iNumberOfPages = llGetListLength(lButtons)/9;
        lButtons = llList2List(lButtons,iPage*9,iPage*9+8);
    }
    if (!llGetListLength(lButtons)){
        llOwnerSay("There aren't any animation sets installed!");
    }
    Dialog(kID, sPrompt, lButtons, lStaticButtons, iPage, iAuth,"Menu~Load");
}

MenuMultiAnims(key kID, integer iPage, integer iAuth)
{
    if (!iPage)
    {
        g_iPage = 0;
    }
    string sPrompt = "|=====Multi Anims=====|"+
                "\n ► Next Animation on the list ."+
                "\n ◄ Last Animation on the list.";
    list lButtons  = [];
    integer i;
    integer iEnd = llGetListLength(g_lAnimStates);
    for (i; i<iEnd; i++)
    {
        string sState = llList2String(g_lAnimStates,i);
        if(llLinksetDataRead("ao_"+sState) != "")
        {
            lButtons += [sState];
        }
    }
    i = 0;
    iEnd = llGetListLength(g_lSwimStates)-1;
    for (i; i<iEnd; i++)
    {
        string sState = llList2String(g_lSwimStates,i);
        if(llLinksetDataRead("ao_"+sState) != "")
        {
            lButtons += [sState];
        }
    }
    list lStaticButtons = [UPMENU];
    if (llGetListLength(lButtons) > 11)
    {
        lStaticButtons = ["◄","►",UPMENU];
        g_iNumberOfPages = llGetListLength(lButtons)/9;
        lButtons = llList2List(lButtons,iPage*9,iPage*9+8);
    }
    // Start dialog.
    Dialog(kID, sPrompt, lButtons, lStaticButtons, iPage, iAuth, "Menu~MultiAnims");
}

MenuAnimation(key kID, string sAnimState, integer iAuth)
{
    string sPrompt = "|====="+sAnimState+"=====|";
    // load toggle buttons.
    b_sShuffle = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead("ao_"+sAnimState+"rand"))+"Shuffle";
    // set status information.
    sPrompt +=  "\n Current "+sAnimState+" Timer:"+llLinksetDataRead("ao_"+sAnimState+"change")+
                "\n"+b_sShuffle;
    // Populate Buttons list.
    list lButtons  = [];
    if((integer)llLinksetDataRead("ao_"+sAnimState+"change") > 0)
    {
        lButtons = ["Timer",b_sShuffle];
    }
    else
    {
        lButtons = ["Select Anim","Timer"];
    }
    // Start dialog.
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Animation~"+sAnimState);
}

MenuTime(key kID, string sAnimState, integer iAuth)
{
    string sPrompt = "|====="+sAnimState+" Time=====|";
    // load toggle buttons.
    // set status information.
    sPrompt +=  "\n Current "+sAnimState+" Timer:"+llLinksetDataRead("ao_"+sAnimState+"change")+
                "\n 0 = Disabled";
    // Populate Buttons list.
    list lButtons = ["20","30","45","60","90","120","180"];
    // Start dialog.
    Dialog(kID, sPrompt, lButtons, ["Custom","Disable",UPMENU], 0, iAuth, "Time~"+sAnimState);
}

MenuChooseAnim(key kID, string sAnimState, integer iPage, integer iAuth)
{
    if (!iPage)
    {
        g_iPage = 0;
    }
    string sAnim = llLinksetDataRead(sAnimState);
    string sPrompt = "\n"+sAnimState+": \""+sAnim+"\"\n";
    g_lAnims2Choose = llListSort(llParseString2List(llLinksetDataRead("ao_"+sAnimState),[","],[]),1,TRUE);
    list lButtons;
    integer iEnd = llGetListLength(g_lAnims2Choose);
    integer i;
    while (++i<=iEnd)
    {
        lButtons += (string)i;
        sPrompt += "\n"+(string)i+": "+llList2String(g_lAnims2Choose,i-1);
    }
    list lStaticButtons = [UPMENU];
    if (llGetListLength(lButtons) > 11)
    {
        lStaticButtons = ["◄","►",UPMENU];
        g_iNumberOfPages = llGetListLength(lButtons)/9;
        lButtons = llList2List(lButtons,iPage*9,iPage*9+8);
    }
    Dialog(kID, sPrompt, lButtons, lStaticButtons,iPage,iAuth,"Select~"+sAnimState);
}

MenuAdmin(key kID, integer iAuth)
{
    b_sLock     = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead("ao_lock"))+"Lock";
    b_sAccess   = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead("ao_noaccess"))+"No Access";
    b_sPlugins  = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead("ao_plugins"))+"Pluggins";
    string sPrompt = "|=====Adnimistration=====|"+
        "\n "+b_sLock+" - enables no detach when rlv is present."+
        "\n "+b_sAccess+" - Prevents the sub from accessing the menu except to reset the ao or connect it if the owner has no access."+
        "\n "+b_sPlugins+" - allows the ao to accept note cards to load from plugins and addons via the collar setting."
    ;
    list lButtons = [];
    list lUtilityButtons = [];// this is only here so we can set ultities to respect online and offline mode.
    if(iAuth == CMD_WEARER && (integer)llLinksetDataRead("ao_noaccess"))
    {
        lButtons = ["Reset AO"];
        if(!(integer)llLinksetDataRead("ao_online"))
        {
            lUtilityButtons = ["CONNECT",UPMENU];
        }
        else
        {
            lUtilityButtons = ["Collar",UPMENU];
        }
    }
    else
    {
        lButtons = [b_sLock,b_sAccess,b_sPlugins,"HUD Options","Reset AO"];
        if( (integer)llLinksetDataRead("ao_online")) // we only need certain buttons when they are nesissary.
        {
            lUtilityButtons = ["Collar","DISCONNECT",UPMENU];
        }
        else
        {
            lUtilityButtons = ["CONNECT",UPMENU];
        }
    }

    Dialog(kID, sPrompt, lButtons, lUtilityButtons, 0, iAuth, "Menu~Admin");
}

Menu_Confirm(key kID, integer iAuth, string sMenu, string sQuery)
{
    string sPrompt = "\n ao Confirmation Menu\n\n"+sQuery;
    string sQMenu = "Menu~Q"+sMenu;
    list lButtons = ["Yes"];
    Dialog(kID, sPrompt, lButtons, ["No"], 0, iAuth, sQMenu);
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

default
{
    link_message(integer iLink, integer iNum, string sMsg, key kID)
    {
        if(iNum == DIALOG_RESPONSE)
        {
            list lPar = llParseString2List(sMsg,[","],[]);
            integer iAuth = llList2Integer(lPar,0);
            string sMenu = llList2String(lPar,1);
            sMsg = llList2String(lPar,2);
            integer iRespring = TRUE;
            if (sMenu == "Menu~Main")
            {
                if (sMsg == "Admin")
                {
                    MenuAdmin(kID, iAuth);
                    iRespring = FALSE;
                }
                else if (sMsg == "Anims" && (integer)llLinksetDataRead("ao_loaded"))
                {
                    iRespring = FALSE;
                    MenuMultiAnims(kID, 0, iAuth);
                }
                else if (sMsg == "Load")
                {
                    MenuLoad(kID, 0, iAuth);
                    iRespring = FALSE;
                }
                else if (sMsg == b_sPower)
                {
                    llLinksetDataWrite("ao_power",(string)(!(integer)llLinksetDataRead("ao_power")));
                }
                else if(sMsg == b_sSitAO)
                {
                    llLinksetDataWrite("ao_sitctl",(string)(!(integer)llLinksetDataRead("ao_sitctl")));
                }
                else if( sMsg == b_sSitAny)
                {
                    llLinksetDataWrite("ao_sitanywhere",(string)(!(integer)llLinksetDataRead("ao_sitanywhere")));
                }
                else if( sMsg == b_sTyping)
                {
                    llLinksetDataWrite("ao_typingctl",(string)(!(integer)llLinksetDataRead("ao_typingctl")));
                }
                if(iRespring)
                {
                    Menu(kID,iAuth);
                }
            }
            else if( sMenu == "Menu~Load")
            {
                integer index = llListFindList(g_lCustomCards,[sMsg]);
                if (~index)
                {
                    sMsg = llList2String(g_lCustomCards,index-1);
                }
                if (llGetInventoryType(sMsg) == INVENTORY_NOTECARD)
                {
                    if(llLinksetDataRead("ao_card") != sMsg) // there is no point in expending the time to read whats already in memory.
                    {
                        if(llGetInventoryType(sMsg) == INVENTORY_NOTECARD)
                        {
                            llLinksetDataWrite("ao_loaded",(string)FALSE);
                            llLinksetDataWrite("ao_card",sMsg);
                        }
                        else if (kID != "" && kID != NULL_KEY)
                        {
                            Notify("that card does not seem to exist!",kID);
                            MenuLoad(kID,g_iPage,iAuth);
                        }
                    }
                    else if (kID != "" && kID != NULL_KEY)
                    {
                        Notify("Card is already loaded try a different one or clear memory",kID);
                        MenuLoad(kID,g_iPage,iAuth);
                    }
                    return;
                }
                else if ((integer)llLinksetDataRead("ao_loaded")&& sMsg == "BACK")
                {
                    Menu(kID,iAuth);
                    g_lCustomCards = [];
                    return;
                }
                else if (sMsg == "►")
                {
                    if (++g_iPage > g_iNumberOfPages)
                    {
                        g_iPage = 0;
                    }
                }
                else if (sMsg == "◄")
                {
                    if (--g_iPage < 0)
                    {
                        g_iPage = g_iNumberOfPages;
                    }
                }
                else if (!(integer)llLinksetDataRead("ao_loaded"))
                {
                     Notify("Please load an animation set first.",kID);
                }
                else
                {
                    Notify("Could not find animation set: "+sMsg,kID);
                }
                MenuLoad(kID,g_iPage,iAuth);
            }
            else if(sMenu == "Menu~MultiAnims")
            {
                if (sMsg == UPMENU)
                {
                    iRespring = FALSE;
                    Menu(kID,iAuth);
                }
                else if(llListFindList(g_lAnimStates,[sMsg]) != -1)
                {
                    iRespring = FALSE;
                    MenuAnimation(kID, sMsg, iAuth);
                }
                else if (sMsg == "►")
                {
                    if (++g_iPage > g_iNumberOfPages)
                    {
                        g_iPage = 0;
                    }
                }
                else if (sMsg == "◄")
                {
                    if (--g_iPage < 0)
                    {
                        g_iPage = g_iNumberOfPages;
                    }
                }
                if(iRespring)
                {
                    MenuMultiAnims(kID, 0, iAuth);
                }
            }
            else if(~llSubStringIndex(sMenu,"Animation"))
            {
                string sAnimState = llList2String(llParseString2List(sMenu,["~"],[]),1);
                if (sMsg == UPMENU)
                {
                    iRespring = FALSE;
                    MenuMultiAnims(kID, 0, iAuth);
                }
                else if (sMsg == "Select Anim")
                {
                    iRespring = FALSE;
                    MenuChooseAnim(kID, sAnimState, 0, iAuth);
                }
                else if (sMsg == "Timer")
                {
                    iRespring = FALSE;
                    MenuTime(kID, sAnimState, iAuth);
                }
                else if (sMsg == b_sShuffle)
                {
                    llLinksetDataWrite("ao_"+sAnimState+"rand",(string)(!(integer)llLinksetDataRead("ao_"+sAnimState+"rand")));
                }
                if(iRespring)
                {
                    MenuAnimation(kID, sAnimState, iAuth);
                }
            }
            else if( ~llSubStringIndex(sMenu,"Time"))
            {
                string sAnimState = llList2String(llParseString2List(sMenu,["~"],[]),1);
                if (sMsg == UPMENU)
                {
                    MenuAnimation(kID, sAnimState, iAuth);
                    iRespring = FALSE;
                }
                else if(sMsg == "Disable")
                {
                    if((integer)llLinksetDataRead("ao_"+sAnimState+"change"))
                    {
                        llLinksetDataWrite("ao_"+sAnimState+"change",(string)0);
                    }
                    else
                    {
                        llLinksetDataWrite("ao_"+sAnimState+"change",(string)120);
                    }
                }
                else if(sMsg == "Custom")
                {
                    iRespring = FALSE;
                    string sPrompt = "|=====Set Time=====|\nSet a custom timer any thing greater than 0";
                    Dialog(kID, sPrompt, ["!!llTextBox!!"], [UPMENU], 0, iAuth, sMenu);
                }
                else
                {
                    if((integer)sMsg)
                    {
                        llLinksetDataWrite("ao_"+sAnimState+"change",sMsg);
                    }
                    else if((integer)llLinksetDataRead("ao_"+sAnimState+"change"))
                    {
                        llLinksetDataWrite("ao_"+sAnimState+"change",(string)0);
                    }
                    else
                    {
                        llLinksetDataWrite("ao_"+sAnimState+"change",(string)120);
                    }
                }
                if(iRespring)
                {
                    MenuTime(kID, sAnimState, iAuth);
                }
            }
            else if(~llSubStringIndex(sMenu,"Select"))
            {
                llOwnerSay("[Selecting animation]"+llList2String(g_lAnims2Choose,((integer)sMsg-1)));
                string sAnimState = llList2String(llParseString2List(sMenu,["~"],[]),1);
                if (sMsg == UPMENU)
                {
                    MenuAnimation(kID, sAnimState, iAuth);
                    iRespring = FALSE;
                }
                else if (sMsg == "►")
                {
                    if (++g_iPage > g_iNumberOfPages)
                    {
                        g_iPage = 0;
                    }
                }
                else if (sMsg == "◄")
                {
                    if (--g_iPage < 0)
                    {
                        g_iPage = g_iNumberOfPages;
                    }
                }
                else if(llListFindList(llParseString2List(llLinksetDataRead("ao_"+sAnimState),[","],[]),[llList2String(g_lAnims2Choose,(integer)sMsg)]) != -1)
                {
                    string sAnim = llList2String(g_lAnims2Choose,((integer)sMsg-1));
                    if(llGetInventoryType(sAnim) == INVENTORY_ANIMATION)
                    {
                        Notify("Setting animation "+sAnim+" to State "+sAnimState,kID);
                        llLinksetDataWrite(sAnimState,sAnim);
                    }
                    else
                    {
                        Notify("Animation does not exist in inventory!",kID);
                    }
                    g_lAnims2Choose = [];
                }
                if(iRespring)
                {
                    MenuChooseAnim(kID, sAnimState, g_iPage, iAuth);
                }
            }
            else if( sMenu == "Menu~Admin")
            {
                if (sMsg == UPMENU)
                {
                    iRespring = FALSE;
                    Menu(kID, iAuth);
                }
                else if (sMsg == b_sLock)
                {
                    llLinksetDataWrite("ao_lock",(string)(!(integer)llLinksetDataRead("ao_lock")));
                }
                else if (sMsg == b_sAccess)
                {
                    llLinksetDataWrite("ao_noaccess",(string)(!(integer)llLinksetDataRead("ao_noaccess")));
                }
                else if (sMsg == b_sPlugins)
                {
                    llLinksetDataWrite("ao_plugins",(string)(!(integer)llLinksetDataRead("ao_plugins")));
                }
                else if (sMsg == "Reset AO") // so we can clear memory in the event of bugs.
                {
                    iRespring = FALSE;
                    Menu_Confirm(kID,iAuth,"mem","Would you like to clear LinksetData?");
                }
                else if( sMsg == "HUD Options")
                {
                    iRespring = FALSE;
                    llMessageLinked(LINK_SET, MENU_REQUEST, (string)iAuth+"|MenuOptions",kID);
                }
                else if (sMsg == "Collar")
                {
                    iRespring = FALSE;
                    llMessageLinked(LINK_SET,iAuth,"CollarMenu",kID);
                }
                else if (sMsg == "DISCONNECT")
                {
                    iRespring = FALSE;
                    llLinksetDataWrite("ao_online",(string)FALSE);
                }
                else if (sMsg == "CONNECT")
                {
                    iRespring = FALSE;
                    // if the collar disconects but is available we want the user to be able to connect it if they don't wish to safe word.
                    llLinksetDataWrite("ao_online",(string)TRUE);
                }
                if(iRespring)
                {
                    MenuAdmin(kID,iAuth);
                }
            }
            else if(~llSubStringIndex(sMenu,"Menu~Q"))
            {
                if( sMsg == "Yes")
                {
                    if(~llSubStringIndex(sMenu,"mem"))
                    {
                        llOwnerSay("AO memory is being wiped and scripts being reset");
                        llLinksetDataReset();
                    }
                }
                else if( sMsg == "No")
                {
                    if(~llSubStringIndex(sMenu,"mem"))
                    {
                        MenuAdmin(kID, iAuth);
                    }
                }
            }
        }
        else if(iNum == MENU_REQUEST)
        {
            list lPar = llParseString2List(sMsg,["|"],[]);
            integer iAuth = llList2Integer(lPar,0);
            string sMenu = llList2String(lPar,1);
            if(sMenu == "MenuMain")
            {
                Menu( kID, iAuth);
            }
            if(sMenu == "MenuAdmin")
            {
                MenuAdmin( kID, iAuth);
            }
        }
    }
}
