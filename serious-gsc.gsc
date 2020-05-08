/*
    serious mw3 utility
    youtube.com/anthonything
    
    Note: Please remember to thread SeriousUtil() in your init function, or some functions will not work correctly.
*/

#include maps\mp\gametypes\_hud_util;

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

// [CALLER] player
// [shader] The shader to draw (image). Note: This must be precached in init using 'precacheshader' for it to show up correctly.
// [x] X position of the shader (relative to the align input)
// [y] Y position of the shader (relative to the align input)
// [width] Width of the shader
// [height] Height of the shader
// [color] Tint of the shader
// [alpha] The opacity of the shader (0 to 1 scaled, 1 being completely opaque, and 0 being invisible)
// [sort] Z position of the shader (a higher sort will be drawn over a lower sort)
// [?align] The alignment to use when drawing the position of the element relative to its size. (center means to subtract half the width/height from the draw pos)
// [?relative] The relative position to use when placing the element on the screen (ie: TOPRIGHT)
// [?isLevel] Determines if the hud element is to be drawn on a specific client, or for all clients.
// Create an icon and return it.
Icon(shader, x, y, width, height, color, alpha, sort, align = "center", relative = "center", isLevel = false)
{
    if(isLevel)
        icon = maps\mp\gametypes\_hud_util::createServerIcon(shader, width, height);
    else
        icon = self maps\mp\gametypes\_hud_util::createIcon(shader, width, height);
    
    icon SetScreenPoint(align, relative, x, y);
    
    icon.color          = color;
    icon.alpha          = alpha;
    icon.sort           = sort;
    
    icon.hideWhenInMenu = true;
    
    return icon;
}

// [CALLER] player
// [string] The text you want the string to display
// [x] X position of the text (relative to the align input)
// [y] Y position of the text (relative to the align input)
// [font] The font of the text
// [fontscale] The scale of the font for the text
// [color] The color tint of the text
// [alpha] The opacity of the text (0 to 1 scaled, 1 being completely opaque, and 0 being invisible)
// [sort] Z position of the text (a higher sort will be drawn over a lower sort)
// [?align] The alignment to use when drawing the position of the element relative to its size. (center means to subtract half the width/height from the draw pos)
// [?relative] The relative position to use when placing the element on the screen (ie: TOPRIGHT)
// [?isLevel] Determines if the hud element is to be drawn on a specific client, or for all clients.
// Create a text element and return it.
Text(string, x, y, font, fontScale, color, alpha, sort, align = "center", relative = "center", isLevel = false)
{
    if(isLevel)
        text = self maps\mp\gametypes\_hud_util::createServerFontString(font, fontScale);
    else
        text = self maps\mp\gametypes\_hud_util::createFontString(font, fontScale);
    
    text SetScreenPoint(align, relative, x, y);
    text SetText(string);
    
    text.color          = color;
    text.alpha          = alpha;
    text.sort           = sort;
    
    text.hideWhenInMenu = true;

    return text;
}

// [CALLER] none
// [value] The RGB color component to convert
// Convert a hex integer into a color vector
color(value)
{
    /*
        Size constraints comment:
        
        Why is this better than rgb = (r,g,b) => return (r/255, g/255, b/255)?
        
        This will emit PSC, GetInt, align(4), value, SFT, align(1 + pos, 4), 4
        rgb... emits PSC, {GetInt, align(4), value}[3], SFT, align(1 + pos, 4), 4
        Vector emits Vec, align(4), r as float, b as float, g as float 
        
        color:  Min: 14, Max: 17
        rgb:    Min: 30, Max: 33
        vector: Min: 13, Max: 16
    */

    return
    (
    (value & 0xFF0000) / 0xFF0000,
    (value & 0x00FF00) / 0x00FF00,
    (value & 0x0000FF) / 0x0000FF
    );
}

// [CALLER] Hud Element
// [point] The alignment to use when drawing the position of the element relative to its size. (center means to subtract half the width/height from the draw pos)
// [relativePoint] The relative position to use when placing the element on the screen (ie: TOPRIGHT)
// [xOffset] Horizontal position relative to the element's parent
// [yOffset] Vertical position relative to the element's parent
// [moveTime] Time that the element will take to reach its destination
// Setpoint, but without being relative adjustable
SetScreenPoint(point, relativePoint, xOffset, yOffset, moveTime)
{
    self maps\mp\gametypes\_hud_util::setPoint(point, relativePoint, xOffset, yOffset, moveTime);
    self.horzAlign = strip_suffix(self.horzAlign, "_adjustable");
    self.vertAlign = strip_suffix(self.vertAlign, "_adjustable");
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
    
    //use a local variable to save some bytecode space
    bmatrix = [];
    bmatrix[SL_BUTTONS_AS_1]     = SL_BINDS_AS_1;
    bmatrix[SL_BUTTONS_AS_2]     = SL_BINDS_AS_2;
    bmatrix[SL_BUTTONS_AS_3]     = SL_BINDS_AS_3;
    bmatrix[SL_BUTTONS_AS_4]     = SL_BINDS_AS_4;
    bmatrix[SL_BUTTONS_JUMP]     = SL_BINDS_JUMP;
    bmatrix[SL_BUTTONS_STANCE]   = SL_BINDS_STANCE;
    bmatrix[SL_BUTTONS_SPRINT]   = SL_BINDS_SPRINT;
    bmatrix[SL_BUTTONS_WNEXT]    = SL_BINDS_WNEXT;
    
    level.slbutton = bmatrix;
    
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

    // shorthand hack to allow us to use 1 function for monitoring
    while(level == self)
    {
        self waittill("connected", player);
        player thread SButtonMonitor();
    }
    
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
    slb    = level.slbutton[button];
    
    // safety net
    self notify(slb + onpressed);
    self endon(slb + onpressed);
    
    self endon("disconnect");
    level endon("game_ended");

    // this could be called more than once, so we use an initializer
    if(!isdefined(self.slbutton[button]))
    {
        self.slbutton[button] = false;
        
        // note: if the arguments match, an infinite loop will occur, subsequently crashing the game.
        self notifyOnPlayerCommand(slb + "+", "+" + slb);
        self notifyOnPlayerCommand(slb + "-", "-" + slb);
    }

    // main monitor loop
    while(1)
    {
        self waittill(slb + prefix);
        self notify(SL_BUTTONS, button, onpressed);
    }
}
    
#endregion
