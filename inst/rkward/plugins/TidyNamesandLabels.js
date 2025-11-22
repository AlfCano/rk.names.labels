// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!



function preprocess(is_preview){
	// add requirements etc. here
	echo("require(janitor)\n");	echo("require(stringr)\n");	echo("require(vctrs)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var obj = getValue("tn_obj");
    var repair_method = getValue("tn_repair_method");
    var case_method = getValue("tn_case_method");
    var scope = getValue("tn_scope");
    var do_trim = getValue("tn_trim");
    var do_squish = getValue("tn_squish");
    var copy_labels = getValue("tn_copy_to_label");

    var code = "res_obj <- " + obj + "\n";
    code += "current_names <- names(res_obj)\n";

    if(repair_method == "janitor") {
        code += "res_obj <- janitor::clean_names(res_obj)\n";
        code += "current_names <- names(res_obj)\n";
    } else if (repair_method == "syntactic") {
        code += "current_names <- make.names(current_names, unique = TRUE)\n";
    } else if (repair_method == "unique") {
        code += "current_names <- make.unique(current_names)\n";
    } else if (repair_method == "universal") {
        code += "current_names <- vctrs::vec_as_names(current_names, repair = \"universal\", quiet = TRUE)\n";
    }

    if(scope == "names" || scope == "both") {
        if(case_method == "lower") code += "current_names <- tolower(current_names)\n";
        if(case_method == "upper") code += "current_names <- toupper(current_names)\n";
        if(do_trim == "1") code += "current_names <- stringr::str_trim(current_names)\n";
        if(do_squish == "1") code += "current_names <- stringr::str_squish(current_names)\n";
    }
    code += "names(res_obj) <- current_names\n";

    if(scope == "labels" || scope == "both") {
         if(case_method != "none" || do_trim == "1" || do_squish == "1") {
             code += "for(n in names(res_obj)) {\n";
             code += "  curr_lab <- rk.get.label(res_obj[[n]])\n";
             code += "  if(!is.null(curr_lab) && !is.na(curr_lab)) {\n";
             if(case_method == "lower") code += "    curr_lab <- tolower(curr_lab)\n";
             if(case_method == "upper") code += "    curr_lab <- toupper(curr_lab)\n";
             if(do_trim == "1") code += "    curr_lab <- stringr::str_trim(curr_lab)\n";
             if(do_squish == "1") code += "    curr_lab <- stringr::str_squish(curr_lab)\n";
             code += "    rk.set.label(res_obj[[n]], curr_lab)\n";
             code += "  }\n";
             code += "}\n";
         }
    }

    if(copy_labels == "1") {
       code += "for(n in names(res_obj)) {\n";
       code += "  if(!is.null(res_obj[[n]])) rk.set.label(res_obj[[n]], n)\n";
       code += "}\n";
    }
    code += "tidy_data <- res_obj\n";
    echo(code);
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("Tidy Names and Labels results")).print();
echo("rk.header(\"Tidy Names and Labels process completed.\")\n");
	//// save result object
	// read in saveobject variables
	var tnSaveRes = getValue("tn_save_res");
	var tnSaveResActive = getValue("tn_save_res.active");
	var tnSaveResParent = getValue("tn_save_res.parent");
	// assign object to chosen environment
	if(tnSaveResActive) {
		echo(".GlobalEnv$" + tnSaveRes + " <- tidy_data\n");
	}

}

