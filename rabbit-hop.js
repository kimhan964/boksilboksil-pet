// Current rabbit_hop_motion.gd phase/flight equations, adapted to room pixels.
export function hopPhase(elapsed,hop){
 const period=hop.period,base=period-.28,time=((elapsed%period)+period)%period,launchTime=base*.12,landTime=base*.82,recovery=base+.16;
 if(time<launchTime)return hop.launch*time/launchTime;
 if(time<landTime)return hop.launch+(hop.land-hop.launch)*(time-launchTime)/(landTime-launchTime);
 if(time<recovery)return hop.land+(1-hop.land)*(time-landTime)/(recovery-landTime);
 return .999999;
}
export function hopFlight(elapsed,hop){return Math.max(0,Math.min(1,(hopPhase(elapsed,hop)-hop.launch)/(hop.land-hop.launch)));}
export function hopLift(elapsed,hop){return Math.sin(hopFlight(elapsed,hop)*Math.PI)**2*hop.height;}
export function hopTravelRate(elapsed,dt,hop){
 const travel=t=>{const cycles=Math.floor(t/hop.period),p=hopFlight(t,hop);return cycles+p*p*(3-2*p);};
 return Math.max(0,(travel(elapsed+dt)-travel(elapsed))*hop.period/Math.max(.00001,dt));
}
