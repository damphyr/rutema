function toggleContentFolding( callingElement )
{
	var elem, vis;
	//var par = callingElement.parentNode;
	var par = callingElement
	for (i = par.childNodes.length - 1; i >= 0; i--) {
		if (par.childNodes[i].nodeType == 1) {
			elem = par.childNodes[i];
			break;
		}
	}
	vis = elem.style;
	vis.display = (vis.display==''||vis.display=='block')?'none':'block';
}