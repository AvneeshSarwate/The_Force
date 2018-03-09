function empressAlbumArtLoader(){
	var slotID = 5;
    destroyInput(slotID);
    var texture = {};
    texture.type = "tex_2D";
    texture.globject = gl.createTexture();
    texture.image = new Image();
    texture.loaded = false;
    whichSlot = "";
    texture.image.onload = function()
    {
        createGLTextureNearest(gl, texture.image, texture.globject);
        texture.loaded = true;
    }
    texture.image.src = 'presets/empress.png';
    mInputs[slotID] = texture;
    createInputStr();
}