var midiPatternMap = {};

//lets you write a regex but use "-a" as a shorthand for a midi-note wildcard.
//this function recompiles the regex into a standard one
var buildRegex = rgx => new RegExp(rgx.toString().slice(1, -1).replace(/-a/g, "(-\\d{1,3})")+"$");
var br = buildRegex;
midiPatternMap["responsivevis1"] = [
    // {chan:0, paramNum: 1, paramTarget: 0, fadeTime: 3, lastMatched: -1, seq: [80, 79, 77]},
    // {chan:0, paramNum: 1, paramTarget: 0, fadeTime: 3, lastMatched: -1, regex: br(/-80-a{1,3}-79-a{1,3}-77/)},
    // {chan:0, paramNum: 3, paramTarget: .3, fadeTime: 3, lastMatched: -1, seq: [46]},
    // {chan:0, paramNum: 3, paramTarget: .4, fadeTime: 3, lastMatched: -1, regex: br(/-46-a{1,10}-48/)},
    // {chan:0, paramNum: 3, paramTarget: .5, fadeTime: 3, lastMatched: -1, regex: br(/-46-a{1,3}-48-a{1,3}-48/)},
    // {chan:1, paramNum: 5, paramTarget: .4, fadeTime: 1, lastMatched: -1, regex: br(/-60-a{1,3}-62-a{1,3}-63/)},
    // {chan:1, paramNum: 6, paramTarget: .9, fadeTime: 0.5, lastMatched: -1, regex: br(/-62-a{1,3}-64/)},
    // {chan:1, paramNum: 5, paramTarget: .4, fadeTime: 0.5, lastMatched: -1, regex: br(/-63-a{1,3}-68-a{1,3}-67/)},

    // {chan:0, paramNum: 0, paramTarget: .8, fadeTime: .8, lastMatched: -1, regex: br(/-50/)},
    {chan:0, paramNum: 1, paramTarget: .8, fadeTime: .8, lastMatched: -1, regex: br(/-52/)},    
    {chan:0, paramNum: 1, paramTarget: .8, fadeTime: .8, lastMatched: -1, regex: br(/-52/)},
    {chan:0, paramNum: 2, paramTarget: 1, fadeTime: 4, lastMatched: -1, regex: br(/-57-59-60/)},
    {chan:0, paramNum: 0, paramTarget: .4, fadeTime: 2, lastMatched: -1, regex: br(/-55/)},

    {chan:0, paramNum: 3, paramTarget: .9, fadeTime: 6, lastMatched: -1, regex: br(/-57-a{1,3}-60/)},
    {chan:0, paramNum: 3, paramTarget: .9, fadeTime: 6, lastMatched: -1, regex: br(/-57-60/)},
    {chan:0, paramNum: 0, paramTarget: .4, fadeTime: 2, lastMatched: -1, regex: br(/-59-62/)},
    {chan:0, paramNum: 0, paramTarget: .4, fadeTime: 2, lastMatched: -1, regex: br(/-59-a{1,3}-62/)},
    {chan:0, paramNum: 2, paramTarget: 1, fadeTime: 4, lastMatched: -1, regex: br(/-79-a{1,8}-76/)},
    {chan:0, paramNum: 4, paramTarget: .4, fadeTime: 2, lastMatched: -1, regex: br(/-a.{1,4}\1/)},
];

midiPatternMap['rainbowHits_slider'] = [
    {chan:0, paramNum: 1, paramTarget: 0, fadeTime: 3, lastMatched: -1, seq: [68, 67, 65]},
    {chan:0, paramNum: 1, paramTarget: 0, fadeTime: 3, lastMatched: -1, regex: br(/-68-a{1,3}-67-a{1,3}-65/)},
    {chan:0, paramNum: 3, paramTarget: .3, fadeTime: 3, lastMatched: -1, seq: [48]},
    {chan:0, paramNum: 3, paramTarget: .4, fadeTime: 3, lastMatched: -1, regex: br(/-48-a{1,10}-50/)},
    {chan:0, paramNum: 3, paramTarget: .5, fadeTime: 3, lastMatched: -1, regex: br(/-48-a{1,3}-50-a{1,3}-48/)},
    {chan:0, paramNum: 5, paramTarget: .4, fadeTime: 1, lastMatched: -1, regex: br(/-60-a{1,3}-62-a{1,3}-63/)},
    {chan:0, paramNum: 6, paramTarget: .9, fadeTime: 0.5, lastMatched: -1, regex: br(/-62-a{1,3}-64/)},
    {chan:0, paramNum: 5, paramTarget: .4, fadeTime: 0.5, lastMatched: -1, regex: br(/-63-a{1,3}-68-a{1,3}-67/)},

    {chan:0, paramNum: 0, paramTarget: .8, fadeTime: .8, lastMatched: -1, regex: br(/-50/)},
]

midiPatternMap["responsivevis2"] = [

];




//single note sequence, (or a particular chord/cadence) for impact shots
//drum patterns, esp if playing in layers, as one shots for "pulse"
/*have each note (or each prefix, or segment ending on a target note) of an ascending phrase be mapped to higher and higher
values of the same parameter, so the speed at which you go thru maps to the animation
*/
/*make your animation such that certain patterns/parameters are localized to different areas of the screen,
or are mapped to different moving objects/areas
*/
/*can combine the previous two ideas to have some patterns move an area, and some patterns animate it - a "gesture"*/
/*think of playing with matematical combinations of some parameters (with different targets and decay times) as
a single "number" - eg motion via (param1+param2+param3) - could get interesting "dancy" movement if the tirggers are set up right
*/
/*
control uniforms via parameters - different time streams (finally allowing you to properly slow down/speed up time), random walks
where force is the random variable (for different forces, switch probabilities, etc)
*/
/*if you have a loop and want an animation to start at the "beginning" - rotate the template of the sequence to have the first note
at the end. 
*/
/*watch out for race conditions - eg, two sequences both and during an animation frame, so one of the two doesn't get triggered.*/
/*you'll need different types of patterns for live melody playing vs stacked loops - might even have to play around with different t
ypes of match functions (eg, naive sequence match => regex => sequence state machine)
*/
/*rather than having a phrase detection jump to a target and then ramp back to the default, could have it trigger a ramp from the current
value to a target over time - this would work better for when you want a certain animation "texture" to sustain over a musical 
"texture" i.e set of loops - it only changes when specific other sequences are triggered that distrub the texture*/
/*
multiple types of pattern triggers 
- jump and return (the implemented idea)
- ramp-to-target (described above) 
- what else?
*/
/*
copied from phone notes
Music-visuals -
- musical sequences that toggle other sequences on and off 
- Can also procedurally generate sequence-param mappings (can even have them "suggested" to you via light up play on keyboard). 
- Have a hyper keyboard that generates phrases - the side buttons can be used to play generated phrases or record input to be transformed 
*/
/*
don't forget the bigger picture - responive movement to musical improve that reflects 
"something deeper" (which used to be narrative but now could be anything deeper - maybe "gesture" in the dance sense)
*/
/*
Strategies for having visuals "move" with the music (related how the music itself changes) (not mutually exclusive)
- sectional - big differences between parts - maybe even no shared "subparts" between sections
    would need to "cue" this, both visually and musically - eg a "scene" change in the looper, and then
    switching to a different shader and/or changing the pattern triggers + what parameters they control 
- thematic - elements of visuals follows some imporant melodies/themes 
- textural - no easily identifiabe "parts" of the moving image that respond independently to music,
    e.g., different balls moving with different instruments
- gestural - following "musical arcs" of some sort on a note by note level - either melodic contours 
    or something else (like what?)

could have a theme template and 
*/