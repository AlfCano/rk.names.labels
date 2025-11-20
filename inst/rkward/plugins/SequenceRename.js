// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!



function preprocess(is_preview){
	// add requirements etc. here
	echo("require(tibble)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var df = getValue("sr_df");
    var cols = getValue("sr_cols").split("\n");
    var mode = getValue("sr_mode");
    var code = "res_obj <- " + df + "\n";

    if(mode == "seq") {
        var prefix = getValue("sr_prefix");
        var suffix = getValue("sr_suffix");
        var start_num = getValue("sr_start");
        var col_str = "";
        for (var i = 0; i < cols.length; i++) {
             var cl = cols[i].split("[[\"").pop().replace(/\"]]/g, "").replace(/\"/g, "");
             if(i > 0) col_str += ", ";
             col_str += "\"" + cl + "\"";
        }
        code += "target_cols <- c(" + col_str + ")\n";
        code += "sel_indices <- which(names(res_obj) %in% target_cols)\n";
        code += "new_names <- paste0(\"" + prefix + "\", seq(from=" + start_num + ", length.out=length(sel_indices)), \"" + suffix + "\")\n";
        code += "names(res_obj)[sel_indices] <- new_names\n";
    } else {
        var strategy = getValue("sr_repair");
        code += "res_obj <- tibble::as_tibble(res_obj, .name_repair = \"" + strategy + "\")\n";
    }
    // RULE 3: Unconditional assignment to hard-coded name "renamed_df"
    code += "renamed_df <- res_obj\n";
    echo(code);
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("Sequence Rename results")).print();

    echo("rk.header(\"Sequence Rename / Repair process completed.\")\n");
  
	//// save result object
	// read in saveobject variables
	var srSave = getValue("sr_save");
	var srSaveActive = getValue("sr_save.active");
	var srSaveParent = getValue("sr_save.parent");
	// assign object to chosen environment
	if(srSaveActive) {
		echo(".GlobalEnv$" + srSave + " <- renamed_df\n");
	}

}

