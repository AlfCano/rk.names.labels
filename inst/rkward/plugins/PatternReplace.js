// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!



function preprocess(is_preview){
	// add requirements etc. here
	echo("require(stringr)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var obj = getValue("rp_obj");
    var patt = getValue("rp_pattern");
    var repl = getValue("rp_replace");
    var scope = getValue("rp_scope");
    var code = "res_obj <- " + obj + "\n";

    if(patt != "") {
        if(scope == "names") {
            code += "names(res_obj) <- stringr::str_replace_all(names(res_obj), pattern = \"" + patt + "\", replacement = \"" + repl + "\")\n";
        } else {
            code += "for(col in names(res_obj)) {\n";
            code += "  old_lab <- rk.get.label(res_obj[[col]])\n";
            code += "  if(!is.null(old_lab) && !is.na(old_lab)) {\n";
            code += "     new_lab <- stringr::str_replace_all(old_lab, pattern = \"" + patt + "\", replacement = \"" + repl + "\")\n";
            code += "     rk.set.label(res_obj[[col]], new_lab)\n";
            code += "  }\n";
            code += "}\n";
        }
    }
    code += "replaced_data <- res_obj\n";
    echo(code);
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("Pattern Replace results")).print();
echo("rk.header(\"Pattern Replacement process completed.\")\n");
	//// save result object
	// read in saveobject variables
	var rpSaveRes = getValue("rp_save_res");
	var rpSaveResActive = getValue("rp_save_res.active");
	var rpSaveResParent = getValue("rp_save_res.parent");
	// assign object to chosen environment
	if(rpSaveResActive) {
		echo(".GlobalEnv$" + rpSaveRes + " <- replaced_data\n");
	}

}

