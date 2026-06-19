local({
  # =========================================================================================
  # 1. Prerequisites & Package Metadata
  # =========================================================================================
  require(rkwarddev)
  rkwarddev.required("0.10-3")

  package_about <- rk.XML.about(
    name = "rk.names.labels",
    author = person(
      given = "Alfonso",
      family = "Cano",
      email = "alfonso.cano@correo.buap.mx",
      role = c("aut", "cre")
    ),
    about = list(
      desc = "A plugin package to clean and create names and labels of variables of a data.frame or manipulate names in a list in the Rkward GUI.",
      version = "0.0.6", # Actualizado para reflejar la mejora de copiado
      url = "https://github.com/AlfCano/rk.names.labels",
      license = "GPL (>= 3)"
    )
  )

  # =========================================================================================
  # 2. Reusable UI Elements
  # =========================================================================================

  var_select <- rk.XML.varselector(id.name = "vars")

  # =========================================================================================
  # Component 1: Tidy Names and Labels
  # =========================================================================================

  tn_target <- rk.XML.varslot("Select Data Frame or List", source = var_select, required = TRUE, classes = c("data.frame", "list"), id.name = "tn_obj")

  # 1. Name Repair
  tn_repair <- rk.XML.dropdown("Name Repair Strategy (Names Only)", options = list(
    "None" = list(val = "none", chk = TRUE),
    "Janitor (snake_case)" = list(val = "janitor"),
    "Make Syntactic (base::make.names)" = list(val = "syntactic"),
    "Make Unique (base::make.unique)" = list(val = "unique"),
    "Universal (vctrs/tibble)" = list(val = "universal")
  ), id.name = "tn_repair_method")

  # 2. Case Transformation
  tn_case <- rk.XML.radio("Case Transformation", options = list(
    "No Change" = list(val = "none", chk = TRUE),
    "Lowercase (tolower)" = list(val = "lower"),
    "Uppercase (toupper)" = list(val = "upper")
  ), id.name = "tn_case_method")

  # 3. Scope
  tn_scope <- rk.XML.dropdown("Apply Transformations To", options = list(
      "Names Only" = list(val = "names", chk = TRUE),
      "Labels Only" = list(val = "labels"),
      "Both Names and Labels" = list(val = "both")
  ), id.name = "tn_scope")

  # 4. Cleanup
  tn_stringr <- rk.XML.row(
    rk.XML.col(
      rk.XML.cbox("Trim Whitespace (str_trim)", value = "1", id.name = "tn_trim"),
      rk.XML.cbox("Squish Whitespace (str_squish)", value = "1", id.name = "tn_squish")
    )
  )

  tn_warning <- rk.XML.text("<b>Note:</b> 'Name Repair' strategies only affect Names. Case and Whitespace options apply based on the dropdown selection.")

  # NUEVO: Control de copiado Antes/Después/No Copiar
  tn_copy_mode <- rk.XML.radio("Copy Variable Names to Labels", options = list(
    "Do not copy" = list(val = "none", chk = TRUE), # <-- chk = TRUE ahora está aquí
    "Before processing (Preserves original survey questions)" = list(val = "before"),
    "After processing (Copies the cleaned names)" = list(val = "after")
  ), id.name = "tn_copy_mode")

  tn_actions <- rk.XML.frame(
    tn_copy_mode,
    label = "Additional Actions"
  )

  tn_save <- rk.XML.saveobj("Save result as", chk = TRUE, initial = "tidy_data", id.name = "tn_save_res")

  tn_dialog <- rk.XML.dialog(
    label = "Tidy Names and Labels",
    child = rk.XML.row(
      var_select,
      rk.XML.col(
        rk.XML.tabbook(tabs = list(
            "Input" = rk.XML.col(tn_target),
            "Transformations" = rk.XML.col(
                rk.XML.frame(tn_repair, label = "Structure & Repair"),
                rk.XML.frame(tn_case, label = "Case Conversion"),
                rk.XML.frame(tn_scope, tn_stringr, label = "Scope and Cleanup"),
                tn_warning
            ),
            "Output" = rk.XML.col(tn_actions, tn_save)
        ))
      )
    )
  )

  js_calc_tn <- '
    var obj = getValue("tn_obj");
    var repair_method = getValue("tn_repair_method");
    var case_method = getValue("tn_case_method");
    var scope = getValue("tn_scope");
    var do_trim = getValue("tn_trim");
    var do_squish = getValue("tn_squish");
    var copy_mode = getValue("tn_copy_mode");

    var code = "res_obj <- " + obj + "\\n";

    // NUEVA LÓGICA: Copiar ANTES de procesar
    if(copy_mode == "before") {
       code += "# Preserve original names as labels before cleaning\\n";
       code += "for(n in names(res_obj)) {\\n";
       code += "  if(!is.null(res_obj[[n]])) rk.set.label(res_obj[[n]], n)\\n";
       code += "}\\n\\n";
    }

    code += "current_names <- names(res_obj)\\n";

    if(repair_method == "janitor") {
        code += "res_obj <- janitor::clean_names(res_obj)\\n";
        code += "current_names <- names(res_obj)\\n";
    } else if (repair_method == "syntactic") {
        code += "current_names <- make.names(current_names, unique = TRUE)\\n";
    } else if (repair_method == "unique") {
        code += "current_names <- make.unique(current_names)\\n";
    } else if (repair_method == "universal") {
        code += "current_names <- vctrs::vec_as_names(current_names, repair = \\"universal\\", quiet = TRUE)\\n";
    }

    if(scope == "names" || scope == "both") {
        if(case_method == "lower") code += "current_names <- tolower(current_names)\\n";
        if(case_method == "upper") code += "current_names <- toupper(current_names)\\n";
        if(do_trim == "1") code += "current_names <- stringr::str_trim(current_names)\\n";
        if(do_squish == "1") code += "current_names <- stringr::str_squish(current_names)\\n";
    }
    code += "names(res_obj) <- current_names\\n";

    if(scope == "labels" || scope == "both") {
         if(case_method != "none" || do_trim == "1" || do_squish == "1") {
             code += "for(n in names(res_obj)) {\\n";
             code += "  curr_lab <- rk.get.label(res_obj[[n]])\\n";
             code += "  if(!is.null(curr_lab) && !is.na(curr_lab)) {\\n";
             if(case_method == "lower") code += "    curr_lab <- tolower(curr_lab)\\n";
             if(case_method == "upper") code += "    curr_lab <- toupper(curr_lab)\\n";
             if(do_trim == "1") code += "    curr_lab <- stringr::str_trim(curr_lab)\\n";
             if(do_squish == "1") code += "    curr_lab <- stringr::str_squish(curr_lab)\\n";
             code += "    rk.set.label(res_obj[[n]], curr_lab)\\n";
             code += "  }\\n";
             code += "}\\n";
         }
    }

    // NUEVA LÓGICA: Copiar DESPUÉS de procesar
    if(copy_mode == "after") {
       code += "# Copy cleaned names to labels\\n";
       code += "for(n in names(res_obj)) {\\n";
       code += "  if(!is.null(res_obj[[n]])) rk.set.label(res_obj[[n]], n)\\n";
       code += "}\\n";
    }

    code += "tidy_data <- res_obj\\n";
    echo(code);
  '
  js_print_tn <- 'echo("rk.header(\\"Tidy Names and Labels process completed.\\")\\n");'

  help_tn <- rk.rkh.doc(
    title = rk.rkh.title("Tidy Names and Labels"),
    summary = rk.rkh.summary("Provides tools to clean variable names and labels using standard R methods, 'janitor', and 'stringr'."),
    usage = rk.rkh.usage("Select a data.frame. Configure repair strategies and string cleaning options."),
    settings = rk.rkh.settings(
        rk.rkh.setting(id = "tn_repair_method", text = "Method to standardise structure (Names only)."),
        rk.rkh.setting(id = "tn_scope", text = "Apply rules to Names, Labels, or Both.")
    )
  )

  # =========================================================================================
  # Component 2: Pattern Replacement
  # =========================================================================================

  rp_target <- rk.XML.varslot("Select Data Frame or List", source = var_select, required = TRUE, classes = c("data.frame", "list"), id.name = "rp_obj")
  rp_pattern <- rk.XML.input("Pattern (Regex)", id.name = "rp_pattern")
  rp_replace <- rk.XML.input("Replacement", id.name = "rp_replace")
  rp_scope <- rk.XML.radio("Scope", options = list("Names" = list(val = "names", chk = TRUE), "Labels" = list(val = "labels")), id.name = "rp_scope")
  rp_save <- rk.XML.saveobj("Save result as", chk = TRUE, initial = "replaced_data", id.name = "rp_save_res")

  rp_dialog <- rk.XML.dialog(
    label = "Pattern Replacement",
    child = rk.XML.row(var_select, rk.XML.col(rp_target, rk.XML.frame(rp_pattern, rp_replace, label="Substitution"), rp_scope, rp_save))
  )

  js_calc_rp <- '
    var obj = getValue("rp_obj");
    var patt = getValue("rp_pattern");
    var repl = getValue("rp_replace");
    var scope = getValue("rp_scope");
    var code = "res_obj <- " + obj + "\\n";

    if(patt != "") {
        if(scope == "names") {
            code += "names(res_obj) <- stringr::str_replace_all(names(res_obj), pattern = \\"" + patt + "\\", replacement = \\"" + repl + "\\")\\n";
        } else {
            code += "for(col in names(res_obj)) {\\n";
            code += "  old_lab <- rk.get.label(res_obj[[col]])\\n";
            code += "  if(!is.null(old_lab) && !is.na(old_lab)) {\\n";
            code += "     new_lab <- stringr::str_replace_all(old_lab, pattern = \\"" + patt + "\\", replacement = \\"" + repl + "\\")\\n";
            code += "     rk.set.label(res_obj[[col]], new_lab)\\n";
            code += "  }\\n";
            code += "}\\n";
        }
    }
    code += "replaced_data <- res_obj\\n";
    echo(code);
  '
  js_print_rp <- 'echo("rk.header(\\"Pattern Replacement process completed.\\")\\n");'

  help_rp <- rk.rkh.doc(
    title = rk.rkh.title("Pattern Replacement"),
    summary = rk.rkh.summary("Performs regex pattern matching and replacement."),
    usage = rk.rkh.usage("Select a data object and define regex patterns."),
    settings = rk.rkh.settings(rk.rkh.setting(id="rp_pattern", text="Regex pattern."))
  )

  component_rp <- rk.plugin.component("Pattern Replace", xml = list(dialog = rp_dialog), js = list(require = "stringr", calculate = js_calc_rp, printout = js_print_rp), rkh = list(help = help_rp), hierarchy = list("data", "Names and Labels"))

  # =========================================================================================
  # Component 3: Sequence Rename
  # =========================================================================================

  sr_target_df <- rk.XML.varslot("Select Data Frame", source = var_select, required=TRUE, classes="data.frame", id.name="sr_df")
  sr_cols <- rk.XML.varslot("Select Columns to Rename", source = var_select, required=TRUE, multi=TRUE, id.name="sr_cols")
  sr_mode <- rk.XML.radio("Mode", options = list("Sequence" = list(val = "seq", chk = TRUE), "Tibble Repair" = list(val = "tibble")), id.name = "sr_mode")
  sr_opts <- rk.XML.frame(rk.XML.input("Prefix", initial = "Var", id.name = "sr_prefix"), rk.XML.input("Suffix", id.name = "sr_suffix"), rk.XML.spinbox("Start Number", min = 1, initial = 1, id.name = "sr_start"))
  sr_tibble_opts <- rk.XML.dropdown("Repair Strategy", options = list("Universal" = list(val = "universal", chk = TRUE), "Unique" = list(val = "unique")), id.name = "sr_repair")
  sr_save <- rk.XML.saveobj("Save Result", initial="renamed_df", id.name="sr_save")

  sr_dialog <- rk.XML.dialog(
      label = "Sequence Rename",
      child = rk.XML.row(var_select, rk.XML.col(rk.XML.tabbook(tabs = list("Selection"=rk.XML.col(sr_target_df, sr_cols), "Configuration"=rk.XML.col(sr_mode, rk.XML.frame(sr_opts, label="Sequence Options"), rk.XML.frame(sr_tibble_opts, label="Tibble Repair")), "Output"=rk.XML.col(sr_save)))))
  )

  js_calc_sr <- '
    var df = getValue("sr_df");
    var cols = getValue("sr_cols").split("\\n");
    var mode = getValue("sr_mode");
    var code = "res_obj <- " + df + "\\n";
    if(mode == "seq") {
        var prefix = getValue("sr_prefix");
        var suffix = getValue("sr_suffix");
        var start_num = getValue("sr_start");
        var col_str = "";
        for (var i = 0; i < cols.length; i++) {
             var cl = cols[i].split("[[\\"").pop().replace(/\\"]]/g, "").replace(/\\"/g, "");
             if(i > 0) col_str += ", ";
             col_str += "\\\"" + cl + "\\\"";
        }
        code += "target_cols <- c(" + col_str + ")\\n";
        code += "sel_indices <- which(names(res_obj) %in% target_cols)\\n";
        code += "new_names <- paste0(\\\"" + prefix + "\\\", seq(from=" + start_num + ", length.out=length(sel_indices)), \\\"" + suffix + "\\\")\\n";
        code += "names(res_obj)[sel_indices] <- new_names\\n";
    } else {
        var strategy = getValue("sr_repair");
        code += "res_obj <- tibble::as_tibble(res_obj, .name_repair = \\\"" + strategy + "\\\")\\n";
    }
    code += "renamed_df <- res_obj\\n";
    echo(code);
  '
  js_print_sr <- 'echo("rk.header(\\"Sequence Rename / Repair process completed.\\")\\n");'

  help_sr <- rk.rkh.doc(
    title = rk.rkh.title("Sequence Rename"),
    summary = rk.rkh.summary("Renames specific columns or applies tibble repair."),
    usage = rk.rkh.usage("Select columns to rename or apply global name repair."),
    settings = rk.rkh.settings(rk.rkh.setting(id="sr_mode", text="Renaming mode."))
  )

  component_sr <- rk.plugin.component("Sequence Rename", xml = list(dialog = sr_dialog), js = list(require = "tibble", calculate = js_calc_sr, printout = js_print_sr), rkh = list(help = help_sr), hierarchy = list("data", "Names and Labels"))

  # =========================================================================================
  # Component 4: Dictionary Lookup
  # =========================================================================================

  dl_target <- rk.XML.varslot("Target Data Frame", source = var_select, required = TRUE, classes = "data.frame", id.name = "dl_target")
  dl_dict <- rk.XML.varslot("Dictionary Data Frame", source = var_select, required = TRUE, classes = "data.frame", id.name = "dl_dict")
  dl_key <- rk.XML.varslot("Dictionary Key Column (Variable Names)", source = var_select, required = TRUE, id.name = "dl_key_col")
  dl_val <- rk.XML.varslot("Dictionary Value Column (Labels)", source = var_select, required = TRUE, id.name = "dl_val_col")

  dl_save <- rk.XML.saveobj("Save Target as", chk=TRUE, initial="labeled_data", id.name="dl_save")

  dl_dialog <- rk.XML.dialog(
    label = "Dictionary Label Lookup",
    child = rk.XML.row(
      var_select,
      rk.XML.col(
        rk.XML.frame(dl_target, label="Data"),
        rk.XML.frame(dl_dict, label="Dictionary Source"),
        rk.XML.frame(dl_key, dl_val, label="Dictionary Columns"),
        dl_save
      )
    )
  )

  js_calc_dl <- '
    var target = getValue("dl_target");
    var key_vec = getValue("dl_key_col");
    var val_vec = getValue("dl_val_col");

    var code = "res_obj <- " + target + "\\n";
    code += "keys <- " + key_vec + "\\n";
    code += "vals <- " + val_vec + "\\n";

    code += "for(col_name in names(res_obj)) {\\n";
    code += "   match_idx <- match(col_name, keys)\\n";
    code += "   if(!is.na(match_idx)) {\\n";
    code += "       new_label <- as.character(vals[match_idx])\\n";
    code += "       rk.set.label(res_obj[[col_name]], new_label)\\n";
    code += "   }\\n";
    code += "}\\n";
    code += "labeled_data <- res_obj\\n";
    echo(code);
  '
  js_print_dl <- 'echo("rk.header(\\"Dictionary Labeling process completed.\\")\\n");'

  help_dl <- rk.rkh.doc(
      title = rk.rkh.title("Dictionary Label Lookup"),
      summary = rk.rkh.summary("Label variables based on a dictionary dataframe."),
      usage = rk.rkh.usage("Select the dictionary dataframe and specifically drag the key/value columns to the respective slots."),
      settings = rk.rkh.settings(
        rk.rkh.setting(id="dl_target", text="Target data."),
        rk.rkh.setting(id="dl_key_col", text="Column containing the variable names (Key)."),
        rk.rkh.setting(id="dl_val_col", text="Column containing the new labels (Value).")
      )
  )

  component_dl <- rk.plugin.component("Dictionary Lookup", xml = list(dialog = dl_dialog), js = list(require = "lookup", calculate = js_calc_dl, printout = js_print_dl), rkh = list(help = help_dl), hierarchy = list("data", "Names and Labels"))

  # =========================================================================================
  # Component 5: Catalog Assignment
  # =========================================================================================

  vl_target <- rk.XML.varslot("Target Data Frame", source = var_select, required = TRUE, classes = "data.frame", id.name = "vl_target")
  vl_catalogs <- rk.XML.varslot("Catalog Source (List or Data Frame)", source = var_select, required = TRUE, classes = c("list", "data.frame"), id.name = "vl_catalogs")
  vl_key <- rk.XML.input("Key Column (in catalogs)", initial="CVE", id.name = "vl_key")
  vl_val <- rk.XML.input("Value Column (in catalogs)", initial="descrip", id.name = "vl_val")
  vl_save <- rk.XML.saveobj("Save result as", chk=TRUE, initial="labeled_levels", id.name="vl_save")

  vl_dialog <- rk.XML.dialog(
    label = "Catalog Assignment",
    child = rk.XML.row(var_select, rk.XML.col(rk.XML.frame(vl_target, label="Target Data"), rk.XML.frame(vl_catalogs, label="Catalog Source"), rk.XML.frame(vl_key, vl_val, label="Catalog Structure"), vl_save))
  )

  js_calc_vl <- '
    var target = getValue("vl_target");
    var cats = getValue("vl_catalogs");
    var key = getValue("vl_key");
    var val = getValue("vl_val");
    var code = "res_obj <- " + target + "\\n";
    code += "catalog_source <- " + cats + "\\n";
    code += "if(is.data.frame(catalog_source)) {\\n";
    code += "  target_vars <- names(res_obj)\\n";
    code += "  is_single_cat <- TRUE\\n";
    code += "} else {\\n";
    code += "  target_vars <- intersect(names(res_obj), names(catalog_source))\\n";
    code += "  is_single_cat <- FALSE\\n";
    code += "}\\n";
    code += "for(var_name in target_vars) {\\n";
    code += "  if(is_single_cat) { curr_cat <- catalog_source } else { curr_cat <- catalog_source[[var_name]] }\\n";
    code += "  if(!is.null(curr_cat) && (is.factor(res_obj[[var_name]]) || is.character(res_obj[[var_name]]))) {\\n";
    code += "     if(is.character(res_obj[[var_name]])) res_obj[[var_name]] <- as.factor(res_obj[[var_name]])\\n";
    code += "     current_levels <- levels(res_obj[[var_name]])\\n";
    code += "     new_levels <- lookup::vlookup(current_levels, curr_cat, \\"" + key + "\\", \\"" + val + "\\")\\n";
    code += "     levels(res_obj[[var_name]]) <- new_levels\\n";
    code += "  }\\n";
    code += "}\\n";
    code += "labeled_levels <- res_obj\\n";
    echo(code);
  '
  js_print_vl <- 'echo("rk.header(\\"Catalog Assignment process completed.\\")\\n");'

  help_vl <- rk.rkh.doc(
    title = rk.rkh.title("Catalog Assignment"),
    summary = rk.rkh.summary("Applies value labels to factors in a data frame using a reference catalog."),
    usage = rk.rkh.usage("Select target data and catalog list/dataframe."),
    settings = rk.rkh.settings(rk.rkh.setting(id = "vl_target", text = "Target Data."))
  )

  component_vl <- rk.plugin.component("Catalog Assignment", xml = list(dialog = vl_dialog), js = list(require = "lookup", calculate = js_calc_vl, printout = js_print_vl), rkh = list(help = help_vl), hierarchy = list("data", "Names and Labels", "Value labels (levels)"))

  # =========================================================================================
  # Component 6: Import Catalog
  # =========================================================================================

  ic_dir <- rk.XML.browser("Select Directory (containing CSVs)", type = "dir", required = TRUE, id.name = "ic_dir")

  ic_pattern <- rk.XML.input("File Pattern (Regex)", id.name = "ic_pattern")
  ic_note <- rk.XML.text("Default: .csv$ (matches CSV files)")

  ic_encoding <- rk.XML.dropdown("Encoding", options = list("UTF-8" = list(val = "UTF-8", chk = TRUE), "Latin1" = list(val = "latin1")), id.name = "ic_encoding")
  ic_save <- rk.XML.saveobj("Save Catalog List as", chk=TRUE, initial="catalog_list", id.name="ic_save")

  ic_dialog <- rk.XML.dialog(
    label = "Import Catalog",
    child = rk.XML.col(
      rk.XML.frame(ic_dir, label = "Source Directory"),
      rk.XML.frame(ic_pattern, ic_note, ic_encoding, label = "File Options"),
      ic_save
    )
  )

  js_calc_ic <- '
    var dir = getValue("ic_dir");
    var pattern = getValue("ic_pattern");
    var enc = getValue("ic_encoding");

    if(pattern == "") pattern = "\\\\\\\\.csv$";

    var code = "iconv.recursive <- function (x, from) {\\n";
    code += "    attribs <- attributes (x)\\n";
    code += "    if (is.character (x)) {\\n";
    code += "        x <- iconv (x, from=from, to=\\"\\", sub=\\"\\")\\n";
    code += "    } else if (is.list (x)) {\\n";
    code += "        x <- lapply (x, function (sub) iconv.recursive (sub, from))\\n";
    code += "    }\\n";
    code += "    attributes (x) <- lapply (attribs, function (sub) iconv.recursive (sub, from))\\n";
    code += "    x\\n";
    code += "}\\n\\n";

    code += "files <- list.files(path = \\"" + dir + "\\", pattern = \\"" + pattern + "\\", full.names = TRUE)\\n";
    code += "res_list <- list()\\n";
    code += "for (f in files) {\\n";
    code += "   # Import data\\n";
    code += "   dat <- rio::import(f)\\n";
    code += "   # Convert encoding\\n";
    code += "   dat <- iconv.recursive(dat, from = \\"" + enc + "\\")\\n";
    code += "   # Use filename without extension as list key\\n";
    code += "   key_name <- tools::file_path_sans_ext(basename(f))\\n";
    code += "   res_list[[key_name]] <- dat\\n";
    code += "}\\n";

    code += "catalog_list <- res_list\\n";
    echo(code);
  '

  js_print_ic <- 'echo("rk.header(\\"Catalog Import process completed.\\")\\n");'

  help_ic <- rk.rkh.doc(
    title = rk.rkh.title("Import Catalog"),
    summary = rk.rkh.summary("Batch imports CSV files from a directory into a named list of data frames."),
    usage = rk.rkh.usage("Select a directory containing CSV files. The plugin will create a List where each item is a dataframe named after the file (minus extension)."),
    settings = rk.rkh.settings(
      rk.rkh.setting(id="ic_dir", text="Directory containing the catalog files."),
      rk.rkh.setting(id="ic_encoding", text="Original character encoding.")
    )
  )

  component_ic <- rk.plugin.component("Import Catalog", xml = list(dialog = ic_dialog), js = list(require = "rio", calculate = js_calc_ic, printout = js_print_ic), rkh = list(help = help_ic), hierarchy = list("data", "Names and Labels", "Value labels (levels)"))

  # =========================================================================================
  # Main Skeleton Call
  # =========================================================================================

  rk.plugin.skeleton(
    about = package_about,
    path = ".",
    xml = list(dialog = tn_dialog),
    js = list(require = c("janitor", "stringr", "vctrs"), calculate = js_calc_tn, printout = js_print_tn),
    rkh = list(help = help_tn),
    components = list(component_rp, component_sr, component_dl, component_vl, component_ic),
    pluginmap = list(name = "Tidy Names and Labels", hierarchy = list("data", "Names and Labels")),
    create = c("pmap", "xml", "js", "desc", "rkh"),
    load = TRUE,
    overwrite = TRUE,
    show = FALSE
  )

  cat("Plugin files generated successfully in '", normalizePath("."), "'. Run rk.updatePluginMessages('.') and devtools::install('.')", sep="")
})
