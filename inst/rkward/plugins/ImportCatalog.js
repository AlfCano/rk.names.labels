// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!



function preprocess(is_preview){
	// add requirements etc. here
	echo("require(rio)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var dir = getValue("ic_dir");
    var pattern = getValue("ic_pattern");
    var enc = getValue("ic_encoding");

    // FIXED: Double escaping for correct R string generation (\\\\ -> \\ -> \. in R)
    if(pattern == "") pattern = "\\\\.csv$";

    var code = "iconv.recursive <- function (x, from) {\n";
    code += "    attribs <- attributes (x)\n";
    code += "    if (is.character (x)) {\n";
    code += "        x <- iconv (x, from=from, to=\"\", sub=\"\")\n";
    code += "    } else if (is.list (x)) {\n";
    code += "        x <- lapply (x, function (sub) iconv.recursive (sub, from))\n";
    code += "    }\n";
    code += "    attributes (x) <- lapply (attribs, function (sub) iconv.recursive (sub, from))\n";
    code += "    x\n";
    code += "}\n\n";

    code += "files <- list.files(path = \"" + dir + "\", pattern = \"" + pattern + "\", full.names = TRUE)\n";
    code += "res_list <- list()\n";
    code += "for (f in files) {\n";
    code += "   # Import data\n";
    code += "   dat <- rio::import(f)\n";
    code += "   # Convert encoding\n";
    code += "   dat <- iconv.recursive(dat, from = \"" + enc + "\")\n";
    code += "   # Use filename without extension as list key\n";
    code += "   key_name <- tools::file_path_sans_ext(basename(f))\n";
    code += "   res_list[[key_name]] <- dat\n";
    code += "}\n";

    code += "catalog_list <- res_list\n";
    echo(code);
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("Import Catalog results")).print();
echo("rk.header(\"Catalog Import process completed.\")\n");
	//// save result object
	// read in saveobject variables
	var icSave = getValue("ic_save");
	var icSaveActive = getValue("ic_save.active");
	var icSaveParent = getValue("ic_save.parent");
	// assign object to chosen environment
	if(icSaveActive) {
		echo(".GlobalEnv$" + icSave + " <- catalog_list\n");
	}

}

