// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!



function preprocess(is_preview){
	// add requirements etc. here
	echo("require(lookup)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var target = getValue("vl_target");
    var cats = getValue("vl_catalogs");
    var key = getValue("vl_key");
    var val = getValue("vl_val");

    var code = "res_obj <- " + target + "\n";
    code += "catalog_source <- " + cats + "\n";

    // Check if source is a single Data Frame or a List
    code += "if(is.data.frame(catalog_source)) {\n";
    code += "  # Case A: Single Catalog Data Frame -> Apply to ALL columns in target\n";
    code += "  target_vars <- names(res_obj)\n";
    code += "  is_single_cat <- TRUE\n";
    code += "} else {\n";
    code += "  # Case B: List of Catalogs -> Match by name\n";
    code += "  target_vars <- intersect(names(res_obj), names(catalog_source))\n";
    code += "  is_single_cat <- FALSE\n";
    code += "}\n";

    code += "for(var_name in target_vars) {\n";
    code += "  if(is_single_cat) { curr_cat <- catalog_source } else { curr_cat <- catalog_source[[var_name]] }\n";
    code += "  \n";
    code += "  # Process only if valid catalog and variable is factor/character\n";
    code += "  if(!is.null(curr_cat) && (is.factor(res_obj[[var_name]]) || is.character(res_obj[[var_name]]))) {\n";
    code += "     if(is.character(res_obj[[var_name]])) res_obj[[var_name]] <- as.factor(res_obj[[var_name]])\n";
    code += "     \n";
    code += "     current_levels <- levels(res_obj[[var_name]])\n";
    code += "     new_levels <- lookup::vlookup(current_levels, curr_cat, \"" + key + "\", \"" + val + "\")\n";
    code += "     levels(res_obj[[var_name]]) <- new_levels\n";
    code += "  }\n";
    code += "}\n";

    // RULE 3: Unconditional assignment to "labeled_levels"
    code += "labeled_levels <- res_obj\n";
    echo(code);
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("Value labels (levels) results")).print();

    echo("rk.header(\"Value Levels (Factor Labels) process completed.\")\n");
  
	//// save result object
	// read in saveobject variables
	var vlSave = getValue("vl_save");
	var vlSaveActive = getValue("vl_save.active");
	var vlSaveParent = getValue("vl_save.parent");
	// assign object to chosen environment
	if(vlSaveActive) {
		echo(".GlobalEnv$" + vlSave + " <- labeled_levels\n");
	}

}

