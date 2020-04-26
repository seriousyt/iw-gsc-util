/*
    serious mw3 utility
    youtube.com/anthonything
*/

#region Defines
    
    #region buttons
    // non builtins
    #define SL_BUTTONS_AS_1   = 0x0;
    #define SL_BUTTONS_AS_2   = 0x1;
    #define SL_BUTTONS_AS_3   = 0x2;
    #define SL_BUTTONS_AS_4   = 0x3;
    #define SL_BUTTONS_JUMP   = 0x4;
    #define SL_BUTTONS_STANCE = 0x5;
    #define SL_BUTTONS_SPRINT = 0x6;
    #define SL_BUTTONS_WNEXT  = 0x7;

    // builtins
    #define SL_BUTTONS_USE    = 0x8;
    #define SL_BUTTONS_MELEE  = 0x9;
    #define SL_BUTTONS_ADS    = 0xA;
    #define SL_BUTTONS_ATTACK = 0xB;
    #define SL_BUTTONS_TAC    = 0xC;
    #define SL_BUTTONS_FRAG   = 0xD;

    // bind notifies
    #define SL_BINDS_AS_1     = "actionslot " + 0x1;
    #define SL_BINDS_AS_2     = "actionslot " + 0x2;
    #define SL_BINDS_AS_3     = "actionslot " + 0x3;
    #define SL_BINDS_AS_4     = "actionslot " + 0x4;
    #define SL_BINDS_JUMP     = "gostand";
    #define SL_BINDS_STANCE   = "stance";
    #define SL_BINDS_SPRINT   = "breath_sprint";
    #define SL_BINDS_WNEXT    = "weapnext";
    #endregion

    #region internal
    // this set of defines is to keep our string count down with notifies.
    #define SL_BUTTONS = "slbutton";
    #define SL_BUTTONS_MONITOR = SL_BUTTONS + 0;
    #endregion

#endregion

#region Functions

// [CALLER] player
// Makes the caller invulnerable to damage
EnableInvulnerability()
{
     self.invulnerable = true;
}

// [CALLER] player
// Makes the caller no longer invulnerable to damage.
DisableInvulnerability()
{
    self.invulnerable = false;
    self.health       = self.maxhealth;
    self thread DamageOverride(self, self, 0);
}

// [CALLER] player
// [button] The button to check. See Defines->Buttons for the list of buttons available.
// determine if a player has pressed a given button.
IsButtonPressed(button)
{
    // non builtins
    if(button < 0x8)
        return self.slbutton[button];
        
    // builtins
    switch(button)
    {
        case SL_BUTTONS_USE:
            return self UseButtonPressed();
        case SL_BUTTONS_MELEE:
            return self MeleeButtonPressed();
        case SL_BUTTONS_ADS:
            return self AdsButtonPressed();
        case SL_BUTTONS_ATTACK:
            return self AttackButtonPressed();
        case SL_BUTTONS_TAC:
            return self SecondaryOffhandButtonPressed();
        default:
            return self FragButtonPressed();
    }
    
    // shouldnt be possible but may as well
    return false;
}

// [CALLER] none
// [variable] the variable to convert into a bool
// Safely determine if the input variable is true
bool(variable)
{
    return isdefined(variable) && int(variable);
}
#endregion

#region Overrides

// [INTERNAL] - should not be called manually
// [CALLER] player
// an override for the builtin damage function.
DamageOverride(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset)
{
    if(!bool(self.invulnerable))
        self [[ maps\mp\gametypes\_damage::Callback_PlayerDamage ]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
    else
        self.health = self.maxhealth;
}
  
// [INTERNAL] - should not be called manually
// [CALLER] player
// an override for the builtin death function.  
PlayerKilledOverride(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
    if(!bool(self.invulnerable))
        self [[ maps\mp\gametypes\_damage::Callback_PlayerKilled ]](eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
    else
        self.health = self.maxhealth;
}
#endregion

#region Internal

// [INTERNAL] - should not be called manually
// [CALLER] level
// the main method of the serious util. this must be called in init()
SeriousUtil()
{
    if(isdefined(level.sinit))
        return;
    level.sinit                = true;
    level.callbackPlayerDamage = ::DamageOverride;
    level.callbackPlayerKilled = ::PlayerKilledOverride;
    level thread SButtonMonitor();
}

// [INTERNAL] - should not be called manually
// [CALLER] player or level
// the builtin method for monitoring buttons
SButtonMonitor()
{
    self notify(SL_BUTTONS_MONITOR);
    self endon(SL_BUTTONS_MONITOR);
    self endon("game_ended");
    self endon("disconnect");
    
    // button matrix to prevent an ugly switch
    if(!isdefined(level.slbutton))
    {
        level.slbutton = [];
        level.slbutton[SL_BUTTONS_AS_1]     = SL_BINDS_AS_1;
        level.slbutton[SL_BUTTONS_AS_2]     = SL_BINDS_AS_2;
        level.slbutton[SL_BUTTONS_AS_3]     = SL_BINDS_AS_3;
        level.slbutton[SL_BUTTONS_AS_4]     = SL_BINDS_AS_4;
        level.slbutton[SL_BUTTONS_JUMP]     = SL_BINDS_JUMP;
        level.slbutton[SL_BUTTONS_STANCE]   = SL_BINDS_STANCE;
        level.slbutton[SL_BUTTONS_SPRINT]   = SL_BINDS_SPRINT;
        level.slbutton[SL_BUTTONS_WNEXT]    = SL_BINDS_WNEXT;
    }
    
    // shorthand hack to allow us to use 1 function for monitoring
    while(level == self)
    {
        self waittill("connected", player);
        player thread SButtonMonitor();
    }
    
    // if the level somehow escapes that loop we dont want it to try to act as a player
    if(level == self) 
        return;
    
    // this could be called more than once so we will use an initializer
    if(!isdefined(self.slbutton))
    {
        self.slbutton = [];
        for(i = 0; i < 8; i++)
        {
            self thread slb_intern(i, true); //button pressed
            self thread slb_intern(i, false); //button released
        }
    }

    // main notify loop
    while(1)
    {
        self waittill(SL_BUTTONS, button, state);
        self.slbutton[button] = state;
    }
}

// [INTERNAL] - should not be called manually
// [CALLER] player
// [button] The button to check. See Defines->Buttons for the list of buttons available. This should only be a builtin button (< 0x8)
// [onpressed] Determines if this function monitors press (true) or release (false)
// the builtin monitor for a specific non-builtin button
slb_intern(button, onpressed)
{
    
    prefix = onpressed ? "+" : "-";
    
    // safety net
    self notify(level.slbutton[button] + onpressed);
    self endon(level.slbutton[button] + onpressed);
    self endon("disconnect");
    level endon("game_ended");

    // this could be called more than once, so we use an initializer
    if(!isdefined(self.slbutton[button]))
    {
        self.slbutton[button] = false;
        
        // note: if the arguments match, an infinite loop will occur, subsequently crashing the game.
        self notifyOnPlayerCommand(level.slbutton[button] + "+", "+" + level.slbutton[button]);
        self notifyOnPlayerCommand(level.slbutton[button] + "-", "-" + level.slbutton[button]);
    }

    // main monitor loop
    while(1)
    {
        self waittill(level.slbutton[button] + prefix);
        self notify(SL_BUTTONS, button, onpressed);
    }
}
    
#endregion
