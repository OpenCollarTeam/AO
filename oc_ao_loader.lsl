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

// Load note cards and set aniamtin states
key g_kCard;
integer g_iCardLine =0;

list g_lAnimStates = [ //http://wiki.secondlife.com/wiki/LlSetAnimationOverride
    "Crouching","CrouchWalking","Falling Down","Flying","FlyingSlow",
    "Hovering","Hovering Down","Hovering Up","Jumping","Landing",
    "PreJumping","Running","Standing","Sitting","Sitting on Ground","Standing Up",
    "Striding","Soft Landing","Taking Off","Turning Left","Turning Right","Walking"
];

list g_lSwimStates = ["Swim Forward","Swim Hover","Swim Slow","Swim Up","Swim Down"];
clear_states()
{
    integer i;
    integer iEnd = llGetListLength(g_lAnimStates);
    for(i; i<iEnd ;i++)
    {
        string sState = llList2String(g_lAnimStates,i);
        llLinksetDataDelete(sState);
        llLinksetDataDelete("ao_"+sState);
    }
    i=0;
    iEnd = llGetListLength(g_lSwimStates);
    for(i; i<iEnd ;i++)
    {
        string sState = llList2String(g_lSwimStates,i);
        llLinksetDataDelete(sState);
        llLinksetDataDelete("ao_"+sState);
    }
    llResetTime();
    g_iCardLine = 0;
    g_kCard = llGetNotecardLine(llLinksetDataRead("ao_card"),g_iCardLine);
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
//
default
{
    state_entry()
    {
        if(llLinksetDataRead("ao_card") != "" && (integer)llLinksetDataRead("ao_power"))
        {
            clear_states();
        }
    }
    changed(integer change)
    {
        if(change & CHANGED_INVENTORY)
        {
            if(llLinksetDataRead("ao_card") != "" && (integer)llLinksetDataRead("ao_power"))
            {
                clear_states();
            }
        }
    }
    linkset_data(integer iAction, string sName, string sVal)
    {
        if(iAction == LINKSETDATA_UPDATE)
        {
            if(sName == "ao_card" && sVal != "" && llGetInventoryType(sVal) == INVENTORY_NOTECARD &&
            !(integer)llLinksetDataRead("ao_loaded"))
            {
                llOwnerSay("loading note card "+sVal);
                clear_states();
            }
        }
    }

    dataserver(key kRequest, string sData)
    {
        if (kRequest == g_kCard)
        {
            if (sData != EOF)
            {
                if (llGetSubString(sData,0,0) != "[")
                {
                     jump next;
                }
                string sAnimationState = llStringTrim(llGetSubString(sData,1,llSubStringIndex(sData,"]")-1),STRING_TRIM);
                // Translate common ZHAOII, Oracul and AX anim state values
                if (sAnimationState == "Stand.1" || sAnimationState == "Stand.2" || sAnimationState == "Stand.3")
                {
                    sAnimationState = "Standing";
                }
                else if (sAnimationState == "Walk.N")
                {
                    sAnimationState = "Walking";
                }
                else if (sAnimationState == "Running")
                {
                    sAnimationState = "Running";
                }
                else if (sAnimationState == "Turn.L")
                {
                    sAnimationState = "Turning Left";
                }
                else if (sAnimationState == "Turn.R")
                {
                    sAnimationState = "Turning Right";
                }
                else if (sAnimationState == "Sit.N")
                {
                    sAnimationState = "Sitting";
                }
                else if (sAnimationState == "Sit.G" || sAnimationState == "Sitting On Ground")
                {
                    sAnimationState = "Sitting on Ground";
                }
                else if (sAnimationState == "Crouch" || sAnimationState == "Crouching")
                {
                    sAnimationState = "Crouching";
                }
                else if (sAnimationState == "Walk.C" || sAnimationState == "Crouch Walking")
                {
                    sAnimationState = "CrouchWalking";
                }
                else if (sAnimationState == "Jump.N" || sAnimationState == "Jumping")
                {
                    sAnimationState = "Jumping";
                }
                else if (sAnimationState == "Takeoff")
                {
                    sAnimationState = "Taking Off";
                }
                else if (sAnimationState == "Hover.N")
                {
                    sAnimationState = "Hovering";
                }
                else if (sAnimationState == "Hover.U" || sAnimationState == "Flying Up")
                {
                    sAnimationState = "Hovering Up";
                }
                else if (sAnimationState == "Hover.D" || sAnimationState == "Flying Down")
                {
                    sAnimationState = "Hovering Down";
                }
                else if (sAnimationState == "Fly.N")
                {
                    sAnimationState = "Flying";
                }
                else if (sAnimationState == "Flying Slow")
                {
                    sAnimationState = "FlyingSlow";
                }
                else if (sAnimationState == "Land.N")
                {
                    sAnimationState = "Landing";
                }
                else if (sAnimationState == "Falling")
                {
                    sAnimationState = "Falling Down";
                }
                else if (sAnimationState == "Jump.P" || sAnimationState == "Pre Jumping")
                {
                    sAnimationState = "PreJumping";
                }
                else if (sAnimationState == "Stand.U")
                {
                    sAnimationState = "Standing Up";
                }
                if (!~llListFindList(g_lAnimStates,[sAnimationState]) && !~llListFindList(g_lSwimStates,[sAnimationState]))
                {
                    jump next;
                }
                if (llStringLength(sData)-1 > llSubStringIndex(sData,"]"))
                {
                    sData = llGetSubString(sData,llSubStringIndex(sData,"]")+1,-1);
                    list lTemp = llParseString2List(sData, ["|",","],[]);
                    string sAnim = sData;
                    if(~llSubStringIndex(sData,"|") || ~llSubStringIndex(sData,","))
                    {
                        if(llLinksetDataRead("ao_"+sAnimationState) == "")
                            // check if a list aleady exists if not just dump the list to the list, else apend the second list to the list, this allows multipel [ state name ] options for a single animation set to compensate for string length issues.
                        {
                            llLinksetDataWrite("ao_"+sAnimationState,llDumpList2String(lTemp,","));
                        }
                        else
                        {
                            llLinksetDataWrite("ao_"+sAnimationState,llLinksetDataRead("ao_"+sAnimationState)+","+llDumpList2String(lTemp,","));
                        }
                        if(sAnimationState == "Standing" || sAnimationState == "Sitting" || sAnimationState == "Sitting on Ground")
                        {
                            check_settings("ao_"+sAnimationState+"change",(string)120);
                            check_settings("ao_"+sAnimationState+"rand",(string)TRUE);
                        }
                        else
                        {
                            check_settings("ao_"+sAnimationState+"change",(string)0);
                            check_settings("ao_"+sAnimationState+"rand",(string)FALSE);
                        }
                        sAnim = llList2String(lTemp,0);
                    }
                    if(llGetInventoryType(sAnim) == INVENTORY_ANIMATION)
                    {
                        llLinksetDataWrite(sAnimationState,sAnim);
                    }
                }
                @next;
                g_kCard = llGetNotecardLine(llLinksetDataRead("ao_card"),++g_iCardLine);
            }
            else
            {
                llOwnerSay(
                    "Note Card "+llLinksetDataRead("ao_card")+" Loaded into Linkset Data in "+(string)llGetTime()+"s"+
                    "\nLinksetMemory free: "+(string)llLinksetDataAvailable()+"bytes"
                );

                llLinksetDataWrite("ao_loaded",(string)TRUE);
                g_kCard = "";
            }
        }

    }
}
