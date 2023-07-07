/*
    A minimal re write of the AO System to use Linkset Data
    this script is intended to be a stand alone ao managed from linkset storage
    which would allow it to be populated by any interface script.
    Created: Mar 21 2023
    By: Phidoux (taya.Maruti)
    ------------------------------------
    | Contributers  and updates below  |
    ------------------------------------
    | Name | Date | comment            |
    ------------------------------------
*/

// this texture is a spritemap with all buttons on it, for faster texture
// loading than having separate textures for each button.
string BTN_TEXTURE = "fb9a678d-c692-400e-e08c-9e0e85503925";

// There are 3 columns of buttons and 8 rows of buttons in the sprite map.
integer BTN_XS = 3;
integer BTN_YS = 2;

// starting at the top left and moving to the right, the button sprites are in
// this order.
list BTNS = [
    "Minimize",
    "Maximize",
    "Power",
    "Menu",
    "SitAny"
];

float g_fGap = 0.001; // This is the space between buttons
float g_Yoff = 0.002; // space between buttons and screen top/bottom border
float g_Zoff = 0.04; // space between buttons and screen left/right border

list g_lButtons; // buttons names for Order menu
list g_lPrimOrder = [0,1,2,3,4]; // -- List must always start with '0','1'
// -- 0:Spacer, 1:Root, 2:Power, 3:Sit Anywhere, 4:Menu
// -- Spacer serves to even up the list with actual link numbers

integer g_iLayout = 1;
integer g_iHidden = FALSE;
integer g_iPosition = 69;
integer g_iOldPos;
vector g_vAOoffcolor = <0.5,0.5,0.5>;
vector g_vAOoncolor = <1,1,1>;

integer DIALOG          = -9000;
integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT  = -9002;
integer MENU_REQUEST    = -9003;

//integer g_iMenuStride;
integer g_iPage = 0;
integer g_iNumberOfPages;

string UPMENU = "BACK";
list g_lCheckBoxes = ["▢","▣"];

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName)
{
    llMessageLinked( LINK_SET, DIALOG, sPrompt+","+llDumpList2String(lChoices,"`")+","+llDumpList2String(lUtilityButtons,"`")+","+(string)iAuth+","+sName, kID);
    iPage = 0;
}

MenuOptions(key kID,integer iAuth)
{
    string sPrompt = "|=====HUD Options=====|";
    list lButtons = ["Horizontal", "Vertical", "Order"];

    Dialog(kID,sPrompt,lButtons,[UPMENU], 0, iAuth, "Menu~Options");
}

MenuOrder(key kID,integer iAuth)
{
    string sPrompt = "|=====HUD Order=====|\n Select which button to move.";
    integer i;
    list lButtons;
    integer iPos;
    for (i=2;i<llGetListLength(g_lPrimOrder);++i)
    {
        iPos = llList2Integer(g_lPrimOrder,i);
        lButtons += llList2List(g_lButtons,iPos,iPos);
    }
    Dialog(kID, sPrompt, g_lButtons, ["Reset",UPMENU], 0, iAuth, "Menu~Ordermenu");
}

FindButtons()// collect buttons names & links
{
    g_lButtons = [" ", "Minimize"] ;
    g_lPrimOrder = [0, 1];  //  '1' - root prim
    integer i;
    for (i=2; i<=llGetNumberOfPrims(); ++i)
    {
        g_lButtons += llGetLinkPrimitiveParams(i, [PRIM_DESC]);
        g_lPrimOrder += i;
    }
}

SetButtonTexture(integer link, string name)
{
    integer idx = llListFindList(BTNS, [name]);
    if (idx == -1)
    {
        return;
    }
    integer x = idx % BTN_XS;
    integer y = idx / BTN_XS;
    vector scale = <1.0 / BTN_XS, 1.0 / BTN_YS, 0>;
    vector offset = <
        scale.x * (x - (BTN_XS / 2.0 - 0.5)),
        scale.y * -1 * (y - (BTN_YS / 2.0 - 0.5)),
    0>;
    llSetLinkPrimitiveParamsFast(link, [
        PRIM_TEXTURE,
            ALL_SIDES,
            BTN_TEXTURE,
            scale,
            offset,
            0
    ]);
}

TextureButtons()
{
    integer i = llGetNumberOfPrims();

    while (i)
    {
        string name = llGetLinkName(i);
        if (i == 1)
        {
            if (g_iHidden)
            {
                name = "Maximize";
            }
            else
            {
                name = "Minimize";
            }
        }

        SetButtonTexture(i, name);
        i--;
    }
}

PositionButtons()
{
    integer iPosition = llGetAttached();
    vector vSize = llGetScale();
    //  Allows manual repositioning, without resetting it, if needed
    if (iPosition != g_iPosition && iPosition > 30)//do this only when attached to the hud
    {
        vector vOffset = <0.01, vSize.y/2+g_Yoff, vSize.z/2+g_Zoff>;
        if (iPosition == ATTACH_HUD_TOP_RIGHT || iPosition == ATTACH_HUD_TOP_CENTER || iPosition == ATTACH_HUD_TOP_LEFT)
        {
            vOffset.z = -vOffset.z;
        }
        if (iPosition == ATTACH_HUD_TOP_LEFT || iPosition == ATTACH_HUD_BOTTOM_LEFT)
        {
            vOffset.y = -vOffset.y;
        }
        llSetPos(vOffset); // Position the Root Prim on screen
        g_iPosition = iPosition;
    }
    if (g_iHidden)
    {
        SetButtonTexture(1, "Maximize");
        llSetLinkPrimitiveParamsFast(LINK_ALL_OTHERS, [PRIM_POSITION,<1,0,0>]);
    }
    else
    {
        SetButtonTexture(1, "Minimize");
        float fYoff = vSize.y + g_fGap;
        float fZoff = vSize.z + g_fGap;
        if (iPosition == ATTACH_HUD_TOP_LEFT || iPosition == ATTACH_HUD_TOP_CENTER || iPosition == ATTACH_HUD_TOP_RIGHT)
        {
            fZoff = -fZoff;
        }
        if (iPosition == ATTACH_HUD_TOP_CENTER || iPosition == ATTACH_HUD_TOP_LEFT || iPosition == ATTACH_HUD_BOTTOM || iPosition == ATTACH_HUD_BOTTOM_LEFT)
        {
            fYoff = -fYoff;
        }
        if (iPosition == ATTACH_HUD_TOP_CENTER || iPosition == ATTACH_HUD_BOTTOM)
        {
            g_iHidden = FALSE;
        }
        if (g_iLayout)
        {
            fYoff = 0;
        }
        else
        {
            fZoff = 0;
        }
        integer i;
        integer LinkCount=llGetListLength(g_lPrimOrder);
        for (i=2;i<=LinkCount;++i)
        {
            llSetLinkPrimitiveParamsFast(llList2Integer(g_lPrimOrder,i),[PRIM_POSITION,<0.01, fYoff*(i-1), fZoff*(i-1)>]);
        }
    }
}

DoButtonOrder(integer iNewPos)// -- Set the button order and reset display
{
    integer iOldPos = llList2Integer(g_lPrimOrder, g_iOldPos);
    iNewPos = llList2Integer(g_lPrimOrder,iNewPos);
    integer i = 2;
    list lTemp = [0,1];
    for(;i<llGetListLength(g_lPrimOrder);++i)
    {
        integer iTempPos = llList2Integer(g_lPrimOrder,i);
        if (iTempPos == iOldPos)
        {
            lTemp += [iNewPos];
        }
        else if (iTempPos == iNewPos)
        {
            lTemp += [iOldPos];
        }
        else
        {
            lTemp += [iTempPos];
        }
    }
    g_lPrimOrder = lTemp;
    g_iOldPos = -1;
    PositionButtons();
}

DetermineColors()
{
    g_vAOoncolor = llGetColor(0);
    g_vAOoffcolor = g_vAOoncolor/2;
    ShowStatus();
}

ShowStatus()
{
    vector vColor = g_vAOoffcolor;
    if ((integer)llLinksetDataRead("ao_power"))
    {
        vColor = g_vAOoncolor;
    }
    llSetLinkColor(llListFindList(g_lButtons,["Power"]), vColor, ALL_SIDES);
    if ((integer)llLinksetDataRead("ao_sitanywhere"))
    {
        vColor = g_vAOoncolor;
    }
    else
    {
        vColor = g_vAOoffcolor;
    }
    llSetLinkColor(llListFindList(g_lButtons,["SitAny"]), vColor, ALL_SIDES);
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
    state_entry()
    {
        FindButtons();
        PositionButtons();
        TextureButtons();
        DetermineColors();
    }

    attach(key kID)
    {
        if (kID == NULL_KEY)
        {
            llResetScript();
        }
        else if(llGetAttached() <= 30)
        {
            llOwnerSay("Sorry, this device can only be attached to the HUD.");
            llRequestPermissions(kID, PERMISSION_ATTACH);
            llDetachFromAvatar();
        }
        else
        {
            PositionButtons();
        }
    }

    linkset_data(integer iAction, string sName, string sValue)
    {

        if(iAction == LINKSETDATA_UPDATE)
        {
            // update the visual status
            ShowStatus();
        }
        else if(iAction == LINKSETDATA_RESET)
        {
            llResetScript();
        }
    }

    touch_start(integer total_number)
    {
        string sButton = (string)llGetObjectDetails(llGetLinkKey(llDetectedLinkNumber(0)),[OBJECT_DESC]);
        if (sButton == "Menu")
        {
            //MenuAO(g_kWearer,CMD_WEARER);
            if(llDetectedKey(0) == llGetOwner())
            {
                llMessageLinked(LINK_SET, MENU_REQUEST, "503|MenuMain", llDetectedKey(0));
            }
        }
        else if (~llSubStringIndex(llToLower(sButton),"ao"))
        {
            g_iHidden = !g_iHidden;
            //llOwnerSay("button to toggle ao touched");
            //llLinksetDataWrite("ao_toggle",(string)(!(integer)llLinksetDataRead("ao_toggle")));
            PositionButtons();
        }
        else if (!(integer)llLinksetDataRead("ao_noaccess"))
        {
            if (sButton == "SitAny")
            {
                llLinksetDataWrite("ao_sitanywhere",(string)(!(integer)llLinksetDataRead("ao_sitanywhere")));
            }
            else if (sButton == "Power")
            {
                llLinksetDataWrite("ao_power",(string)(!(integer)llLinksetDataRead("ao_power")));
                ShowStatus();
            }
        }
        else if((integer)llLinksetDataRead("ao_noaccess"))
        {
            llInstantMessage(llDetectedKey(0),"Sorry Acess to these functions have been revoked!");
        }
    }
    link_message(integer iLink, integer iNum, string sMsg, key kID)
    {
        if(iNum == DIALOG_RESPONSE)
        {
            list lPar = llParseString2List(sMsg,[","],[]);
            integer iAuth = llList2Integer(lPar,0);
            string sMenu = llList2String(lPar,1);
            sMsg = llList2String(lPar,2);
            integer iRespring = TRUE;
            if( sMenu == "Menu~Options")
            {
                if(sMsg == UPMENU)
                {
                    iRespring = FALSE;
                    llMessageLinked(LINK_SET, MENU_REQUEST, (string)iAuth+"|MenuAdmin",kID);
                }
                else if(sMsg == "Horizontal")
                {
                    g_iLayout = FALSE;
                    PositionButtons();
                }
                else if(sMsg == "Vertical")
                {
                    g_iLayout = TRUE;
                    PositionButtons();
                }
                else if(sMsg == "Order")
                {
                    iRespring = FALSE;
                    MenuOrder(kID,iAuth);
                }
                if(iRespring)
                {
                    MenuOptions(kID,iAuth);
                }
            }
            else if(sMenu == "Menu~Ordermenu")
            {
                if(sMsg == UPMENU)
                {
                    iRespring = FALSE;
                    MenuOptions(kID, iAuth);
                }
                else if(sMsg == "Reset")
                {
                    FindButtons();
                    Notify("Order position reset to default.",kID);
                    PositionButtons();
                }
                else if(llSubStringIndex(sMsg,":") >= 0)
                {
                    DoButtonOrder(llList2Integer(llParseString2List(sMsg,[":"],[]),1));
                }
                else
                {
                    iRespring = FALSE;
                    list lButtons;
                    string sPrompt;
                    integer iTemp = llListFindList(g_lButtons,[sMsg]);
                    g_iOldPos = llListFindList(g_lPrimOrder, [iTemp]);
                    sPrompt = "|=====HUD Order=====|\nWhich Slot do you want to swam for the "+sMsg+" button.";
                    integer i;
                    for (i=2; i < llGetListLength(g_lPrimOrder);++i)
                    {
                        if( g_iOldPos != i)
                        {
                            lButtons += [llList2String(g_lButtons,llList2Integer(g_lPrimOrder,i))+":"+(string)i];
                        }
                    }
                    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, sMenu);
                }
                if(iRespring)
                {
                    MenuOrder(kID,iAuth);
                }
            }
        }
        else if(iNum == MENU_REQUEST)
        {
            list lPar = llParseString2List(sMsg,["|"],[]);
            integer iAuth = llList2Integer(lPar,0);
            string sMenu = llList2String(lPar,1);
            if(sMenu == "MenuOptions")
            {
                MenuOptions( kID, iAuth);
            }
        }
    }
}
