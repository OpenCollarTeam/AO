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
//string g_sVersion = "1.2.0"; // version (major.minor(no greater than 9 if so rolle to major).bug)
list g_lAnimStates = [ //http://wiki.secondlife.com/wiki/LlSetAnimationOverride
    "Crouching","CrouchWalking","Falling Down","Flying","FlyingSlow",
    "Hovering","Hovering Down","Hovering Up","Jumping","Landing",
    "PreJumping","Running","Standing","Sitting","Sitting on Ground","Standing Up",
    "Striding","Soft Landing","Taking Off","Turning Left","Turning Right","Walking"
];

list g_lSwimStates = ["Swim Forward","Swim Hover","Swim Slow","Swim Up","Swim Down"];

default
{
    state_entry()
    {
        if((integer)llLinksetDataRead("ao_power"))
        {
            llSetTimerEvent(1);
        }
        else
        {
            llSetTimerEvent(0);
        }
    }
    attach(key kID)
    {
        if(kID != NULL_KEY)
        {
            if((integer)llLinksetDataRead("ao_power"))
            {
                llSetTimerEvent(1);
            }
            else
            {
                llSetTimerEvent(0);
            }
        }
        else
        {
            llSetTimerEvent(0);
        }
    }
    linkset_data(integer iAction,string sName,string sValue)
    {
        if( iAction == LINKSETDATA_UPDATE)
        {
            if(sName == "ao_power")
            {
                if((integer)sValue)
                {
                    llSetTimerEvent(1);
                }
                else
                {
                    llSetTimerEvent(0);
                }
            }
        }
    }
    timer()
    {
        integer iTyping = (llGetAgentInfo(llGetOwner())&AGENT_TYPING);
        vector vPos = llGetPos();
        float fWater = llWater(ZERO_VECTOR);
        if(vPos.z <= fWater)
        {
            llLinksetDataWrite("ao_swiming",(string)TRUE);
        }
        else
        {
            llLinksetDataWrite("ao_swiming",(string)FALSE);
        }

        if(iTyping != (integer)llLinksetDataRead("ao_typing"))
        {
            llLinksetDataWrite("ao_typing",(string)iTyping);
        }

        // Detact if we are in water to enable the swimming anims.
        //llLinksetDataWrite("ao_animstate",llGetAnimation(llGetOwner()));
        integer i;
        integer iEnd = llGetListLength(g_lAnimStates);
        for(i; i<llGetListLength(g_lAnimStates); i++)
        {
            string sState = llList2String(g_lAnimStates,i);\
            if((integer)llLinksetDataRead("ao_"+sState+"change") != 0 && llGetUnixTime() > (integer)llLinksetDataRead("ao_"+sState+"timer"))
            {
                list lAnims = llParseString2List(llLinksetDataRead("ao_"+sState),[","],[]);
                integer iIndex;
                if((integer)llLinksetDataRead("ao_"+sState+"rand"))
                {
                    iIndex = (integer)llFrand((llGetListLength(lAnims)-1));
                }
                else
                {
                    iIndex = llListFindList(lAnims,[llLinksetDataRead(sState)])+1;
                    if ( iIndex >= llGetListLength(lAnims))
                    {
                        iIndex = 0;
                    }
                }
                string sAnim = llList2String(lAnims,iIndex);
                if(llGetInventoryType(sAnim) == INVENTORY_ANIMATION && sAnim != llLinksetDataRead(sState))
                {
                    if(sState != "Sitting" || (integer)llLinksetDataRead("ao_sitctl"))
                    {
                        llLinksetDataWrite(sState,sAnim);
                    }
                    llLinksetDataWrite("ao_"+sState+"timer",(string)(llGetUnixTime()+(integer)llLinksetDataRead("ao_"+sState+"change")));
                }
                sAnim = "";
                lAnims = [];
            }
        }

        if(iTyping != (integer)llLinksetDataRead("ao_typing"))
        {
            llLinksetDataWrite("ao_typing",(string)iTyping);
        }
        i=0;
        iEnd = llGetListLength(g_lSwimStates);
        for(i; i<llGetListLength(g_lSwimStates); i++)
        {
            string sState = llList2String(g_lSwimStates,i);
            if((integer)llLinksetDataRead("ao_"+sState+"change") && llGetUnixTime() > (integer)llLinksetDataRead("ao_"+sState+"timer"))
            {
                list lAnims = llParseString2List(llLinksetDataRead("ao_"+sState),[","],[]);
                integer iIndex;
                if((integer)llLinksetDataRead("ao_"+sState+"rand"))
                {
                    iIndex = (integer)llFrand((llGetListLength(lAnims)-1));
                }
                else
                {
                    iIndex = llListFindList(lAnims,[llLinksetDataRead(sState)])+1;
                    if ( iIndex >= llGetListLength(lAnims))
                    {
                        iIndex = 0;
                    }
                }
                string sAnim = llList2String(lAnims,iIndex);
                if(llGetInventoryType(sAnim) == INVENTORY_ANIMATION && sAnim != llLinksetDataRead(sState))
                {
                    llLinksetDataWrite(sState,sAnim);
                    llLinksetDataWrite("ao_"+sState+"timer",(string)(llGetUnixTime()+(integer)llLinksetDataRead("ao_"+sState+"change")));
                }
                sAnim = "";
                lAnims = [];
            }
        }
    }
}
