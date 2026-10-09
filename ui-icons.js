// Each symbol is a separately generated watercolor image, shared by DOM and Canvas UI.
export const UI_ICONS=['feed','pet','play','clean','sleep','decorate','friends','journal','skins','acorn','sun','flower','sound-on','sound-off','fullscreen','camera','close','check','move','rotate','goals','gift','lock'];
export function iconHTML(name){
  if(!UI_ICONS.includes(name))throw new Error('Unknown UI icon: '+name);
  return `<img class="ui-art" src="assets/ui-icons/${name}.png" alt="" aria-hidden="true" draggable="false">`;
}
