inlets = 1;
outlets = 1;

function dictionary(){
	var senselDict = new Dict(arguments[0]);
	var numTouches = senselDict.get("contacts");
	var valsList = new Array();
	var keys = senselDict.getkeys();
	valsList.push(numTouches);
	for(var i = 0; i < 16; i++){
		var touchDict = senselDict.get(i);
		if(touchDict){
			valsList.push(i);
			valsList.push(touchDict.get("x"));
			valsList.push(touchDict.get("y"));
			valsList.push(touchDict.get("force"));
		}
	}
	outlet(0, valsList);
}
