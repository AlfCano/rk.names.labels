// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!



function preprocess(is_preview){
	// add requirements etc. here
	echo("require(lookup)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var target = getValue("dl_target");
    var dict = getValue("dl_dict");
    var key = getValue("dl_key_col");
    var val = getValue("dl_val_col");

    var code = "res_obj <- " + target + "\n";
    code += "dict_df <- " + dict + "\n";
    code += "keys <- dict_df[[\"" + key + "\"]]\n";
    code += "vals <- dict_df[[\"" + val + "\"]]\n";

    code += "for(col_name in names(res_obj)) {\n";
    code += "   match_idx <- match(col_name, keys)\n";
    code += "   if(!is.na(match_idx)) {\n";
    code += "       new_label <- as.character(vals[match_idx])\n";
    code += "       rk.set.label(res_obj[[col_name]], new_label)\n";
    code += "   }\n";
    code += "}\n";

    // RULE 3: Unconditional assignment to hard-coded name "labeled_data"
    code += "labeled_data <- res_obj\n";
    echo(code);
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("Dictionary Lookup results")).print();

    echo("rk.header(\"Dictionary Labeling process completed.\")\n");
  
	//// save result object
	// read in saveobject variables
	var dlSave = getValue("dl_save");
	var dlSaveActive = getValue("dl_save.active");
	var dlSaveParent = getValue("dl_save.parent");
	// assign object to chosen environment
	if(dlSaveActive) {
		echo(".GlobalEnv$" + dlSave + " <- labeled_data\n");
	}

}

